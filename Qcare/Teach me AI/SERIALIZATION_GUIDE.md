# Serialization and Deserialization Guide

This guide explains how data serialization (Entity/Transformers → JSON) and deserialization (JSON → Entities/Transformers) works in the QCare API codebase.

---

## Table of Contents

1. [Core Concepts](#core-concepts)
2. [Serialization: Converting Objects to JSON](#serialization-converting-objects-to-json)
3. [Deserialization: Converting JSON to Objects](#deserialization-converting-json-to-objects)
4. [Transformers](#transformers)
5. [Entities](#entities)
6. [Working with Nested Objects](#working-with-nested-objects)
7. [Complete Workflow Example](#complete-workflow-example)
8. [Common Patterns and Best Practices](#common-patterns-and-best-practices)
9. [Quick Reference](#quick-reference)

---

## Core Concepts

The codebase uses **class-transformer** library for serialization/deserialization. The two main operations are:

| Operation | Function | Direction | Use Case |
|-----------|----------|-----------|----------|
| **Serialization** | `instanceToPlain()` | Object → JSON | Sending data to clients (API responses) |
| **Deserialization** | `plainToInstance()` | JSON → Object | Receiving data from clients (API requests) |

### Key Decorators

| Decorator | Purpose | Example |
|-----------|---------|---------|
| `@Exclude()` | Hides property from JSON output | `@Exclude()` password: string; |
| `@Expose()` | Explicitly includes property | `@Expose({ name: "user_id" })` userId: string; |
| `@Type(() => Class)` | Specifies nested type | `@Type(() => Address)` address: Address; |

---

## Serialization: Converting Objects to JSON

Serialization converts class instances into plain JSON objects for API responses.

### The `instanceToPlain()` Function

```typescript
import { instanceToPlain } from "class-transformer";

// Basic usage
const plainObject = instanceToPlain(entityInstance);

// With options
const plainObject = instanceToPlain(entityInstance, {
  excludeExtraneousValues: true,  // Remove undefined/unset fields
  exposeUnsetFields: false,        // Don't show fields that weren't set
});
```

### Serialization Options Used in This Codebase

| Option | What It Does | When to Use |
|--------|--------------|-------------|
| `excludeExtraneousValues: true` | Removes properties not marked with `@Expose()` | For clean API responses |
| `exposeUnsetFields: false` | Excludes undefined/null properties | To avoid sending empty values |

### Example: Basic Serialization

```typescript
import { Expose, instanceToPlain } from "class-transformer";

class UserResponse {
  @Expose()
  id: string;

  @Expose()
  name: string;

  @Expose({ name: "email_address" })
  emailAddress: string;

  @Expose()
  password: string;  // This will be included - not what we want!
}

// Better approach with @Exclude
@Exclude({ toPlainOnly: true })  // Default: exclude everything
class UserResponse {
  @Expose()  // Only expose what's explicitly marked
  id: string;

  @Expose()
  name: string;

  @Expose({ name: "email_address" })
  emailAddress: string;

  password: string;  // Automatically excluded
}

// Usage
const user = new UserResponse();
user.id = "123";
user.name = "John Doe";
user.emailAddress = "john@example.com";
user.password = "secret123";

const json = instanceToPlain(user);
// Result: { id: "123", name: "John Doe", email_address: "john@example.com" }
```

---

## Deserialization: Converting JSON to Objects

Deserialization converts incoming JSON data into typed class instances.

### The `plainToInstance()` Function

```typescript
import { plainToInstance } from "class-transformer";

// Basic usage
const instance = plainToInstance(MyClass, jsonData);

// With options (used in codebase utility)
const instance = plainToInstance(MyClass, jsonData, {
  excludeExtraneousValues: false,      // Keep extra fields
  enableImplicitConversion: true,       // Auto-convert types
});
```

### Example: Deserializing Request Data

```typescript
// Incoming JSON from client
const requestBody = {
  user_id: "123",
  full_name: "John Doe",
  contact: {
    email: "john@example.com",
    phone: "123-456-7890"
  }
};

// Transform to class instance
const userInstance = plainToInstance(CreateUserRequest, requestBody);
// userInstance.userId = "123"
// userInstance.fullName = "John Doe"
```

---

## Transformers

Transformers define the API contract for request/response data. They live in `src/shared/transformers/`.

### Base Transformer Pattern

All transformers extend `BaseTransformer` which provides a `toJSON()` method:

```typescript
import { Exclude, instanceToPlain } from "class-transformer";

@Exclude({ toPlainOnly: true })  // Exclude by default
class BaseTransformer {
  toJSON() {
    return instanceToPlain(this, {
      excludeExtraneousValues: true,
      exposeUnsetFields: false,
    });
  }
}
```

### Creating a Response Transformer

```typescript
// src/shared/transformers/room.transformer.ts
import { Exclude, Expose, Type } from "class-transformer";
import BaseTransformer from "@/shared/transformers/base.transformer";
import { Gender } from "@/shared/enums/room.enum";

@Exclude()  // Default: hide everything
export default class RoomTransformer extends BaseTransformer {
  @Expose()
  id: string;

  @Expose()
  number: number;

  @Expose({ name: "meter_number" })
  meterNumber: number;

  @Expose()
  gender: Gender;

  @Expose({ name: "bed_count" })
  bedCount: number;

  // Nested object
  @Expose()
  @Type(() => Metadata)
  type: Metadata;
}
```

### Creating a Request Transformer

```typescript
// src/shared/transformers/building.transformer.ts
import { Exclude, Expose, Type } from "class-transformer";
import BaseTransformer from "@/shared/transformers/base.transformer";

@Exclude()
export class Address {
  @Expose({ name: "address_line" })
  addressLine: string;

  @Expose()
  country: string;

  @Expose()
  city: string;
}

@Exclude()
export class Building {
  @Expose()
  id: string;

  @Expose()
  name: string;

  @Expose({ name: "legal_name" })
  legalName: string;

  @Expose()
  @Type(() => Address)
  address: Address;
}

@Exclude()
export class CreateSingleBuildingRequest extends BaseTransformer {
  @Expose()
  @Type(() => Building)
  building: Building;
}
```

### Using Transformers in Controllers

```typescript
import { instanceToPlain, plainToInstance } from "class-transformer";
import { CreateSingleBuildingRequest } from "@/shared/transformers/building.transformer";
import { RoomTransformer } from "@/shared/transformers/room.transformer";

// Deserialization: Request → Transformer Class
export const createBuilding: RequestHandler = async (req, res) => {
  const building = plainToInstance(CreateSingleBuildingRequest, req.body);
  await addNewBuilding(building);
  return res.status(201).json({ message: "Building created" });
};

// Serialization: Entity → Transformer → JSON
export const getRoom: RequestHandler = async (req, res) => {
  const room = await getOneRoom(req.params.id);  // Returns TypeORM entity

  const transformer = Object.assign(new RoomTransformer(), room);
  const response = instanceToPlain(transformer);

  return res.json({ message: "Room fetched", data: response });
};

// Alternative using toJSON()
export const getRoomAlternative: RequestHandler = async (req, res) => {
  const room = await getOneRoom(req.params.id);

  const transformer = Object.assign(new RoomTransformer(), room);
  const response = transformer.toJSON();  // Calls toJSON() from BaseTransformer

  return res.json({ message: "Room fetched", data: response });
};

// For arrays
export const getAllRooms: RequestHandler = async (req, res) => {
  const rooms = await getAllRoomsFromDB();

  const transformedData = rooms.map((room) =>
    instanceToPlain(Object.assign(new RoomTransformer(), room))
  );

  return res.json({ data: transformedData });
};
```

---

## Entities

TypeORM entities also use `class-transformer` decorators for serialization.

### Base Entity Pattern

All entities extend `BaseSerialEntity` which has `toJSON()` method:

```typescript
// src/database/entities/BaseSerialEntity.ts
import { Exclude, Expose, instanceToPlain } from "class-transformer";

@Exclude({ toPlainOnly: true })
class BaseSerialEntity extends BaseEntity {
  @Expose()
  @PrimaryGeneratedColumn("increment", { type: "bigint" })
  id!: string;

  @CreateDateColumn({ type: "timestamp", name: "created_at" })
  createdAt!: Date;  // Not exposed - no @Expose

  @UpdateDateColumn({ type: "timestamp", name: "updated_at" })
  updatedAt!: Date;  // Not exposed

  @DeleteDateColumn({ type: "timestamp", name: "deleted_at" })
  deletedAt!: Date | null;  // Not exposed

  toJSON() {
    return instanceToPlain(this, {
      excludeExtraneousValues: true,
      exposeUnsetFields: false,
    });
  }
}
```

### Creating an Entity

```typescript
// src/database/entities/Room.entity.ts
import { Exclude, Expose } from "class-transformer";
import { Column, Entity, ManyToOne } from "typeorm";
import BaseSerialEntity from "@/database/entities/BaseSerialEntity";

@Entity({ name: "rooms" })
@Exclude({ toPlainOnly: true })  // Exclude by default
export default class Room extends BaseSerialEntity {
  @Expose()  // Only exposed fields
  @Column()
  number!: number;

  @Expose()
  @Column({ type: "enum", enum: Gender })
  gender!: Gender;

  @Column()
  password!: string;  // Automatically excluded (no @Expose)

  @ManyToOne(() => Floor)
  floor!: Floor;  // Automatically excluded (no @Expose)

  @Expose({ name: "is_active" })
  @Column({ default: true })
  isActive!: boolean;
}
```

### Using Entity Serialization

```typescript
// In services or controllers
const room = await roomRepository.findOne({ where: { id: "1" } });

// Use the built-in toJSON() method
const response = room.toJSON();
// Result: { id: "1", number: 101, gender: "MALE", is_active: true }

// Or use instanceToPlain directly
const response = instanceToPlain(room);
// Same result
```

---

## Working with Nested Objects

### Nested Transformers

Use the `@Type()` decorator to specify the class of nested properties:

```typescript
import { Exclude, Expose, Type } from "class-transformer";

@Exclude()
export class Address {
  @Expose({ name: "street_name" })
  streetName: string;

  @Expose()
  city: string;
}

@Exclude()
export class User {
  @Expose()
  id: string;

  @Expose()
  name: string;

  @Expose()
  @Type(() => Address)  // Important: specifies nested type
  address: Address;
}
```

### Arrays of Nested Objects

```typescript
@Exclude()
export class UserWithRoles {
  @Expose()
  id: string;

  @Expose()
  @Type(() => Role)  // Works for arrays too
  roles: Role[];
}
```

### Pagination Meta (Nested Response)

```typescript
// src/shared/transformers/pagination.transformer.ts
export class PaginationMeta {
  @Expose({ name: "total" })
  totalDoc: number;

  @Expose({ name: "limit" })
  limit: number;

  @Expose({ name: "total_page" })
  totalPage: number;

  @Expose({ name: "current_page" })
  currPage: number;
}

// src/shared/transformers/resident.transformer.ts
export class GetResidentsResponse extends BaseTransformer {
  @Expose()
  @Type(() => ResidentTransformer)
  residents: ResidentTransformer[];

  @Expose({ name: "pagination_meta" })
  @Type(() => PaginationMeta)
  paginationMeta: PaginationMeta;
}

// Usage in controller
export const getAllResidents: RequestHandler = async (req, res) => {
  const { data, meta } = await getAllResidentsFromDB();

  const response = instanceToPlain(
    Object.assign(new GetResidentsResponse(), {
      residents: data.map(r => Object.assign(new ResidentTransformer(), r)),
      paginationMeta: meta
    })
  );

  return res.json({ data: response });
};
```

---

## Complete Workflow Example

Let's trace a complete request/response flow for creating and fetching a building.

### 1. Define the Transformer

```typescript
// src/shared/transformers/building.transformer.ts
import { Exclude, Expose, Type } from "class-transformer";
import BaseTransformer from "@/shared/transformers/base.transformer";

@Exclude()
export class Address {
  @Expose({ name: "address_line" })
  addressLine: string;

  @Expose()
  country: string;

  @Expose()
  city: string;
}

@Exclude()
export class Building {
  @Expose()
  id: string;

  @Expose()
  name: string;

  @Expose({ name: "legal_name" })
  legalName: string;

  @Expose()
  @Type(() => Address)
  address: Address;
}

export class CreateSingleBuildingRequest extends BaseTransformer {
  @Expose()
  @Type(() => Building)
  building: Building;
}

export class GetBuildingsRequest extends BaseTransformer {
  @Expose()
  id: string;

  @Expose()
  name: string;
}
```

### 2. Define Zod Validation Schema

```typescript
// src/validations/buildingValidation.ts
import * as z from "zod";

export const createSingleBuildingSchema = z.object({
  building: z.object({
    name: z.string().min(1, "Building name is required"),
    legal_name: z.string(),
    address: z.object({
      address_line: z.string(),
      country: z.number().transform((val) => val.toString()),
      city: z.string(),
    }),
  }),
});
```

### 3. Define the Route

```typescript
// src/routes/building.route.ts
import { Router } from "express";
import { validateToken } from "@/middlewares/auth.middleware";
import { validateReqBody } from "@/middlewares/validation.middleware";
import { createSingleBuildingSchema } from "@/validations/buildingValidation";
import { createBuilding, getBuilding } from "@/controllers/building.controller";

router.post(
  APIRoute.EMPTY,
  validateToken(),
  validateReqBody(createSingleBuildingSchema),  // Validates with Zod
  createBuilding
);

router.get(
  "/:id",
  validateToken(),
  getBuilding
);
```

### 4. Implement the Controller

```typescript
// src/controllers/building.controller.ts
import { instanceToPlain, plainToInstance } from "class-transformer";
import { CreateSingleBuildingRequest, GetBuildingsRequest } from "@/shared/transformers/building.transformer";
import { addNewBuilding, getBuildingById } from "@/services/building.service";

export const createBuilding: RequestHandler = async (req, res) => {
  // Step 1: Deserialize JSON to typed class
  const buildingRequest = plainToInstance(CreateSingleBuildingRequest, req.body);

  // Step 2: Pass to service layer
  await addNewBuilding(buildingRequest);

  return res.status(201).json({
    message: "Building created successfully"
  });
};

export const getBuilding: RequestHandler = async (req, res) => {
  const { id } = req.params;

  // Step 1: Get from service (returns TypeORM entity)
  const building = await getBuildingById(id);

  // Step 2: Serialize entity to transformer, then to JSON
  const transformer = Object.assign(new GetBuildingsRequest(), building);
  const response = instanceToPlain(transformer);

  return res.json({
    message: "Building fetched successfully",
    data: response
  });
};
```

### 5. Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         REQUEST FLOW (Create)                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  Client JSON                                                            │
│  ┌─────────────────────────────────────┐                               │
│  │ {                                   │                               │
│  │   "building": {                     │                               │
│  │     "name": "Sunrise Tower",        │                               │
│  │     "legal_name": "Sunrise Ltd",    │                               │
│  │     "address": {                    │                               │
│  │       "address_line": "123 Main St",│                               │
│  │       "country": "1",               │                               │
│  │       "city": "10"                  │                               │
│  │     }                               │                               │
│  │   }                                 │                               │
│  │ }                                   │                               │
│  └─────────────────────────────────────┘                               │
│           │                                                             │
│           ▼                                                             │
│  Zod Validation Middleware                                             │
│  ┌─────────────────────────────────────┐                               │
│  │ Validates structure & types         │                               │
│  │ Transforms: country → "1" (string) │                               │
│  │ Transforms: city → "10" (string)   │                               │
│  └─────────────────────────────────────┘                               │
│           │                                                             │
│           ▼                                                             │
│  Controller                                                             │
│  ┌─────────────────────────────────────┐                               │
│  │ plainToInstance(                    │                               │
│  │   CreateSingleBuildingRequest,      │                               │
│  │   req.body                          │                               │
│  │ )                                   │                               │
│  └─────────────────────────────────────┘                               │
│           │                                                             │
│           ▼                                                             │
│  Service Layer → Database                                              │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                         RESPONSE FLOW (Get)                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  Database → Service Layer                                               │
│  ┌─────────────────────────────────────┐                               │
│  │ Returns TypeORM Entity              │                               │
│  │ {                                   │                               │
│  │   id: "1",                          │                               │
│  │   name: "Sunrise Tower",            │                               │
│  │   legalName: "Sunrise Ltd",         │                               │
│  │   address: { addressLine, ... },    │                               │
│  │   createdAt: Date,                  │  Internal fields not exposed  │
│  │   updatedAt: Date,                  │  because no @Expose           │
│  │   deletedAt: null                   │                               │
│  │ }                                   │                               │
│  └─────────────────────────────────────┘                               │
│           │                                                             │
│           ▼                                                             │
│  Controller                                                             │
│  ┌─────────────────────────────────────┐                               │
│  │ Object.assign(                      │                               │
│  │   new GetBuildingsRequest(),        │                               │
│  │   entity                            │                               │
│  │ )                                   │                               │
│  │                                     │                               │
│  │ instanceToPlain(transformer)        │                               │
│  └─────────────────────────────────────┘                               │
│           │                                                             │
│           ▼                                                             │
│  Client JSON                                                            │
│  ┌─────────────────────────────────────┐                               │
│  │ {                                   │                               │
│  │   "id": "1",                        │                               │
│  │   "name": "Sunrise Tower",          │                               │
│  │   "legal_name": "Sunrise Ltd",      │  Note: camelCase → snake_case │
│  │   "address": { ... }                │                               │
│  │ }                                   │                               │
│  └─────────────────────────────────────┘                               │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Common Patterns and Best Practices

### 1. Always Use `@Exclude()` at Class Level

```typescript
// ✅ Good: Default to exclude, explicitly expose
@Exclude()
export class UserTransformer {
  @Expose()
  id: string;

  @Expose()
  name: string;

  password: string;  // Automatically excluded
}

// ❌ Bad: Have to manually exclude sensitive fields
export class UserTransformer {
  id: string;
  name: string;
  @Exclude()
  password: string;
}
```

### 2. Use `@Expose()` with `name` for Property Renaming

```typescript
@Exclude()
export class User {
  @Expose({ name: "user_id" })
  userId: string;  // In DB/API: user_id

  @Expose({ name: "full_name" })
  fullName: string;  // In DB/API: full_name

  @Expose()
  email: string;  // No renaming: email
}
```

### 3. Use `@Type()` for Nested Objects

```typescript
@Exclude()
export class Order {
  @Expose()
  id: string;

  @Expose()
  @Type(() => Customer)  // Required for proper serialization
  customer: Customer;

  @Expose()
  @Type(() => OrderItem)
  items: OrderItem[];
}
```

### 4. Pattern: Entity → Transformer → JSON

```typescript
// Step 1: Fetch entity from DB
const entity = await repository.findOne({ where: { id } });

// Step 2: Map to transformer
const transformer = Object.assign(new MyTransformer(), entity);

// Step 3: Serialize to JSON
const json = instanceToPlain(transformer);

// Or use toJSON() from BaseTransformer
const json = transformer.toJSON();
```

### 5. Pattern: JSON → Transformer → Entity

```typescript
// Step 1: Deserialize request to transformer
const request = plainToInstance(CreateRequest, req.body);

// Step 2: Map to entity (in service layer)
const entity = repository.create({
  name: request.building.name,
  legalName: request.building.legalName,
  // ... map fields
});

// Step 3: Save entity
await repository.save(entity);
```

### 6. Handle Arrays

```typescript
// Serializing arrays
const entities = await repository.find();
const transformed = entities.map(entity =>
  instanceToPlain(Object.assign(new MyTransformer(), entity))
);

// Or with pagination
const [data, total] = await repository.findAndCount({ ...options });
const transformedData = data.map(item =>
  instanceToPlain(Object.assign(new MyTransformer(), item))
);
```

### 7. Nullable Properties

```typescript
@Exclude()
export class User {
  @Expose()
  id: string;

  @Expose()
  name: string;

  @Expose({ name: "avatar_url" })
  avatarUrl: string | null;  // Can be null in JSON
}
```

---

## Quick Reference

### Utility Functions (src/utils/transformer.ts)

```typescript
// Deserialization helper
deserialize<TClass>(
  data: unknown,
  cls: new (...args: unknown[]) => TClass
): TClass

// Serialization helper
serialize(
  data: unknown,
  cls: new (...args: unknown[]) => object
): unknown
```

### Common Operations

| Task | Code |
|------|------|
| Serialize single object | `instanceToPlain(Object.assign(new MyTransformer(), entity))` |
| Serialize array | `entities.map(e => instanceToPlain(Object.assign(new MyTransformer(), e)))` |
| Deserialize request | `plainToInstance(MyRequestClass, req.body)` |
| Use entity's toJSON | `entity.toJSON()` |

### File Locations

| Type | Location |
|------|----------|
| Transformers | `src/shared/transformers/` |
| Entities | `src/database/entities/` |
| Validations (Zod) | `src/validations/` |
| Controllers | `src/controllers/` |
| Services | `src/services/` |

### Key Imports

```typescript
// For decorators
import { Exclude, Expose, Type } from "class-transformer";

// For serialization/deserialization
import { instanceToPlain, plainToInstance } from "class-transformer";

// For base classes
import BaseTransformer from "@/shared/transformers/base.transformer";
import BaseSerialEntity from "@/database/entities/BaseSerialEntity";
```

---

## Summary

1. **Serialization (Object → JSON)**: Use `instanceToPlain()` for sending data to clients
2. **Deserialization (JSON → Object)**: Use `plainToInstance()` for receiving data from clients
3. **Transformers**: Define API contracts in `src/shared/transformers/`
4. **Entities**: Extend `BaseSerialEntity` which includes `toJSON()` method
5. **Decorators**:
   - `@Exclude()`: Hide from JSON (use at class level)
   - `@Expose()`: Show in JSON, optionally rename with `name` option
   - `@Type()`: Specify nested object types
6. **Always use transformers** between entities and API responses for clean API contracts
7. **Zod validates first**, then `plainToInstance` creates typed objects from validated data
