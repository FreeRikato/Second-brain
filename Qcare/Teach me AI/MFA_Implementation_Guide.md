# MFA (Multi-Factor Authentication) Implementation Guide

This guide explains how MFA is implemented in the QCare backend using TOTP (Time-based One-Time Password) and email OTP fallback. You'll learn the complete flow from setup to verification.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Database Schema](#database-schema)
4. [Configuration](#configuration)
5. [Implementation Flow](#implementation-flow)
6. [Service Layer](#service-layer)
7. [Controller Layer](#controller-layer)
8. [Routes & Middleware](#routes--middleware)
9. [Security Features](#security-features)
10. [Step-by-Step Implementation](#step-by-step-implementation)

---

## Overview

This implementation supports **two MFA methods**:

1. **TOTP (Time-based One-Time Password)** - Using authenticator apps (Google Authenticator, Authy, etc.)
2. **Email OTP** - As a fallback when users don't have access to their authenticator app

### Key Features

- QR code generation for easy authenticator app setup
- TOTP code validation with time drift tolerance
- Email OTP with rate limiting and attempt tracking
- Temporary MFA token for secure setup flow
- Redis-based OTP storage with automatic expiry
- Static MFA code support for QA environments

---

## Architecture

### Request Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           MFA AUTHENTICATION FLOW                           │
└─────────────────────────────────────────────────────────────────────────────┘

1. LOGIN PHASE
   ┌─────────┐    ┌────────────┐    ┌──────────┐    ┌─────────────┐
   │  User   │───▶│ POST /login│───▶│ Validate │───▶│ Generate    │
   │         │    │            │    │ Password │    │ MFA Token   │
   └─────────┘    └────────────┘    └──────────┘    └─────────────┘
                                                           │
                                                           ▼
        ┌──────────────────────────────────────────────────────────┐
        │ Set MFA Token Cookie (short-lived, 5 minutes)           │
        │ Return: { generate_qr: true } if first-time MFA setup   │
        └──────────────────────────────────────────────────────────┘

2. SETUP PHASE (TOTP)
   ┌─────────┐    ┌─────────────────┐    ┌────────────┐    ┌─────────┐
   │  User   │───▶│ GET /generate-qr│───▶│ Generate   │───▶│ QR Code │
   │         │    │                 │    │ TOTP Secret│    │ (base64)│
   └─────────┘    └─────────────────┘    └────────────┘    └─────────┘
                                                           │
                                                           ▼
        ┌──────────────────────────────────────────────────────────┐
        │ User scans QR with authenticator app (Google Auth, etc.) │
        └──────────────────────────────────────────────────────────┘

3. VERIFICATION PHASE
   ┌─────────┐    ┌───────────────┐    ┌───────────┐    ┌──────────┐
   │  User   │───▶│POST /verify-mfa│───▶│ Validate  │───▶│ Success? │
   │         │    │ (TOTP code)    │    │ TOTP Code │    │          │
   └─────────┘    └───────────────┘    └───────────┘    └──────────┘
                                                           │
                                      ┌──────────────────┴──────────────┐
                                      │ Yes                              │ No
                                      ▼                                  ▼
                             ┌─────────────────┐              ┌──────────────────┐
                             │ Set Access +    │              │ Return Error     │
                             │ Refresh Tokens  │              │ (try again)      │
                             │ Clear MFA Token │              └──────────────────┘
                             └─────────────────┘

4. FALLBACK PHASE (Email OTP)
   ┌─────────┐    ┌─────────────┐    ┌───────────┐    ┌────────────┐
   │  User   │───▶│POST /send-otp│───▶│ Generate  │───▶│ Send Email │
   │         │    │              │    │ 6-digit OTP│    │ with OTP   │
   └─────────┘    └─────────────┘    └───────────┘    └────────────┘
                                                           │
                                                           ▼
   ┌─────────┐    ┌──────────────────┐    ┌───────────┐    ┌──────────┐
   │  User   │───▶│POST /verify-mfa-otp│───▶│ Validate  │───▶│ Success? │
   │         │    │                  │    │ OTP Code  │    │          │
   └─────────┘    └──────────────────┘    └───────────┘    └──────────┘
                                                           │
                                      ┌──────────────────┴──────────────┐
                                      │ Yes                              │ No
                                      ▼                                  ▼
                             ┌─────────────────┐              ┌──────────────────┐
                             │ Set Access +    │              │ Increment Error  │
                             │ Refresh Tokens  │              │ Count (max 3)    │
                             │ Clear MFA Token │              └──────────────────┘
                             └─────────────────┘
```

---

## Database Schema

### InternalUser Entity

```typescript
// src/database/entities/InternalUser.entity.ts

@Entity({ name: "internal_users" })
class InternalUser extends BaseSerialEntity {
  // ... other fields

  @Column({ type: "varchar", nullable: true })
  mfaSecret: string | null;           // TOTP secret key

  @Column({ type: "boolean", default: false })
  isMfaVerified!: boolean;            // MFA setup completion status

  @Expose({ name: "access_token" })
  accessToken?: string;               // JWT access token

  @Expose({ name: "refresh_token" })
  refreshToken?: string;              // JWT refresh token

  @Expose({ name: "mfa_token" })
  mfaToken?: string;                  // Short-lived MFA setup token

  @Expose({ name: "generate_qr" })
  generateQr?: boolean;               // Flag to trigger QR code display
}
```

### Migration

```typescript
// Migrations that added MFA support
// Example: 1765964156041-AuthenticationMFA.ts
@Column({ type: "boolean", default: false })
is_mfa_verified: boolean;
```

---

## Configuration

### MFA Constants

```typescript
// src/shared/constants/auth.constants.ts
export const mfaConstants = {
  ISSUER: "QCare",        // App name shown in authenticator
  ALGORITHM: "sha1",      // TOTP hash algorithm
  DIGITS: 6,              // Code length
  PERIOD: 30,             // Code validity period (seconds)
} as const;
```

### OTP Configuration

```typescript
// src/configs/otp.ts
export const OTP_LENGTH = 6;           // 6-digit OTP
export const OTP_EXPIRY_SECONDS = 300;  // 5 minutes
export const OTP_REDIS_KEY_PREFIX = "otp:";
export const MAX_OTP_ATTEMPTS = 3;      // Max failed attempts
```

### Authentication Configuration

```typescript
// src/configs/auth.ts (based on usage)
export const authConfig = {
  accessTokenExpiry: 3600,      // 1 hour
  refreshTokenExpiry: 604800,   // 7 days
  mfaTokenExpiry: 300,          // 5 minutes (for setup phase)

  // Different secrets for different token types
  accessTokenSecret: process.env.JWT_ACCESS_SECRET,
  refreshTokenSecret: process.env.JWT_REFRESH_SECRET,
  mfaTokenSecret: process.env.JWT_MFA_SECRET,
};
```

---

## Implementation Flow

### Phase 1: Login

When a user logs in with email and password:

1. **Validate credentials** - Check email exists and password matches
2. **Generate MFA Token** - Create a short-lived JWT (5 minutes) for MFA flow
3. **Check first login** - Set `generateQr` flag if user needs MFA setup
4. **Set MFA cookie** - Store MFA token in HTTP-only cookie

```typescript
// src/services/auth.service.ts - loginWithCreds()
export const loginWithCreds = async (email: string, password: string) => {
  const user = await getUserByEmail(email);
  if (!user) throw new BadRequestError("", LOGIN_ERROR);

  const isValid = await user.validatePassword(password);
  if (!isValid) throw new BadRequestError("", LOGIN_ERROR);

  user.generateMfaToken();      // Generate short-lived MFA token
  user.checkIfFirstLogin();     // Set generateQr flag if needed

  return user;
};
```

### Phase 2: TOTP Setup (QR Code Generation)

If it's the user's first time or MFA isn't verified:

1. **Generate TOTP secret** - Create a unique secret key
2. **Create otpauth URL** - Format: `otpauth://totp/ISSUER:USER?secret=SECRET&...`
3. **Store secret** - Save to database (unverified)
4. **Generate QR code** - Convert URL to base64 image

```typescript
// src/services/auth.service.ts - generateQrCodeUrl()
export const generateQrCodeUrl = async (userId: string, email: string) => {
  // Generate TOTP key with custom settings
  const key = Totp.generateKey(
    {
      issuer: mfaConstants.ISSUER,  // "QCare"
      user: email,
    },
    {
      algo: mfaConstants.ALGORITHM,  // "sha1"
      digits: mfaConstants.DIGITS,    // 6
      period: mfaConstants.PERIOD,    // 30 seconds
    },
  );

  // Save secret to database (mark as unverified)
  await saveOne({
    entity: InternalUser,
    data: {
      id: userId,
      mfaSecret: key.secret,       // Store the secret
      isMfaVerified: false,        // Not verified yet
    },
  });

  // Generate QR code as base64 data URL
  const qrCodeDataUrl = await QRCode.toDataURL(key.url);
  return qrCodeDataUrl;
};
```

### Phase 3: TOTP Verification

User provides 6-digit code from authenticator app:

1. **Validate TOTP code** - Check against stored secret with time drift tolerance
2. **Mark as verified** - Update `isMfaVerified` flag
3. **Generate auth tokens** - Create access and refresh tokens
4. **Clear MFA token** - Remove temporary MFA cookie

```typescript
// src/services/auth.service.ts - validateMfaCode()
export const validateMfaCode = async (userId: string, code: string) => {
  const user = await getUserById(userId);
  if (!user) throw new UnauthenticationError(USER_NOT_FOUND);
  if (!user.mfaSecret) throw new BadRequestError(MFA_NOT_SET);

  // QA Environment: Allow static code for testing
  const currentEnv = env.NODE_ENV as NodeEnv;
  const staticMfaCode = env.QA_STATIC_MFA_CODE;

  if (currentEnv === NodeEnv.LOCAL && code === staticMfaCode) {
    await saveOne({
      entity: InternalUser,
      data: { id: userId, isMfaVerified: true },
    });
    user.generateAuthTokens();
    return user;
  }

  // Regular TOTP validation (with 1-period drift tolerance)
  const isValid = Totp.validate({
    passcode: code,
    secret: user.mfaSecret,
    drift: 1,  // Allow ±30 seconds clock skew
  });

  if (!isValid) throw new BadRequestError(INVALID_OTP);

  // Mark MFA as verified
  await saveOne({
    entity: InternalUser,
    data: { id: userId, isMfaVerified: true },
  });

  user.generateAuthTokens();
  return user;
};
```

### Phase 4: Email OTP (Fallback)

When user can't access authenticator app:

1. **Generate OTP** - Create 6-digit random code
2. **Store in Redis** - Save with expiry and attempt counter
3. **Send email** - Queue email with OTP
4. **Validate OTP** - Check code, track attempts, consume on success

```typescript
// src/services/otp.service.ts - generateAndSendOtp()
export const generateAndSendOtp = async (email: string): Promise<void> => {
  const user = await getUserByEmail(email);
  if (!user) throw new BadRequestError(USER_NOT_FOUND);

  // Generate cryptographically secure random OTP
  const otp = generateOTP(OTP_LENGTH);  // 6 digits

  // Store in Redis with metadata
  await storeOTP(email, otp);

  // Send email via queue
  await sendOtpEmail(email, otp, user.name ?? "");
};
```

---

## Service Layer

### MFA Service Functions

```typescript
// src/services/auth.service.ts

// Generate QR code for TOTP setup
generateQrCodeUrl(userId: string, email: string): Promise<string>

// Validate TOTP code from authenticator app
validateMfaCode(userId: string, code: string): Promise<InternalUser>

// Validate email OTP (fallback method)
validateMfaOtp(userId: string, otpCode: string): Promise<InternalUser>
```

### OTP Service Functions

```typescript
// src/services/otp.service.ts

// Generate and send OTP via email
generateAndSendOtp(email: string): Promise<void>

// Validate OTP and consume it (single-use)
validateAndConsumeOtp(email: string, otpCode: string): Promise<void>

// Retrieve stored OTP data from Redis
getStoredOtp(email: string): Promise<IOtpData | null>

// Increment failed attempt counter
incrementOtpAttempts(email: string): Promise<number>

// Delete OTP from Redis
deleteStoredOtp(email: string): Promise<void>
```

### OTP Data Structure

```typescript
export interface IOtpData {
  code: string;        // 6-digit OTP
  attempts: number;    // Failed attempt count
  createdAt: number;   // Timestamp (ms)
}
```

### OTP Generation Logic

```typescript
function generateOTP(length = OTP_LENGTH): string {
  // Generate cryptographically secure random number
  const otp = crypto.randomInt(0, Math.pow(10, length));
  // Pad with leading zeros (e.g., "123" becomes "000123")
  return otp.toString().padStart(length, "0");
}

async function storeOTP(email: string, otp: string): Promise<void> {
  const otpKey = `${OTP_REDIS_KEY_PREFIX}${email}`;
  const otpData = {
    code: otp,
    attempts: 0,
    createdAt: Date.now(),
  };

  // Store in Redis with expiry
  await redis.set(otpKey, JSON.stringify(otpData), "EX", OTP_EXPIRY_SECONDS);
}
```

---

## Controller Layer

### Controllers

```typescript
// src/controllers/auth.controller.ts

// Handle login request
export const login: RequestHandler = async (req, res) => {
  const { email, password } = plainToInstance(LoginRequest, req.body);
  const user = await loginWithCreds(email, password);

  // Set MFA token cookie (5 minutes)
  setCookie(res, tokenType.MFA_TOKEN, user.mfaToken, {
    maxAge: authConfig.mfaTokenExpiry * 1000,
    path: defaultPath,
  });

  const response = {
    message: AuthResponse.LOGIN_SUCCESS,
  };

  if (user.generateQr) {
    response.generate_qr = true;  // Tell frontend to show QR setup
  }
  return res.json(response);
};

// Generate QR code
export const generateQr: RequestHandler = async (req, res) => {
  const { id, email } = req.user;
  const url = await generateQrCodeUrl(id, email);
  return res.json({ qr_base64: url });
};

// Verify TOTP code
export const verifyCode: RequestHandler = async (req, res) => {
  const { code } = plainToInstance(VerifyCodeRequest, req.body);
  const userId = req.user.id;
  const user = await validateMfaCode(userId, code);

  res.clearCookie(tokenType.MFA_TOKEN, { path: mfaPath });

  // Set access token cookie
  setCookie(res, tokenType.ACCESS_TOKEN, user.accessToken, {
    maxAge: authConfig.accessTokenExpiry * 1000,
    path: defaultPath,
  });

  // Set refresh token cookie
  setCookie(res, tokenType.REFRESH_TOKEN, user.refreshToken, {
    maxAge: authConfig.refreshTokenExpiry * 1000,
    path: refreshPath,
  });

  return res.json({ message: AuthResponse.VERIFY_CODE_SUCCESS });
};

// Send OTP via email
export const sendOtp: RequestHandler = async (req, res) => {
  const email = req.user.email;
  await generateAndSendOtp(email);
  return res.json({ message: AuthResponse.SEND_OTP_SUCCESS });
};

// Verify email OTP
export const verifyMfaOtp: RequestHandler = async (req, res) => {
  const { otp } = plainToInstance(VerifyMfaOtpRequest, req.body);
  const userId = req.user.id;
  const user = await validateMfaOtp(userId, otp);

  res.clearCookie(tokenType.MFA_TOKEN, { path: mfaPath });

  setCookie(res, tokenType.ACCESS_TOKEN, user.accessToken, {
    maxAge: authConfig.accessTokenExpiry * 1000,
    path: defaultPath,
  });

  setCookie(res, tokenType.REFRESH_TOKEN, user.refreshToken, {
    maxAge: authConfig.refreshTokenExpiry * 1000,
    path: refreshPath,
  });

  return res.json({ message: AuthResponse.VERIFY_MFA_OTP_SUCCESS });
};
```

---

## Routes & Middleware

### Route Definitions

```typescript
// src/routes/v1/auth.routes.ts

// Login - returns MFA token
router.post(APIRoute.LOGIN, validateReqBody(loginRequestSchema), login);

// Generate QR code (requires MFA token)
router.get(
  APIRoute.GENERATE_QR,
  validateToken(tokenType.MFA_TOKEN, false),
  generateQr,
);

// Verify TOTP code (requires MFA token)
router.post(
  APIRoute.VERIFY_MFA,
  validateToken(tokenType.MFA_TOKEN, false),
  validateReqBody(verifyMfaCodeRequestSchema),
  verifyCode,
);

// Send OTP via email (requires MFA token, rate-limited)
router.post(
  APIRoute.SEND_OTP,
  validateToken(tokenType.MFA_TOKEN, false),
  otpRateLimiter,  // Rate limiting middleware
  sendOtp,
);

// Verify email OTP (requires MFA token)
router.post(
  APIRoute.VERIFY_MFA_OTP,
  validateToken(tokenType.MFA_TOKEN, false),
  validateReqBody(verifyMfaOtpRequestSchema),
  verifyMfaOtp,
);
```

### API Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/api/v1/auth/login` | Login with email/password | No |
| GET | `/api/v1/auth/generate-qr` | Get QR code for TOTP setup | MFA Token |
| POST | `/api/v1/auth/verify-mfa` | Verify TOTP code | MFA Token |
| POST | `/api/v1/auth/send-otp` | Send email OTP | MFA Token |
| POST | `/api/v1/auth/verify-mfa-otp` | Verify email OTP | MFA Token |

### Validation Schemas

```typescript
// src/validations/authValidation.ts

export const verifyMfaCodeRequestSchema = z.object({
  code: z.string(),  // 6-digit TOTP code from authenticator
});

export const verifyMfaOtpRequestSchema = z.object({
  otp: z.string().regex(
    RegEx.OTP,
    `OTP must be a ${OTP_LENGTH}-digit number`
  ),
});
```

### Token Validation Middleware

```typescript
// src/middlewares/validateToken.middleware.ts

// Token type to secret mapping
const tokenSecretMap: Record<string, string> = {
  [tokenTypes.ACCESS_TOKEN]: authConfig.accessTokenSecret,
  [tokenTypes.REFRESH_TOKEN]: authConfig.refreshTokenSecret,
  [tokenTypes.MFA_TOKEN]: authConfig.mfaTokenSecret,
  [tokenTypes.RESET_TOKEN]: authConfig.resetTokenSecret,
};

// Usage: validateToken(tokenType, useInvalidDataError)
validateToken(tokenTypes.MFA_TOKEN, false)  // For MFA endpoints
```

---

## Security Features

### 1. Time-Based Code Validation

TOTP codes are only valid for 30 seconds (configurable). The implementation includes **drift tolerance** to handle clock skew:

```typescript
const isValid = Totp.validate({
  passcode: code,
  secret: user.mfaSecret,
  drift: 1,  // Allow ±30 seconds (1 period)
});
```

### 2. OTP Expiry

Email OTPs expire after 5 minutes:

```typescript
export const OTP_EXPIRY_SECONDS = 300;  // 5 minutes
```

### 3. Attempt Limiting

Failed OTP attempts are tracked:

```typescript
export const MAX_OTP_ATTEMPTS = 3;

// On each failed attempt:
await incrementOtpAttempts(email);

// After max attempts, OTP is deleted and user must request new one
if (updatedAttempts >= MAX_OTP_ATTEMPTS) {
  await deleteStoredOtp(email);
  throw new BadRequestError(OTP_ATTEMPTS_EXCEEDED);
}
```

### 4. Single-Use OTPs

OTPs are consumed immediately after successful validation:

```typescript
export const validateAndConsumeOtp = async (
  email: string,
  otpCode: string,
): Promise<void> => {
  // ... validation logic ...

  // Delete OTP to prevent reuse
  await deleteStoredOtp(email);
};
```

### 5. Rate Limiting

OTP email requests are rate-limited to prevent abuse:

```typescript
// src/middlewares/otpRateLimiter.middleware.ts
router.post(
  APIRoute.SEND_OTP,
  validateToken(tokenType.MFA_TOKEN, false),
  otpRateLimiter,  // Prevents spam
  sendOtp,
);
```

### 6. HTTP-Only Cookies

All tokens are stored in HTTP-only cookies to prevent XSS:

```typescript
setCookie(res, tokenType.ACCESS_TOKEN, user.accessToken, {
  maxAge: authConfig.accessTokenExpiry * 1000,
  path: defaultPath,
  httpOnly: true,  // Not accessible via JavaScript
  secure: true,    // Only sent over HTTPS
  sameSite: 'strict',
});
```

### 7. Token Blacklisting

Logout and token refresh blacklist old tokens in Redis:

```typescript
await redis.set(`blacklisted:${authToken}`, "1", "EX", 60 * 60 * 12);  // 12 hours
```

### 8. Separate Token Secrets

Different token types use different secrets:

```typescript
mfaTokenSecret: process.env.JWT_MFA_SECRET,       // Short-lived
accessTokenSecret: process.env.JWT_ACCESS_SECRET,  // Medium-lived
refreshTokenSecret: process.env.JWT_REFRESH_SECRET // Long-lived
```

### 9. Cryptographically Secure Random Numbers

OTP generation uses Node.js crypto:

```typescript
const otp = crypto.randomInt(0, Math.pow(10, length));
```

### 10. QA Environment Static Code

For testing in local environment:

```typescript
if (currentEnv === NodeEnv.LOCAL && code === staticMfaCode) {
  // Bypass TOTP validation in QA
  user.generateAuthTokens();
  return user;
}
```

---

## Step-by-Step Implementation

### Step 1: Install Dependencies

```bash
npm install time2fa qrcode
npm install -D @types/qrcode
```

- **time2fa**: TOTP generation and validation library
- **qrcode**: QR code generation for authenticator app setup

### Step 2: Update Entity

Add MFA fields to your user entity:

```typescript
@Entity({ name: "internal_users" })
class InternalUser extends BaseSerialEntity {
  // ... existing fields

  @Column({ type: "varchar", nullable: true })
  mfaSecret: string | null;

  @Column({ type: "boolean", default: false })
  isMfaVerified!: boolean;

  @Expose({ name: "mfa_token" })
  mfaToken?: string;

  @Expose({ name: "generate_qr" })
  generateQr?: boolean;

  generateMfaToken() {
    const { id, email, role } = this;
    this.mfaToken = generateJwtToken(
      { id, email, role: role.name },
      authConfig.mfaTokenExpiry,
      authConfig.mfaTokenSecret,
    );
  }

  checkIfFirstLogin() {
    if (!this.mfaSecret || !this.isMfaVerified) {
      this.generateQr = true;
    }
  }
}
```

### Step 3: Create Migration

Generate and run migration:

```bash
make migration-generate name=addMfaFields
```

### Step 4: Configure Constants

Create configuration files:

```typescript
// src/shared/constants/auth.constants.ts
export const mfaConstants = {
  ISSUER: "YourAppName",
  ALGORITHM: "sha1",
  DIGITS: 6,
  PERIOD: 30,
} as const;

// src/configs/otp.ts
export const OTP_LENGTH = 6;
export const OTP_EXPIRY_SECONDS = 300;
export const OTP_REDIS_KEY_PREFIX = "otp:";
export const MAX_OTP_ATTEMPTS = 3;
```

### Step 5: Implement OTP Service

```typescript
// src/services/otp.service.ts
import * as crypto from "crypto";
import { redis } from "@/configs/redis";
import { mailQueue } from "@/queues/mailQueue";

export interface IOtpData {
  code: string;
  attempts: number;
  createdAt: number;
}

function generateOTP(length = OTP_LENGTH): string {
  const otp = crypto.randomInt(0, Math.pow(10, length));
  return otp.toString().padStart(length, "0");
}

async function storeOTP(email: string, otp: string): Promise<void> {
  const otpKey = `${OTP_REDIS_KEY_PREFIX}${email}`;
  const otpData = {
    code: otp,
    attempts: 0,
    createdAt: Date.now(),
  };
  await redis.set(otpKey, JSON.stringify(otpData), "EX", OTP_EXPIRY_SECONDS);
}

export const generateAndSendOtp = async (email: string): Promise<void> => {
  const user = await getUserByEmail(email);
  if (!user) throw new BadRequestError(USER_NOT_FOUND);

  const otp = generateOTP(OTP_LENGTH);
  await storeOTP(email, otp);

  // Send email
  await mailQueue.addJobInQueue({
    notificationEvent: EmailEvent.SEND_OTP,
    recipientEmail: email,
    variables: { name: user.name ?? "", otp },
  });
};

export const validateAndConsumeOtp = async (
  email: string,
  otpCode: string,
): Promise<void> => {
  const otpData = await getStoredOtp(email);
  if (!otpData) throw new BadRequestError(OTP_EXPIRED);

  if (otpData.code !== otpCode) {
    await incrementOtpAttempts(email);
    throw new BadRequestError(INVALID_OTP);
  }

  await deleteStoredOtp(email);
};
```

### Step 6: Implement MFA Service

```typescript
// src/services/auth.service.ts
import * as QRCode from "qrcode";
import { Totp } from "time2fa";

export const generateQrCodeUrl = async (userId: string, email: string) => {
  type Algorithms = "sha1" | "sha256" | "sha512";

  const key = Totp.generateKey(
    { issuer: mfaConstants.ISSUER, user: email },
    {
      algo: mfaConstants.ALGORITHM as Algorithms,
      digits: mfaConstants.DIGITS,
      period: mfaConstants.PERIOD,
    },
  );

  await saveOne({
    entity: InternalUser,
    data: { id: userId, mfaSecret: key.secret, isMfaVerified: false },
  });

  return await QRCode.toDataURL(key.url);
};

export const validateMfaCode = async (userId: string, code: string) => {
  const user = await getUserById(userId);
  if (!user || !user.mfaSecret) throw new BadRequestError(MFA_NOT_SET);

  const isValid = Totp.validate({
    passcode: code,
    secret: user.mfaSecret,
    drift: 1,
  });

  if (!isValid) throw new BadRequestError(INVALID_OTP);

  await saveOne({
    entity: InternalUser,
    data: { id: userId, isMfaVerified: true },
  });

  user.generateAuthTokens();
  return user;
};
```

### Step 7: Create Controllers

```typescript
// src/controllers/auth.controller.ts
export const login: RequestHandler = async (req, res) => {
  const { email, password } = plainToInstance(LoginRequest, req.body);
  const user = await loginWithCreds(email, password);

  setCookie(res, tokenType.MFA_TOKEN, user.mfaToken, {
    maxAge: authConfig.mfaTokenExpiry * 1000,
    path: defaultPath,
  });

  return res.json({
    message: AuthResponse.LOGIN_SUCCESS,
    generate_qr: user.generateQr,
  });
};

export const generateQr: RequestHandler = async (req, res) => {
  const { id, email } = req.user;
  const url = await generateQrCodeUrl(id, email);
  return res.json({ qr_base64: url });
};

export const verifyCode: RequestHandler = async (req, res) => {
  const { code } = plainToInstance(VerifyCodeRequest, req.body);
  const userId = req.user.id;
  const user = await validateMfaCode(userId, code);

  res.clearCookie(tokenType.MFA_TOKEN, { path: mfaPath });

  setCookie(res, tokenType.ACCESS_TOKEN, user.accessToken, {
    maxAge: authConfig.accessTokenExpiry * 1000,
    path: defaultPath,
  });

  setCookie(res, tokenType.REFRESH_TOKEN, user.refreshToken, {
    maxAge: authConfig.refreshTokenExpiry * 1000,
    path: refreshPath,
  });

  return res.json({ message: AuthResponse.VERIFY_CODE_SUCCESS });
};
```

### Step 8: Setup Routes

```typescript
// src/routes/v1/auth.routes.ts
router.post(APIRoute.LOGIN, validateReqBody(loginRequestSchema), login);

router.get(
  APIRoute.GENERATE_QR,
  validateToken(tokenType.MFA_TOKEN, false),
  generateQr,
);

router.post(
  APIRoute.VERIFY_MFA,
  validateToken(tokenType.MFA_TOKEN, false),
  validateReqBody(verifyMfaCodeRequestSchema),
  verifyCode,
);
```

### Step 9: Add Validation Schemas

```typescript
// src/validations/authValidation.ts
export const verifyMfaCodeRequestSchema = z.object({
  code: z.string(),
});

export const verifyMfaOtpRequestSchema = z.object({
  otp: z.string().regex(RegEx.OTP, `OTP must be a ${OTP_LENGTH}-digit number`),
});
```

### Step 10: Testing

Write integration tests:

```typescript
describe("MFA Flow", () => {
  it("should generate QR code on first login", async () => {
    const user = await new InternalUserFactory(AppDataSource).create();

    const response = await request(app)
      .post("/api/v1/auth/login")
      .send({ email: user.email, password: "Test@123" });

    expect(response.body.generate_qr).toBe(true);
  });

  it("should verify TOTP code and issue tokens", async () => {
    // Setup user with MFA secret
    const user = await new InternalUserFactory(AppDataSource)
      .withMfaSecret()
      .create();

    // Generate valid TOTP code
    const code = Totp.generate({ secret: user.mfaSecret });

    const response = await request(app)
      .post("/api/v1/auth/verify-mfa")
      .set("Cookie", [`mfaToken=${mfaToken}`])
      .send({ code });

    expect(response.status).toBe(200);
    expect(response.headers["set-cookie"]).toContain(
      expect.stringContaining("accessToken")
    );
  });
});
```

---

## Complete API Flow Example

### First-Time Setup (TOTP)

```bash
# 1. Login
curl -X POST https://api.example.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"Password@123"}'

# Response:
# {
#   "message": "Login successful",
#   "generate_qr": true
# }

# 2. Get QR code (cookie from previous step)
curl -X GET https://api.example.com/api/v1/auth/generate-qr \
  -H "Cookie: mfaToken=eyJhbGc..."

# Response:
# {
#   "qr_base64": "data:image/png;base64,iVBORw0KGgoAAAANSU..."
# }

# User scans QR with Google Authenticator app

# 3. Verify TOTP code
curl -X POST https://api.example.com/api/v1/auth/verify-mfa \
  -H "Cookie: mfaToken=eyJhbGc..." \
  -H "Content-Type: application/json" \
  -d '{"code":"123456"}'

# Response:
# {
#   "message": "MFA verified successfully"
# }
# Sets: accessToken and refreshToken cookies
```

### Subsequent Logins

```bash
# 1. Login
curl -X POST https://api.example.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"Password@123"}'

# Response:
# {
#   "message": "Login successful"
# }
# (No generate_qr flag)

# 2. Verify TOTP
curl -X POST https://api.example.com/api/v1/auth/verify-mfa \
  -H "Cookie: mfaToken=eyJhbGc..." \
  -H "Content-Type: application/json" \
  -d '{"code":"789012"}'
```

### Email OTP Fallback

```bash
# 1. Request OTP
curl -X POST https://api.example.com/api/v1/auth/send-otp \
  -H "Cookie: mfaToken=eyJhbGc..."

# Response:
# {
#   "message": "OTP sent successfully"
# }
# (Email sent to user's registered email)

# 2. Verify OTP
curl -X POST https://api.example.com/api/v1/auth/verify-mfa-otp \
  -H "Cookie: mfaToken=eyJhbGc..." \
  -H "Content-Type: application/json" \
  -d '{"otp":"654321"}'
```

---

## Key Takeaways

1. **Two-phase authentication**: Login → MFA verification
2. **Temporary MFA token**: Short-lived (5 min) token for setup/verification
3. **TOTP standard**: Industry-standard time-based codes (30-second validity)
4. **Email fallback**: OTP option when authenticator unavailable
5. **Security layers**: Rate limiting, attempt tracking, expiry, blacklisting
6. **QR code setup**: Easy onboarding with authenticator apps
7. **QA support**: Static code for testing in local environment

---

## Common Patterns

### Checking if User Needs MFA Setup

```typescript
checkIfFirstLogin() {
  if (!this.mfaSecret || !this.isMfaVerified) {
    this.generateQr = true;
  }
}
```

### Validating Token Type in Middleware

```typescript
validateToken(tokenTypes.MFA_TOKEN, false)  // MFA token, no strict error mode
```

### Cookie Path Isolation

```typescript
// MFA token only works on auth endpoints
setCookie(res, tokenType.MFA_TOKEN, token, { path: "/api/v1/auth" });

// Access token works everywhere
setCookie(res, tokenType.ACCESS_TOKEN, token, { path: "/" });
```

---

## File Reference

| File | Purpose |
|------|---------|
| `src/database/entities/InternalUser.entity.ts` | MFA fields and token generation |
| `src/services/auth.service.ts` | TOTP generation and validation |
| `src/services/otp.service.ts` | Email OTP generation and validation |
| `src/controllers/auth.controller.ts` | HTTP request handlers |
| `src/routes/v1/auth.routes.ts` | Route definitions |
| `src/validations/authValidation.ts` | Zod validation schemas |
| `src/shared/constants/auth.constants.ts` | MFA configuration constants |
| `src/configs/otp.ts` | OTP configuration |
| `src/middlewares/validateToken.middleware.ts` | Token validation logic |
| `src/middlewares/otpRateLimiter.middleware.ts` | OTP rate limiting |

---

This guide provides everything needed to implement MFA from scratch. The implementation follows industry standards for TOTP and includes security best practices like rate limiting, attempt tracking, and token blacklisting.
