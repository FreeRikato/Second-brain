# DocuSign Integration Guide

A comprehensive guide to implementing DocuSign integration in your Node.js/TypeScript application, based on the QCare API implementation.

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Environment Configuration](#environment-configuration)
5. [Core Components](#core-components)
6. [Implementation Guide](#implementation-guide)
7. [Complete Workflow](#complete-workflow)
8. [Security Best Practices](#security-best-practices)
9. [Testing & Debugging](#testing--debugging)
10. [Common Pitfalls](#common-pitfalls)

---

## Overview

This DocuSign integration implements a complete agreement signing workflow with:
- **JWT Authentication**: RSA-signed tokens for secure API access
- **PDF Generation**: Dynamic HTML-to-PDF conversion with template variables
- **Envelope Management**: Creating and sending DocuSign envelopes
- **Webhook Processing**: HMAC-validated event handling
- **Queue-Based Processing**: Asynchronous, retry-capable job processing

### Key Features

- Embedded signing experience for users
- Template-based agreement generation
- Automatic document storage on Azure Blob
- Full audit trail with status tracking
- Queue-based reliability with BullMQ

---

## Architecture

```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐
│   Booking   │ ───> │ Agreement    │ ───> │   DocuSign  │
│   Created   │      │ Queue        │      │   Envelope  │
└─────────────┘      └──────────────┘      └─────────────┘
                           │                      │
                           ▼                      ▼
                    ┌──────────────┐      ┌─────────────┐
                    │  PDF Gen +   │      │   DocuSign  │
                    │  Template    │      │   Webhook   │
                    └──────────────┘      └─────────────┘
                           │                      │
                           ▼                      ▼
                    ┌──────────────┐      ┌─────────────┐
                    │   Email      │      │   Event     │
                    │  Notification│      │   Queue     │
                    └──────────────┘      └─────────────┘
                                                  │
                                                  ▼
                                           ┌─────────────┐
                                           │ Azure Blob  │
                                           │   Upload    │
                                           └─────────────┘
```

---

## Prerequisites

### 1. DocuSign Account Setup

1. **Create a DocuSign Developer Account**
   - Go to [https://developers.docusign.com](https://developers.docusign.com)
   - Sign up for a free developer sandbox account

2. **Create an App Integration**
   - Go to Settings > Apps and Keys
   - Click "Add App" > "Confidential Client"
   - Select "JWT Grant" authentication
   - Note your **Integration Key** (Client ID)

3. **Generate RSA Key Pair**
   ```bash
   openssl genrsa -out docusign_private_key.txt 4096
   openssl rsa -in docusign_private_key.txt -pubout -out docusign_public_key.txt
   ```

4. **Upload Public Key**
   - Copy the contents of `docusign_public_key.txt`
   - Paste it in the app configuration under "RSA Public Key"

5. **Grant impersonation consent**
   - Use the consent URL with your integration key and user ID
   - Format: `https://account-d.docusign.com/oauth/auth?response_type=code&scope=signature%20impersonation&client_id={INTEGRATION_KEY}&redirect_uri={REDIRECT_URI}`

6. **Get Your User ID**
   - Go to Settings > Apps and Keys
   - Find your API Username (GUID format)

7. **Configure Webhook**
   - Go to Settings > Connect
   - Create a new Connect configuration
   - Set your webhook URL
   - Enable HMAC signature validation
   - Note your **Connect Key** (HMAC secret)

---

## Environment Configuration

### Required Environment Variables

Add these to your `.env` file:

```bash
# DocuSign OAuth Configuration
DOCUSIGN_INTEGRATION_KEY="your-integration-key-here"
DOCUSIGN_USER_ID="your-user-id-guid-here"
DOCUSIGN_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----\n...\n-----END RSA PRIVATE KEY-----\n"

# DocuSign API Domains (Demo Environment)
DOCUSIGN_DOMAIN="https://account-d.docusign.com"
DOCUSIGN_ENVELOPE_DOMAIN="https://demo.docusign.net/restapi"

# Webhook Configuration
DOCUSIGN_CONNECT_KEY="your-hmac-secret-key"

# Return URL after signing (embedded signing)
DOCUSIGN_RETURN_URL="https://yourapp.com/agreement/signed"
```

### Environment Validation Schema

```typescript
// src/validations/envValidation.ts
import { z } from "zod";

export const envValidationSchema = z.object({
  // ... other env vars

  DOCUSIGN_INTEGRATION_KEY: z.string(),
  DOCUSIGN_USER_ID: z.string(),
  DOCUSIGN_PRIVATE_KEY: z.string(),
  DOCUSIGN_DOMAIN: z.string(),
  DOCUSIGN_ENVELOPE_DOMAIN: z.string(),
  DOCUSIGN_RETURN_URL: z.url(),
  DOCUSIGN_CONNECT_KEY: z.string().nonempty(),
});
```

### Environment Switching

For production, update the domains:

```bash
# Production Environment
DOCUSIGN_DOMAIN="https://account.docusign.com"
DOCUSIGN_ENVELOPE_DOMAIN="https://www.docusign.net/restapi"
```

---

## Core Components

### 1. Type Definitions

```typescript
// src/shared/types/docusign.type.ts

// JWT payload for authentication
export interface IDocuSignJWTPayload {
  iss: string;  // Integration key
  sub: string;  // User ID
  aud: string;  // Auth server domain
  iat: number;  // Issued at
  exp: number;  // Expiration
  scope: string; // "signature"
}

// OAuth token response
export interface IDocuSignTokenResponse {
  access_token: string;
  token_type: string;
  expires_in: number;
  scope: string;
}

// User info with account details
export interface IDocuSignUserInfo {
  sub: string;
  name: string;
  email: string;
  accounts: IDocuSignAccount[];
}

export interface IDocuSignAccount {
  account_id: string;
  is_default: boolean;
  account_name: string;
  base_uri: string;
}

// Envelope creation payload
export interface IDocuSignEnvelopePayload {
  documents: IDocuSignDocument[];
  emailSubject: string;
  recipients: {
    signers: IDocuSignSigner[];
  };
  status: DocuSignStatusEnum;
}

export interface IDocuSignDocument {
  documentBase64: string;
  documentId: string;
  fileExtension: string;
  name: string;
}

export interface IDocuSignSigner {
  email: string;
  name: string;
  recipientId: string;
  clientUserId?: string;  // For embedded signing
  routingOrder: string;
  embeddedRecipientStartURL: string;
}

// Envelope creation response
export interface IDocuSignEnvelopeResponse {
  envelopeId: string;
  uri: string;
  statusDateTime: string;
  status: string;
}
```

### 2. Constants

```typescript
// src/shared/constants/docusign.constants.ts

export const DocuSignEndpoint = {
  // OAuth endpoints
  OAUTH_TOKEN: "/oauth/token",
  OAUTH_USERINFO: "/oauth/userinfo",

  // Envelope endpoints
  ENVELOPES: (accountId: string) =>
    `/restapi/v2.1/accounts/${accountId}/envelopes`,
} as const;

export const DocuSignJWT = {
  TOKEN_EXPIRY: 3600, // 1 hour in seconds
  SCOPE: "signature",
} as const;

export const DocuSignEnvelope = {
  EMAIL_SUBJECT: "Agreement Signature Request",
  DOCUMENT_NAME: "Agreement",
  DOCUMENT_ID: "1",
  FILE_EXTENSION: "pdf",
  RECIPIENT_ID: "1",
  ROUTING_ORDER: "1",
  STATUS_SENT: "sent",
  STATUS_CREATED: "created",
  // For embedded signing - start at DocuSign
  EMBEDDED_RECIPIENT_START_URL: "SIGN_AT_DOCUSIGN",
} as const;
```

### 3. Enums

```typescript
// src/shared/enums/docusign.enum.ts

// Agreement status tracking
export enum AgreementStatus {
  SENT = "sent",
  DELIVERED = "delivered",
  COMPLETED = "completed",
  VOIDED = "voided",
  DECLINED = "declined",
  FAILED = "failed",
}

// Envelope creation status
export enum DocuSignStatusEnum {
  SENT = "sent",
  CREATED = "created",
}

// Webhook event types
export enum DocusignEventStatusEnum {
  COMPLETED = "envelope-completed",
  DELETED = "envelope-deleted",
}
```

---

## Implementation Guide

### Step 1: Install Dependencies

```bash
npm install docusign-esign axios node-jose puppeteer
npm install --save-dev @types/node-jose
```

### Step 2: JWT Authentication Service

```typescript
// src/services/docusign.service.ts

import axios from "axios";
import * as jose from "node-jose";
import env from "@/configs/environment";
import {
  DocuSignEndpoint,
  DocuSignJWT,
} from "@/shared/constants/docusign.constants";
import type {
  IDocuSignJWTPayload,
  IDocuSignTokenResponse,
  IDocuSignUserInfo,
} from "@/shared/types/docusign.type";
import logger from "@/utils/logger";

/**
 * Generates a JWT token for DocuSign authentication
 * Uses RS256 algorithm with your private key
 */
export const generateJWT = async (): Promise<string> => {
  const {
    DOCUSIGN_PRIVATE_KEY,
    DOCUSIGN_INTEGRATION_KEY,
    DOCUSIGN_USER_ID,
    DOCUSIGN_DOMAIN,
  } = env;

  // Parse private key (handle newlines from env)
  const privateKey = DOCUSIGN_PRIVATE_KEY.replace(/\\n/g, "\n");

  // Create JWT payload
  const payload: IDocuSignJWTPayload = {
    iss: DOCUSIGN_INTEGRATION_KEY,
    sub: DOCUSIGN_USER_ID,
    aud: DOCUSIGN_DOMAIN.replace("https://", ""),
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + DocuSignJWT.TOKEN_EXPIRY,
    scope: DocuSignJWT.SCOPE,
  };

  try {
    // Create keystore and add private key
    const keystore = jose.JWK.createKeyStore();
    const key = await keystore.add(privateKey, "pem");

    // Sign JWT with RS256
    const jwt = await jose.JWS.createSign(
      { format: "compact", fields: { alg: "RS256", typ: "JWT" } },
      key,
    )
      .update(JSON.stringify(payload))
      .final();

    return jwt as unknown as string;
  } catch (error) {
    logger.error("Error generating DocuSign JWT", { error });
    throw new Error("Failed to generate DocuSign JWT");
  }
};

/**
 * Exchanges JWT for OAuth access token
 */
export const getAccessToken = async (): Promise<IDocuSignTokenResponse> => {
  const { DOCUSIGN_DOMAIN } = env;

  try {
    const jwt = await generateJWT();

    const response = await axios.post<IDocuSignTokenResponse>(
      `${DOCUSIGN_DOMAIN}${DocuSignEndpoint.OAUTH_TOKEN}`,
      {
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion: jwt,
      },
      {
        headers: {
          "Content-Type": "application/json",
        },
      },
    );

    return response.data;
  } catch (error) {
    logger.error("Failed to get DocuSign access token", { error });
    throw new Error("Failed to get DocuSign access token");
  }
};

/**
 * Fetches user info including account details
 */
export const getUserInfo = async (
  accessToken: string,
): Promise<IDocuSignUserInfo> => {
  const { DOCUSIGN_DOMAIN } = env;

  try {
    const response = await axios.get<IDocuSignUserInfo>(
      `${DOCUSIGN_DOMAIN}${DocuSignEndpoint.OAUTH_USERINFO}`,
      {
        headers: {
          Authorization: `Bearer ${accessToken}`,
        },
      },
    );

    return response.data;
  } catch (error) {
    logger.error("Failed to get DocuSign user info", { error });
    throw new Error("Failed to get DocuSign user info");
  }
};
```

### Step 3: PDF Generation with Templates

```typescript
// src/utils/agreementUtils.ts

/**
 * Replaces template variables with actual values
 * Usage: replaceTemplateVariables(html, { fullName: "John" })
 * Replaces #fullName# with "John"
 */
export const replaceTemplateVariables = (
  htmlContent: string,
  variables: Record<string, string>,
): string => {
  return Object.entries(variables).reduce((content, [key, value]) => {
    const regex = new RegExp(`#${key}#`, "g");
    return content.replace(regex, value);
  }, htmlContent);
};
```

```typescript
// src/services/docusign.service.ts (continued)

import puppeteer from "puppeteer";
import AppDataSource from "@/database/dataSource";
import Booking from "@/database/entities/Booking.entity";
import { getAgreementTemplate } from "@/services/template.service";

/**
 * Generates PDF from HTML template with variable replacement
 */
export const generateAgreementPDF = async (
  bookingId: string,
): Promise<string> => {
  const bookingRepo = AppDataSource.getRepository(Booking);

  try {
    // Fetch booking with all relations
    const booking = await bookingRepo.findOne({
      where: { id: bookingId },
      relations: [
        "user",
        "user.college",
        "building",
        "bed",
        "bed.room",
        "bed.room.type",
        "pricingPlanRoomTypeMap",
        "pricingPlanRoomTypeMap.roomType",
      ],
    });

    if (!booking) {
      throw new BadRequestError("Booking not found");
    }

    // Get template from database
    const template = await getAgreementTemplate();

    // Build variables from booking data
    const variables = await buildAgreementVariables(booking);

    // Replace template variables
    const processedHtml = replaceTemplateVariables(
      template.content,
      variables,
    );

    // Launch Puppeteer
    const browser = await puppeteer.launch({
      headless: true,
      args: ["--no-sandbox", "--disable-setuid-sandbox"],
    });

    const page = await browser.newPage();

    // Set content and wait for network idle
    await page.setContent(processedHtml, {
      waitUntil: "networkidle0",
    });

    // Add TinyMCE styles for better formatting
    await page.addStyleTag({
      url: "https://cdnjs.cloudflare.com/ajax/libs/tinymce/8.1.2/skins/content/default/content.min.css",
    });

    // Generate PDF
    const pdfBuffer = await page.pdf({
      format: "A4",
      printBackground: true,
      margin: {
        top: "50px",
        right: "20px",
        bottom: "50px",
        left: "20px",
      },
    });

    await browser.close();

    // Convert to base64
    return Buffer.from(pdfBuffer).toString("base64");
  } catch (error) {
    logger.error("Error generating agreement PDF", { error, bookingId });
    throw error;
  }
};

/**
 * Builds variable map from booking entity
 */
export const buildAgreementVariables = async (
  booking: Booking,
): Promise<Record<string, string>> => {
  const { user, building, bed, bookedCheckedInDate, bookedCheckedOutDate } =
    booking;

  // Fetch related data
  const [guardian, buildingAddress, userAddress] = await Promise.all([
    AppDataSource.getRepository(UserGuardian).findOne({
      where: { student: { id: user.id } },
    }),
    AppDataSource.getRepository(Address).findOne({
      where: {
        addressableId: building?.id,
        addressableType: AddressTypeEnum.BUILDING,
      },
      relations: ["city", "country"],
    }),
    AppDataSource.getRepository(Address).findOne({
      where: {
        addressableId: user.id,
        addressableType: AddressTypeEnum.USER,
      },
      relations: ["city", "country"],
    }),
  ]);

  return {
    fullName: user.name,
    userAddress: formatAddress(userAddress),
    userEmail: user.email,
    userMobileNumber: `${user.phoneCode}${user.phoneNumber}`,
    guardianName: guardian?.name ?? "",
    guardianEmail: guardian?.email ?? "",
    institutionName: user.college?.name ?? "",
    buildingLegalName: building?.legalName ?? "",
    buildingAddress: formatAddress(buildingAddress),
    roomNumber: bed?.room.number,
    apartmentNumber: bed?.room.apartment?.number ?? "",
    roomType: bed?.room.type.name,
    bookedCheckinDate: dayjs(bookedCheckedInDate).format("DD MMM YYYY"),
    bookedCheckoutDate: dayjs(bookedCheckedOutDate).format("DD MMM YYYY"),
    // ... add more fields as needed
  };
};
```

### Step 4: Envelope Creation

```typescript
// src/services/docusign.service.ts (continued)

import {
  DocuSignEndpoint,
  DocuSignEnvelope,
} from "@/shared/constants/docusign.constants";
import { DocuSignStatusEnum } from "@/shared/enums/docusign.enum";
import type {
  IDocuSignEnvelopePayload,
  IDocuSignEnvelopeResponse,
} from "@/shared/types/docusign.type";

/**
 * Sends envelope to DocuSign
 */
export const sendEnvelope = async (
  booking: Booking,
  pdfBase64: string,
): Promise<IDocuSignEnvelopeResponse> => {
  const { DOCUSIGN_ENVELOPE_DOMAIN } = env;

  try {
    // Get access token
    const tokenResponse = await getAccessToken();
    const accessToken = tokenResponse.access_token;

    // Get user info with account details
    const userInfo = await getUserInfo(accessToken);

    // Find default account
    const defaultAccount = userInfo.accounts.find(
      (account) => account.is_default,
    );

    if (!defaultAccount) {
      throw new BadRequestError("Default DocuSign account not found");
    }

    // Build envelope payload
    const envelopePayload: IDocuSignEnvelopePayload = {
      documents: [
        {
          documentBase64: pdfBase64,
          documentId: DocuSignEnvelope.DOCUMENT_ID,
          fileExtension: DocuSignEnvelope.FILE_EXTENSION,
          name: DocuSignEnvelope.DOCUMENT_NAME,
        },
      ],
      emailSubject: DocuSignEnvelope.EMAIL_SUBJECT,
      recipients: {
        signers: [
          {
            email: booking.user.email,
            name: booking.user.name,
            recipientId: DocuSignEnvelope.RECIPIENT_ID,
            clientUserId: booking.user.id, // For embedded signing
            routingOrder: DocuSignEnvelope.ROUTING_ORDER,
            embeddedRecipientStartURL:
              DocuSignEnvelope.EMBEDDED_RECIPIENT_START_URL,
          },
        ],
      },
      status: DocuSignStatusEnum.SENT,
    };

    // Send envelope
    const url = `${DOCUSIGN_ENVELOPE_DOMAIN}${DocuSignEndpoint.ENVELOPES(
      defaultAccount.account_id,
    )}`;

    const response = await axios.post<IDocuSignEnvelopeResponse>(
      url,
      envelopePayload,
      {
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
      },
    );

    return response.data;
  } catch (error) {
    logger.error("Error sending DocuSign envelope", {
      error,
      bookingId: booking.id,
    });
    throw error;
  }
};
```

### Step 5: Queue-Based Processing

```typescript
// src/queues/agreement.queue.ts

import BaseQueue from "@/queues/base";
import {
  generateAgreementPDF,
  sendEnvelope,
} from "@/services/docusign.service";
import { AgreementStatus } from "@/shared/enums/docusign.enum";
import type { IAgreementQueuePayload } from "@/shared/types/docusign.type";

class AgreementQueue extends BaseQueue<
  IAgreementQueuePayload,
  typeof QUEUE_NAMES.AGREEMENT_QUEUE
> {
  constructor() {
    super(QUEUE_NAMES.AGREEMENT_QUEUE);
  }

  async jobProcessor(data: IAgreementQueuePayload): Promise<void> {
    const bookingId = data.bookingId;

    try {
      const bookingRepo = AppDataSource.getRepository(Booking);
      const booking = await bookingRepo.findOne({
        where: { id: bookingId },
        relations: ["user"],
      });

      if (!booking) {
        throw new BadRequestError("Booking not found");
      }

      logger.info("Starting agreement send process", { bookingId });

      // Step 1: Generate PDF
      const pdfBase64 = await generateAgreementPDF(bookingId);
      logger.info("Agreement PDF generated successfully", { bookingId });

      // Step 2: Send envelope
      const { envelopeId } = await sendEnvelope(booking, pdfBase64);
      logger.info("Envelope sent to DocuSign successfully", {
        bookingId,
        envelopeId,
      });

      // Step 3: Update booking
      Object.assign(booking, {
        envelopeId,
        agreementStatus: AgreementStatus.SENT,
        envelopeSentAt: new Date(),
      });

      await bookingRepo.save(booking);

      logger.info("Agreement send process completed", {
        bookingId,
        envelopeId,
      });
    } catch (error) {
      logger.error("Agreement send process failed", { error, bookingId });
      throw error; // Let queue handle retry
    }
  }

  async addAgreementSendJob(bookingId: string) {
    return this.addJob(QUEUE_NAMES.AGREEMENT_QUEUE, { bookingId });
  }
}

export const agreementQueue = new AgreementQueue();
```

### Step 6: Webhook Handler

```typescript
// src/controllers/webhook.controller.ts

import crypto from "node:crypto";
import docusignEventQueue from "@/queues/docusignEvent.queue";
import { HttpStatusCode } from "axios";

export const processDocusignEvents: RequestHandler = async (req, res) => {
  // 1. Extract signature header
  const signature = req.header("X-DocuSign-Signature-1");

  if (!signature) {
    return res.sendStatus(HttpStatusCode.Unauthorized);
  }

  // 2. Calculate HMAC
  const hmac = crypto
    .createHmac("sha256", env.DOCUSIGN_CONNECT_KEY)
    .update(req.rawBody)
    .digest("base64");

  // 3. Timing-safe comparison (prevents timing attacks)
  const isValid = crypto.timingSafeEqual(
    Buffer.from(hmac),
    Buffer.from(signature),
  );

  if (!isValid) {
    return res.sendStatus(HttpStatusCode.Unauthorized);
  }

  // 4. Parse and validate event data
  const eventData = DocusignWebhookEventSchema.parse(req.body);

  // 5. Queue event processing
  await docusignEventQueue.addJobInQueue(
    eventData.data.envelopeId,
    eventData.event,
  );

  return res.sendStatus(HttpStatusCode.Ok);
};
```

### Step 7: Webhook Event Processing

```typescript
// src/queues/docusignEvent.queue.ts

import BaseQueue from "@/queues/base";
import { getAgreementDocumentPDF } from "@/services/docusign.service";
import { uploadToAzureBlob } from "@/services/image.service";
import {
  updateAgreementDocument,
  updateEnvelopeStatus,
} from "@/services/webhook.service";
import { AgreementStatus } from "@/shared/enums/docusign.enum";
import { DocusignEventStatusEnum } from "@/shared/enums/docusign.enum";

class DocusignEventQueue extends BaseQueue<
  IDocusignEventQueuePayload,
  typeof QUEUE_NAMES.DOCUSIGN_EVENT_QUEUE
> {
  constructor() {
    super(QUEUE_NAMES.DOCUSIGN_EVENT_QUEUE);
  }

  async jobProcessor(data: IDocusignEventQueuePayload): Promise<void> {
    const { envelopeId, event } = data;

    try {
      if (event === DocusignEventStatusEnum.COMPLETED) {
        // Update booking status
        await updateEnvelopeStatus(envelopeId, AgreementStatus.COMPLETED);

        // Download signed PDF
        const pdf = await getAgreementDocumentPDF(envelopeId);

        // Upload to Azure Blob
        const blobName = await uploadToAzureBlob(
          pdf,
          "application/pdf",
          `agreements/${envelopeId}.pdf`,
        );

        // Update document record
        await updateAgreementDocument(envelopeId, blobName);
      }

      logger.info("DocuSign event processed successfully", { envelopeId });
    } catch (error) {
      logger.error("Error processing DocuSign event", { error });
      throw error;
    }
  }

  async addJobInQueue(
    envelopeId: string,
    event: DocusignEventStatusEnum,
  ) {
    return this.addJob(QUEUE_NAMES.DOCUSIGN_EVENT_QUEUE, {
      envelopeId,
      event,
    });
  }
}

export const docusignEventQueue = new DocusignEventQueue();
```

### Step 8: Get Signing URL (Embedded Signing)

```typescript
// src/services/docusign.service.ts (continued)

import docusign from "docusign-esign";
import type {
  IDocuSignRecipient,
  IDocuSignRecipientsResponse,
  IDocuSignRecipientViewRequest,
} from "@/shared/types/docusign.type";

/**
 * Generates embedded signing URL for user
 */
export const getAgreementSigningUrl = async (
  envelopeId: string,
  recipientId: string,
) => {
  try {
    // Get access token
    const tokenResponse = await getAccessToken();
    const accessToken = tokenResponse.access_token;

    // Get account info
    const userInfo = await getUserInfo(accessToken);
    const accountId = userInfo.accounts[0]?.account_id;

    // Initialize API client
    const apiClient = new docusign.ApiClient();
    apiClient.setBasePath(`${env.DOCUSIGN_ENVELOPE_DOMAIN}/restapi`);
    apiClient.addDefaultHeader("Authorization", `Bearer ${accessToken}`);

    const envelopesApi = new docusign.EnvelopesApi(apiClient);

    // Get recipients
    const recipients = (await envelopesApi.listRecipients(
      accountId ?? "",
      envelopeId,
    )) as unknown as IDocuSignRecipientsResponse;

    // Find the specific signer
    const signer: IDocuSignRecipient | undefined = recipients.signers?.find(
      (s: IDocuSignRecipient) => s.recipientId === recipientId,
    );

    if (!signer) {
      throw new BadRequestError("Signer not found in envelope");
    }

    // Create recipient view request
    const recipientViewRequest: IDocuSignRecipientViewRequest = {
      authenticationMethod: "none",
      email: signer.email,
      userName: signer.name,
      recipientId: signer.recipientId,
      returnUrl: env.DOCUSIGN_RETURN_URL,
    };

    if (signer.clientUserId) {
      recipientViewRequest.clientUserId = signer.clientUserId;
    }

    // Generate signing URL
    const view = await envelopesApi.createRecipientView(
      accountId ?? "",
      envelopeId,
      {
        recipientViewRequest,
      },
    );

    return view.url;
  } catch (error) {
    logger.error("Error creating recipient view", { error });
    throw error;
  }
};

/**
 * Downloads signed PDF from DocuSign
 */
export const getAgreementDocumentPDF = async (envelopeId: string) => {
  const tokenResponse = await getAccessToken();
  const accessToken = tokenResponse.access_token;

  const userInfo = await getUserInfo(accessToken);
  const accountId = userInfo.accounts[0]?.account_id;

  const apiClient = new docusign.ApiClient();
  apiClient.setBasePath(env.DOCUSIGN_ENVELOPE_DOMAIN);
  apiClient.addDefaultHeader("Authorization", `Bearer ${accessToken}`);

  const envelopesApi = new docusign.EnvelopesApi(apiClient);

  // Get combined PDF (all documents)
  const pdf = await envelopesApi.getDocument(
    accountId ?? "",
    envelopeId,
    "combined",
    {},
  );

  return Buffer.from(pdf);
};
```

### Step 9: Webhook Service Functions

```typescript
// src/services/webhook.service.ts

import AppDataSource from "@/database/dataSource";
import Booking from "@/database/entities/Booking.entity";
import { Document } from "@/database/entities/Document.entity";
import { DocumentStatus, DocumentType } from "@/shared/enums/document.enum";
import type { AgreementStatus } from "@/shared/enums/docusign.enum";

/**
 * Updates envelope status in booking
 */
export const updateEnvelopeStatus = async (
  envelopeId: string,
  status: AgreementStatus,
) => {
  const bookingRepo = AppDataSource.getRepository(Booking);
  const booking = await bookingRepo.findOne({
    where: { envelopeId },
  });

  if (booking) {
    booking.agreementStatus = status;
    booking.envelopeCompletedAt = new Date();
    await booking.save();
  }
};

/**
 * Creates or updates agreement document
 */
export const updateAgreementDocument = async (
  envelopeId: string,
  documentKey: string,
) => {
  const bookingRepo = AppDataSource.getRepository(Booking);
  const booking = await bookingRepo.findOne({
    where: { envelopeId },
    relations: ["user"],
  });

  if (booking?.user) {
    const documentRepo = AppDataSource.getRepository(Document);
    let document = await documentRepo.findOne({
      where: {
        user: { id: booking.user.id },
        type: DocumentType.AGREEMENT,
      },
    });

    if (!document) {
      // Create new document
      document = await documentRepo
        .create({
          user: booking.user,
          status: DocumentStatus.SIGNED,
          type: DocumentType.AGREEMENT,
          expiresAt: booking.bookedCheckedOutDate,
          documentKey,
          fileName: "agreement.pdf",
        })
        .save();
    } else {
      // Update existing document
      await documentRepo.update(
        { id: document.id },
        {
          documentKey,
          status: DocumentStatus.SIGNED,
          expiresAt: booking.bookedCheckedOutDate,
        },
      );
    }

    return document;
  }
};
```

---

## Complete Workflow

### 1. Agreement Sending Workflow

```
┌──────────────────────────────────────────────────────────────────┐
│                    Booking Created                                │
└──────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│              Add Job to Agreement Queue                            │
│         agreementQueue.addAgreementSendJob(bookingId)              │
└──────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│              Queue Processor Runs                                  │
│  1. Fetch booking with relations                                   │
│  2. Generate JWT token                                             │
│  3. Exchange JWT for access token                                  │
│  4. Fetch user info & account ID                                  │
└──────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│              PDF Generation                                       │
│  1. Get template from database                                    │
│  2. Build variables from booking                                  │
│  3. Replace #variables# in template                               │
│  4. Convert HTML to PDF with Puppeteer                            │
│  5. Convert PDF buffer to base64                                  │
└──────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│              Create DocuSign Envelope                             │
│  1. Build envelope payload with PDF                               │
│  2. Add signer (email, name, clientUserId)                        │
│  3. POST to DocuSign API                                          │
│  4. Receive envelopeId                                            │
└──────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│              Update Booking                                        │
│  - envelopeId                                                     │
│  - agreementStatus = "sent"                                       │
│  - envelopeSentAt = now                                           │
└──────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│              DocuSign Sends Email                                  │
│         User receives email to sign                               │
└──────────────────────────────────────────────────────────────────┘
```

### 2. Webhook Workflow

```
┌──────────────────────────────────────────────────────────────────┐
│              User Signs Document                                   │
└──────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│              DocuSign Sends Webhook                                │
│  - Event: "envelope-completed"                                    │
│  - Contains envelopeId                                            │
│  - HMAC signed header                                             │
└──────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│              Webhook Controller                                    │
│  1. Extract X-DocuSign-Signature-1 header                         │
│  2. Calculate HMAC SHA256                                        │
│  3. Timing-safe comparison                                       │
│  4. Validate request payload                                      │
└──────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│              Add Job to Event Queue                                │
│      docusignEventQueue.addJobInQueue(envelopeId, event)          │
└──────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│              Event Processor                                       │
│  1. Update booking status (completed)                             │
│  2. Download signed PDF from DocuSign                             │
│  3. Upload to Azure Blob Storage                                  │
│  4. Update/create document record                                │
└──────────────────────────────────────────────────────────────────┘
```

### 3. Embedded Signing Workflow

```
┌──────────────────────────────────────────────────────────────────┐
│              User Opens Signing Page                               │
└──────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│              Backend: getAgreementSigningUrl()                     │
│  1. Get access token                                              │
│  2. Get account info                                              │
│  3. List envelope recipients                                      │
│  4. Find specific signer by recipientId                           │
│  5. Create recipient view request                                 │
│  6. Generate signing URL                                          │
└──────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│              Frontend: Redirect to URL                             │
│         User signs in embedded iframe                             │
└──────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│              DocuSign Redirects Back                               │
│              to DOCUSIGN_RETURN_URL                                │
└──────────────────────────────────────────────────────────────────┘
```

---

## Security Best Practices

### 1. JWT Token Storage

```typescript
// Cache tokens to avoid regenerating
let cachedToken: { token: string; expiresAt: number } | null = null;

export const getAccessToken = async (): Promise<IDocuSignTokenResponse> => {
  // Check cache
  if (cachedToken && Date.now() < cachedToken.expiresAt) {
    return { access_token: cachedToken.token, token_type: "Bearer", expires_in: 3600, scope: "signature" };
  }

  // Generate new token
  const jwt = await generateJWT();
  const response = await axios.post(/* ... */);

  // Cache for 5 minutes (token valid for 1 hour)
  cachedToken = {
    token: response.data.access_token,
    expiresAt: Date.now() + 5 * 60 * 1000,
  };

  return response.data;
};
```

### 2. HMAC Webhook Validation

Always use timing-safe comparison:

```typescript
import crypto from "node:crypto";

const isValid = crypto.timingSafeEqual(
  Buffer.from(hmac),
  Buffer.from(signature),
);
```

**Why?** Regular string comparison (`===`) is vulnerable to timing attacks where attackers can measure response times to guess valid signatures.

### 3. Private Key Storage

```bash
# Use separate env file for secrets
# .env.secret (gitignored)
DOCUSIGN_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----\n..."

# .env (committed)
DOCUSIGN_INTEGRATION_KEY="..."
```

Load in order:

```typescript
import dotenv from "dotenv";

dotenv.config(); // Load .env
dotenv.config({ path: ".env.secret", override: true }); // Override with secrets
```

### 4. Environment-Specific Domains

```typescript
// Demo/Sandbox
DOCUSIGN_DOMAIN="https://account-d.docusign.com"
DOCUSIGN_ENVELOPE_DOMAIN="https://demo.docusign.net/restapi"

// Production
DOCUSIGN_DOMAIN="https://account.docusign.com"
DOCUSIGN_ENVELOPE_DOMAIN="https://www.docusign.net/restapi"
```

### 5. Rate Limiting

Implement rate limiting on webhook endpoint:

```typescript
import rateLimit from "express-rate-limit";

export const webhookLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Max 100 requests per window
  standardHeaders: true,
  legacyHeaders: false,
});
```

---

## Testing & Debugging

### 1. Unit Testing JWT Generation

```typescript
import { generateJWT } from "@/services/docusign.service";

describe("DocuSign JWT", () => {
  it("should generate valid JWT token", async () => {
    const jwt = await generateJWT();

    expect(jwt).toBeDefined();
    expect(typeof jwt).toBe("string");

    // Decode and verify structure
    const parts = jwt.split(".");
    expect(parts).toHaveLength(3);

    const payload = JSON.parse(Buffer.from(parts[1], "base64").toString());

    expect(payload).toHaveProperty("iss");
    expect(payload).toHaveProperty("sub");
    expect(payload).toHaveProperty("aud");
    expect(payload).toHaveProperty("iat");
    expect(payload).toHaveProperty("exp");
  });
});
```

### 2. Mocking DocuSign API

```typescript
import { jest } from "@jest/globals";

import axios from "axios";
import { sendEnvelope } from "@/services/docusign.service";

jest.mock("axios");

describe("sendEnvelope", () => {
  it("should send envelope successfully", async () => {
    const mockResponse = {
      data: {
        envelopeId: "test-envelope-id",
        uri: "/envelopes/test-envelope-id",
        statusDateTime: new Date().toISOString(),
        status: "sent",
      },
    };

    (axios.post as jest.Mock).mockResolvedValue(mockResponse);

    const result = await sendEnvelope(mockBooking, "base64pdf");

    expect(result.envelopeId).toBe("test-envelope-id");
  });
});
```

### 3. Testing Webhooks

Use DocuSign's webhook simulator or ngrok for local testing:

```bash
# Install ngrok
brew install ngrok

# Start your server
npm run dev

# In another terminal, expose local port
ngrok http 3000

# Use the ngrok URL in DocuSign Connect config
# https://abc123.ngrok.io/api/v1/webhooks/docusign
```

### 4. Debug Logging

```typescript
import logger from "@/utils/logger";

// Log each step
logger.info("Generating DocuSign JWT", {
  userId: env.DOCUSIGN_USER_ID,
  integrationKey: env.DOCUSIGN_INTEGRATION_KEY,
});

logger.info("Sending envelope", {
  bookingId: booking.id,
  userEmail: booking.user.email,
});

logger.info("Envelope sent successfully", {
  envelopeId: response.data.envelopeId,
  status: response.data.status,
});
```

---

## Common Pitfalls

### 1. Private Key Format Issues

**Problem**: Private key from env has escaped newlines

**Solution**:
```typescript
const privateKey = DOCUSIGN_PRIVATE_KEY.replace(/\\n/g, "\n");
```

### 2. Missing Impersonation Consent

**Problem**: `consent_required` error when getting access token

**Solution**: Grant consent by visiting:
```
https://account-d.docusign.com/oauth/auth?
  response_type=code&
  scope=signature+impersonation&
  client_id={INTEGRATION_KEY}&
  redirect_uri={REDIRECT_URI}
```

### 3. Webhook Signature Validation Fails

**Problem**: HMAC doesn't match

**Causes**:
- Wrong `DOCUSIGN_CONNECT_KEY`
- Request body modified by middleware (body parser)
- Using `req.body` instead of `req.rawBody`

**Solution**: Capture raw body before parsing:
```typescript
app.use(
  express.json({
    verify: (req, res, buf) => {
      req.rawBody = buf;
    },
  }),
);
```

### 4. Puppeteer Timeout

**Problem**: PDF generation hangs

**Causes**:
- Missing resources (images, fonts)
- Network requests not completing
- Sandbox issues

**Solution**:
```typescript
await page.setContent(processedHtml, {
  waitUntil: "networkidle0", // Wait for no network activity
  timeout: 30000, // 30 second timeout
});
```

### 5. Account Not Found

**Problem**: Can't find default account

**Solution**: Always check for default account:
```typescript
const defaultAccount = userInfo.accounts.find(
  (account) => account.is_default,
);

// Fallback to first account if no default
const account = defaultAccount || userInfo.accounts[0];

if (!account) {
  throw new BadRequestError("No DocuSign account found");
}
```

### 6. Template Variables Not Replaced

**Problem**: #fullName# appears in PDF

**Cause**: Variable name mismatch

**Solution**: Define supported variables:
```typescript
// src/shared/constants/template.constants.ts

export const supportedVariables = [
  "fullName",
  "userEmail",
  "buildingAddress",
  // ... etc
];

// Validate template before saving
const missing = supportedVariables.filter(
  (v) => !template.content.includes(`#${v}#`),
);
```

### 7. Queue Job Retries

**Problem**: Jobs keep failing and retrying infinitely

**Solution**: Configure queue options:
```typescript
class AgreementQueue extends BaseQueue {
  constructor() {
    super(QUEUE_NAMES.AGREEMENT_QUEUE, {
      attempts: 3, // Max 3 attempts
      backoff: {
        type: "exponential",
        delay: 5000, // Start with 5s
      },
      removeOnComplete: {
        count: 100, // Keep last 100 completed jobs
      },
      removeOnFail: {
        count: 500, // Keep last 500 failed jobs
      },
    });
  }
}
```

---

## Quick Reference

### Environment Variables Checklist

- [ ] `DOCUSIGN_INTEGRATION_KEY` - OAuth Client ID
- [ ] `DOCUSIGN_USER_ID` - API Username GUID
- [ ] `DOCUSIGN_PRIVATE_KEY` - RSA private key (with \n)
- [ ] `DOCUSIGN_DOMAIN` - OAuth server URL
- [ ] `DOCUSIGN_ENVELOPE_DOMAIN` - API base URL
- [ ] `DOCUSIGN_CONNECT_KEY` - Webhook HMAC secret
- [ ] `DOCUSIGN_RETURN_URL` - Post-signing redirect

### File Structure

```
src/
├── services/
│   └── docusign.service.ts          # Main DocuSign logic
├── queues/
│   ├── agreement.queue.ts            # Agreement sending queue
│   └── docusignEvent.queue.ts        # Webhook event queue
├── controllers/
│   └── webhook.controller.ts         # Webhook endpoint
├── shared/
│   ├── constants/
│   │   └── docusign.constants.ts     # API endpoints & constants
│   ├── types/
│   │   └── docusign.type.ts          # TypeScript interfaces
│   └── enums/
│       └── docusign.enum.ts          # Status enums
└── utils/
    └── agreementUtils.ts             # Template utilities
```

### Key Functions

| Function | Purpose |
|----------|---------|
| `generateJWT()` | Create RS256-signed JWT |
| `getAccessToken()` | Exchange JWT for OAuth token |
| `getUserInfo()` | Get account details |
| `generateAgreementPDF()` | HTML to PDF conversion |
| `sendEnvelope()` | Create DocuSign envelope |
| `getAgreementSigningUrl()` | Generate embedded signing URL |
| `getAgreementDocumentPDF()` | Download signed document |

---

## Additional Resources

- [DocuSign API Reference](https://developers.docusign.com/docs/esign-rest-api/reference/)
- [JWT Grant Authentication](https://developers.docusign.com/platform/auth)
- [Embedded Signing](https://developers.docusign.com/docs/esign-rest-api/esign101/concepts/embedding/)
- [Connect Webhooks](https://developers.docusign.com/docs/esign-rest-api/esign101/event-notifications/)
- [docusign-esign SDK](https://github.com/docusign/docusign-esign-node-client)

---

## Summary

This guide covers a production-ready DocuSign integration with:

1. **JWT Authentication** - Secure, token-based API access
2. **PDF Generation** - Dynamic HTML templates with variable replacement
3. **Envelope Management** - Creating and managing signature requests
4. **Embedded Signing** - Seamless in-app signing experience
5. **Webhook Processing** - HMAC-validated event handling
6. **Queue-Based Architecture** - Reliable, retry-capable async processing
7. **Document Storage** - Automatic Azure Blob upload of signed documents

Follow the implementation guide step-by-step to build your own integration, or use this as a reference for understanding the QCare implementation.
