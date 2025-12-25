# Email & SMS Sending Guide - QCare API

A complete guide to sending emails and SMS messages in the QCare backend codebase.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Email Sending](#email-sending)
3. [SMS Sending](#sms-sending)
4. [Queue System](#queue-system)
5. [Configuration](#configuration)
6. [Testing](#testing)
7. [Common Patterns](#common-patterns)
8. [Troubleshooting](#troubleshooting)

---

## Architecture Overview

The email and SMS system uses a **queue-based architecture** with **BullMQ** and **Redis**:

```
Service Layer → Queue → Worker → External API
     ↓            ↓         ↓            ↓
  Your Code    Redis    Processor    SendGrid/Twilio/etc
```

### Key Components

| Component | File | Purpose |
|-----------|------|---------|
| Email Queue | `src/queues/mailQueue.ts` | Manages email job queue |
| SMS Queue | `src/queues/sms.queue.ts` | Manages SMS job queue |
| Base Queue | `src/queues/base.ts` | Shared queue logic |
| Email Service | `src/services/email.service.ts` | Email processing logic |
| Mailer Utility | `src/utils/mailer.ts` | Nodemailer wrapper |
| SMS Utility | `src/utils/sms.utils.ts` | SMS API integration |
| Email Templates | `src/static/emailNotificationEvent.ts` | Template definitions |

---

## Email Sending

### Quick Start - Sending an Email

The simplest way to send an email:

```typescript
import { mailQueue } from "@/queues/mailQueue";
import { EmailEvent } from "@/shared/enums/emailEvent.enum";

await mailQueue.addJobInQueue({
  notificationEvent: EmailEvent.FORGOT_PASSWORD,
  recipientEmail: "user@example.com",
  variables: {
    name: "John Doe",
    resetUrl: "https://qcare.com/reset?token=abc123",
  },
});
```

That's it! The email will be processed asynchronously by the queue worker.

### How It Works

1. **You call `mailQueue.addJobInQueue()`** with your payload
2. **Job is added to Redis queue** (`mail-queue`)
3. **Worker picks up the job** and processes it
4. **`sendEmailNotification()`** looks up the template
5. **Variables are interpolated** into the template
6. **`sendMail()`** sends via Nodemailer

### Adding a New Email Template

#### Step 1: Add Event to Enum

**File:** `src/shared/enums/emailEvent.enum.ts`

```typescript
export enum EmailEvent {
  FORGOT_PASSWORD = "forgot_password",
  SEND_OTP = "send_otp",
  // Add your new event here
  WELCOME_EMAIL = "welcome_email",
}
```

#### Step 2: Add Template Definition

**File:** `src/static/emailNotificationEvent.ts`

```typescript
import { EmailEvent } from "@/shared/enums/emailEvent.enum";
import { emailNotificationReceiverType } from "@/shared/enums/emailNotificationReceiverType.enum";

const emailNotificationEvent: NotificationEmailType = [
  // ... existing templates ...

  {
    event: EmailEvent.WELCOME_EMAIL,
    email: [
      {
        recipientType: emailNotificationReceiverType.SUPER_ADMIN,
        subject: "Welcome to QCare!",
        body: "Hello ${name}, Welcome to QCare! Your account is ready.",
        htmlBody: `
          <h1>Welcome to QCare!</h1>
          <p>Hello ${name},</p>
          <p>Your account is ready to use.</p>
          <a href="${loginUrl}">Login Now</a>
        `,
      },
    ],
  },
];
```

**Template Variables:**
- Use `${variableName}` syntax for interpolation
- Both `body` (text) and `htmlBody` (optional HTML) are supported
- Variables are passed in the `variables` object when calling the queue

#### Step 3: Use Your New Template

```typescript
await mailQueue.addJobInQueue({
  notificationEvent: EmailEvent.WELCOME_EMAIL,
  recipientEmail: newUser.email,
  variables: {
    name: newUser.firstName,
    loginUrl: "https://qcare.com/login",
  },
});
```

### Email Types Reference

**File:** `src/shared/types/mail.type.ts`

```typescript
interface IMailPayload {
  notificationEvent: EmailEvent;  // Which template to use
  variables: Record<string, string>; // Data to interpolate
  recipientEmail?: string;        // Override recipient (optional)
}
```

---

## SMS Sending

### Quick Start - Sending an SMS

Sending an SMS is even simpler:

```typescript
import { smsQueue } from "@/queues/sms.queue";

await smsQueue.addJobInQueue({
  phoneCode: "1",        // Country code (without +)
  phoneNumber: "2345678900", // Phone number (without + or country code)
  message: "Your appointment is confirmed.",
});
```

### Using SMS Templates

**File:** `src/shared/constants/sms.constants.ts`

```typescript
export const SmsContent = {
  RESIDENT_CONTACT_INFO_VALIDATION: (otp: string) =>
    `Your OTP to validate the phone number is ${otp}.`,
} as const;
```

**Usage:**

```typescript
import { SmsContent } from "@/shared/constants/sms.constants";

await smsQueue.addJobInQueue({
  phoneCode: "44",
  phoneNumber: "1234567890",
  message: SmsContent.RESIDENT_CONTACT_INFO_VALIDATION("123456"),
});
```

### Adding a New SMS Template

Edit `src/shared/constants/sms.constants.ts`:

```typescript
export const SmsContent = {
  RESIDENT_CONTACT_INFO_VALIDATION: (otp: string) =>
    `Your OTP to validate the phone number is ${otp}.`,

  // Add your template here
  APPOINTMENT_REMINDER: (date: string, time: string) =>
    `Reminder: You have an appointment on ${date} at ${time}.`,

  BOOKING_CONFIRMATION: (bookingId: string) =>
    `Your booking ${bookingId} has been confirmed.`,
} as const;
```

### SMS Types Reference

**File:** `src/shared/types/sms.type.ts`

```typescript
interface SmsQueuePayload {
  message: string;      // The SMS content
  phoneNumber: string;  // Phone number (without + or country code)
  phoneCode: string;    // Country code (without +)
}
```

**Phone Format:**
- Final format: `+<phoneCode><phoneNumber>`
- Example: `+12123456789` (country code: 1, phone: 2123456789)

---

## Queue System

The queues use **BullMQ** with **Redis** for reliable job processing.

### Default Queue Configuration

**File:** `src/configs/redis.ts`

```typescript
export const defaultJobOptions: DefaultJobOptions = {
  keepLogs: 1000,           // Keep last 1000 log entries
  attempts: 5,              // Retry failed jobs 5 times
  backoff: {
    type: "exponential",    // Exponential backoff between retries
    delay: 2000,            // Initial delay: 2 seconds
  },
  removeOnComplete: 200,    // Remove completed jobs after 200
  removeOnFail: {
    age: 60 * 60 * 24 * 7,  // Remove failed jobs after 7 days
  },
};
```

### Creating a Custom Queue

If you need a new queue for other async operations:

```typescript
// src/queues/myCustomQueue.ts
import BaseQueue from "@/queues/base";
import type { MyCustomPayload } from "@/shared/types/my.type";

const queueName = "my-custom-queue";

class MyCustomQueue extends BaseQueue<MyCustomPayload, "my-custom-queue"> {
  constructor() {
    super(queueName);
  }

  async jobProcessor(data: MyCustomPayload): Promise<void> {
    // Your processing logic here
    await doSomething(data);
  }

  async addJobInQueue(jobData: MyCustomPayload) {
    return this.addJob(queueName, jobData);
  }
}

export const myCustomQueue = new MyCustomQueue();
```

### Queue Lifecycle

**Initialization:** Queues are automatically started when imported in `server.ts`:

```typescript
import { mailQueue } from "@/queues/mailQueue";
import { smsQueue } from "@/queues/sms.queue";
// ... queues start automatically
```

**Graceful Shutdown:** On server shutdown, queues close properly:

```typescript
await mailQueue.close();
await smsQueue.close();
```

---

## Configuration

### Email Configuration

**File:** `src/configs/mail.ts`

#### Local/Test Environment

Uses **MailHog** (no real emails sent):

```typescript
{
  host: "localhost",
  port: 1025,
  secure: false,
  defaultSender: "noreply@qcare.com",
  replyTo: "support@qcare.com",
  webUiUrl: "http://localhost:8025", // View emails here
}
```

#### Production Environment

Fetches credentials from **Azure Key Vault**:

```typescript
{
  host: "<from Key Vault>",
  port: 527,
  auth: {
    user: "<from Key Vault>",
    pass: "<from Key Vault>",
  },
  secure: false,
  defaultSender: "noreply@qcare.com",
  replyTo: "support@qcare.com",
}
```

### Environment Variables

**File:** `.env` or `.env.test`

```bash
# Email Configuration
MAIL_HOST=localhost
MAIL_PORT=1025
MAIL_USERNAME=
MAIL_PASSWORD=
MAIL_DEFAULT_SENDER=noreply@qcare.com
MAIL_REPLY_TO=support@qcare.com

# SMS Configuration (Infinity Tech Africa)
SMS_INFINITY_TECH_AFRICA_URL=https://api.infinitytech.africa/sms
SMS_INFINITY_TECH_AFRICA_TOKEN=your_token_here

# Redis (required for queues)
REDIS_HOST=localhost
REDIS_PORT=6379
```

### Key Vault Integration

For production, credentials are stored in Azure Key Vault:

```typescript
import { getSecret } from "@/utils/keyVaultClient";

const host = await getSecret("MAIL_HOST");
const user = await getSecret("MAIL_USERNAME");
const pass = await getSecret("MAIL_PASSWORD");
```

---

## Testing

### Testing Email Sending

**Test Factory:**

```typescript
// In your test file
import { mailQueue } from "@/queues/mailQueue";

it("should send password reset email", async () => {
  await mailQueue.addJobInQueue({
    notificationEvent: EmailEvent.FORGOT_PASSWORD,
    recipientEmail: "test@example.com",
    variables: { name: "Test User", resetUrl: "http://test.com/reset" },
  });

  // Wait for queue processing
  await new Promise(resolve => setTimeout(resolve, 1000));

  // Assert email was sent (check logs, DB, or mock mailer)
});
```

### Testing SMS Sending

```typescript
import { smsQueue } from "@/queues/sms.queue";

it("should send OTP via SMS", async () => {
  await smsQueue.addJobInQueue({
    phoneCode: "1",
    phoneNumber: "2345678900",
    message: "Your OTP is 123456",
  });

  // Wait and assert
  await new Promise(resolve => setTimeout(resolve, 1000));
});
```

### Viewing Emails in Local Development

1. Start the server
2. Send an email
3. Open **MailHog UI**: http://localhost:8025
4. View your captured emails

---

## Common Patterns

### Pattern 1: OTP Email

```typescript
// Generate OTP
const otp = generateOtp(); // Your OTP logic

// Send email
await mailQueue.addJobInQueue({
  notificationEvent: EmailEvent.SEND_OTP,
  recipientEmail: user.email,
  variables: {
    name: user.name,
    otp: otp,
  },
});
```

### Pattern 2: Dynamic Template Variables

```typescript
await mailQueue.addJobInQueue({
  notificationEvent: EmailEvent.WELCOME_EMAIL,
  recipientEmail: user.email,
  variables: {
    name: user.firstName,
    email: user.email,
    companyName: "QCare",
    loginUrl: `${appUrl}/login`,
    supportPhone: "+1-234-567-8900",
  },
});
```

### Pattern 3: SMS with Template

```typescript
import { SmsContent } from "@/shared/constants/sms.constants";

await smsQueue.addJobInQueue({
  phoneCode: user.phoneCode,
  phoneNumber: user.phoneNumber,
  message: SmsContent.APPOINTMENT_REMINDER(
    appointment.date,
    appointment.time
  ),
});
```

### Pattern 4: Conditional Notifications

```typescript
// Send email if user has email
if (user.email) {
  await mailQueue.addJobInQueue({
    notificationEvent: EmailEvent.SEND_OTP,
    recipientEmail: user.email,
    variables: { name: user.name, otp },
  });
}

// Send SMS if user has phone
if (user.phoneNumber) {
  await smsQueue.addJobInQueue({
    phoneCode: user.phoneCode,
    phoneNumber: user.phoneNumber,
    message: SmsContent.RESIDENT_CONTACT_INFO_VALIDATION(otp),
  });
}
```

### Pattern 5: Service Layer Integration

```typescript
// src/services/user.service.ts
import { mailQueue } from "@/queues/mailQueue";
import { EmailEvent } from "@/shared/enums/emailEvent.enum";

export const createUser = async (userData: CreateUserDto) => {
  const user = await saveOne({ entity: User, data: userData });

  // Send welcome email
  await mailQueue.addJobInQueue({
    notificationEvent: EmailEvent.WELCOME_EMAIL,
    recipientEmail: user.email,
    variables: {
      name: user.name,
      loginUrl: `${env.APP_URL}/login`,
    },
  });

  return user;
};
```

---

## Troubleshooting

### Emails Not Sending

1. **Check Redis is running:**
   ```bash
   redis-cli ping
   # Should return: PONG
   ```

2. **Check queue health:**
   ```typescript
   await mailQueue.healthCheck();
   ```

3. **Check logs for errors:**
   - Queue processing logs include job ID and attempt count
   - Look for `Processing failed` messages

4. **Verify MailHog (local):**
   - Ensure MailHog is running on port 1025
   - Check http://localhost:8025 for captured emails

5. **Verify credentials (production):**
   - Check Key Vault secrets exist
   - Verify MAIL_HOST, MAIL_USERNAME, MAIL_PASSWORD

### SMS Not Sending

1. **Check Infinity Tech Africa credentials:**
   ```bash
   echo $SMS_INFINITY_TECH_AFRICA_TOKEN
   ```

2. **Verify phone format:**
   - Final format must be: `+<code><number>`
   - Example: `+12123456789`

3. **Check API response:**
   - Look for axios errors in logs
   - Verify Bearer token is valid

### Queue Jobs Stuck

1. **Check Redis connection:**
   ```typescript
   import { redis } from "@/configs/redis";
   redis.status // Should be 'ready'
   ```

2. **View queue stats:**
   ```typescript
   const waiting = await mailQueue.queue.getWaitingCount();
   const active = await mailQueue.queue.getActiveCount();
   const failed = await mailQueue.queue.getFailedCount();
   ```

3. **Retry failed jobs:**
   ```typescript
   await mailQueue.queue.retryJobs();
   ```

### Variable Interpolation Not Working

1. **Check variable names match template:**
   ```typescript
   // Template: "Hello ${name}, your OTP is ${otp}"
   // Variables must be: { name: "...", otp: "..." }
   ```

2. **Ensure all required variables are provided:**
   ```typescript
   variables: {
     name: user.name,
     otp: otp,
     // Missing variables will be replaced with empty string
   }
   ```

---

## File Reference

### Email Files

| File | Purpose |
|------|---------|
| `src/queues/mailQueue.ts` | Email queue implementation |
| `src/services/email.service.ts` | Email processing logic |
| `src/utils/mailer.ts` | Nodemailer wrapper |
| `src/configs/mail.ts` | Email configuration |
| `src/static/emailNotificationEvent.ts` | Email templates |
| `src/shared/types/mail.type.ts` | Type definitions |
| `src/shared/enums/emailEvent.enum.ts` | Email events enum |

### SMS Files

| File | Purpose |
|------|---------|
| `src/queues/sms.queue.ts` | SMS queue implementation |
| `src/utils/sms.utils.ts` | SMS API integration |
| `src/shared/types/sms.type.ts` | Type definitions |
| `src/shared/constants/sms.constants.ts` | SMS templates |

### Queue Files

| File | Purpose |
|------|---------|
| `src/queues/base.ts` | Base queue class |
| `src/configs/redis.ts` | Redis & BullMQ config |

---

## Best Practices

### Do's

✅ **Always use queues** - Never send emails/SMS directly in controllers
✅ **Use templates** - Keep message content in template files
✅ **Handle errors gracefully** - Queues auto-retry on failure
✅ **Use environment variables** - Keep credentials out of code
✅ **Test with MailHog** - View emails locally without sending
✅ **Log important events** - Queue processing includes logging
✅ **Use Key Vault in production** - Secure credential storage

### Don'ts

❌ **Don't send emails synchronously** - Always use queues
❌ **Don't hardcode credentials** - Use environment variables or Key Vault
❌ **Don't forget to interpolate variables** - Use `${var}` syntax
❌ **Don't mix phone formats** - Always use `+<code><number>`
❌ **Don't skip error handling** - Let queues handle retries

---

## Summary

### Sending an Email - 3 Steps

1. **Import the queue:**
   ```typescript
   import { mailQueue } from "@/queues/mailQueue";
   ```

2. **Import the email event:**
   ```typescript
   import { EmailEvent } from "@/shared/enums/emailEvent.enum";
   ```

3. **Add job to queue:**
   ```typescript
   await mailQueue.addJobInQueue({
     notificationEvent: EmailEvent.SEND_OTP,
     recipientEmail: "user@example.com",
     variables: { name: "User", otp: "123456" },
   });
   ```

### Sending an SMS - 2 Steps

1. **Import the queue:**
   ```typescript
   import { smsQueue } from "@/queues/sms.queue";
   ```

2. **Add job to queue:**
   ```typescript
   await smsQueue.addJobInQueue({
     phoneCode: "1",
     phoneNumber: "2345678900",
     message: "Your message here",
   });
   ```

---

## Need Help?

- Check existing implementations in `src/services/`
- Review email templates in `src/static/emailNotificationEvent.ts`
- Look at queue tests for examples
- Check logs for detailed error messages
