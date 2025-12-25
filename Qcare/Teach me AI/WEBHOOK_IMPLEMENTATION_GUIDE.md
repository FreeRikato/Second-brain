# Webhook Implementation Guide

This guide teaches you how to implement secure webhooks in the QCare API codebase following the established patterns.

---

## Table of Contents

1. [Overview](#overview)
2. [Security Architecture](#security-architecture)
3. [Implementation Steps](#implementation-steps)
4. [Code Examples](#code-examples)
5. [Testing](#testing)
6. [Best Practices](#best-practices)

---

## Overview

### What is a Webhook?

A webhook is an HTTP callback that allows external services to send real-time data to your API when specific events occur.

### Webhook Flow in QCare

```
External Service
    ↓
POST /api/v1/webhook/[endpoint]
    ↓
authenticateWebhook (Security Middleware)
    ↓
validateReqBody (Validation Middleware)
    ↓
Controller (Thin Layer)
    ↓
Service (Business Logic)
    ↓
Database/Queue
```

---

## Security Architecture

### Why Webhook Security Matters

Webhooks are publicly accessible endpoints that accept data from external sources. Without proper security, anyone could send malicious data to your system.

### Security Layers Implemented

1. **HMAC-SHA256 Signature Validation**
   - Ensures request comes from a trusted source
   - Uses shared secret key known only to you and the sender

2. **Timestamp Verification**
   - Prevents replay attacks
   - Rejects requests older than 5 minutes

3. **Timing-Safe Comparison**
   - Prevents timing attacks
   - Uses `crypto.timingSafeEqual()` instead of `===`

### Required Headers

Every webhook request must include these headers:

```
x-webhook-signature: [HMAC-SHA256 signature]
x-webhook-timestamp: [Unix timestamp in milliseconds]
```

---

## Implementation Steps

### Step 1: Define Route Constants

**File:** `src/shared/constants/apiRoutes.constants.ts`

```typescript
export class MyWebhookRoutes {
  public static readonly MY_ENDPOINT = "/my-endpoint";
}
```

---

### Step 2: Create Validation Schema

**File:** `src/validations/webhook.validation.ts`

```typescript
import { z } from "zod";

export const myWebhookSchema = z.object({
  // Define your expected webhook payload structure
  id: z.string().min(1, "ID is required"),
  event: z.string().min(1, "Event type is required"),
  data: z.object({
    // Nested data structure
    name: z.string().min(1),
    email: z.string().email(),
  }),
  timestamp: z.number().optional(), // Optional: sender's timestamp
});
```

---

### Step 3: Create Webhook Routes

**File:** `src/routes/v1/myWebhook.routes.ts`

```typescript
import { Router } from "express";
import { validateToken } from "@/middlewares/auth.middleware";
import { authenticateWebhook } from "@/middlewares/webhookAuth.middleware";
import { validateReqBody } from "@/middlewares/validation.middleware";
import { myWebhookSchema } from "@/validations/webhook.validation";
import { processMyWebhook } from "@/controllers/myWebhook.controller";
import { APIRoute } from "@/shared/constants/apiRoutes.constants";
import { MyWebhookRoutes } from "@/shared/constants/apiRoutes.constants";

const router = Router();

// Webhook routes DO NOT use validateToken() - they use authenticateWebhook instead
router.post(
  APIRoute.MY_WEBHOOK + MyWebhookRoutes.MY_ENDPOINT,
  authenticateWebhook,      // Webhook security (HMAC signature)
  validateReqBody(myWebhookSchema), // Validate payload
  processMyWebhook          // Controller
);

export default router;
```

**Key Point:** Webhooks use `authenticateWebhook` middleware, NOT `validateToken()`. Webhooks are authenticated via signature, not JWT tokens.

---

### Step 4: Register Routes

**File:** `src/routes/v1/index.ts`

```typescript
import myWebhookRoutes from "@/routes/v1/myWebhook.routes";

// In your router setup
router.use(APIRoute.MY_WEBHOOK, myWebhookRoutes);
```

And update the route constants:

**File:** `src/shared/constants/apiRoutes.constants.ts`

```typescript
export class APIRoute {
  // ... other routes
  public static readonly MY_WEBHOOK = "/my-webhook";
}
```

---

### Step 5: Create Controller

**File:** `src/controllers/myWebhook.controller.ts`

```typescript
import { RequestHandler } from "express";
import { processMyWebhookEvent } from "@/services/myWebhook.service";
import { httpStatus } from "@/shared/constants/httpStatus.constants";

export const processMyWebhook: RequestHandler = async (req, res) => {
  // Controller is a thin wrapper - delegate to service
  const result = await processMyWebhookEvent(req.body);

  return res.status(httpStatus.OK).json({
    message: "Webhook processed successfully",
    data: result,
  });
};
```

---

### Step 6: Create Service

**File:** `src/services/myWebhook.service.ts`

```typescript
import { AppDataSource } from "@/database/data-source";
import { getScopedRepository } from "@/database/connection";
import { BadRequestError } from "@/utils/error";
import { webhookErrors } from "@/shared/constants/error.constants";
import { UserProfile } from "@/database/entities/UserProfile";

/**
 * Process webhook event
 * @param webhookData - Validated webhook payload
 * @returns Processing result
 */
export const processMyWebhookEvent = async (webhookData: any) => {
  return AppDataSource.transaction(async (tx) => {
    // 1. Business logic validation
    const existingUser = await getScopedRepository(UserProfile, tx).exists({
      where: { email: webhookData.data.email },
    });

    if (existingUser) {
      throw new BadRequestError(
        webhookErrors.alreadyExists(webhookData.data.email, "email")
      );
    }

    // 2. Process data (example: create user profile)
    // Your business logic here...

    return {
      id: webhookData.id,
      processed: true,
    };
  });
};
```

---

## Code Examples

### Example 1: Simple Webhook (User Profile)

**Controller** (`src/controllers/webhook.controller.ts`):

```typescript
export const createUserProfile: RequestHandler = async (req, res) => {
  const webhookData = req.body;
  const userProfile = await processUserProfileWebhook(webhookData);

  return res.json({
    message: "User profile created successfully via webhook",
    data: userProfile,
  });
};
```

**Service** (`src/services/webhook.service.ts`):

```typescript
export const processUserProfileWebhook = async (webhookData: any) => {
  return AppDataSource.transaction(async (tx) => {
    const { email, firstName, lastName, address } = webhookData;

    // Check if user already exists
    const existingProfile = await getScopedRepository(UserProfile, tx).exists({
      where: { email },
    });

    if (existingProfile) {
      throw new BadRequestError(
        webhookErrors.alreadyExists(email, "email")
      );
    }

    // Create user profile
    const savedProfile = await saveOne({
      entity: UserProfile,
      data: {
        email,
        firstName,
        lastName,
        password: await generateHash(faker.internet.password()), // Default password
      },
      transactionalEntityManager: tx,
    });

    // Create associated address
    if (address) {
      await saveOne({
        entity: Address,
        data: {
          addressableId: savedProfile.id,
          addressableType: AddressTypeEnum.USER_PROFILE,
          ...address,
        },
        transactionalEntityManager: tx,
      });
    }

    return savedProfile;
  });
};
```

---

### Example 2: Async Webhook (DocuSign)

For webhooks that trigger long-running processes, use BullMQ queues:

**Controller** (`src/controllers/webhook.controller.ts`):

```typescript
export const processDocusignEvents: RequestHandler = async (req, res) => {
  // Quickly acknowledge webhook (within 30 seconds)
  await addDocusignEventToQueue(req.body);

  return res.json({
    message: "DocuSign event received and queued for processing",
  });
};
```

**Queue** (`src/queues/docusignEvent.queue.ts`):

```typescript
import { Queue } from "bullmq";
import { redisConfig } from "@/config/redis";

export const docusignEventQueue = new Queue("docusign-events", {
  connection: redisConfig,
});

export const addDocusignEventToQueue = async (eventData: any) => {
  await docusignEventQueue.add("process-docusign-event", eventData);
};

// Worker processes events asynchronously
// Worker code would be in a separate file
```

---

## Security Implementation Details

### HMAC Signature Generation

**Sender Side** (external service):

```typescript
const crypto = require("crypto");

const webhookSecret = process.env.WEBHOOK_SECRET; // Shared secret
const payload = JSON.stringify(body);
const timestamp = Date.now();

// Create signature
const signature = crypto
  .createHmac("sha256", webhookSecret)
  .update(payload + timestamp)
  .digest("hex");

// Send request
fetch("https://your-api.com/api/v1/webhook/endpoint", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    "x-webhook-signature": signature,
    "x-webhook-timestamp": timestamp.toString(),
  },
  body: payload,
});
```

### Signature Validation

**Receiver Side** (`src/middlewares/webhookAuth.middleware.ts`):

```typescript
import { Request, Response, NextFunction } from "express";
import crypto from "crypto";
import { UnauthenticationError } from "@/utils/error";
import { webhookErrors } from "@/shared/constants/error.constants";

export const authenticateWebhook = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    // 1. Extract headers
    const signature = req.headers["x-webhook-signature"] as string;
    const timestamp = req.headers["x-webhook-timestamp"] as string;

    if (!signature || !timestamp) {
      throw new UnauthenticationError(
        webhookErrors.missingWebhookSignatureOrTimestamp
      );
    }

    // 2. Validate timestamp (prevent replay attacks)
    const currentTime = Date.now();
    const requestTime = parseInt(timestamp, 10);
    const timeDifference = (currentTime - requestTime) / 1000; // Convert to seconds

    if (timeDifference > 300) {
      // 5 minutes = 300 seconds
      throw new UnauthenticationError(webhookErrors.timestampOld);
    }

    // 3. Calculate expected signature
    const webhookSecret = process.env.WEBHOOK_SECRET!;
    const payload = JSON.stringify(req.body);

    const expectedSignature = crypto
      .createHmac("sha256", webhookSecret)
      .update(payload + timestamp)
      .digest("hex");

    // 4. Timing-safe comparison (prevent timing attacks)
    const signatureBuffer = Buffer.from(signature);
    const expectedBuffer = Buffer.from(expectedSignature);

    if (signatureBuffer.length !== expectedBuffer.length) {
      throw new UnauthenticationError(webhookErrors.invalidSign);
    }

    const isValid = crypto.timingSafeEqual(signatureBuffer, expectedBuffer);

    if (!isValid) {
      throw new UnauthenticationError(webhookErrors.invalidSign);
    }

    // 5. Signature is valid, proceed to next middleware
    next();
  } catch (error) {
    next(error);
  }
};
```

---

## Environment Variables

Add to your `.env` file:

```bash
# Webhook secret for HMAC signature validation
WEBHOOK_SECRET=your_super_secret_key_here

# For DocuSign webhooks specifically
DOCUSIGN_CONNECT_KEY=your_docusign_connect_key
```

**Important:**
- Use different secrets for different webhook providers
- Store secrets securely (never commit to git)
- Use long, random strings (at least 32 characters)

---

## Testing

### Test Helper Functions

**File:** `src/tests/helpers/webhook.helper.ts`

```typescript
import crypto from "crypto";

/**
 * Generate webhook signature for testing
 */
export const generateWebhookSignature = (
  body: any,
  timestamp: number,
  secret: string = process.env.WEBHOOK_SECRET!
) => {
  const payload = JSON.stringify(body);
  return crypto
    .createHmac("sha256", secret)
    .update(payload + timestamp)
    .digest("hex");
};

/**
 * Make authenticated webhook request
 */
export const makeWebhookRequest = async (
  app: Express,
  endpoint: string,
  body: any
) => {
  const timestamp = Date.now();
  const signature = generateWebhookSignature(body, timestamp);

  return app
    .post(endpoint)
    .set("x-webhook-signature", signature)
    .set("x-webhook-timestamp", timestamp.toString())
    .send(body);
};
```

### Integration Test Example

**File:** `src/tests/integration/v1/webhook/myWebhook.test.ts`

```typescript
import { App } from "supertest";
import { makeWebhookRequest } from "@/tests/helpers/webhook.helper";
import { newTestApp } from "@/tests/utils/testApp";

describe("My Webhook", () => {
  let app: App;

  beforeAll(async () => {
    app = await newTestApp();
  });

  it("should process valid webhook request", async () => {
    const webhookData = {
      id: "webhook-123",
      event: "user.created",
      data: {
        name: "John Doe",
        email: "john@example.com",
      },
    };

    const response = await makeWebhookRequest(
      app,
      "/api/v1/webhook/my-webhook/my-endpoint",
      webhookData
    );

    expect(response.status).toBe(200);
    expect(response.body.message).toContain("successfully");
  });

  it("should reject webhook without signature", async () => {
    const response = await app
      .post("/api/v1/webhook/my-webhook/my-endpoint")
      .send({ id: "test" });

    expect(response.status).toBe(401);
  });

  it("should reject webhook with invalid signature", async () => {
    const response = await app
      .post("/api/v1/webhook/my-webhook/my-endpoint")
      .set("x-webhook-signature", "invalid-signature")
      .set("x-webhook-timestamp", Date.now().toString())
      .send({ id: "test" });

    expect(response.status).toBe(401);
  });

  it("should reject webhook with old timestamp", async () => {
    const oldTimestamp = Date.now() - 400 * 1000; // 400 seconds ago
    const webhookData = { id: "test" };

    const signature = generateWebhookSignature(
      webhookData,
      oldTimestamp
    );

    const response = await app
      .post("/api/v1/webhook/my-webhook/my-endpoint")
      .set("x-webhook-signature", signature)
      .set("x-webhook-timestamp", oldTimestamp.toString())
      .send(webhookData);

    expect(response.status).toBe(401);
  });
});
```

---

## Best Practices

### 1. **Always Use Transactions**

```typescript
// ✅ Good - Transactional
export const processWebhook = async (data: any) => {
  return AppDataSource.transaction(async (tx) => {
    // Multiple database operations
    // All succeed or all fail
  });
};

// ❌ Bad - Non-transactional
export const processWebhook = async (data: any) => {
  // If second operation fails, first is not rolled back
};
```

### 2. **Validate Input Early**

Use Zod schemas to validate before processing:

```typescript
router.post(
  "/endpoint",
  authenticateWebhook,
  validateReqBody(myWebhookSchema), // Validate before controller
  controller
);
```

### 3. **Use Queues for Long Operations**

```typescript
// ❌ Bad - Blocks webhook response
export const processWebhook = async (data: any) => {
  await generatePDF(); // Takes 30 seconds
  await uploadToAzure();
  await sendEmail();
};

// ✅ Good - Non-blocking
export const processWebhook = async (data: any) => {
  await addToQueue(data); // Returns immediately
  return { received: true };
};
```

### 4. **Idempotency**

Make webhooks idempotent - processing the same webhook twice should not create duplicates:

```typescript
export const processWebhook = async (data: any) => {
  // Check if already processed
  const existing = await repository.exists({
    where: { webhookEventId: data.id },
  });

  if (existing) {
    return { status: "already-processed" };
  }

  // Process new webhook
  // ...
};
```

### 5. **Error Handling**

Return appropriate HTTP status codes:

```typescript
// 200 OK - Successfully processed
// 202 Accepted - Accepted for async processing
// 400 Bad Request - Invalid payload
// 401 Unauthorized - Invalid signature
// 409 Conflict - Business logic violation (duplicate)
// 500 Internal Server Error - Server error (will retry sender)
```

### 6. **Logging**

Log webhook events for debugging:

```typescript
import logger from "@/utils/logger";

export const processWebhook = async (data: any) => {
  logger.info("Webhook received", {
    eventId: data.id,
    eventType: data.event,
    timestamp: Date.now(),
  });

  try {
    // Process webhook
    logger.info("Webhook processed successfully", { eventId: data.id });
  } catch (error) {
    logger.error("Webhook processing failed", {
      eventId: data.id,
      error: error.message,
    });
    throw error;
  }
};
```

### 7. **Webhook Provider Best Practices**

When designing webhooks that YOU will call:

- Provide test/sandbox environment
- Allow configuring webhook URL
- Support multiple retry attempts with exponential backoff
- Document payload structure clearly
- Include unique event ID for idempotency
- Send signatures using standard HMAC-SHA256

---

## Webhook Security Checklist

Before deploying a webhook, verify:

- [ ] Using `authenticateWebhook` middleware (NOT `validateToken`)
- [ ] HMAC signature validation implemented
- [ ] Timestamp verification enabled (5-minute window)
- [ ] Timing-safe comparison used
- [ ] Input validation with Zod schema
- [ ] HTTPS enforced in production
- [ ] Webhook secret stored securely
- [ ] Rate limiting considered (if needed)
- [ ] Idempotency implemented
- [ ] Proper error responses (don't leak sensitive info)
- [ ] Logging implemented (for debugging)
- [ ] Integration tests written

---

## Troubleshooting

### Common Issues

**1. "Invalid webhook signature" error**

- Check that `WEBHOOK_SECRET` matches exactly on both sides
- Verify payload is stringified the same way: `JSON.stringify(body) + timestamp`
- Ensure headers are sent correctly (case-sensitive)

**2. "Timestamp is too old" error**

- Check system clocks are synchronized
- Verify timestamp is in milliseconds, not seconds
- Ensure timestamp is generated just before sending

**3. Webhook processed twice**

- Implement idempotency check
- Use unique event ID from webhook payload

**4. Webhook timeout**

- Move long operations to background queue
- Respond quickly (within 30 seconds)
- Use status 202 Accepted for async processing

---

## Summary

To implement a secure webhook in QCare:

1. **Define route constants** in `apiRoutes.constants.ts`
2. **Create Zod validation schema** for payload
3. **Create route** with `authenticateWebhook` middleware
4. **Create controller** (thin wrapper)
5. **Create service** with business logic (use transactions)
6. **Register routes** in `src/routes/v1/index.ts`
7. **Add WEBHOOK_SECRET** to `.env`
8. **Write integration tests** with signature helpers
9. **Consider queues** for long-running operations
10. **Implement idempotency** for reliability

---

## Additional Resources

**Existing Webhook Implementations:**
- User Profile Webhook: `src/controllers/webhook.controller.ts:8`
- DocuSign Webhook: `src/controllers/webhook.controller.ts:21`
- Security Middleware: `src/middlewares/webhookAuth.middleware.ts`
- Test Helpers: `src/tests/helpers/webhook.helper.ts`

**Related Files:**
- Routes: `src/routes/v1/webhook.routes.ts`
- Services: `src/services/webhook.service.ts`
- Queue: `src/queues/docusignEvent.queue.ts`
- Tests: `src/tests/integration/v1/webhook/`

---

Happy coding! 🚀
