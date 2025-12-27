# Qcare API Authentication System

Complete guide to understanding how authentication works in the Qcare API codebase.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [JWT Token System](#jwt-token-system)
3. [Authentication Flow](#authentication-flow)
4. [Middleware Chain](#middleware-chain)
5. [MFA/TOTP Authentication](#mfatotp-authentication)
6. [Token Management](#token-management)
7. [Password Reset](#password-reset)
8. [Cookie Security](#cookie-security)
9. [Webhook Authentication](#webhook-authentication)
10. [Key Files Reference](#key-files-reference)

---

## Architecture Overview

The Qcare API uses a **JWT-based authentication system** with the following components:

- **JWT Tokens**: Four types of tokens for different purposes
- **Redis**: Token blacklisting and session management
- **Bcrypt**: Password hashing
- **TOTP**: Multi-factor authentication
- **HTTP-only Cookies**: Secure token storage
- **Role-Based Access Control**: Granular permissions

### User Types

The system handles two types of users:

1. **Internal Users** (`InternalUser` entity)
   - Super Admin, Admin, Customer Executive, Customer Care
   - Stored in `internal_users` table
   - Have role relationships

2. **Residents** (`UserProfile` entity)
   - Role: `Role.RESIDENT`
   - Stored in `user_profiles` table
   - Have blacklist status

---

## JWT Token System

### Token Types

The system uses **four types of JWT tokens**, each derived from a master secret:

```typescript
// src/configs/auth.ts
export const authConfig = {
  accessTokenSecret: masterSecret + "_ACCESS_TOKEN",
  refreshTokenSecret: masterSecret + "_REFRESH_TOKEN",
  mfaTokenSecret: masterSecret + "_MFA_TOKEN",
  resetTokenSecret: masterSecret + "_RESET_TOKEN",

  accessTokenExpiry: 60 * 15,      // 15 minutes
  refreshTokenExpiry: 60 * 60 * 24, // 24 hours
  mfaTokenExpiry: 60 * 5,           // 5 minutes
};
```

### Token Purposes

| Token Type        | Purpose                    | Expiry       | Secret                            |
| ----------------- | -------------------------- | ------------ | --------------------------------- |
| **Access Token**  | API request authentication | 15 minutes   | `masterSecret + "_ACCESS_TOKEN"`  |
| **Refresh Token** | Get new access tokens      | 24 hours     | `masterSecret + "_REFRESH_TOKEN"` |
| **MFA Token**     | MFA verification flow      | 5 minutes    | `masterSecret + "_MFA_TOKEN"`     |
| **Reset Token**   | Password reset flow        | Configurable | `masterSecret + "_RESET_TOKEN"`   |

### Token Payload Structure

```typescript
interface TokenPayload {
  id: string;      // User ID
  email: string;   // User email
  role: Role;      // User role (e.g., "super_admin", "resident")
}
```

### Token Generation

Tokens are generated in the user entity methods:

**For Internal Users** (`src/database/entities/InternalUser.entity.ts`):
```typescript
generateAuthTokens() {
  const { id, email, role } = this;

  this.accessToken = generateJwtToken(
    { id, email, role: role.name },
    authConfig.accessTokenExpiry,
    authConfig.accessTokenSecret,
  );

  this.refreshToken = generateJwtToken(
    { id, email, role: role.name },
    authConfig.refreshTokenExpiry,
    authConfig.refreshTokenSecret,
  );
}
```

**For Residents** (`src/database/entities/UserProfile.entity.ts`):
```typescript
generateAuthTokens() {
  const { id, email } = this;

  this.accessToken = generateJwtToken(
    { id, email, role: Role.RESIDENT },
    authConfig.accessTokenExpiry,
    authConfig.accessTokenSecret,
  );

  this.refreshToken = generateJwtToken(
    { id, email, role: Role.RESIDENT },
    authConfig.refreshTokenExpiry,
    authConfig.refreshTokenSecret,
  );
}
```

---

## Authentication Flow

### Complete Login Flow

```
┌─────────────────┐
│  User submits   │
│  credentials    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Validate       │
│  email/password │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Check MFA      │
│  enabled?       │
└────────┬────────┘
         │
    ┌────┴────┐
    │ Yes     │ No
    ▼         ▼
┌────────┐ ┌──────────────┐
│ Generate│ │ Generate     │
│ MFA     │ │ Auth Tokens  │
│ token   │ └──────────────┘
└────────┘      │
    │           ▼
    │    ┌──────────────┐
    │    │ Set cookies  │
    │    │ (access +    │
    │    │  refresh)    │
    │    └──────────────┘
    │           │
    └─────┬─────┘
          ▼
   ┌──────────────┐
   │ Return       │
   │ response     │
   └──────────────┘
```

### Step 1: Login with Credentials

**Controller**: `src/controllers/auth.controller.ts`

```typescript
export const login: RequestHandler = async (req, res) => {
  const { email, password } = plainToInstance(LoginRequest, req.body);

  // Validate credentials and get user
  const user = await loginWithCreds(email, password);

  // Set MFA token cookie (if MFA enabled)
  setCookie(res, tokenType.MFA_TOKEN, user.mfaToken, {
    maxAge: authConfig.mfaTokenExpiry * 1000,
    path: defaultPath,
  });

  return res.json({
    message: "Login successful",
    generate_qr: user.generateQr  // Whether to show QR code
  });
};
```

**Service**: `src/services/auth.service.ts`

```typescript
export const loginWithCreds = async (email: string, password: string) => {
  // Fetch user with role
  const user = await getUserByEmail(email);

  // Verify password using bcrypt
  const isPasswordValid = await bcrypt.compare(password, user.password);
  if (!isPasswordValid) {
    throw new UnauthenticationError("Invalid credentials");
  }

  // Check if user is blacklisted (for residents)
  if (user instanceof UserProfile && user.isBlacklisted) {
    throw new UnauthenticationError("Account blacklisted");
  }

  // Generate MFA token if enabled
  if (user instanceof InternalUser && user.isMfaEnabled) {
    const mfaToken = generateJwtToken(
      { id: user.id, email: user.email },
      authConfig.mfaTokenExpiry,
      authConfig.mfaTokenSecret,
    );
    user.mfaToken = mfaToken;
  } else {
    // No MFA, generate auth tokens directly
    user.generateAuthTokens();
  }

  return user;
};
```

### Step 2: MFA Verification (if enabled)

```typescript
export const verifyMfa: RequestHandler = async (req, res) => {
  const { code } = req.body;
  const mfaToken = req.cookies.mfaToken;

  // Validate MFA token
  const decoded = validateJwt(mfaToken, authConfig.mfaTokenSecret);
  const payload = decoded.data as TokenPayload;

  // Verify TOTP code
  const user = await validateMfaCode(payload.id, code);

  // Set auth cookies
  setCookie(res, tokenType.ACCESS_TOKEN, user.accessToken, {
    maxAge: authConfig.accessTokenExpiry * 1000,
    path: defaultPath,
  });

  setCookie(res, tokenType.REFRESH_TOKEN, user.refreshToken, {
    maxAge: authConfig.refreshTokenExpiry * 1000,
    path: refreshPath,
  });

  // Clear MFA token
  setCookie(res, tokenType.MFA_TOKEN, "", {
    maxAge: 0,
    path: defaultPath,
  });

  return res.json({ message: "MFA verified successfully" });
};
```

---

## Middleware Chain

### Route Protection Pattern

Routes are protected using a middleware chain:

```typescript
router.post(
  APIRoute.EMPTY,
  validateToken(),                    // 1. Authenticate
  setAccessPermission([Role.ADMIN]),  // 2. Authorize
  validateReqBody(schema),            // 3. Validate input
  controllerHandler,                  // 4. Handle request
);
```

### 1. Token Validation Middleware

**File**: `src/middlewares/validateToken.middleware.ts`

```typescript
export default function validateToken(
  tokenType = "accessToken",
  useInvalidDataError = false,
) {
  return async (req: Request, _: Response, next: NextFunction) => {
    // Get token from cookies
    const token = req.cookies[tokenType] as string;

    if (!token) {
      throw new UnauthenticationError("Token not provided");
    }

    // Check Redis blacklist
    const isBlacklisted = await redis.get(`blacklisted:${token}`);
    if (isBlacklisted) {
      throw new UnauthenticationError("Token blacklisted");
    }

    // Get the appropriate secret
    const secret = tokenSecretMap[tokenType];

    // Validate JWT
    const decoded = validateJwt(token, secret);
    const payload = decoded.data as TokenPayload;

    // Fetch user based on role
    let user;
    switch (payload.role) {
      case Role.RESIDENT:
        user = await findOne({
          entity: UserProfile,
          options: { where: { email: payload.email } },
        });
        break;
      default:
        user = await findOne({
          entity: InternalUser,
          options: { where: { email: payload.email } },
        });
        break;
    }

    if (!user) {
      throw new UnauthenticationError("User not found");
    }

    // Attach to request
    req.user = payload;
    req.token = token;
    req.refreshToken = req.cookies[tokenType.REFRESH_TOKEN];

    next();
  };
}
```

**Key Features**:
- Reads token from HTTP-only cookies
- Checks Redis blacklist before validation
- Fetches user from appropriate entity based on role
- Attaches user payload to `req.user`
- Stores current tokens for blacklisting

### 2. Role-Based Access Control

**File**: `src/middlewares/setAccessPermission.middleware.ts`

```typescript
export const setAccessPermission = (allowedRoles: Role[]) => {
  return (req: Request, _: Response, next: NextFunction) => {
    const userRole = req.user.role;

    if (!allowedRoles.includes(userRole)) {
      throw new UnauthorizationError(FORBIDDEN_ACCESS);
    }

    next();
  };
};
```

**Usage Examples**:

```typescript
// Only super admins
setAccessPermission([Role.SUPER_ADMIN])

// Multiple roles
setAccessPermission([Role.ADMIN, Role.CUSTOMER_EXECUTIVE])

// All internal users
setAccessPermission([
  Role.SUPER_ADMIN,
  Role.ADMIN,
  Role.CUSTOMER_EXECUTIVE,
  Role.CUSTOMER_CARE,
])
```

### 3. Refresh Token Middleware

Special middleware for handling refresh token rotation:

```typescript
export const validateRefreshToken = async (
  req: Request,
  _: Response,
  next: NextFunction,
) => {
  const refreshToken = req.cookies[tokenType.REFRESH_TOKEN];

  if (!refreshToken) {
    throw new UnauthenticationError("Refresh token not provided");
  }

  // Validate and get new tokens
  const userPayloadData = validateJwt(
    refreshToken,
    authConfig.refreshTokenSecret,
  );

  const user = await findOne({
    entity: InternalUser,
    options: {
      where: { email: (userPayloadData.data as TokenPayload).email },
      relations: ["role"],
    },
  });

  // Blacklist old tokens
  await blackListAuthTokens(req.token, refreshToken);

  // Generate new tokens
  user.generateAuthTokens();

  req.newTokens = {
    accessToken: user.accessToken,
    refreshToken: user.refreshToken,
  };

  next();
};
```

---

## MFA/TOTP Authentication

### TOTP Setup Flow

```
┌─────────────────┐
│ User requests   │
│ MFA setup       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Generate TOTP   │
│ secret + QR URL │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Store secret    │
│ in database     │
│ (unverified)    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Return QR code  │
│ to user         │
└─────────────────┘
```

### Generate QR Code

**Service**: `src/services/auth.service.ts`

```typescript
export const generateQrCodeUrl = async (userId: string, email: string) => {
  // Generate TOTP key
  const key = Totp.generateKey({
    issuer: "QCare",
    user: email,
  }, {
    algo: "sha1",
    digits: 6,
    period: 30,
  });

  // Save secret (not verified yet)
  await saveOne({
    entity: InternalUser,
    data: {
      id: userId,
      mfaSecret: key.secret,
      isMfaVerified: false,
    },
  });

  // Generate QR code image
  const qrCodeDataUrl = await QRCode.toDataURL(key.url);

  return qrCodeDataUrl;
};
```

### Verify and Enable MFA

```typescript
export const verifyAndEnableMfa = async (
  userId: string,
  code: string,
) => {
  const user = await getUserById(userId);

  if (!user.mfaSecret) {
    throw new BadRequestError("MFA not set up");
  }

  // Validate TOTP code
  const isValid = Totp.validate({
    passcode: code,
    secret: user.mfaSecret,
    drift: 1,  // Allow 1 time step variance
  });

  if (!isValid) {
    throw new BadRequestError("Invalid OTP");
  }

  // Enable MFA
  await saveOne({
    entity: InternalUser,
    data: {
      id: userId,
      isMfaVerified: true,
      isMfaEnabled: true,
    },
  });

  // Generate backup codes
  const backupCodes = generateBackupCodes(userId);

  return { user, backupCodes };
};
```

### TOTP Validation during Login

```typescript
export const validateMfaCode = async (userId: string, code: string) => {
  const user = await getUserById(userId);

  if (!user.mfaSecret) {
    throw new BadRequestError("MFA not set up");
  }

  // QA environment: Allow static code
  if (currentEnv === NodeEnv.LOCAL && code === env.QA_STATIC_MFA_CODE) {
    await saveOne({
      entity: InternalUser,
      data: {
        id: userId,
        isMfaVerified: true,
      },
    });
    user.generateAuthTokens();
    return user;
  }

  // Regular TOTP validation
  const isValid = Totp.validate({
    passcode: code,
    secret: user.mfaSecret,
    drift: 1,
  });

  if (!isValid) {
    throw new BadRequestError("Invalid OTP");
  }

  // Mark MFA as verified for this session
  await saveOne({
    entity: InternalUser,
    data: { id: userId, isMfaVerified: true },
  });

  user.generateAuthTokens();
  return user;
};
```

### Disable MFA

```typescript
export const disableMfa = async (userId: string) => {
  await saveOne({
    entity: InternalUser,
    data: {
      id: userId,
      mfaSecret: null,
      isMfaEnabled: false,
      isMfaVerified: false,
    },
  });
};
```

---

## Token Management

### Token Blacklisting

Tokens are blacklisted in Redis to prevent reuse after logout or token rotation:

**Service**: `src/services/auth.service.ts`

```typescript
export const blackListAuthTokens = async (
  authToken: string,
  refreshToken: string,
) => {
  // Blacklist access token (12 hours)
  await redis.set(
    `blacklisted:${authToken}`,
    "1",
    "EX",
    60 * 60 * 12
  );

  // Check if refresh token already blacklisted
  const isBlacklisted = await redis.get(`blacklisted:${refreshToken}`);

  if (!isBlacklisted) {
    // Blacklist refresh token (12 hours)
    await redis.set(
      `blacklisted:${refreshToken}`,
      "1",
      "EX",
      60 * 60 * 12
    );
  }
};
```

**When tokens are blacklisted**:
- After successful token validation (automatic rotation)
- During logout
- During refresh token flow

### Refresh Token Flow

```typescript
export const refreshAccessToken = async (
  refreshToken: string,
  oldAccessToken: string,
) => {
  // Check if refresh token is blacklisted
  const isBlacklisted = await redis.get(
    `blacklisted:${refreshToken}`
  );

  if (isBlacklisted) {
    throw new UnauthenticationError("Token blacklisted");
  }

  // Validate refresh token
  const userPayloadData = validateJwt(
    refreshToken,
    authConfig.refreshTokenSecret,
  );

  // Fetch user
  const user = await findOne({
    entity: InternalUser,
    options: {
      where: {
        email: (userPayloadData.data as TokenPayload).email,
      },
      relations: ["role"],
    },
  });

  if (!user) {
    throw new UnauthenticationError("User not found");
  }

  // Blacklist old tokens
  await blackListAuthTokens(oldAccessToken, refreshToken);

  // Generate new tokens
  user.generateAuthTokens();

  return {
    accessToken: user.accessToken,
    refreshToken: user.refreshToken,
  };
};
```

### Logout Flow

```typescript
export const logout: RequestHandler = async (req, res) => {
  const refreshToken = req.refreshToken;

  // Blacklist current tokens
  await blackListAuthTokens(req.token, refreshToken);

  // Clear access token cookie
  setCookie(res, tokenType.ACCESS_TOKEN, "", {
    maxAge: 0,
    path: defaultPath,
  });

  // Clear refresh token cookies (multiple paths)
  res.clearCookie(tokenType.REFRESH_TOKEN, { path: refreshPath });
  res.clearCookie(tokenType.REFRESH_TOKEN, {
    path: residentRefreshPath,
  });

  return res.json({ message: "Logout successful" });
};
```

---

## Password Reset

### Password Reset Flow

```
┌─────────────────┐
│ User requests   │
│ password reset  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Generate opaque │
│ reset token     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Hash token and  │
│ store in Redis  │
│ (5 min expiry)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Send email with │
│ reset link      │
└─────────────────┘
```

### Generate Reset Token

```typescript
export const sendResetPasswordMail = async (email: string) => {
  // Fetch user
  const user = await getUserByEmail(email);

  // Generate opaque token (not JWT)
  const resetToken = generateOpaqueToken();  // Random string

  // Hash token for storage
  const tokenHash = hashToken(resetToken);

  // Store in Redis with expiry
  const expiryMinutes = 5;
  await redis.set(
    `pwdreset:${tokenHash}`,
    JSON.stringify({
      id: user.id,
      email: user.email,
      role: user.role.name,
      expiresAt: dayjs().add(expiryMinutes, "minute").valueOf(),
    }),
    "PX",
    expiryMinutes * 60 * 1000,  // Milliseconds
  );

  // Create reset URL
  const resetUrl = `${env.RESET_URL}?token=${resetToken}`;

  // Send email
  await mailQueue.addJobInQueue({
    notificationEvent: EmailEvent.FORGOT_PASSWORD,
    recipientEmail: user.email,
    variables: {
      name: user.name ?? "",
      resetUrl,
    },
  });
};
```

### Reset Password with Token

```typescript
export const resetPasswordWithToken = async (
  id: string,
  token: string,
  newPassword: string,
) => {
  // Hash the provided token
  const tokenHash = hashToken(token);

  // Get reset data from Redis
  const resetData = await redis.get(`pwdreset:${tokenHash}`);

  if (!resetData) {
    throw new BadRequestError("Invalid or expired token");
  }

  const data = JSON.parse(resetData);

  // Verify user ID matches
  if (data.id !== id) {
    throw new BadRequestError("Invalid token");
  }

  // Check expiry
  if (dayjs().valueOf() > data.expiresAt) {
    await redis.del(`pwdreset:${tokenHash}`);
    throw new BadRequestError("Token expired");
  }

  // Update password
  await updatePassword(newPassword, id);

  // Delete token (one-time use)
  await redis.del(`pwdreset:${tokenHash}`);
};
```

### Password Update

```typescript
export const updatePassword = async (
  newPassword: string,
  userId: string,
) => {
  // Hash new password
  const hashedPassword = await bcrypt.hash(newPassword, 10);

  // Update in database
  await saveOne({
    entity: InternalUser,
    data: {
      id: userId,
      password: hashedPassword,
    },
  });
};
```

---

## Cookie Security

### Cookie Configuration

**File**: `src/utils/cookie.ts`

```typescript
export const baseCookieOptions: CookieOptions = {
  httpOnly: true,          // Prevent XSS attacks (not accessible via JS)
  secure: true,            // HTTPS only
  sameSite: "none",        // Allow cross-site cookies
  partitioned: true,       // CHIPS (Cookies Having Independent Partitioned State)
  domain: env.AUTH_COOKIE_DOMAIN,
};

export function setCookie(
  res: Response,
  name: string,
  value: string | undefined,
  options: Pick<CookieOptions, "path" | "maxAge">,
) {
  res.cookie(name, value, {
    ...baseCookieOptions,
    ...options,
  });
}
```

### Cookie Paths

Different cookies use different paths:

```typescript
const defaultPath = "/api";                    // Access token path
const refreshPath = "/api/v1/auth/refresh";    // Refresh token path (internal users)
const residentRefreshPath = "/api/v1/resident/auth/refresh";  // Refresh token path (residents)
```

### Setting Cookies

```typescript
// Set access token
setCookie(res, tokenType.ACCESS_TOKEN, user.accessToken, {
  maxAge: authConfig.accessTokenExpiry * 1000,  // 15 minutes
  path: defaultPath,
});

// Set refresh token
setCookie(res, tokenType.REFRESH_TOKEN, user.refreshToken, {
  maxAge: authConfig.refreshTokenExpiry * 1000,  // 24 hours
  path: refreshPath,
});
```

### Clearing Cookies

```typescript
// Clear cookie by setting maxAge to 0
setCookie(res, tokenType.ACCESS_TOKEN, "", {
  maxAge: 0,
  path: defaultPath,
});

// Or use clearCookie
res.clearCookie(tokenType.REFRESH_TOKEN, { path: refreshPath });
```

### Security Features

1. **HttpOnly**: Cookies cannot be accessed via JavaScript (prevents XSS)
2. **Secure**: Cookies only sent over HTTPS
3. **SameSite=None**: Allows cross-site requests (for frontend/backend separation)
4. **Partitioned**: Enables CHIPS for better privacy
5. **Domain**: Restricts to specific domain

---

## Webhook Authentication

Webhooks use **HMAC-SHA256** signature validation:

**File**: `src/middlewares/webhookAuth.middleware.ts`

```typescript
export const authenticateWebhook: RequestHandler = (req, _, next) => {
  const signature = req.headers["x-webhook-signature"] as string;
  const timestamp = req.headers["x-webhook-timestamp"] as string;

  if (!signature || !timestamp) {
    throw new UnauthenticationError("Missing webhook headers");
  }

  // Prevent replay attacks (5-minute window)
  const requestTime = parseInt(timestamp, 10);
  const currentTime = dayjs().unix();

  if (Math.abs(currentTime - requestTime) > 300) {
    throw new UnauthenticationError("Timestamp expired");
  }

  // Create expected signature
  const webhookSecret = env.WEBHOOK_SECRET;
  const payload = JSON.stringify(req.body) + timestamp;
  const expectedSignature = crypto
    .createHmac("sha256", webhookSecret)
    .update(payload)
    .digest("hex");

  // Timing-safe comparison (prevents timing attacks)
  if (
    !crypto.timingSafeEqual(
      Buffer.from(signature, "hex"),
      Buffer.from(expectedSignature, "hex"),
    )
  ) {
    throw new UnauthenticationError("Invalid signature");
  }

  next();
};
```

### Webhook Security Features

1. **HMAC-SHA256 Signature**: Cryptographic signature verification
2. **Timestamp Validation**: Prevents replay attacks (5-minute window)
3. **Timing-Safe Comparison**: Prevents timing attacks
4. **Payload Integrity**: Ensures request body hasn't been tampered with

### Required Headers

- `x-webhook-signature`: HMAC-SHA256 signature of `payload + timestamp`
- `x-webhook-timestamp`: Unix timestamp of request

---

## Security Best Practices

### Password Security

```typescript
// Hash passwords with bcrypt (cost factor: 10)
const hashedPassword = await bcrypt.hash(plainPassword, 10);

// Verify password
const isValid = await bcrypt.compare(plainPassword, hashedPassword);
```

### Token Security

1. **Short-lived access tokens** (15 minutes)
2. **Token blacklisting** on every request (automatic rotation)
3. **Http-only cookies** prevent XSS token theft
4. **Secure flag** ensures HTTPS-only transmission
5. **Opaque reset tokens** instead of JWT for password reset

### Rate Limiting

The system implements rate limiting for:
- OTP requests
- Password reset emails
- Login attempts (via application-level checks)

### Environment-Specific Behavior

```typescript
// Local/QA environment: Allow static MFA code for testing
if (currentEnv === NodeEnv.LOCAL && code === env.QA_STATIC_MFA_CODE) {
  // Bypass TOTP validation
}
```

---

## Key Files Reference

### Core Authentication Files

| File | Purpose |
|------|---------|
| `src/configs/auth.ts` | Authentication configuration and secrets |
| `src/services/auth.service.ts` | Authentication business logic |
| `src/controllers/auth.controller.ts` | Auth HTTP endpoints |
| `src/middlewares/validateToken.middleware.ts` | Token validation middleware |
| `src/middlewares/setAccessPermission.middleware.ts` | Role-based authorization |
| `src/middlewares/webhookAuth.middleware.ts` | Webhook signature validation |
| `src/utils/cookie.ts` | Cookie management utilities |
| `src/utils/jwt.ts` | JWT generation and validation |

### Entity Files

| File | Purpose |
|------|---------|
| `src/database/entities/InternalUser.entity.ts` | Internal user entity with token generation |
| `src/database/entities/UserProfile.entity.ts` | Resident user entity with token generation |
| `src/database/entities/Role.entity.ts` | Role definitions |

### Validation Files

| File | Purpose |
|------|---------|
| `src/validations/auth.validation.ts` | Auth request validation schemas |

### Type Definitions

```typescript
// Token payload structure
interface TokenPayload {
  id: string;
  email: string;
  role: Role;
}

// Role enum
enum Role {
  SUPER_ADMIN = "super_admin",
  ADMIN = "admin",
  CUSTOMER_EXECUTIVE = "customer_executive",
  CUSTOMER_CARE = "customer_care_coordinator",
  RESIDENT = "resident",
}

// Token type enum
enum tokenType {
  ACCESS_TOKEN = "accessToken",
  REFRESH_TOKEN = "refreshToken",
  MFA_TOKEN = "mfaToken",
}
```

---

## Common Patterns

### Protected Route Example

```typescript
import { Router } from "express";
import validateToken from "@/middlewares/validateToken.middleware";
import { setAccessPermission } from "@/middlewares/setAccessPermission.middleware";
import { validateReqBody } from "@/middlewares/validateRequest.middleware";
import { Role } from "@/shared/constants";
import { someSchema } from "@/validations/some.validation";
import { someController } from "@/controllers/some.controller";

const router = Router();

router.post(
  "/api/v1/some-route",
  validateToken(),                                  // 1. Authenticate
  setAccessPermission([Role.ADMIN, Role.SUPER_ADMIN]),  // 2. Authorize
  validateReqBody(someSchema),                      // 3. Validate input
  someController,                                   // 4. Handle request
);

export default router;
```

### Accessing Authenticated User

```typescript
export const someController: RequestHandler = async (req, res) => {
  // User payload attached by validateToken middleware
  const { id, email, role } = req.user;

  // Use user information for business logic
  const result = await someService(id);

  return res.json({ message: "Success", data: result });
};
```

### Manual Token Validation

```typescript
import { validateJwt } from "@/utils/jwt";
import { authConfig } from "@/configs/auth";

// Validate a token manually
const decoded = validateJwt(
  tokenString,
  authConfig.accessTokenSecret,
);

const payload = decoded.data as TokenPayload;
console.log(payload.id, payload.email, payload.role);
```

---

## Summary

The Qcare API authentication system provides:

1. **Multi-token JWT architecture** with different purposes (access, refresh, MFA, reset)
2. **Role-based access control** for granular permissions
3. **MFA/TOTP support** for enhanced security
4. **Redis-based token blacklisting** for session invalidation
5. **Secure cookie storage** with HttpOnly, Secure, and SameSite flags
6. **Password reset flow** with one-time opaque tokens
7. **Webhook authentication** with HMAC signature validation
8. **Automatic token rotation** on every authenticated request
9. **Environment-specific behavior** for QA/testing

The system follows security best practices including bcrypt password hashing, short-lived tokens, timing-safe comparisons, and comprehensive protection against common attacks (XSS, replay attacks, timing attacks).
