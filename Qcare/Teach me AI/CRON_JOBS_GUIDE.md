# Cron Jobs & Queues - Complete Implementation Guide

This guide explains how to implement and work with cron jobs and background queues in the QCare API codebase.

---

## Table of Contents

1. [Overview](#overview)
2. [Cron Jobs (node-cron)](#cron-jobs-node-cron)
3. [Background Queues (BullMQ)](#background-queues-bullmq)
4. [When to Use Which](#when-to-use-which)
5. [Complete Examples](#complete-examples)

---

## Overview

The codebase uses **two different mechanisms** for background/scheduled tasks:

| Feature | node-cron | BullMQ |
|---------|-----------|--------|
| **Use Case** | Simple scheduled tasks | Async job processing with retry |
| **Scheduling** | Cron expressions (time-based) | On-demand or repeatable jobs |
| **Persistence** | In-memory only | Redis-backed |
| **Retry Logic** | Manual | Built-in with exponential backoff |
| **Monitoring** | Logs only | Job tracking, progress, failed jobs |
| **Example** | Daily midnight tasks | Sending emails, processing webhooks |

---

## Cron Jobs (node-cron)

### What Are They?

**node-cron** runs functions on a schedule using cron expressions. Tasks are simple, run in-memory, and are defined in `src/server.ts`.

### Directory Structure

```
src/
├── cron/                      # Cron job functions
│   ├── changePricingPlanStatus.ts
│   ├── expireDocuments.ts
│   └── updateBedStatus.ts
└── server.ts                  # Cron scheduling & initialization
```

### How They Work

1. **Define the function** in `src/cron/`
2. **Schedule it** in `src/server.ts` using `cron.schedule()`
3. **Start the scheduler** with `dailyCronJob.start()`

### Implementation Pattern

#### Step 1: Create the Cron Function (`src/cron/yourTask.ts`)

```typescript
import dayjs from "dayjs";
import { LessThanOrEqual } from "typeorm";

import { YourEntity } from "@/database/entities/YourEntity.entity";
import { update } from "@/services/database";
import { YourStatus } from "@/shared/enums/yourEntity.enum";

/**
 * Cron job to update records based on date conditions
 * Runs daily at midnight
 */
export const yourCronFunction = async (): Promise<void> => {
  const now = dayjs().toDate();

  // Use the generic update service for bulk updates
  await update({
    entity: YourEntity,
    data: { status: YourStatus.UPDATED },
    options: {
      expirationDate: LessThanOrEqual(now),
      status: YourStatus.PENDING,
    },
  });
};
```

**Key Patterns:**
- Use `dayjs` for date handling (project standard)
- Use the generic `update()` service for simple bulk updates
- Use `AppDataSource.getRepository()` for complex queries
- Always return `Promise<void>` for async consistency

#### Step 2: Register in Server (`src/server.ts`)

```typescript
import cron from "node-cron";
import { yourCronFunction } from "@/cron/yourTask";

// In startServer() function
const dailyCronJob = cron.schedule("0 0 * * *", async () => {
  // Your existing cron jobs
  await activatePricingPlan();
  await markExpiredPricingPlansInactive();

  // Add your new cron job
  await yourCronFunction();
});

dailyCronJob.start();
```

#### Step 3: Test Your Cron Job

Create `src/tests/integration/v1/yourCron.test.ts`:

```typescript
import dayjs from "dayjs";

import { yourCronFunction } from "@/cron/yourTask";
import AppDataSource from "@/database/dataSource";
import { YourEntity } from "@/database/entities/YourEntity.entity";
import { YourStatus } from "@/shared/enums/yourEntity.enum";
import { YourEntityFactory } from "@/tests/factories/yourEntity.factory";

describe("yourCronFunction", () => {
  it("should update expired records", async () => {
    const yesterday = dayjs().subtract(1, "day").toDate();
    const tomorrow = dayjs().add(1, "day").toDate();

    // Create test data
    const expiredRecord = await new YourEntityFactory(AppDataSource).create({
      status: YourStatus.PENDING,
      expirationDate: yesterday,
    });

    const futureRecord = await new YourEntityFactory(AppDataSource).create({
      status: YourStatus.PENDING,
      expirationDate: tomorrow,
    });

    // Run the cron function
    await yourCronFunction();

    // Verify results
    await expiredRecord.reload();
    await futureRecord.reload();

    expect(expiredRecord.status).toBe(YourStatus.UPDATED);
    expect(futureRecord.status).toBe(YourStatus.PENDING);
  });
});
```

### Cron Expression Reference

```
* * * * *
│ │ │ │ │
│ │ │ │ └─── Day of week (0-7, Sunday = 0 or 7)
│ │ │ └───── Month (1-12)
│ │ └─────── Day of month (1-31)
│ └───────── Hour (0-23)
└─────────── Minute (0-59)
```

**Common Examples:**

| Expression | Description |
|------------|-------------|
| `0 0 * * *` | Daily at midnight |
| `0 */6 * * *` | Every 6 hours |
| `0 0 * * 0` | Weekly on Sunday at midnight |
| `0 0 1 * *` | Monthly on the 1st at midnight |
| `*/30 * * * *` | Every 30 minutes |

---

## Background Queues (BullMQ)

### What Are They?

**BullMQ** is a Redis-backed queue system for processing background jobs asynchronously. Jobs can be added on-demand (e.g., send email when user registers) and run with automatic retry logic.

### Directory Structure

```
src/
├── queues/                    # Queue implementations
│   ├── base.ts               # Abstract base class
│   ├── mailQueue.ts
│   ├── sms.queue.ts
│   ├── agreement.queue.ts
│   └── docusignEvent.queue.ts
├── configs/
│   └── redis.ts              # Redis connection & job options
├── shared/
│   ├── constants/
│   │   └── queue.constants.ts # Queue name constants
│   └── types/
│       └── yourQueue.type.ts  # Type definitions
└── server.ts                  # Queue initialization & graceful shutdown
```

### How They Work

1. **Define queue name** in `queue.constants.ts`
2. **Define payload type** in `shared/types/`
3. **Create queue class** extending `BaseQueue` in `src/queues/`
4. **Initialize queue** in `src/server.ts`
5. **Add jobs** from anywhere in the application

### Implementation Pattern

#### Step 1: Define Queue Name (`src/shared/constants/queue.constants.ts`)

```typescript
export const QUEUE_NAMES = {
  MAIL_QUEUE: "mail-queue",
  AGREEMENT_QUEUE: "agreement-queue",
  DOCUSIGN_EVENT_QUEUE: "docusign-event-queue",
  YOUR_QUEUE: "your-queue", // Add your queue name here
} as const;
```

#### Step 2: Define Payload Type (`src/shared/types/yourQueue.type.ts`)

```typescript
export interface YourQueuePayload {
  userId: string;
  actionType: "send_notification" | "process_data";
  metadata?: Record<string, unknown>;
}
```

#### Step 3: Create Queue Class (`src/queues/yourQueue.ts`)

```typescript
import BaseQueue from "@/queues/base";
import { QUEUE_NAMES } from "@/shared/constants/queue.constants";
import type { YourQueuePayload } from "@/shared/types/yourQueue.type";
import { yourBusinessService } from "@/services/yourBusiness.service";
import logger from "@/utils/logger";

const queueName = QUEUE_NAMES.YOUR_QUEUE;

/**
 * Your Queue for processing background tasks
 * Handles async operations with retry logic
 */
class YourQueue extends BaseQueue<YourQueuePayload, typeof queueName> {
  constructor() {
    super(queueName);
  }

  /**
   * Job processor - This is where the actual work happens
   * Called automatically by the worker when a job is processed
   *
   * @param data - Job payload containing task data
   */
  async jobProcessor(data: YourQueuePayload): Promise<void> {
    const { userId, actionType, metadata } = data;

    try {
      logger.info("Processing your queue job", { userId, actionType });

      // Call your business logic here
      await yourBusinessService(userId, actionType, metadata);

      logger.info("Your queue job completed successfully", { userId });
    } catch (error) {
      logger.error("Your queue job failed", { error, userId });
      throw error; // Re-throw to trigger BullMQ retry logic
    }
  }

  /**
   * Convenience method to add a job to this queue
   * Call this from anywhere in the application
   *
   * @param payload - Job data
   * @param options - Optional BullMQ job options
   */
  async addJobInQueue(payload: YourQueuePayload, options = {}) {
    return this.addJob(queueName, payload, options);
  }
}

// Export singleton instance
export const yourQueue = new YourQueue();
export default YourQueue;
```

#### Step 4: Initialize in Server (`src/server.ts`)

```typescript
import { yourQueue } from "@/queues/yourQueue";

export const startServer = async () => {
  // ... existing code ...

  // Graceful shutdown handler
  const gracefulShutdown = async () => {
    logger.info("🔄 Gracefully shutting down...");

    // Close queue workers - Add your queue here
    await mailQueue.close();
    await agreementQueue.close();
    await yourQueue.close();

    logger.info("✅ Queues closed successfully");

    // ... rest of shutdown code ...
  };

  process.on("SIGTERM", gracefulShutdown);
  process.on("SIGINT", gracefulShutdown);

  return server;
};
```

#### Step 5: Use the Queue in Your Code

```typescript
import { yourQueue } from "@/queues/yourQueue";

// In a controller or service
export const yourControllerFunction: RequestHandler = async (req, res) => {
  const { userId } = req.body;

  // Add job to queue - runs asynchronously
  await yourQueue.addJobInQueue({
    userId,
    actionType: "send_notification",
    metadata: { source: "api" },
  });

  return res.json({
    message: "Task queued successfully",
    data: { userId },
  });
};
```

### BullMQ Configuration (`src/configs/redis.ts`)

Default job options apply to all queues:

```typescript
export const defaultJobOptions: DefaultJobOptions = {
  keepLogs: 1000,           // Keep last 1000 job logs
  attempts: 5,              // Retry up to 5 times on failure
  backoff: {
    type: "exponential",    // Exponential backoff between retries
    delay: 2000,           // Start with 2 second delay
  },
  removeOnComplete: 200,    // Keep last 200 completed jobs
  removeOnFail: {
    age: 60 * 60 * 24 * 7,  // Remove failed jobs after 7 days
  },
};
```

**Override defaults per job:**

```typescript
await yourQueue.addJobInQueue(payload, {
  attempts: 3,
  backoff: {
    type: "exponential",
    delay: 5000,
  },
});
```

### Base Queue Architecture

The `BaseQueue` abstract class provides:

```typescript
export abstract class BaseQueue<TData, NameType extends string> {
  queue: Queue<TData>;              // BullMQ queue instance
  worker: Worker<TData>;            // BullMQ worker instance
  logger: Logger;                   // Winston logger with queue context

  // Abstract method - implement in your queue
  abstract jobProcessor(jobData: Job<TData>["data"]): Promise<void>;

  // Built-in methods
  addJob(name, data, options)       // Add job to queue
  close(force)                      // Graceful shutdown
  healthCheck()                     // Check if worker is running
}
```

**Features provided automatically:**
- Automatic retry with exponential backoff
- Structured logging with queue name context
- Error handling and tracking
- Redis connection management
- Graceful shutdown support

---

## When to Use Which

### Use **node-cron** for:

- Simple, time-based scheduled tasks
- Database cleanup/maintenance
- Status updates based on date/time
- Tasks that don't need retry logic
- Tasks that run on a fixed schedule

**Examples:**
- Daily midnight cleanup
- Hourly data aggregation
- Weekly report generation

### Use **BullMQ** for:

- Async operations triggered by user actions
- Tasks that need retry logic
- External API calls (email, SMS, webhooks)
- Long-running processes
- High-volume background processing
- Jobs that need monitoring/tracking

**Examples:**
- Sending emails after user registration
- Processing webhook events
- Generating PDF documents
- Syncing data with external services

---

## Complete Examples

### Example 1: Simple Cron Job - Send Daily Digest Emails

**`src/cron/sendDailyDigest.ts`**

```typescript
import dayjs from "dayjs";
import { LessThan } from "typeorm";

import User from "@/database/entities/User.entity";
import { addJobInQueue } from "@/queues/mailQueue";
import { AppDataSource } from "@/database/dataSource";

export const sendDailyDigest = async (): Promise<void> => {
  const yesterday = dayjs().subtract(1, "day").startOf("day").toDate();

  const userRepo = AppDataSource.getRepository(User);

  // Find users who haven't received digest in 24 hours
  const users = await userRepo.find({
    where: {
      lastDigestSentAt: LessThan(yesterday),
      isActive: true,
    },
  });

  // Add email jobs to queue (async processing)
  for (const user of users) {
    await addJobInQueue({
      to: user.email,
      subject: "Your Daily Digest",
      template: "daily-digest",
      data: { user },
    });
  }
};
```

**`src/server.ts`**

```typescript
const dailyCronJob = cron.schedule("0 8 * * *", async () => {
  // Runs daily at 8 AM
  await sendDailyDigest();
});
```

---

### Example 2: BullMQ - Process Payment Webhooks

**`src/shared/types/payment.type.ts`**

```typescript
export interface PaymentWebhookPayload {
  paymentId: string;
  status: "success" | "failed" | "pending";
  amount: number;
  currency: string;
}
```

**`src/shared/constants/queue.constants.ts`**

```typescript
export const QUEUE_NAMES = {
  // ... existing queues
  PAYMENT_WEBHOOK_QUEUE: "payment-webhook-queue",
} as const;
```

**`src/queues/paymentWebhook.queue.ts`**

```typescript
import BaseQueue from "@/queues/base";
import { QUEUE_NAMES } from "@/shared/constants/queue.constants";
import type { PaymentWebhookPayload } from "@/shared/types/payment.type";
import { updatePaymentStatus } from "@/services/payment.service";
import logger from "@/utils/logger";

const queueName = QUEUE_NAMES.PAYMENT_WEBHOOK_QUEUE;

class PaymentWebhookQueue extends BaseQueue<
  PaymentWebhookPayload,
  typeof queueName
> {
  constructor() {
    super(queueName);
  }

  async jobProcessor(data: PaymentWebhookPayload): Promise<void> {
    const { paymentId, status, amount, currency } = data;

    try {
      logger.info("Processing payment webhook", { paymentId, status });

      // Update payment status in database
      await updatePaymentStatus(paymentId, status, amount, currency);

      // Send confirmation email if payment successful
      if (status === "success") {
        // Could add another job to mail queue here
      }

      logger.info("Payment webhook processed successfully", { paymentId });
    } catch (error) {
      logger.error("Payment webhook processing failed", {
        error,
        paymentId,
      });
      throw error; // Triggers retry
    }
  }

  async addPaymentWebhookJob(data: PaymentWebhookPayload) {
    return this.addJob(queueName, data, {
      // Custom options: only retry 3 times for payments
      attempts: 3,
    });
  }
}

export const paymentWebhookQueue = new PaymentWebhookQueue();
export default PaymentWebhookQueue;
```

**Usage in webhook controller:**

```typescript
export const handlePaymentWebhook: RequestHandler = async (req, res) => {
  const { payment_id, status, amount, currency } = req.body;

  // Process asynchronously
  await paymentWebhookQueue.addPaymentWebhookJob({
    paymentId: payment_id,
    status,
    amount,
    currency,
  });

  return res.status(202).json({ message: "Webhook received" });
};
```

---

## Testing Strategies

### Testing Cron Jobs

```typescript
describe("yourCronFunction", () => {
  it("should handle edge cases", async () => {
    // Arrange: Create test data with factories
    const expiredRecord = await new YourEntityFactory(AppDataSource).create({
      status: YourStatus.PENDING,
      expiresAt: dayjs().subtract(1, "day").toDate(),
    });

    // Act: Run the cron function
    await yourCronFunction();

    // Assert: Verify database state
    await expiredRecord.reload();
    expect(expiredRecord.status).toBe(YourStatus.UPDATED);
  });
});
```

### Testing Queues

**Unit Test (simple):**

```typescript
import { yourQueue } from "@/queues/yourQueue";

describe("YourQueue", () => {
  it("should add and process job", async () => {
    await yourQueue.addJobInQueue({
      userId: "123",
      actionType: "send_notification",
    });

    // Wait for job to process (or use mocks)
    await new Promise((resolve) => setTimeout(resolve, 1000));
  });
});
```

**Integration Test (with mocked service):**

```typescript
import { yourQueue } from "@/queues/yourQueue";
import { yourBusinessService } from "@/services/yourBusiness.service";

// Mock the service to avoid actual processing
jest.mock("@/services/yourBusiness.service");

describe("YourQueue Integration", () => {
  it("should process job with retry", async () => {
    (yourBusinessService as jest.Mock).mockRejectedValueOnce(
      new Error("Temporary failure")
    ).mockResolvedValueOnce(undefined);

    await yourQueue.addJobInQueue({
      userId: "123",
      actionType: "send_notification",
    });

    // Wait for retries
    await new Promise((resolve) => setTimeout(resolve, 5000));

    expect(yourBusinessService).toHaveBeenCalledTimes(2);
  });
});
```

---

## Key Takeaways

### For Cron Jobs:

1. Keep functions simple and focused
2. Use `dayjs` for date operations
3. Test with factories covering edge cases
4. Register in `src/server.ts` with proper cron expression
5. Consider timezone implications

### For BullMQ Queues:

1. Always extend `BaseQueue` for consistency
2. Define types for payloads (TypeScript safety)
3. Add queue names to constants
4. Throw errors in `jobProcessor` to trigger retries
5. Remember to add to graceful shutdown in `server.ts`
6. Use structured logging for debugging

---

## Common Pitfalls

### Cron Jobs:
- **Forgetting to start** the scheduler: `dailyCronJob.start()`
- **Blocking operations**: Don't run long tasks directly - use queues instead
- **Timezone issues**: Cron uses server timezone

### BullMQ Queues:
- **Not throwing errors**: Silently caught errors won't trigger retries
- **Missing graceful shutdown**: Jobs may be killed mid-processing
- **Overwriting defaults**: Be careful with job options that remove retry logic

---

## Additional Resources

- **BullMQ Docs**: https://docs.bullmq.io/
- **node-cron**: https://www.npmjs.com/package/node-cron
- **Cron Expressions**: https://crontab.guru/

---

## Quick Reference Card

```
CREATE CRON JOB:
1. src/cron/yourTask.ts → export const yourFunction
2. src/server.ts → import + add to cron.schedule()
3. Test → src/tests/integration/v1/yourCron.test.ts

CREATE QUEUE:
1. src/shared/constants/queue.constants.ts → add name
2. src/shared/types/yourQueue.type.ts → define interface
3. src/queues/yourQueue.ts → extend BaseQueue
4. src/server.ts → import + add to gracefulShutdown()
5. Use → import { yourQueue } from "@/queues/yourQueue"

CRON EXPRESSIONS:
┌───────────── minute (0 - 59)
│ ┌───────────── hour (0 - 23)
│ │ ┌───────────── day of month (1 - 31)
│ │ │ ┌───────────── month (1 - 12)
│ │ │ │ ┌───────────── day of week (0 - 7) (Sunday = 0)
│ │ │ │ │
* * * * *
```
