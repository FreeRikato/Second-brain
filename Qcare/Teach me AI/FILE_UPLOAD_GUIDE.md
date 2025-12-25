# File Upload Guide - QCare API

This guide explains how file uploads are implemented in the QCare API codebase. After reading this, you should be able to implement file uploads independently.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture & Libraries](#architecture--libraries)
3. [Configuration](#configuration)
4. [Upload Patterns](#upload-patterns)
5. [Step-by-Step Implementation](#step-by-step-implementation)
6. [Best Practices](#best-practices)
7. [Common Pitfalls](#common-pitfalls)

---

## Overview

The QCare API supports **two main file upload patterns**:

| Pattern | Use Case | Flow |
|---------|----------|------|
| **Direct Upload** | Images, avatars, small files | Client → Server → Azure Blob Storage |
| **Pre-signed URL Upload** | Documents, large files | Client requests URL → Client uploads directly to Azure → Client sends metadata |

### Key Components

- **Storage**: Azure Blob Storage
- **Middleware**: Multer (for direct uploads)
- **Validation**: Zod schemas
- **Authentication**: SAS tokens with expiration

---

## Architecture & Libraries

### Core Dependencies

```json
{
  "multer": "2.0.2",                           // Multipart form-data handling
  "@azure/storage-blob": "12.28.0",            // Azure SDK
  "csv-parser": "3.2.0"                        // CSV file handling
}
```

### File Structure

```
src/
├── configs/
│   └── storage.ts                    # Azure configuration
├── middlewares/
│   └── imageUpload.middleware.ts     # Multer middleware
├── services/
│   ├── image.service.ts              # Azure operations
│   └── document.service.ts           # Document business logic
├── utils/
│   └── storage.ts                    # Pre-signed URL generation
└── validations/
    └── documentValidation.ts         # Zod schemas
```

---

## Configuration

### Environment Variables

Required in `.env` or `.env.test`:

```bash
OBJECT_STORAGE_ACCOUNT_NAME=<azure-account-name>
OBJECT_STORAGE_ACCOUNT_KEY=<azure-account-key>
CONTAINER_NAME=<container-name>
STORAGE_CONNECTION_STRING=<connection-string>
```

### Storage Configuration (`src/configs/storage.ts`)

```typescript
import {
  BlobServiceClient,
  StorageSharedKeyCredential,
} from "@azure/storage-blob";
import env from "@/configs/environment";

export const sharedKeyCredential = new StorageSharedKeyCredential(
  env.OBJECT_STORAGE_ACCOUNT_NAME,
  env.OBJECT_STORAGE_ACCOUNT_KEY,
);

export const blobServiceClient = new BlobServiceClient(
  `https://${OBJECT_STORAGE_ACCOUNT_NAME}.blob.core.windows.net`,
  sharedKeyCredential,
);

export const blobContainerClient =
  blobServiceClient.getContainerClient(CONTAINER_NAME);
```

---

## Upload Patterns

### Pattern 1: Direct Upload (Images)

**Use for**: Building images, profile avatars, small files (< 10MB)

**Flow**:
```
Client POST with file
    ↓
Multer middleware (stores in memory)
    ↓
Controller receives buffer
    ↓
Service uploads to Azure
    ↓
Returns file key
```

**Example Route** (`src/routes/v1/image.routes.ts`):

```typescript
router.post(
  APIRoute.BUILDING,
  validateToken(),
  setAccessPermission([Role.SUPER_ADMIN]),
  upload.single("file"),          // Multer middleware
  uploadBuildingImage,            // Controller
);
```

### Pattern 2: Pre-signed URL Upload (Documents)

**Use for**: Documents, large files, when you want to save server bandwidth

**Flow**:
```
Client POST with filename
    ↓
Server generates pre-signed URL (10 min expiry)
    ↓
Client PUT directly to Azure
    ↓
Client POST with metadata (file key, type, etc.)
    ↓
Server stores metadata in database
```

---

## Step-by-Step Implementation

### Scenario 1: Implementing Direct Image Upload

#### Step 1: Create Upload Middleware (or reuse existing)

`src/middlewares/imageUpload.middleware.ts`:

```typescript
import type { Request } from "express";
import type { FileFilterCallback } from "multer";
import multer from "multer";
import { ApiError } from "@/utils/apiErrors";

const MAX_SIZE = 10 * 1024 * 1024; // 10MB
const allowedMimeTypes = ["image/jpeg", "image/png", "image/webp", "image/gif"];

const fileFilter = (
  _req: Request,
  file: Express.Multer.File,
  cb: FileFilterCallback,
): void => {
  if (allowedMimeTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new ApiError("Unsupported file format"));
  }
};

export const upload = multer({
  storage: multer.memoryStorage(),  // Store in memory, not disk
  limits: { fileSize: MAX_SIZE },
  fileFilter,
});
```

#### Step 2: Create Service Function

`src/services/image.service.ts`:

```typescript
import { randomUUID } from "node:crypto";
import { BlobServiceClient } from "@azure/storage-blob";
import {
  BlobSASPermissions,
  generateBlobSASQueryParameters,
  StorageSharedKeyCredential,
} from "@azure/storage-blob";
import env from "@/configs/environment";

// Upload file buffer to Azure
export const uploadToAzureBlob = async (
  buffer: Buffer,
  mimetype: string,
  fileName?: string,
): Promise<string> => {
  const blobServiceClient = BlobServiceClient.fromConnectionString(
    env.STORAGE_CONNECTION_STRING,
  );
  const containerClient = blobServiceClient.getContainerClient(env.CONTAINER_NAME);

  // Generate unique filename or use provided
  const blobName = fileName ?? `category/${randomUUID()}-file`;

  const blockBlobClient = containerClient.getBlockBlobClient(blobName);
  await blockBlobClient.uploadData(buffer, {
    blobHTTPHeaders: {
      blobContentType: mimetype,  // Set proper MIME type
    },
  });

  return blobName;  // Return the storage key
};

// Generate signed URL for reading (1 hour expiry)
export const getSignedBlobUrl = (blobName: string | null) => {
  if (!blobName) return "";

  const sharedKeyCredential = new StorageSharedKeyCredential(
    env.OBJECT_STORAGE_ACCOUNT_NAME,
    env.OBJECT_STORAGE_ACCOUNT_KEY,
  );

  const containerClient = blobServiceClient.getContainerClient(env.CONTAINER_NAME);
  const blobClient = containerClient.getBlobClient(blobName);

  const expiresOn = new Date(Date.now() + 60 * 60 * 1000); // 1 hour
  const sasToken = generateBlobSASQueryParameters(
    {
      containerName: env.CONTAINER_NAME,
      blobName,
      permissions: BlobSASPermissions.parse("r"),  // Read-only
      startsOn: new Date(),
      expiresOn,
      protocol: SASProtocol.Https,
    },
    sharedKeyCredential,
  ).toString();

  return `${blobClient.url}?${sasToken}`;
};

// Delete file from Azure
export const deleteFromAzureBlob = async (blobName: string): Promise<void> => {
  const blobServiceClient = BlobServiceClient.fromConnectionString(
    env.STORAGE_CONNECTION_STRING,
  );
  const containerClient = blobServiceClient.getContainerClient(env.CONTAINER_NAME);
  const blobClient = containerClient.getBlobClient(blobName);
  await blobClient.deleteIfExists();
};
```

#### Step 3: Create Controller

`src/controllers/category/image.controller.ts`:

```typescript
import type { RequestHandler } from "express";
import { uploadToAzureBlob } from "@/services/image.service";
import { BadRequestError } from "@/utils/apiErrors";

export const uploadCategoryImage: RequestHandler = async (req, res) => {
  if (!req.file) {
    throw new BadRequestError("No file uploaded");
  }

  const { buffer, mimetype } = req.file;

  // Upload to Azure
  const fileKey = await uploadToAzureBlob(buffer, mimetype, `category/${Date.now()}`);

  return res.json({
    message: "Image uploaded successfully",
    data: { key: fileKey },
  });
};
```

#### Step 4: Create Route

`src/routes/v1/category.routes.ts`:

```typescript
import { Router } from "express";
import { uploadCategoryImage } from "@/controllers/category/image.controller";
import { upload } from "@/middlewares/imageUpload.middleware";
import { setAccessPermission } from "@/middlewares/setAccessPermission.middleware";
import validateToken from "@/middlewares/validateToken.middleware";
import { Role } from "@/shared/enums/role.enum";

const router = Router();

router.post(
  "/:id/image",
  validateToken(),
  setAccessPermission([Role.SUPER_ADMIN]),
  upload.single("file"),        // Must match form field name
  uploadCategoryImage,
);

export default router;
```

#### Step 5: Update Entity (if storing reference)

```typescript
@Entity("category")
export class Category extends BaseSerialEntity {
  // ... other fields

  @Column({ name: "image_key", nullable: true })
  imageKey: string | null;
}
```

#### Step 6: Frontend Usage

```javascript
const formData = new FormData();
formData.append("file", imageFile);  // Must match upload.single("file")

const response = await fetch("/api/v1/category/123/image", {
  method: "POST",
  headers: {
    "Authorization": `Bearer ${token}`,
  },
  body: formData,
});

const { data } = await response.json();
// Save data.key to your entity
```

---

### Scenario 2: Implementing Pre-signed URL Upload (Documents)

#### Step 1: Create URL Generation Utility

`src/utils/storage.ts`:

```typescript
import {
  BlobSASPermissions,
  generateBlobSASQueryParameters,
} from "@azure/storage-blob";
import { randomUUID } from "crypto";
import dayjs from "dayjs";
import env from "@/configs/environment";
import { blobContainerClient, sharedKeyCredential } from "@/configs/storage";

// Slugify filename for safe storage
const generateFileStorageKey = (fileName: string) => {
  const slug = fileName
    .normalize("NFKD")           // Split accents from letters
    .replace(/[\u0300-\u036f]/g, "")  // Remove combining diacritics
    .toLowerCase()
    .replace(/\s+/g, "-")        // Spaces → hyphens
    .replace(/[^a-z0-9-]/g, "")  // Drop invalid chars
    .replace(/-+/g, "-")         // Collapse multiple hyphens
    .replace(/^-|-$/g, "");      // Trim leading/trailing hyphens

  return `${randomUUID()}-${slug}`;
};

// Generate pre-signed URL for upload (10 min expiry, Create+Write permissions)
export const generatePutObjectUrl = (fileName: string) => {
  const key = generateFileStorageKey(fileName);
  const permissions = BlobSASPermissions.parse("cw");  // Create + Write
  const expiresOn = dayjs().add(10, "minutes").toDate();
  const blockBlobClient = blobContainerClient.getBlockBlobClient(key);

  const sasToken = generateBlobSASQueryParameters(
    {
      containerName: env.CONTAINER_NAME,
      blobName: key,
      permissions,
      expiresOn,
    },
    sharedKeyCredential,
  ).toString();

  const url = `${blockBlobClient.url}?${sasToken}`;

  return { url, key } as const;
};
```

#### Step 2: Create Validation Schema

`src/validations/documentValidation.ts`:

```typescript
import { z } from "zod";
import { DocumentType, DocumentSubType } from "@/shared/enums/document.enum";

const commonDocumentFields = {
  file_name: z.string().min(1, "File name is required"),
  document_id: z.string().min(1, "Document ID is required"),
  document_key: z.string().min(1, "Document key is required"),
  valid_till: z.string().refine(
    (date) => dayjs(date, "DD/MM/YYYY", true).isValid(),
    { message: "Invalid date format. Expected DD/MM/YYYY" }
  ),
};

export const uploadDocumentRequestSchema = z.object({
  document: z.discriminatedUnion("type", [
    z.object({
      ...commonDocumentFields,
      type: z.literal(DocumentType.IDENTITY_PROOF),
      sub_type: z.enum([
        DocumentSubType.NATIONAL_ID,
        DocumentSubType.PASSPORT,
      ]),
    }),
    z.object({
      ...commonDocumentFields,
      type: z.literal(DocumentType.STUDENT_PROOF),
      sub_type: z.enum([
        DocumentSubType.STUDENT_ID,
        DocumentSubType.ADMISSION_LETTER,
      ]),
    }),
  ]),
});
```

#### Step 3: Create Controller for Pre-signed URL

`src/controllers/shared/document.controller.ts`:

```typescript
import type { RequestHandler } from "express";
import { validateData } from "@/utils/dataValidation";
import { generatePutObjectUrl } from "@/utils/storage";
import { serialize } from "@/utils/transformer";
import { DocumentUploadPayloadSchema } from "@/validations/documentValidation";

export const getPreSignedUploadUrl: RequestHandler = async (req, res) => {
  // Validate request body
  const [{ document: { fileName } }] = await validateData(
    req.body,
    DocumentUploadPayloadSchema,
    DocumentUploadRequestBodyTransformer,
  );

  // Generate pre-signed URL
  const { url, key } = generatePutObjectUrl(fileName);

  res.json(
    serialize(
      { document: { fileName, url, key } },
      DocumentUploadResponseBodyTransformer,
    ),
  );
};
```

#### Step 4: Create Route for URL Generation

`src/routes/v1/document.routes.ts`:

```typescript
router.post(
  "/upload-url",
  validateToken(),
  setAccessPermission([Role.RESIDENT]),
  validateReqBody(DocumentUploadPayloadSchema),
  getPreSignedUploadUrl,
);
```

#### Step 5: Create Controller for Metadata Submission

`src/controllers/document.controller.ts`:

```typescript
export const uploadResidentDocument = async (
  req: CustomRequest<{}, { residentId: string }, UploadDocumentRequest>,
  res: Response,
) => {
  const residentId = req.user.id;
  const documentData = plainToInstance(UploadDocumentRequest, req.body);

  // Store metadata in database (file already uploaded to Azure)
  await uploadDocumentData(residentId, documentData.document);

  return res.json({
    message: "Document uploaded successfully",
  });
};
```

#### Step 6: Frontend Usage (Pre-signed URL Flow)

```javascript
// Step 1: Request pre-signed URL
const { data } = await fetch("/api/v1/document/upload-url", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    "Authorization": `Bearer ${token}`,
  },
  body: JSON.stringify({
    document: { file_name: "passport.jpg" }
  },
}).then(r => r.json());

const { url, key } = data.document;

// Step 2: Upload directly to Azure
await fetch(url, {
  method: "PUT",
  body: file,  // Raw file, not FormData
  headers: {
    "x-ms-blob-type": "BlockBlob",
  },
});

// Step 3: Submit metadata to server
await fetch("/api/v1/resident/document", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    "Authorization": `Bearer ${token}`,
  },
  body: JSON.stringify({
    document: {
      file_name: "passport.jpg",
      document_key: key,        // The key from step 1
      document_id: "P123456",
      type: "IDENTITY_PROOF",
      sub_type: "PASSPORT",
      valid_till: "15/12/2026",
    },
  }),
});
```

---

## Best Practices

### 1. File Naming Convention

```typescript
// Good: Descriptive with UUID
`category/${randomUUID()}-${slugifiedName}`
`user/${userId}/profile-${randomUUID()}`

// Bad: Non-unique or predictable names
`image.jpg`
`upload-${Date.now()}`  // Predictable
```

### 2. Storage Key Organization

```typescript
// Organize by entity type
`building/${buildingId}/image-${uuid}`
`document/${userId}/${docType}-${uuid}`
`profile/${userId}/avatar-${uuid}`
```

### 3. Security

- **Always** set expiration on SAS tokens (10 min for upload, 1 hour for read)
- **Never** expose storage account keys to clients
- **Always** validate file types on server-side (not just client-side)
- **Use** HTTPS-only SAS tokens (`protocol: SASProtocol.Https`)

### 4. Error Handling

```typescript
export const uploadToAzureBlob = async (
  buffer: Buffer,
  mimetype: string,
): Promise<string> => {
  try {
    // ... upload logic
    return blobName;
  } catch (error) {
    throw new BadRequestError("Failed to upload file to storage");
  }
};
```

### 5. Transaction Safety

When updating entities with file references:

```typescript
return AppDataSource.transaction(async (tx) => {
  // Upload file first
  const fileKey = await uploadToAzureBlob(buffer, mimetype);

  // Update entity
  const updated = await saveOne({
    entity: Category,
    data: { imageKey: fileKey },
    transactionalEntityManager: tx,
  });

  return updated;
});
```

### 6. Cleanup on Failure

```typescript
try {
  const fileKey = await uploadToAzureBlob(buffer, mimetype);
  await updateEntityWithImage(entityId, fileKey);
} catch (error) {
  // Cleanup uploaded file if database update fails
  if (fileKey) {
    await deleteFromAzureBlob(fileKey);
  }
  throw error;
}
```

---

## Common Pitfalls

### 1. Forgetting `upload.single()` Middleware

```typescript
// ❌ Wrong - No middleware
router.post("/image", uploadImage);

// ✅ Correct - With middleware
router.post("/image", upload.single("file"), uploadImage);
```

### 2. Mismatched Field Names

```typescript
// Middleware expects "file"
upload.single("file")

// But frontend sends "image"
formData.append("image", file);  // ❌ Won't work

// ✅ Match the names
formData.append("file", file);
```

### 3. Not Checking `req.file`

```typescript
// ❌ Wrong - Will crash if no file
const { buffer } = req.file;

// ✅ Correct - Always check
if (!req.file) {
  throw new BadRequestError("No file uploaded");
}
```

### 4. Using Disk Storage Instead of Memory

```typescript
// ❌ Wrong - Stores to disk
export const upload = multer({
  dest: "uploads/",  // Don't do this
});

// ✅ Correct - Store in memory for Azure upload
export const upload = multer({
  storage: multer.memoryStorage(),
});
```

### 5. Forgetting MIME Type

```typescript
// ❌ Wrong - Azure won't know file type
await blockBlobClient.uploadData(buffer);

// ✅ Correct - Set content type
await blockBlobClient.uploadData(buffer, {
  blobHTTPHeaders: {
    blobContentType: mimetype,
  },
});
```

### 6. Expiring SAS Tokens Too Soon/Late

```typescript
// ❌ Too short - Client upload might fail
expiresOn: dayjs().add(1, "minute").toDate()

// ❌ Too long - Security risk
expiresOn: dayjs().add(24, "hours").toDate()

// ✅ Just right - 10 minutes for uploads
expiresOn: dayjs().add(10, "minutes").toDate()
```

---

## Quick Reference

### File Upload Middleware

| Middleware | Purpose | Location |
|------------|---------|----------|
| `upload.single("field")` | Single file | `src/middlewares/imageUpload.middleware.ts` |
| `upload.array("field", 5)` | Multiple files | Not used in codebase |

### Azure Operations

| Function | Purpose | Expiry |
|----------|---------|--------|
| `uploadToAzureBlob()` | Upload buffer | N/A |
| `getSignedBlobUrl()` | Read URL | 1 hour |
| `deleteFromAzureBlob()` | Delete file | N/A |
| `generatePutObjectUrl()` | Upload URL | 10 minutes |

### Common File Size Limits

```typescript
MAX_IMAGE_SIZE = 10 * 1024 * 1024;  // 10MB (images)
MAX_DOCUMENT_SIZE = 5 * 1024 * 1024;  // 5MB (documents, if needed)
```

### Supported Image Types

```typescript
["image/jpeg", "image/png", "image/webp", "image/gif"]
```

---

## Testing File Uploads

### Integration Test Example

```typescript
import { buildResponse } from "@/utils/helpers";
import request from "supertest";
import { app } from "@/app";

describe("Image Upload", () => {
  it("should upload image successfully", async () => {
    const imageBuffer = Buffer.from("fake-image-content");

    const response = await request(app)
      .post("/api/v1/image/1")
      .set("Cookie", [`token=${token}`])
      .attach("file", imageBuffer, "test.jpg")
      .expect(200);

    expect(response.body.data.key).toBeDefined();
  });

  it("should reject unsupported file types", async () => {
    const pdfBuffer = Buffer.from("%PDF-fake");

    const response = await request(app)
      .post("/api/v1/image/1")
      .set("Cookie", [`token=${token}`])
      .attach("file", pdfBuffer, "test.pdf")
      .expect(400);

    expect(response.body.message).toContain("Unsupported file format");
  });
});
```

---

## Summary

1. **Use Direct Upload** for small files (< 10MB) like images
2. **Use Pre-signed URLs** for large files or documents
3. **Always validate** file type and size on server-side
4. **Store in memory** (not disk) when using Azure
5. **Set proper expiry** on SAS tokens
6. **Organize storage keys** by entity type
7. **Handle errors** and cleanup failed uploads

---

## Related Files

| File | Purpose |
|------|---------|
| `src/configs/storage.ts` | Azure client setup |
| `src/middlewares/imageUpload.middleware.ts` | Multer configuration |
| `src/services/image.service.ts` | Azure operations |
| `src/utils/storage.ts` | Pre-signed URL generation |
| `src/services/document.service.ts` | Document business logic |
| `src/validations/documentValidation.ts` | Zod schemas |

---

**Last Updated**: 2025-12-25
