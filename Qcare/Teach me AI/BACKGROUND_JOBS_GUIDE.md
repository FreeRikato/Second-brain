# Background Jobs Guide - QCare API

A comprehensive guide to implementing and managing background jobs using BullMQ in the QCare API.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Core Components](#core-components)
3. [Creating a New Queue](#creating-a-new-queue)
4. [Enqueuing Jobs](#enqueuing-jobs)
5. [Job Processing](#job-processing)
6. [Error Handling & Retries](#error-handling--retries)
7. [Configuration Options](#configuration-options)
8. [Testing](#testing)
9. [Best Practices](#best-practices)
10. [Real-World Examples](#real-world-examples)

---

## Architecture Overview

The QCare API uses **BullMQ** for background job processing - a Redis-backed queue system that provides:

- **Asynchronous processing** of long-running tasks
- **Automatic retry logic** with exponential backoff
- **Job monitoring** and logging
- **Graceful shutdown** handling
- **Type-safe** job payloads

### Request Flow with Background Jobs

```
HTTP Request
    ↓
Controller/Service
    ↓
Queue Job (returns immediately)
    ↓
Redis Queue (waiting)
    ↓
Worker (processes asynchronously)
    ↓
Business Logic (emails, SMS, PDFs, etc.)
```

### Why Background Jobs?

Background jobs are ideal for:
- Sending emails/SMS (slow external APIs)
- Generating PDFs (CPU intensive)
- Processing webhooks (avoid timeout)
- Batch operations (large datasets)
- Third-party API calls (unpredictable latency)

---

## Core Components

### File Structure

```
src/
├── queues/
│   ├── base.ts                    # Abstract base class
│   ├── mailQueue.ts              # Email queue
│   ├── sms.queue.ts              # SMS queue
│   ├── agreement.queue.ts        # DocuSign queue
│   └── docusignEvent.queue.ts    # DocuSign webhook queue
├── configs/
│   └── redis.ts                  # Redis connection config
├── shared/
│   ├── constants/
│   │   └── queue.constants.ts    # Queue name constants
│   └── types/
│       ├── mail.type.ts          # Email payload types
│       ├── sms.type.ts           # SMS payload types
│       └── docusign.type.ts      # DocuSign payload types
└── server.ts                     # Queue initialization & shutdown
```

### Base Queue Class

All queues extend `BaseQueue` which provides:

```typescript
export abstract class BaseQueue<TData, NameType extends string> {
  queue: Queue<TData>;          // BullMQ queue instance
  worker: Worker<TData>;        // BullMQ worker instance
  logger: Logger;               // Winston logger with queue context

  // Abstract method - must implement
  abstract jobProcessor(jobData: Job<TData>["data"]): Promise<void>;

  // Add job to queue
  addJob(
    name: NameType,
    data: TData,
    options?: JobsOptions,
  ): Job<TData>;

  // Health check
  healthCheck(): Promise<void>;

  // Graceful shutdown
  close(force?: boolean): Promise<void>;
}
```

### Redis Configuration

Located in `src/configs/redis.ts`:

```typescript
import Redis from "ioredis";
import { env } from "@/utils/env";

export const redis = new Redis({
  host: env.REDIS_HOST,
  port: env.REDIS_PORT,
  maxRetriesPerRequest: null,  // Required by BullMQ
});
```

### Default Job Options

Configured in `src/configs/redis.ts`:

```typescript
export const defaultJobOptions: DefaultJobOptions = {
  keepLogs: 1000,                    // Keep last 1000 job logs
  attempts: 5,                       // Retry up to 5 times
  backoff: {
    type: "exponential",             // Exponential backoff
    delay: 2000,                     // Start with 2 second delay
  },
  removeOnComplete: 200,             // Keep last 200 completed jobs
  removeOnFail: {
    age: 60 * 60 * 24 * 7,          // Remove failed jobs after 7 days
  },
};
```

---

## Creating a New Queue

Let's walk through creating a complete queue for generating reports.

### Step 1: Define Queue Name Constant

**File:** `src/shared/constants/queue.constants.ts`

```typescript
export const QUEUE_NAMES = {
  // Existing queues
  MAIL_QUEUE: "mail-queue",
  SMS_QUEUE: "sms-queue",
  AGREEMENT_QUEUE: "agreement-queue",
  DOCUSIGN_EVENT_QUEUE: "docusign-event-queue",

  // Add your new queue
  REPORT_GENERATION_QUEUE: "report-generation-queue",
} as const;
```

### Step 2: Define Payload Type

**File:** `src/shared/types/report.type.ts`

```typescript
export interface ReportGenerationPayload {
  reportId: string;
  reportType: "monthly" | "quarterly" | "annual";
  userId: string;
  startDate: Date;
  endDate: Date;
  format: "pdf" | "excel";
  recipientEmail?: string;
}

export enum ReportType {
  MONTHLY = "monthly",
  QUARTERLY = "quarterly",
  ANNUAL = "annual",
}

export enum ReportFormat {
  PDF = "pdf",
  EXCEL = "excel",
}
```

### Step 3: Create Queue Implementation

**File:** `src/queues/reportGeneration.queue.ts`

```typescript
import BaseQueue from "@/queues/base";
import { QUEUE_NAMES } from "@/shared/constants/queue.constants";
import type { ReportGenerationPayload } from "@/shared/types/report.type";
import { generateReport } from "@/services/report.service";
import { logger } from "@/utils/logger";

const queueName = QUEUE_NAMES.REPORT_GENERATION_QUEUE;

class ReportGenerationQueue extends BaseQueue<
  ReportGenerationPayload,
  typeof queueName
> {
  constructor() {
    super(queueName);
  }

  /**
   * Process report generation job
   * This method is called automatically by BullMQ worker
   */
  async jobProcessor(data: ReportGenerationPayload): Promise<void> {
    const { reportId, reportType, userId, startDate, endDate, format } = data;

    this.logger.info("Starting report generation", {
      reportId,
      reportType,
      format,
    });

    try {
      // Generate the report
      const reportUrl = await generateReport({
        reportId,
        reportType,
        userId,
        startDate,
        endDate,
        format,
      });

      // Send email if recipient provided
      if (data.recipientEmail) {
        await this.sendReportEmail(data.recipientEmail, reportUrl);
      }

      this.logger.info("Report generated successfully", { reportId });
    } catch (error) {
      this.logger.error("Failed to generate report", {
        reportId,
        error: error instanceof Error ? error.message : String(error),
      });

      // Re-throw to trigger BullMQ retry mechanism
      throw error;
    }
  }

  /**
   * Helper method to send report email
   */
  private async sendReportEmail(email: string, reportUrl: string): Promise<void> {
    // Import mail queue to avoid circular dependency
    const { mailQueue } = await import("@/queues/mailQueue");

    await mailQueue.addJobInQueue({
      notificationEvent: "REPORT_READY",
      variables: {
        reportUrl,
      },
      recipientEmail: email,
    });
  }

  /**
   * Convenience method to enqueue report generation job
   */
  async addReportGenerationJob(
    payload: ReportGenerationPayload,
    options?: JobsOptions,
  ) {
    return this.addJob(queueName, payload, options);
  }
}

// Export singleton instance
export const reportGenerationQueue = new ReportGenerationQueue();
```

### Step 4: Initialize Queue in Server

**File:** `src/server.ts`

Add to the graceful shutdown handler:

```typescript
import { reportGenerationQueue } from "@/queues/reportGeneration.queue";

const gracefulShutdown = async () => {
  logger.info("Starting graceful shutdown...");

  try {
    // Close all queues
    await mailQueue.close();
    await smsQueue.close();
    await agreementQueue.close();
    await docusignEventQueue.close();
    await reportGenerationQueue.close();  // Add your queue

    logger.info("All queues closed successfully");
  } catch (error) {
    logger.error("Error during shutdown", { error });
  }

  process.exit(0);
};
```

---

## Enqueuing Jobs

### Basic Job Enqueue

From any service or controller:

```typescript
import { reportGenerationQueue } from "@/queues/reportGeneration.queue";
import type { ReportGenerationPayload } from "@/shared/types/report.type";

export const generateReportController: RequestHandler = async (req, res) => {
  const { userId } = req.user;
  const { reportType, startDate, endDate, format } = req.body;

  const payload: ReportGenerationPayload = {
    reportId: faker.string.uuid(),
    reportType,
    userId,
    startDate: new Date(startDate),
    endDate: new Date(endDate),
    format,
    recipientEmail: req.user.email,
  };

  // Enqueue the job
  const job = await reportGenerationQueue.addReportGenerationJob(payload);

  return res.json({
    message: "Report generation started",
    data: {
      jobId: job.id,
      reportId: payload.reportId,
      status: "processing",
    },
  });
};
```

### With Custom Options

Override default options for specific jobs:

```typescript
import { Job } from "bullmq";

// High priority job
await reportGenerationQueue.addReportGenerationJob(payload, {
  priority: 10,  // Lower number = higher priority
});

// Delayed job (process after 5 minutes)
await reportGenerationQueue.addReportGenerationJob(payload, {
  delay: 5 * 60 * 1000,
});

// Custom retry options
await reportGenerationQueue.addReportGenerationJob(payload, {
  attempts: 3,  // Only retry 3 times
  backoff: {
    type: "exponential",
    delay: 5000,  // Start with 5 second delay
  },
});

// Job with unique ID (prevent duplicates)
await reportGenerationQueue.addReportGenerationJob(payload, {
  jobId: `report-${userId}-${reportType}`,
});
```

### Job ID Pattern

Use meaningful job IDs to prevent duplicate jobs:

```typescript
// Prevent duplicate monthly reports for same user
const jobId = `report-monthly-${userId}-${new Date().toISOString().slice(0, 7)}`;

await reportGenerationQueue.addReportGenerationJob(payload, {
  jobId,
});
```

---

## Job Processing

### Automatic Processing

BullMQ workers automatically:
1. Pull jobs from Redis queue
2. Call your `jobProcessor` method
3. Handle retries on failure
4. Mark jobs as completed/failed

### Job Processor Pattern

```typescript
async jobProcessor(data: ReportGenerationPayload): Promise<void> {
  // 1. Extract data
  const { reportId, reportType, userId } = data;

  // 2. Log job start
  this.logger.info("Processing job", { reportId, reportType });

  // 3. Execute business logic
  try {
    const result = await yourBusinessLogic(data);

    // 4. Log success
    this.logger.info("Job completed", { reportId, result });
  } catch (error) {
    // 5. Log error with context
    this.logger.error("Job failed", {
      reportId,
      error: error instanceof Error ? error.message : String(error),
      stack: error instanceof Error ? error.stack : undefined,
    });

    // 6. Re-throw to trigger retry
    throw error;
  }
}
```

### Accessing Job Metadata

Inside `jobProcessor`, access BullMQ job object:

```typescript
async jobProcessor(jobData: ReportGenerationPayload): Promise<void> {
  // Access job metadata (not currently used in BaseQueue but available)
  const job = this.worker?.getCurrentJob?.();

  if (job) {
    this.logger.info("Job metadata", {
      jobId: job.id,
      attemptsMade: job.attemptsMade,
      data: job.data,
      createdAt: new Date(job.timestamp),
    });
  }

  // Your processing logic
  await processReport(jobData);
}
```

---

## Error Handling & Retries

### Automatic Retry Behavior

With default configuration:
- **Attempt 1**: Immediate failure
- **Attempt 2**: Retry after ~2 seconds
- **Attempt 3**: Retry after ~4 seconds
- **Attempt 4**: Retry after ~8 seconds
- **Attempt 5**: Retry after ~16 seconds

Formula: `delay = initialDelay * (2 ^ (attempt - 1))`

### Error Handling Best Practices

```typescript
async jobProcessor(data: ReportGenerationPayload): Promise<void> {
  try {
    // Validate input
    if (!data.reportId) {
      throw new Error("Report ID is required");
    }

    // Process job
    await processReport(data);

  } catch (error) {
    // Log with full context
    this.logger.error("Job processing failed", {
      reportId: data.reportId,
      error: error instanceof Error ? {
        message: error.message,
        name: error.name,
        stack: error.stack,
      } : error,
    });

    // Re-throw to trigger BullMQ retry
    throw error;
  }
}
```

### Retryable vs Non-Retryable Errors

Sometimes you want to fail immediately without retries:

```typescript
async jobProcessor(data: ReportGenerationPayload): Promise<void> {
  try {
    // Validate input - fail immediately on validation errors
    if (!data.userId) {
      const error = new Error("User ID is required");
      error.name = "ValidationError";

      // Don't retry validation errors
      throw error;
    }

    await processReport(data);

  } catch (error) {
    // Check if error should not be retried
    if (error instanceof Error && error.name === "ValidationError") {
      this.logger.error("Validation error - not retrying", { error });
      // Still throw to mark job as failed, but won't retry
      throw error;
    }

    // Other errors will be retried
    this.logger.error("Job failed - will retry", { error });
    throw error;
  }
}
```

### Handling Partial Failures

When processing multiple items:

```typescript
async jobProcessor(data: BatchReportPayload): Promise<void> {
  const failedItems: string[] = [];

  for (const item of data.items) {
    try {
      await processItem(item);
    } catch (error) {
      this.logger.warn("Item failed", { itemId: item.id, error });
      failedItems.push(item.id);
    }
  }

  // Fail job if critical items failed
  if (failedItems.length > 0) {
    throw new Error(`${failedItems.length} items failed to process`);
  }
}
```

---

## Configuration Options

### Job Options

```typescript
interface JobsOptions {
  // Retry configuration
  attempts?: number;              // Number of retry attempts (default: 5)
  backoff?: {
    type: "fixed" | "exponential";
    delay: number;                // Delay in milliseconds
  };

  // Timing
  delay?: number;                 // Delay before first processing
  timeout?: number;               // Maximum execution time (ms)

  // Priority
  priority?: number;              // Lower number = higher priority (1-10)

  // Deduplication
  jobId?: string;                 // Unique ID to prevent duplicates

  // Lifecycle callbacks
  // (Note: These can be set in BaseQueue if needed)

  // Failure handling
  removeOnFail?: number | { age: number };  // When to remove failed jobs

  // Success handling
  removeOnComplete?: number | { age: number };  // When to remove completed jobs
}
```

### Queue Options

When extending BaseQueue, these are set automatically:

```typescript
{
  connection: redis,              // Redis connection
  defaultJobOptions,              // Default job options
}
```

### Worker Options

Also configured in BaseQueue:

```typescript
{
  connection: redis,
  concurrency: 1,                 // Process 1 job at a time (can be increased)
}
```

---

## Testing

### Mocking Queues in Tests

**File:** `tests/mocks/queue.mock.ts`

```typescript
import { Job } from "bullmq";

export class MockQueue {
  async addJob(...args: unknown[]) {
    return {
      id: "mock-job-id",
      data: args[1],
    } as Job;
  }

  async close() {
    // Mock implementation
  }

  async healthCheck() {
    // Mock implementation
  }
}

export const mockReportGenerationQueue = {
  addReportGenerationJob: vi.fn(),
  close: vi.fn(),
  healthCheck: vi.fn(),
};
```

### Integration Test Example

```typescript
import { reportGenerationQueue } from "@/queues/reportGeneration.queue";
import { ReportFactory } from "@/tests/factories/report.factory";
import { redis } from "@/configs/redis";

describe("Report Generation Queue", () => {
  beforeAll(async () => {
    // Setup test database and Redis
    await setupTestDatabase();
  });

  afterEach(async () => {
    // Clean up Redis queues after each test
    await redis.flushdb();
  });

  it("should process report generation job successfully", async () => {
    // Arrange
    const report = await new ReportFactory(AppDataSource).create();
    const payload: ReportGenerationPayload = {
      reportId: report.id,
      reportType: ReportType.MONTHLY,
      userId: report.userId,
      startDate: new Date("2024-01-01"),
      endDate: new Date("2024-01-31"),
      format: ReportFormat.PDF,
    };

    // Act
    const job = await reportGenerationQueue.addReportGenerationJob(payload);

    // Wait for job to complete (in real scenario, you'd poll job status)
    await new Promise(resolve => setTimeout(resolve, 1000));

    // Assert
    expect(job.id).toBeDefined();

    // Verify report was generated
    const updatedReport = await AppDataSource
      .getRepository(Report)
      .findOne({ where: { id: report.id } });

    expect(updatedReport?.status).toBe("completed");
  });
});
```

---

## Best Practices

### 1. **Type Safety**

Always define payload types:

```typescript
// ✅ Good - Type-safe
interface ReportPayload {
  reportId: string;
  userId: string;
}

async jobProcessor(data: ReportPayload): Promise<void> {
  console.log(data.reportId); // TypeScript knows this exists
}

// ❌ Bad - Untyped
async jobProcessor(data: any): Promise<void> {
  console.log(data.reportId); // No type checking
}
```

### 2. **Immutable Payloads**

Don't modify job data in processor:

```typescript
// ✅ Good
async jobProcessor(data: ReportPayload): Promise<void> {
  const result = await processReport(data.reportId);
  // Don't modify data.reportId
}

// ❌ Bad
async jobProcessor(data: ReportPayload): Promise<void> {
  data.reportId = "new-id"; // Side effect
}
```

### 3. **Logging with Context**

Always log with relevant context:

```typescript
// ✅ Good
this.logger.info("Processing report", {
  reportId: data.reportId,
  userId: data.userId,
  reportType: data.reportType,
});

// ❌ Bad
this.logger.info("Processing report");
```

### 4. **Error Handling**

Always re-throw errors after logging:

```typescript
// ✅ Good
async jobProcessor(data: ReportPayload): Promise<void> {
  try {
    await processReport(data);
  } catch (error) {
    this.logger.error("Job failed", { error });
    throw error; // Re-throw to trigger retry
  }
}

// ❌ Bad - Silently fails
async jobProcessor(data: ReportPayload): Promise<void> {
  try {
    await processReport(data);
  } catch (error) {
    this.logger.error("Job failed", { error });
    // Job marked as successful even though it failed!
  }
}
```

### 5. **Idempotent Operations**

Design jobs to be safe to retry:

```typescript
// ✅ Good - Idempotent
async jobProcessor(data: ReportPayload): Promise<void> {
  const existing = await Report.findOne({ where: { id: data.reportId } });

  if (existing && existing.status === "completed") {
    this.logger.info("Report already generated, skipping");
    return; // Safe to re-run
  }

  await generateReport(data);
}

// ❌ Bad - Not idempotent
async jobProcessor(data: ReportPayload): Promise<void> {
  // Creates duplicate report on retry
  await Report.create({ ...data });
}
```

### 6. **Queue Naming**

Use descriptive, consistent naming:

```typescript
// ✅ Good
QUEUE_NAMES.REPORT_GENERATION_QUEUE

// ❌ Bad
QUEUE_NAMES.REPORTS
QUEUE_NAMES.jobQueue
```

### 7. **Graceful Shutdown**

Always close queues properly:

```typescript
// ✅ Good
process.on("SIGTERM", async () => {
  await reportGenerationQueue.close(); // Wait for jobs to finish
  process.exit(0);
});

// ❌ Bad
process.on("SIGTERM", () => {
  process.exit(0); // Kills active jobs
});
```

### 8. **Monitoring**

Use health checks:

```typescript
// In your health check endpoint
app.get("/health", async (req, res) => {
  try {
    await reportGenerationQueue.healthCheck();
    return res.json({ status: "healthy" });
  } catch (error) {
    return res.status(503).json({ status: "unhealthy", error });
  }
});
```

---

## Real-World Examples

### Example 1: Mail Queue

**File:** `src/queues/mailQueue.ts`

```typescript
import BaseQueue from "@/queues/base";
import { QUEUE_NAMES } from "@/shared/constants/queue.constants";
import type { MailPayload } from "@/shared/types/mail.type";
import { sendMail } from "@/services/mail.service";

const queueName = QUEUE_NAMES.MAIL_QUEUE;

class MailQueue extends BaseQueue<MailPayload, typeof queueName> {
  constructor() {
    super(queueName);
  }

  async jobProcessor(data: MailPayload): Promise<void> {
    const { notificationEvent, recipientEmail, variables } = data;

    this.logger.info("Sending email", {
      event: notificationEvent,
      recipient: recipientEmail,
    });

    try {
      await sendMail({
        to: recipientEmail,
        template: notificationEvent,
        variables,
      });

      this.logger.info("Email sent successfully", {
        event: notificationEvent,
        recipient: recipientEmail,
      });
    } catch (error) {
      this.logger.error("Failed to send email", {
        event: notificationEvent,
        recipient: recipientEmail,
        error,
      });
      throw error;
    }
  }

  async addJobInQueue(payload: MailPayload, options?: JobsOptions) {
    return this.addJob(queueName, payload, options);
  }
}

export const mailQueue = new MailQueue();
```

### Example 2: Agreement Queue (DocuSign)

**File:** `src/queues/agreement.queue.ts`

```typescript
import BaseQueue from "@/queues/base";
import { QUEUE_NAMES } from "@/shared/constants/queue.constants";
import type { AgreementQueuePayload } from "@/shared/types/docusign.type";
import {
  uploadPdfToAzure,
  createDocusignEnvelope,
} from "@/services/agreement.service";

const queueName = QUEUE_NAMES.AGREEMENT_QUEUE;

class AgreementQueue extends BaseQueue<
  AgreementQueuePayload,
  typeof queueName
> {
  constructor() {
    super(queueName);
  }

  async jobProcessor(data: AgreementQueuePayload): Promise<void> {
    const { agreementId, envelopeData, residentId, buildingId } = data;

    this.logger.info("Processing agreement", { agreementId, residentId });

    try {
      // Step 1: Generate PDF
      const pdfBuffer = await this.generateAgreementPdf(data);

      // Step 2: Upload to Azure
      const azureUrl = await uploadPdfToAzure(pdfBuffer, agreementId);

      // Step 3: Create DocuSign envelope
      const envelope = await createDocusignEnvelope({
        envelopeData,
        azureUrl,
        agreementId,
      });

      // Step 4: Update agreement with envelope info
      await this.updateAgreementEnvelope(agreementId, envelope);

      this.logger.info("Agreement processed successfully", { agreementId });
    } catch (error) {
      this.logger.error("Failed to process agreement", {
        agreementId,
        error,
      });
      throw error;
    }
  }

  private async generateAgreementPdf(data: AgreementQueuePayload) {
    // PDF generation logic
  }

  private async updateAgreementEnvelope(agreementId: string, envelope: any) {
    // Update database logic
  }

  async addAgreementJob(
    payload: AgreementQueuePayload,
    options?: JobsOptions,
  ) {
    return this.addJob(queueName, payload, options);
  }
}

export const agreementQueue = new AgreementQueue();
```

### Example 3: SMS Queue

**File:** `src/queues/sms.queue.ts`

```typescript
import BaseQueue from "@/queues/base";
import { QUEUE_NAMES } from "@/shared/constants/queue.constants";
import type { SMSPayload } from "@/shared/types/sms.type";
import { sendSMS } from "@/services/sms.service";

const queueName = QUEUE_NAMES.SMS_QUEUE;

class SMSQueue extends BaseQueue<SMSPayload, typeof queueName> {
  constructor() {
    super(queueName);
  }

  async jobProcessor(data: SMSPayload): Promise<void> {
    const { phoneCode, phoneNumber, message } = data;

    this.logger.info("Sending SMS", {
      phone: `${phoneCode}${phoneNumber}`,
    });

    try {
      await sendSMS({
        phoneCode,
        phoneNumber,
        message,
      });

      this.logger.info("SMS sent successfully");
    } catch (error) {
      this.logger.error("Failed to send SMS", { error });
      throw error;
    }
  }

  async addJobInQueue(payload: SMSPayload, options?: JobsOptions) {
    return this.addJob(queueName, payload, options);
  }
}

export const smsQueue = new SMSQueue();
```

---

## Quick Reference Checklist

When creating a new queue:

- [ ] Define queue name in `queue.constants.ts`
- [ ] Create payload type in `shared/types/`
- [ ] Create queue class extending `BaseQueue`
- [ ] Implement `jobProcessor` method
- [ ] Add convenience method for enqueueing jobs
- [ ] Export singleton instance
- [ ] Add queue to `server.ts` graceful shutdown
- [ ] Add error handling and logging
- [ ] Write integration tests
- [ ] Update health check endpoint (optional)

---

## Troubleshooting

### Jobs Not Processing

1. **Check Redis connection:**
   ```bash
   redis-cli ping
   ```

2. **Check worker is running:**
   ```typescript
   await reportGenerationQueue.healthCheck();
   ```

3. **Check logs for errors:**
   ```bash
   tail -f logs/combined.log | grep "report-generation-queue"
   ```

### Jobs Keep Failing

1. **Check job attempts:**
   ```typescript
   // In jobProcessor
   console.log(`Attempts: ${job.attemptsMade}`);
   ```

2. **Review error logs:**
   ```typescript
   this.logger.error("Job failed", {
     error: error instanceof Error ? error.stack : error,
   });
   ```

3. **Verify data integrity:**
   ```typescript
   // Validate input before processing
   if (!data.requiredField) {
     throw new Error("Missing required field");
   }
   ```

### High Memory Usage

1. **Reduce `removeOnComplete` retention:**
   ```typescript
   removeOnComplete: 50,  // Keep fewer completed jobs
   ```

2. **Reduce concurrency** (if processing multiple jobs):
   ```typescript
   // In BaseQueue constructor
   this.worker = new Worker(queueName, processor, {
     concurrency: 1,  // Process 1 job at a time
   });
   ```

---

## Summary

You now have everything you need to create and manage background jobs in the QCare API:

1. **BaseQueue** provides the foundation
2. **Define types** for type safety
3. **Implement jobProcessor** with your business logic
4. **Enqueue jobs** from services/controllers
5. **Handle errors** properly with logging
6. **Test** with mocked queues
7. **Monitor** with health checks

Key takeaways:
- Always re-throw errors to trigger retries
- Log with context for debugging
- Make jobs idempotent for safe retries
- Use type-safe payloads
- Close queues gracefully on shutdown

Happy coding! 🚀
