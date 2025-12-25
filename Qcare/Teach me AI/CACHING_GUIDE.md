# Caching Guide for QCare API

A comprehensive guide to implementing caching with Redis in the QCare backend codebase.

## Table of Contents

1. [Overview](#overview)
2. [Redis Configuration](#redis-configuration)
3. [Cache Key Patterns](#cache-key-patterns)
4. [TTL Strategies](#ttl-strategies)
5. [Common Caching Patterns](#common-caching-patterns)
6. [Cache Invalidation](#cache-invalidation)
7. [Rate Limiting with Redis](#rate-limiting-with-redis)
8. [Testing with Redis](#testing-with-redis)
9. [Security Best Practices](#security-best-practices)
10. [Quick Reference](#quick-reference)

---

## Overview

This codebase uses **Redis** for:
- Session management (token blacklisting)
- One-time passwords (OTP) storage
- Rate limiting
- Temporary data storage (e.g., multi-step forms)
- User restrictions (e.g., contact update cooldowns)

**Library**: `ioredis` (v5.x)

**BullMQ**: Uses the same Redis connection for job queues.

---

## Redis Configuration

### Setup (`src/configs/redis.ts`)

```typescript
import Redis from "ioredis";
import env from "@/configs/environment";

export const redis = new Redis({
  host: env.REDIS_HOST,
  port: env.REDIS_PORT,
  maxRetriesPerRequest: null, // Required for BullMQ compatibility
});
```

**Key Points**:
- Single persistent connection shared across the app
- `maxRetriesPerRequest: null` is critical for BullMQ compatibility
- Environment variables for host/port configuration

### Environment Variables

```typescript
// In envValidationSchema
REDIS_HOST: z.string(),
REDIS_PORT: z.coerce.number().default(6379),
```

---

## Cache Key Patterns

### Best Practices

1. **Hierarchical Keys**: Organize keys by domain and purpose
2. **Namespaced Prefixes**: Use clear prefixes for different contexts
3. **Consistent Naming**: Follow `domain:feature:identifier` pattern

### Examples from Codebase

```typescript
// ✅ Good - Hierarchical and descriptive
"otp:user@example.com"
"blacklisted:eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
"pwdreset:a1b2c3d4e5f6..."
"resident:refund-details:123:otp"
"resident:contact-update:123:phone:+1234567890"
"rate-limit:reset-password:456"

// ❌ Bad - Unclear or flat
"otp123"
"token_user_123"
"refund_data"
```

### Creating Key Constants

**File**: `src/shared/constants/cache.constants.ts`

```typescript
// Hierarchical key builders for type safety
export const ResidentContactInfoUpdateKey = {
  ROOT: (residentId: string) => `resident:contact-update:${residentId}`,
  PHONE: (residentId: string, phoneCode: string, phoneNumber: string) =>
    `${ResidentContactInfoUpdateKey.ROOT(residentId)}:phone:${phoneCode}${phoneNumber}`,
  EMAIL: (residentId: string, email: string) =>
    `${ResidentContactInfoUpdateKey.ROOT(residentId)}:email:${email}`,
} as const;

export const CacheDuration = {
  RESIDENT_CONTACT_INFO_UPDATE_OTP: 5 * 60,     // 5 minutes
  RESIDENT_CONTACT_INFO_RESTRICTED_24H: 60 * 60 * 24,  // 24 hours
  RESIDENT_CONTACT_INFO_RESTRICTED_30D: 60 * 60 * 24 * 30, // 30 days
} as const;
```

**Benefits**:
- Type-safe key generation
- Single source of truth for key patterns
- Easy refactoring
- Prevents typos in key strings

---

## TTL Strategies

### Choosing the Right TTL

| Use Case | Duration | Example |
|----------|----------|---------|
| OTP Codes | 5 minutes | `OTP_EXPIRY_SECONDS = 300` |
| Session Tokens | 12 hours | `60 * 60 * 12` |
| Rate Limiting | 15 minutes | `RATE_LIMIT_WINDOW = 900` |
| Multi-step Forms | 5-15 minutes | `300` to `900` |
| User Restrictions | 24-30 days | `60 * 60 * 24 * 30` |
| Password Reset Tokens | 5 minutes | `5 * 60` |

### Setting TTL

```typescript
// Method 1: Using SET with EX (seconds)
await redis.set(key, value, "EX", 300);           // 300 seconds

// Method 2: Using SET with PX (milliseconds)
await redis.set(key, value, "PX", 300000);        // 300000 ms (5 minutes)

// Method 3: Using SETEX
await redis.setex(key, 300, value);               // 300 seconds

// Method 4: Using EXPIRE after SET
await redis.set(key, value);
await redis.expire(key, 300);                     // 300 seconds
```

**Note**: `"EX"` and `"PX"` modes are preferred as they're atomic operations.

---

## Common Caching Patterns

### Pattern 1: Store and Retrieve Simple Values

```typescript
import { redis } from "@/configs/redis";

// Store
await redis.set("key", "value", "EX", 300);

// Retrieve
const value = await redis.get("key");
if (value) {
  console.log(value);
}
```

### Pattern 2: Store and Retrieve JSON Objects

```typescript
interface IOtpData {
  code: string;
  attempts: number;
  createdAt: number;
}

// Store with JSON.stringify
const otpData: IOtpData = {
  code: "123456",
  attempts: 0,
  createdAt: Date.now(),
};
await redis.set("otp:user@example.com", JSON.stringify(otpData), "EX", 300);

// Retrieve with JSON.parse
const stored = await redis.get("otp:user@example.com");
if (stored) {
  const otpData = JSON.parse(stored) as IOtpData;
  console.log(otpData.code);
}
```

### Pattern 3: OTP with Attempt Tracking

**Full Service Example** (`src/services/otp.service.ts`):

```typescript
import { redis } from "@/configs/redis";
import { BadRequestError } from "@/utils/apiErrors";

interface IOtpData {
  code: string;
  attempts: number;
  createdAt: number;
}

// Store OTP
async function storeOTP(email: string, otp: string): Promise<void> {
  const otpKey = `otp:${email}`;
  const otpData: IOtpData = {
    code: otp,
    attempts: 0,
    createdAt: Date.now(),
  };

  await redis.set(otpKey, JSON.stringify(otpData), "EX", 300);
}

// Get OTP
export const getStoredOtp = async (email: string): Promise<IOtpData | null> => {
  const otpKey = `otp:${email}`;
  const otpData = await redis.get(otpKey);

  if (!otpData) {
    return null;
  }

  return JSON.parse(otpData) as IOtpData;
};

// Increment attempts
export const incrementOtpAttempts = async (email: string): Promise<number> => {
  const otpData = await getStoredOtp(email);

  if (!otpData) {
    throw new BadRequestError("No OTP found for this email.");
  }

  const updatedAttempts = otpData.attempts + 1;

  if (updatedAttempts >= MAX_OTP_ATTEMPTS) {
    await deleteStoredOtp(email);
    throw new BadRequestError("OTP_ATTEMPTS_EXCEEDED");
  }

  const otpKey = `otp:${email}`;
  const updatedOtpData = {
    ...otpData,
    attempts: updatedAttempts,
  };

  await redis.set(otpKey, JSON.stringify(updatedOtpData), "EX", 300);

  return updatedAttempts;
};

// Delete OTP
export const deleteStoredOtp = async (email: string): Promise<void> => {
  const otpKey = `otp:${email}`;
  await redis.del(otpKey);
};

// Validate and consume OTP
export const validateAndConsumeOtp = async (
  email: string,
  otpCode: string,
): Promise<void> => {
  const otpData = await getStoredOtp(email);

  if (!otpData) {
    throw new BadRequestError("OTP_EXPIRED");
  }

  // Check expiry (additional check beyond TTL)
  const currentTime = Date.now();
  const timeDiff = currentTime - otpData.createdAt;

  if (timeDiff > OTP_EXPIRY_SECONDS * 1000) {
    await deleteStoredOtp(email);
    throw new BadRequestError("OTP_EXPIRED");
  }

  // Validate code
  if (otpData.code !== otpCode) {
    await incrementOtpAttempts(email);
    throw new BadRequestError("INVALID_OTP");
  }

  // Consume (delete) OTP after successful validation
  await deleteStoredOtp(email);
};
```

### Pattern 4: Multi-Step Form Caching

**Example**: Refund Details Collection (`src/services/resident/residentRefundDetails.service.ts`)

```typescript
// Step 1: Store form data temporarily
export const storeRefundDetailsInCache = async (
  residentId: string,
  refundDetailsData: ResidentRefundDetailTransformer,
) => {
  const key = `resident:refund-details:${residentId}:data`;
  await redis.set(key, JSON.stringify(refundDetailsData), "EX", 300);
};

// Step 2: Send OTP and generate token
export const sendOTPForRefundDetails = async (
  residentId: string,
  isResendOTP: boolean,
) => {
  const otp = Math.floor(10000 + Math.random() * 90000);
  const token = crypto.randomUUID();

  await redis.set(`resident:refund-details:${residentId}:otp`, otp, "EX", 300);

  if (!isResendOTP) {
    await redis.set(
      `resident:refund-details:${residentId}:token`,
      token,
      "EX",
      300,
    );
  }

  // Send OTP via email...
  return token;
};

// Step 3: Verify OTP and complete the flow
export const verifyOtpAndUpsert = async (
  residentId: string,
  otp: string,
  token: string,
) => {
  const otpKey = `resident:refund-details:${residentId}:otp`;
  const dataKey = `resident:refund-details:${residentId}:data`;
  const tokenKey = `resident:refund-details:${residentId}:token`;

  const storedOtp = await redis.get(otpKey);
  const storedToken = await redis.get(tokenKey);

  if (!storedOtp || !storedToken) {
    throw new BadRequestError("OTP_EXPIRED");
  }

  if (storedOtp !== otp) {
    throw new BadRequestError("INVALID_OTP");
  }

  if (storedToken !== token) {
    throw new BadRequestError("INVALID_TOKEN");
  }

  const cachedRefundDetails = await redis.get(dataKey);

  if (!cachedRefundDetails) {
    throw new BadRequestError("SESSION_EXPIRED");
  }

  const refundDetails = JSON.parse(cachedRefundDetails);

  // Save to database
  await upsertResidentRefundDetails(residentId, refundDetails);

  // Cleanup all related keys
  await Promise.all([
    redis.del(otpKey),
    redis.del(tokenKey),
    redis.del(dataKey),
  ]);
};
```

### Pattern 5: Token Blacklisting

**Example**: Authentication Service (`src/services/auth.service.ts`)

```typescript
import { redis } from "@/configs/redis";

// Blacklist tokens on logout
export const blackListAuthTokens = async (
  authToken: string,
  refreshToken: string,
) => {
  // Set with 12-hour expiry (matching token lifetime)
  await redis.set(`blacklisted:${authToken}`, "1", "EX", 60 * 60 * 12);

  // Check if refresh token is already blacklisted
  const isBlacklisted = await redis.get(`blacklisted:${refreshToken}`);
  if (!isBlacklisted) {
    await redis.set(`blacklisted:${refreshToken}`, "1", "EX", 60 * 60 * 12);
  }
};

// Validate token isn't blacklisted
export const validateRefreshTokenLogin = async (refreshToken: string) => {
  const isBlacklisted = await redis.get(`blacklisted:${refreshToken}`);
  if (isBlacklisted) {
    throw new UnauthenticationError("TOKEN_BLACKLISTED");
  }

  // Continue with token validation...
};
```

### Pattern 6: Hashed Token Storage (Security)

**Example**: Password Reset (`src/services/auth.service.ts`)

```typescript
import * as crypto from "crypto";
import { redis } from "@/configs/redis";

// Hash token before storing (never store raw tokens)
function hashToken(token: string): string {
  return crypto.createHash("sha256").update(token).digest("hex");
}

// Store hashed token
export const sendResetPasswordMail = async (email: string) => {
  const user = await getUserByEmail(email);
  if (!user) return;

  // Generate opaque token for user
  const resetToken = generateOpaqueToken();

  // Hash before storing
  const tokenHash = hashToken(resetToken);

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
    expiryMinutes * 60 * 1000, // milliseconds for PX mode
  );

  // Send email with raw token...
  return resetToken;
};

// Validate and reset password
export const resetPasswordWithToken = async (
  id: string,
  token: string,
  newPassword: string,
) => {
  await updatePassword(newPassword, id);

  // Clean up the token from Redis
  const tokenHash = hashToken(token);
  await redis.del(`pwdreset:${tokenHash}`);
};
```

---

## Cache Invalidation

### 1. TTL-Based Invalidation (Most Common)

```typescript
// Let Redis automatically expire keys
await redis.set(key, value, "EX", 300); // Auto-deletes after 5 minutes
```

### 2. Manual Deletion

```typescript
// Delete single key
await redis.del(key);

// Delete multiple keys atomically
await Promise.all([
  redis.del(key1),
  redis.del(key2),
  redis.del(key3),
]);
```

### 3. Pattern-Based Deletion (Use Carefully!)

```typescript
// ⚠️ WARNING: KEYS command blocks Redis in production
// Only use this in admin scripts or test cleanup

const keys = await redis.keys("resident:refund-details:*");
if (keys.length > 0) {
  await redis.del(...keys);
}

// Better approach for production: Maintain a SET of keys
// When storing, add to a tracking set
await redis.sadd("user:123:all_keys", key1, key2, key3);

// When invalidating, get all keys and delete
const userKeys = await redis.smembers("user:123:all_keys");
if (userKeys.length > 0) {
  await redis.del(...userKeys);
  await redis.del("user:123:all_keys");
}
```

### 4. Conditional Deletion

```typescript
// Only delete if value matches
const currentValue = await redis.get(key);
if (currentValue === expectedValue) {
  await redis.del(key);
}

// Or use Lua script for atomicity
const luaScript = `
  if redis.call("GET", KEYS[1]) == ARGV[1] then
    return redis.call("DEL", KEYS[1])
  else
    return 0
  end
`;
await redis.eval(luaScript, 1, key, expectedValue);
```

---

## Rate Limiting with Redis

### Pattern 1: Simple Counter with TTL

**Example**: OTP Rate Limiter (`src/middlewares/otpRateLimiter.middleware.ts`)

```typescript
import type { NextFunction, Request, Response } from "express";
import { redis } from "@/configs/redis";
import { InvalidDataError } from "@/utils/apiErrors";

const OTP_RATE_LIMIT_REQUESTS = 3;
const OTP_RATE_LIMIT_WINDOW = 900; // 15 minutes
const OTP_RATE_LIMIT_KEY_PREFIX = "otp_rate_limit:";

export const otpRateLimiter = async (
  req: Request,
  _res: Response,
  next: NextFunction,
): Promise<void> => {
  try {
    const email = req.user.email;
    const rateLimitKey = `${OTP_RATE_LIMIT_KEY_PREFIX}${email}`;

    // Increment counter (atomic operation)
    const count = await redis.incr(rateLimitKey);

    // Set expiry on first request
    if (count === 1) {
      await redis.expire(rateLimitKey, OTP_RATE_LIMIT_WINDOW);
    }

    // Check if limit exceeded
    if (count > OTP_RATE_LIMIT_REQUESTS) {
      const ttl = await redis.ttl(rateLimitKey);

      let remainingTime = 0;
      if (ttl > 0) {
        remainingTime = Math.ceil(ttl / 60); // Convert to minutes
      } else if (ttl === -1) {
        // Key exists but has no expiry, set it
        await redis.expire(rateLimitKey, OTP_RATE_LIMIT_WINDOW);
        remainingTime = Math.ceil(OTP_RATE_LIMIT_WINDOW / 60);
      }

      throw new InvalidDataError(
        `Too many requests. Try again in ${remainingTime} minutes.`,
      );
    }

    next();
  } catch (error) {
    next(error);
  }
};
```

### Pattern 2: Using express-rate-limit with Redis Store

**Example**: Password Reset Limiter (`src/middlewares/passwordResetLimiter.middleware.ts`)

```typescript
import rateLimit from "express-rate-limit";
import { RedisStore } from "rate-limit-redis";
import type { RedisReply } from "rate-limit-redis";
import { redis } from "@/configs/redis";

export const passwordResetLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 3, // 3 attempts per window
  keyGenerator: (req) => req.user.id, // Custom key
  store: new RedisStore({
    sendCommand: async (...args: [string, ...string[]]): Promise<RedisReply> => {
      return (await redis.call(...args)) as RedisReply;
    },
    prefix: "rate-limit:reset-password:",
  }),
  message: { message: "Too many password reset attempts. Try again later." },
});
```

### Rate Limiting Constants

**File**: `src/shared/constants/rateLimit.constants.ts`

```typescript
export const RATE_LIMIT_WINDOW_MS = 15 * 60 * 1000;

export const maxRequests = {
  RESIDENT: 5,   // Residents get 5 requests
  DEFAULT: 3,    // Admins get 3 requests
};

export const OTP_RATE_LIMIT_REQUESTS = 3;
export const OTP_RATE_LIMIT_WINDOW = 900;
export const OTP_RATE_LIMIT_KEY_PREFIX = "otp_rate_limit:";
```

---

## Testing with Redis

### Test Setup (`src/tests/testSetup.ts`)

```typescript
import { redis } from "@/configs/redis";
import { OTP_RATE_LIMIT_KEY_PREFIX } from "@/shared/constants/rateLimit.constants";

beforeAll(async () => {
  // Database setup...
});

afterEach(async () => {
  // Clean up Redis rate limit keys between tests
  const keys = await redis.keys(`${OTP_RATE_LIMIT_KEY_PREFIX}*`);
  if (keys.length > 0) {
    await redis.del(...keys);
  }

  // Database transaction rollback...
});

afterAll(async () => {
  // Cleanup...
});
```

### Testing OTP Flow

```typescript
import { redis } from "@/configs/redis";

describe("OTP Service", () => {
  it("should store and validate OTP successfully", async () => {
    const email = "test@example.com";
    const otp = "123456";

    // Store OTP
    await redis.set(`otp:${email}`, JSON.stringify({
      code: otp,
      attempts: 0,
      createdAt: Date.now(),
    }), "EX", 300);

    // Retrieve and validate
    const stored = await redis.get(`otp:${email}`);
    expect(stored).toBeTruthy();

    const otpData = JSON.parse(stored!);
    expect(otpData.code).toBe(otp);
  });

  it("should return null for expired OTP", async () => {
    const email = "expired@example.com";

    // Store with 1 second expiry
    await redis.set(`otp:${email}`, "123456", "EX", 1);

    // Wait for expiry
    await new Promise(resolve => setTimeout(resolve, 1100));

    const stored = await redis.get(`otp:${email}`);
    expect(stored).toBeNull();
  });
});
```

---

## Security Best Practices

### 1. Never Store Raw Secrets

```typescript
// ❌ BAD - Storing raw token
await redis.set(`reset:${token}`, userData);

// ✅ GOOD - Hash before storing
const tokenHash = hashToken(token);
await redis.set(`reset:${tokenHash}`, userData);
```

### 2. Always Use TTL

```typescript
// ❌ BAD - No expiry, keys live forever
await redis.set(key, value);

// ✅ GOOD - Always set TTL
await redis.set(key, value, "EX", 300);
```

### 3. Use Meaningful Key Names

```typescript
// ❌ BAD - Unclear purpose
await redis.set("t_123", "abc");

// ✅ GOOD - Descriptive and namespaced
await redis.set("blacklisted:eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...", "1");
```

### 4. Sanitize User Input in Keys

```typescript
// ❌ BAD - User input directly in key
await redis.set(`user:${userInput}`, value);

// ✅ GOOD - Validate and sanitize
const safeEmail = userEmail.toLowerCase().trim();
await redis.set(`otp:${safeEmail}`, value);
```

### 5. Don't Store Sensitive Data Longer Than Necessary

```typescript
// OTPs should be deleted immediately after use
if (otpData.code !== otpCode) {
  await incrementOtpAttempts(email);
  throw new BadRequestError(INVALID_OTP);
}

// ✅ Consume OTP immediately on success
await deleteStoredOtp(email);
```

### 6. Handle Redis Errors Gracefully

```typescript
try {
  await redis.set(key, value, "EX", 300);
} catch (error) {
  logger.error("Redis error", { error, key });
  // Decide: fail fast or fallback to database?
  throw new BadRequestError("Failed to store data. Please try again.");
}
```

---

## Quick Reference

### Common Redis Commands Used

| Command | Description | Example |
|---------|-------------|---------|
| `SET` | Store value with optional TTL | `redis.set(key, value, "EX", 300)` |
| `GET` | Retrieve value | `redis.get(key)` |
| `DEL` | Delete key(s) | `redis.del(key1, key2)` |
| `SETEX` | Set with expiry (shorthand) | `redis.setex(key, 300, value)` |
| `INCR` | Atomic increment | `redis.incr(counterKey)` |
| `EXPIRE` | Set TTL on existing key | `redis.expire(key, 300)` |
| `TTL` | Get remaining time to live | `redis.ttl(key)` |
| `KEYS` | Find keys by pattern (use sparingly!) | `redis.keys("pattern:*")` |

### Import Paths

```typescript
// Redis client
import { redis } from "@/configs/redis";

// Error handling
import { BadRequestError } from "@/utils/apiErrors";

// Logging
import logger from "@/utils/logger";
```

### Common Patterns Copy-Paste

#### Store JSON with TTL
```typescript
await redis.set(key, JSON.stringify(data), "EX", 300);
```

#### Retrieve and Parse JSON
```typescript
const stored = await redis.get(key);
const data = stored ? JSON.parse(stored) : null;
```

#### Delete Multiple Keys Atomically
```typescript
await Promise.all([
  redis.del(key1),
  redis.del(key2),
  redis.del(key3),
]);
```

#### Increment with Expiry on First Set
```typescript
const count = await redis.incr(rateLimitKey);
if (count === 1) {
  await redis.expire(rateLimitKey, windowSeconds);
}
```

---

## Summary

Key takeaways for implementing caching in this codebase:

1. ✅ **Use hierarchical key patterns** with constant functions
2. ✅ **Always set TTL** for temporary data
3. ✅ **Hash sensitive tokens** before storage
4. ✅ **Handle errors gracefully** with proper logging
5. ✅ **Clean up keys** after use (especially OTPs)
6. ✅ **Use atomic operations** (INCR, SET with EX) for counters
7. ✅ **Test Redis interactions** with proper cleanup
8. ✅ **Avoid KEYS command** in production hot paths

---

## Additional Resources

- **ioredis Documentation**: https://github.com/luin/ioredis
- **Redis Commands**: https://redis.io/commands/
- **BullMQ Documentation**: https://docs.bullmq.io/
- **Codebase Examples**:
  - `src/services/otp.service.ts` - OTP with attempts
  - `src/services/auth.service.ts` - Token blacklisting
  - `src/middlewares/otpRateLimiter.middleware.ts` - Rate limiting
  - `src/services/resident/residentRefundDetails.service.ts` - Multi-step forms
