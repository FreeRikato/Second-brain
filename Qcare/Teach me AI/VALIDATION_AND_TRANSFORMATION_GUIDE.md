# Validation and Transformation Guide

A comprehensive guide to writing validation and transformation in the QCare backend codebase.

---

## Table of Contents

1. [Overview](#overview)
2. [Validation with Zod](#validation-with-zod)
3. [Transformation with class-transformer](#transformation-with-class-transformer)
4. [Integration with Routes](#integration-with-routes)
5. [Common Patterns](#common-patterns)
6. [Best Practices](#best-practices)

---

## Overview

The QCare backend uses two complementary libraries for data validation and transformation:

- **Zod**: Schema validation and type inference for incoming request data
- **class-transformer**: Response transformation using decorators to format outgoing data

### The Flow

```
Request → Zod Validation → Controller → Service → Database
                                                    ↓
Response ← class-transformer ← Transformer ← Entity ←
```

---

## Validation with Zod

### File Structure

Validation schemas are located in `src/validations/`:

```
src/validations/
├── common/
│   └── field.ts           # Reusable field schemas
├── buildingValidation.ts  # Building-related schemas
├── authValidation.ts      # Auth-related schemas
└── queryValidations.ts    # Query parameter schemas
```

### Basic Field Validation

```typescript
import * as z from "zod";

// String validation
export const basicStringSchema = z.object({
  name: z.string(),
  email: z.email(),
  optional: z.string().optional(),
  nullable: z.string().nullable(),
});

// Number validation
export const numberSchema = z.object({
  age: z.number().int().positive().max(120),
  price: z.number().min(0),
});

// Boolean
export const boolSchema = z.object({
  isActive: z.boolean(),
  isDeleted: z.boolean().optional().default(false),
});
```

### Regex Patterns

Use the shared `RegEx` constants for common patterns:

```typescript
import { RegEx } from "@/shared/constants/regEx.constants";

export const idValidationSchema = z.object({
  id: z.string().regex(RegEx.INT, "ID must be a number"),
});

export const phoneNumberSchema = z.object({
  phone: z.string().regex(RegEx.INT).min(10).max(15),
});
```

### Transformations

Convert values during validation:

```typescript
// Convert number to string
export const buildingSchema = z.object({
  country: z.number().transform((val) => val.toString()),
  city: z.number().transform((val) => val.toString()),
  number: z.number().transform((val) => val.toString()),
});

// String coercion
export const paginationSchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(10),
});

// Date transformation
import dayjs from "dayjs";
import customParseFormat from "dayjs/plugin/customParseFormat";

dayjs.extend(customParseFormat);

export const dateValidationSchema = z.object({
  dob: z
    .string()
    .regex(RegEx.DATE, "Invalid date format (DD/MM/YYYY)")
    .transform((v) => dayjs(v, "DD/MM/YYYY", true).toDate()),
});
```

### Nested Objects

```typescript
export const createBuildingSchema = z.object({
  building: z.object({
    name: z.string().nonempty("Building name is required"),
    legal_name: z.string(),
    short_code: z.string(),

    // Nested object
    address: z.object({
      address_line: z.string(),
      country: z.number().transform((val) => val.toString()),
      city: z.number().transform((val) => val.toString()),
      zip_code: z.string().optional().nullable(),
    }),

    // Array of objects
    account: z.array(
      z.object({
        payment_method: z.number().transform((val) => val.toString()),
        account_number: z.string(),
      }),
    ),
  }),
});
```

### Array Validation

```typescript
// Simple array
export const arraySchema = z.object({
  tags: z.array(z.string()),
});

// Array with minimum length
export const roomTypeSchema = z.object({
  buildings: z
    .array(z.string().regex(RegEx.INT))
    .min(1, "At least one building must be selected"),
});

// Array or single value (union)
export const flexibleArraySchema = z.object({
  building: z
    .union([
      z.array(z.string().regex(RegEx.INT)),
      z.string().regex(RegEx.INT).transform((v) => [v]),
    ])
    .default([])
    .optional(),
});
```

### Enum Validation

```typescript
import { Gender, RoomStatus } from "@/shared/enums/room.enum";

export const enumSchema = z.object({
  gender: z.enum(Gender),
  status: z.enum(RoomStatus),
  category: z.enum(ResidentCategory).optional(),
});

// Discriminated unions for conditional validation
export const contactInfoSchema = z.union([
  z.object({
    action: z.literal("SEND"),
    method: z.literal("PHONE"),
    phoneCode: z.string(),
    phoneNumber: z.string(),
  }),
  z.object({
    action: z.literal("SEND"),
    method: z.literal("EMAIL"),
    email: z.email(),
  }),
  z.object({
    action: z.literal("VERIFY"),
    method: z.literal("PHONE"),
    phoneCode: z.string(),
    phoneNumber: z.string(),
    otp: z.string(),
  }),
  z.object({
    action: z.literal("VERIFY"),
    method: z.literal("EMAIL"),
    email: z.email(),
    otp: z.string(),
  }),
]);
```

### Custom Validation with Refine

```typescript
// Decimal validation helper
const decimalValidation = (fieldName: string) => {
  return z
    .union([
      z.literal(""), // Allow empty string
      z
        .string()
        .regex(/^\d{1,8}(\.\d{1,2})?$/, {
          message: `Must be a decimal with up to 8 digits before decimal and up to 2 decimal places`,
        })
        .refine((val) => parseFloat(val) > 0, {
          message: `${fieldName} must be greater than 0`,
        }),
    ])
    .transform((val) => (val === "" ? null : val))
    .nullable()
    .optional();
};

// Usage
export const pricingSchema = z.object({
  amount: decimalValidation("amount"),
  rent_amount: decimalValidation("rent_amount"),
});
```

### Complex Validations

```typescript
// Date validation
export const bookingSchema = z.object({
  booking: z.object({
    building_id: z.string().regex(/^\d+$/),
    room_type_id: z.string().regex(/^\d+$/),
    check_in_date: z
      .string()
      .refine((val) => !Number.isNaN(new Date(val).getTime())),
    check_out_date: z
      .string()
      .refine((val) => !Number.isNaN(new Date(val).getTime())),
  }),
});

// Dynamic schema based on type
export const getMetaConfigSchema = (requestBody: MetaConfigBody) => {
  const body = requestBody as Record<string, MetaConfigBody>;
  const [metaType] = Object.keys(body) as [keyof typeof metaConfigSchema];

  return z.object({
    [metaType]: metaConfigSchema[metaType],
  });
};
```

### Type Inference

Always export the inferred TypeScript type:

```typescript
export const createSingleBuildingSchema = z.object({
  building: z.object({
    name: z.string(),
  }),
});

// Inferred type for use in services/controllers
export type CreateSingleBuildingSchemaType = z.infer<
  typeof createSingleBuildingSchema
>;
```

### Reusable Field Schemas

Create reusable field schemas in `src/validations/common/field.ts`:

```typescript
import z from "zod";
import { RegEx } from "@/shared/constants/regEx.constants";

export const PhoneNumberFieldSchema = z.coerce
  .string()
  .trim()
  .regex(RegEx.INT)
  .min(6)
  .max(12);

export const PhoneCodeFieldSchema = z.coerce
  .string()
  .trim()
  .regex(RegEx.INT)
  .min(1)
  .max(3);

// Usage
import { PhoneNumberFieldSchema, PhoneCodeFieldSchema } from "@/validations/common/field";

export const residentSchema = z.object({
  phone_number: PhoneNumberFieldSchema,
  phone_code: PhoneCodeFieldSchema,
});
```

---

## Transformation with class-transformer

### File Structure

Transformers are located in `src/shared/transformers/`:

```
src/shared/transformers/
├── base.transformer.ts        # Base transformer class
├── building.transformer.ts    # Building transformers
├── resident.transformer.ts    # Resident transformers
└── pagination.transformer.ts  # Pagination transformers
```

### Base Transformer

All transformers extend the `BaseTransformer`:

```typescript
// base.transformer.ts
import { Exclude, instanceToPlain } from "class-transformer";

@Exclude({ toPlainOnly: true })
class BaseTransformer {
  toJSON() {
    return instanceToPlain(this, {
      excludeExtraneousValues: true,
      exposeUnsetFields: false,
    });
  }
}

export default BaseTransformer;
```

**Key behavior:**
- `@Exclude({ toPlainOnly: true })` - By default, excludes all fields unless exposed
- `excludeExtraneousValues: true` - Only includes defined properties
- `exposeUnsetFields: false` - Omits undefined fields

### Basic Transformer

```typescript
import { Exclude, Expose } from "class-transformer";
import BaseTransformer from "@/shared/transformers/base.transformer";

@Exclude()
export class UserTransformer extends BaseTransformer {
  @Expose()
  id: string;

  @Expose()
  name: string;

  @Expose()
  email: string;
}
```

### Naming Convention Mapping

Use `@Expose({ name: "column_name" })` to map database snake_case to API camelCase:

```typescript
@Exclude()
export class BuildingTransformer {
  @Expose()
  id: string;

  @Expose()
  name: string;

  @Expose({ name: "legal_name" })
  legalName: string;

  @Expose({ name: "short_code" })
  shortCode: string;

  @Expose({ name: "merchant_id" })
  merchantId: string;
}
```

### Nested Objects

Use `@Type(() => Class)` for nested objects:

```typescript
@Exclude()
export class Address {
  @Expose({ name: "address_line" })
  addressLine: string;

  @Expose()
  country: string;

  @Expose()
  city: string;

  @Expose({ name: "zip_code" })
  zipCode: string;
}

@Exclude()
export class Building {
  @Expose()
  id: string;

  @Expose()
  name: string;

  @Expose()
  @Type(() => Address)
  address: Address;
}
```

### Arrays

```typescript
@Exclude()
export class Account {
  @Expose({ name: "payment_method" })
  paymentMethod: string;

  @Expose({ name: "account_number" })
  accountNumber: string;
}

@Exclude()
export class Building {
  @Expose()
  id: string;

  @Expose()
  name: string;

  @Expose({ name: "account" })
  @Type(() => Account)
  accounts: Account[]; // Array transformation
}
```

### Optional and Nullable Fields

```typescript
@Exclude()
export class ResidentRefundDetailTransformer extends BaseTransformer {
  @Expose()
  bankName: string;

  @Expose({ name: "swift_code" })
  swiftCode: string;

  @Expose({ name: "bank_code" })
  bankCode: string | null;  // Nullable field

  @Expose({ name: "credit_currency" })
  creditCurrency: CreditCurrency | null;

  @Expose()
  @Type(() => Country)
  country: Country | null;  // Nullable nested object
}
```

### Custom Transformations

Use `@Transform` for custom field transformations:

```typescript
import { Expose, Transform } from "class-transformer";

@Exclude()
export class UserDetail extends BaseTransformer {
  @Expose()
  id: string;

  @Expose()
  name?: string;

  @Expose({ name: "phone_number" })
  phoneNumber: string | null;

  // Custom transformation from nested object
  @Transform(
    ({ obj }: { obj: { role?: { name?: string } } }) => obj.role?.name ?? "",
    {
      toClassOnly: true,
    },
  )
  @Expose()
  role!: string;
}
```

### Request Transformers

For request bodies (input transformation):

```typescript
export class CreateSingleBuildingRequest extends BaseTransformer {
  @Expose()
  @Type(() => Building)
  building: Building;
}
```

### Response Transformers

For API responses:

```typescript
@Exclude()
export class ResidentTransformer extends BaseTransformer {
  @Expose()
  id: string;

  @Expose()
  name: string;

  @Expose({ name: "room_number" })
  roomNumber: string;

  @Expose({ name: "room_type" })
  roomType: string;

  @Expose({ name: "booked_date" })
  bookedDate: string;
}

export class GetResidentsResponse extends BaseTransformer {
  @Expose()
  @Type(() => ResidentTransformer)
  residents: ResidentTransformer[];

  @Expose({ name: "pagination_meta" })
  @Type(() => PaginationMetaWithTotalScope)
  paginationMeta: PaginationMetaWithTotalScope;
}
```

### Pagination Transformers

```typescript
// pagination.transformer.ts
export class PaginationMeta {
  @Expose({ name: "total" })
  totalDoc: number;

  @Expose({ name: "limit" })
  limit: number;

  @Expose({ name: "total_page" })
  totalPage: number;

  @Expose({ name: "current_page" })
  currPage: number;

  @Expose({ name: "next_page" })
  nextPage: number | null;

  @Expose({ name: "previous_page" })
  prevPage: number | null;

  @Expose({ name: "has_next_page" })
  hasNextPage: boolean;

  @Expose({ name: "has_previous_page" })
  hasPrevPage: boolean;
}

export class PaginationMetaWithTotalScope extends PaginationMeta {
  @Expose({ name: "total_scope" })
  totalScope?: number;
}
```

---

## Integration with Routes

### Validation Middleware

**For request bodies:**

```typescript
import { validateReqBody } from "@/middlewares/validateRequestBody.middleware";
import { createSingleBuildingSchema } from "@/validations/buildingValidation";

router.post(
  APIRoute.EMPTY,
  validateToken(),
  setAccessPermission([Role.SUPER_ADMIN]),
  validateReqBody(createSingleBuildingSchema),  // Validation
  createBuilding,
);
```

**For query parameters:**

```typescript
import { validateQueryParams } from "@/middlewares/validateQueryParams.middleware";
import { paginationAndSearchSchema } from "@/validations/queryValidations";

router.get(
  APIRoute.EMPTY,
  validateToken(),
  validateQueryParams(paginationAndSearchSchema),  // Query validation
  getAllBuildings,
);
```

**For route parameters:**

```typescript
import { validateIdParams } from "@/middlewares/validateIdParams.middleware";

router.get(
  APIRoute.SPECIFIC_RECORD,
  validateToken(),
  validateIdParams("id"),  // ID parameter validation
  getBuilding,
);
```

### Using Transformers in Controllers

```typescript
import { instanceToPlain, plainToInstance } from "class-transformer";
import { CreateSingleBuildingRequest, GetBuildingsRequest } from "@/shared/transformers/building.transformer";

// Input transformation (request → service)
export const createBuilding: RequestHandler = async (req, res) => {
  const building = plainToInstance(CreateSingleBuildingRequest, req.body);
  await addNewBuilding(building);
  return res.status(201).json({ message: "Building created successfully" });
};

// Output transformation (entity → response)
export const getAllBuildings = async (req, res) => {
  const { data, meta } = await getAllBuildingsWithPagination(/* ... */);

  // Transform array of entities
  const transformedData = data.map((item) =>
    instanceToPlain(Object.assign(new GetBuildingsRequest(), item)),
  );

  // Transform pagination meta
  const transformedPaginationMeta = instanceToPlain(
    Object.assign(new PaginationMetaWithTotalScope(), meta),
  );

  return res.json({
    buildings: transformedData,
    pagination_meta: transformedPaginationMeta,
  });
};

// Single entity transformation
export const getBuilding = async (req, res) => {
  const id = req.params.id;
  const data = await getBuildingById(id);

  return res.json(
    instanceToPlain(Object.assign(new CreateSingleBuildingRequest(), data)),
  );
};
```

---

## Common Patterns

### Pattern 1: Create/Update Request

**Validation:**
```typescript
export const updateResidentSchema = z.object({
  resident: z.object({
    name: z.string().trim().min(1),
    dob: z.string().regex(RegEx.DATE),
    phone_number: PhoneNumberFieldSchema,
    address: z.object({
      address_line: z.string().trim().min(1),
      city: z.object({ id: z.string().trim().regex(RegEx.INT) }),
      country: z.object({ id: z.string().trim().regex(RegEx.INT) }),
    }),
  }),
});
```

**Transformer:**
```typescript
export class UpdateResidentRequest extends BaseTransformer {
  @Expose()
  @Type(() => ResidentDetail)
  resident: ResidentDetail;
}
```

### Pattern 2: List with Pagination

**Validation:**
```typescript
export const paginationAndSearchSchema = z.object({
  page: z.string().regex(RegEx.INT).default("1"),
  limit: z.string().regex(RegEx.INT).default("10"),
  search: z.string().optional().default(""),
  status: z.array(z.enum(BookingStatus)).optional(),
  sort_by: z.enum(ResidentListingSortKey).optional(),
  sort_value: z.enum(PaginationDirection).optional(),
});
```

**Transformer:**
```typescript
export class GetResidentsResponse extends BaseTransformer {
  @Expose()
  @Type(() => ResidentTransformer)
  residents: ResidentTransformer[];

  @Expose({ name: "pagination_meta" })
  @Type(() => PaginationMeta)
  paginationMeta: PaginationMeta;
}
```

### Pattern 3: ID Parameter Validation

```typescript
export const idParamSchema = z.object({
  id: z
    .string()
    .regex(RegEx.INT, {
      message: validationError.keyMustBeValidNumber("id"),
    })
    .nonempty({ message: validationError.invalidID("id") }),
});

export type IdParamValidationType = z.infer<typeof idParamSchema>;
```

---

## Best Practices

### Validation

1. **Always validate at the boundary** - Use `validateReqBody`/`validateQueryParams` in routes
2. **Export inferred types** - Use `z.infer<>` for TypeScript types
3. **Use shared regex patterns** - Import from `@/shared/constants/regEx.constants`
4. **Use meaningful error messages** - Provide clear validation messages
5. **Transform early** - Use `.transform()` to convert types during validation
6. **Make optional fields explicit** - Use `.optional()` for nullable/optional fields
7. **Validate dates properly** - Use regex or dayjs for date validation

### Transformation

1. **Always extend BaseTransformer** - Ensures consistent behavior
2. **Use @Exclude() at class level** - Default to excluding, then expose what you need
3. **Map snake_case to camelCase** - Use `@Expose({ name: "column_name" })`
4. **Use @Type() for nested objects** - Required for proper transformation
5. **Keep transformers simple** - Don't add business logic to transformers
6. **Separate request/response transformers** - Different purposes, different classes

### General

1. **One file per domain** - `buildingValidation.ts` and `building.transformer.ts`
2. **Reuse field schemas** - Create common validators in `src/validations/common/`
3. **Match validation to transformer** - Fields should have corresponding transformers
4. **Test your schemas** - Write tests for complex validation logic
5. **Document complex validations** - Add comments for non-obvious validation logic

---

## Quick Reference

### Common Zod Methods

| Method | Purpose |
|--------|---------|
| `.string()` | String type |
| `.number()` | Number type |
| `.boolean()` | Boolean type |
| `.email()` | Email validation |
| `.min(n)` | Minimum length/value |
| `.max(n)` | Maximum length/value |
| `.optional()` | Optional field |
| `.nullable()` | Nullable field |
| `.default(val)` | Default value |
| `.transform(fn)` | Transform value |
| `.refine(fn)` | Custom validation |
| `.regex(pattern)` | Regex match |
| `.enum(arr)` | Enum values |
| `.union([schemas])` | Union of schemas |
| `.array(schema)` | Array of schema |
| `.object(shape)` | Object schema |

### Common class-transformer Decorators

| Decorator | Purpose |
|-----------|---------|
| `@Exclude()` | Exclude from serialization |
| `@Expose()` | Include in serialization |
| `@Expose({ name: "field" })` | Rename field |
| `@Type(() => Class)` | Nested class type |
| `@Transform(fn)` | Custom transformation |

---

## Summary

- **Validation (Zod)**: Validates and transforms **incoming** request data
- **Transformation (class-transformer)**: Formats **outgoing** response data
- Use `validateReqBody`/`validateQueryParams` middleware in routes
- Use `plainToInstance` for input, `instanceToPlain` for output
- Always extend `BaseTransformer` and use `@Exclude()` + `@Expose()`
- Export inferred types from Zod schemas for TypeScript support
