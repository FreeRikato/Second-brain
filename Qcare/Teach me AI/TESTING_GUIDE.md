# QCare API Testing Guide

A complete guide to writing tests for the QCare API codebase. This guide will teach you everything you need to know to write test cases independently for any module.

## Table of Contents

1. [Testing Architecture Overview](#testing-architecture-overview)
2. [Test Configuration](#test-configuration)
3. [Understanding the Test Setup](#understanding-the-test-setup)
4. [Factory Pattern](#factory-pattern)
5. [Writing Integration Tests](#writing-integration-tests)
6. [Writing Unit Tests](#writing-unit-tests)
7. [Testing Services](#testing-services)
8. [Testing Controllers](#testing-controllers)
9. [Testing Error Cases](#testing-error-cases)
10. [Mocking External Services](#mocking-external-services)
11. [Redis Cleanup in Tests](#redis-cleanup-in-tests)
12. [Common Patterns](#common-patterns)
13. [Best Practices](#best-practices)
14. [Quick Reference](#quick-reference)

---

## Testing Architecture Overview

### Key Principles

The QCare API testing strategy is built on these core principles:

1. **Transaction Isolation**: Each test runs in its own transaction that gets rolled back
2. **Test Database**: Uses a separate `qcare-test` database
3. **Factory Pattern**: Centralized test data generation with `@jorgebodega/typeorm-factory`
4. **Test Independence**: Tests don't depend on each other and can run in any order
5. **Redis Cleanup**: Automatic Redis state cleanup between tests

### Test Structure

```
src/tests/
├── factories/           # Entity factories for test data
├── integration/         # Integration tests (API endpoints, services)
├── unit/               # Unit tests (utilities, validators)
├── globalSetup.ts      # Creates test database, runs migrations
├── globalTeardown.ts   # Cleanup after all tests
└── testSetup.ts        # Per-test transaction setup
```

---

## Test Configuration

### Jest Configuration

Located at `jest.config.js`:

```javascript
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/src'],
  testMatch: ['**/__tests__/**/*.ts', '**/?(*.)+(spec|test).ts'],
  globalSetup: '<rootDir>/src/tests/globalSetup.ts',
  globalTeardown: '<rootDir>/src/tests/globalTeardown.ts',
  setupFilesAfterEnv: ['<rootDir>/src/tests/testSetup.ts'],
  testTimeout: 10000,
};
```

### Running Tests

```bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Run specific test file
npm test buildingService.test.ts

# Run tests matching a pattern
npm test -- --testNamePattern="should create"
```

---

## Understanding the Test Setup

### How Test Isolation Works

Every test file automatically gets this setup from `testSetup.ts`:

```typescript
beforeAll(async () => {
  // 1. Initialize database connection
  await AppDataSource.initialize();

  // 2. Create a query runner for transactions
  queryRunner = AppDataSource.createQueryRunner();
  await queryRunner.connect();
  await queryRunner.startTransaction();

  // 3. Override AppDataSource.manager to use the transaction
  Object.defineProperty(AppDataSource, "manager", {
    get: () => queryRunner.manager,
    configurable: true,
  });
});

afterEach(async () => {
  // 1. Rollback the transaction (undoes all DB changes)
  await queryRunner.rollbackTransaction();

  // 2. Start a fresh transaction for next test
  await queryRunner.startTransaction();

  // 3. Clean up Redis keys (rate limiters, etc.)
  const keys = await redis.keys(`${OTP_RATE_LIMIT_KEY_PREFIX}*`);
  if (keys.length > 0) {
    await redis.del(...keys);
  }
});

afterAll(async () => {
  // Clean up and close connections
  await queryRunner.release();
  await AppDataSource.destroy();
});
```

**What This Means for You:**
- Each test starts with a clean database
- Any data you create is automatically deleted after the test
- You don't need to clean up after yourself
- Tests are fast because rollbacks are quicker than deletes

---

## Factory Pattern

Factories create realistic test data with minimal code. They use `@jorgebodega/typeorm-factory` and `@faker-js/faker`.

### Basic Factory Structure

Every factory follows this pattern:

```typescript
// src/tests/factories/building.factory.ts
import { faker } from "@faker-js/faker";
import type { FactorizedAttrs } from "@jorgebodega/typeorm-factory";
import { Factory } from "@jorgebodega/typeorm-factory";
import type { DataSource, EntityManager } from "typeorm";
import Building from "@/database/entities/Building.entity";

export class BuildingFactory extends Factory<Building> {
  protected entity = Building;
  protected dataSource: DataSource;

  constructor(dataSource: DataSource) {
    super();
    this.dataSource = dataSource;
  }

  // Required: Tell the factory how to get the database manager
  protected getEntityManager(): EntityManager {
    return this.dataSource.manager;
  }

  // Required: Define default values for the entity
  protected attrs(): FactorizedAttrs<Building> {
    const uniqueSuffix = faker.string.uuid(); // Prevents duplicate names
    return {
      name: `${faker.company.name()} ${uniqueSuffix}`,
      legalName: faker.company.name(),
      shortCode: faker.string.alphanumeric({ length: 6, casing: "upper" }),
      status: BuildingStatus.ACTIVE,
      // ... other required fields
    };
  }
}
```

### Creating Factory Instances

```typescript
import { BuildingFactory } from "@/tests/factories/building.factory";

// 1. Create a building with default values
const building = await new BuildingFactory(AppDataSource).create();

// 2. Create with custom values
const customBuilding = await new BuildingFactory(AppDataSource).create({
  name: "My Custom Building",
  status: BuildingStatus.INACTIVE,
});

// 3. Create multiple at once
const buildings = await new BuildingFactory(AppDataSource).createMany(5);
```

### Handling Relationships

Factories can create related entities automatically:

```typescript
// Room has a relationship with Building, Floor, and RoomType
protected attrs(): FactorizedAttrs<Room> {
  return {
    roomNumber: faker.number.int({ min: 100, max: 999 }),
    // Use async callbacks for related entities
    building: async () => await new BuildingFactory(this.dataSource).create(),
    floor: async () => await new FloorFactory(this.dataSource).create(),
    roomType: async () => await new RoomTypeFactory(this.dataSource).create(),
    status: RoomStatus.ACTIVE,
  };
}
```

### Factory States (Modifiers)

Add reusable states to your factories:

```typescript
export class BuildingFactory extends Factory<Building> {
  // ... existing code

  // Modifier for inactive buildings
  inactive(): this {
    return this.state(() => ({ status: BuildingStatus.INACTIVE }));
  }

  // Modifier for buildings with specific payment methods
  withPaymentMethods(): this {
    return this.state(async () => ({
      paymentMethods: async () => await new PaymentMethodFactory(this.dataSource).createMany(2),
    }));
  }
}

// Usage
const inactiveBuilding = await new BuildingFactory(AppDataSource)
  .inactive()
  .create();

const buildingWithPayments = await new BuildingFactory(AppDataSource)
  .withPaymentMethods()
  .create();
```

### Handling Seeded Data

For entities that reference seeded data (like countries), check if it exists first:

```typescript
export class CountryFactory extends Factory<Country> {
  protected attrs(): FactorizedAttrs<Country> {
    return {
      name: faker.location.country(),
      code: faker.location.countryCode("alpha-2"),
    };
  }

  // Override create to check for existing seeded data
  async create(props?: FactorizedAttrs<Country>): Promise<Country> {
    if (props?.code) {
      const existing = await this.getEntityManager().findOne(Country, {
        where: { code: props.code }
      });
      if (existing) return existing;
    }
    return super.create(props);
  }
}
```

---

## Writing Integration Tests

Integration tests test multiple layers working together (service + database, or controller + service + database).

### Basic Test Structure

```typescript
describe("Building Service", () => {
  describe("addNewBuilding", () => {
    it("should create a new building with valid data", async () => {
      // Arrange: Prepare test data
      const buildingData = await new BuildingFactory(AppDataSource).create();

      const payload = {
        building: {
          name: `${buildingData.name}-unique-${faker.string.uuid()}`,
          legalName: buildingData.legalName,
          // ... other fields
        },
      };

      const request = plainToInstance(CreateSingleBuildingRequest, payload);

      // Act: Execute the function being tested
      const result = await addNewBuilding(request);

      // Assert: Verify the result
      expect(result.id).toBeTruthy();
      expect(result.name).toBe(request.building.name);
      expect(result.legalName).toBe(request.building.legalName);
    });
  });
});
```

### Using beforeEach for Shared Setup

```typescript
describe("Room Service", () => {
  let building: Building;
  let floor: Floor;
  let roomType: RoomType;

  beforeEach(async () => {
    // Set up data that multiple tests need
    [building, floor, roomType] = await Promise.all([
      new BuildingFactory(AppDataSource).create(),
      new FloorFactory(AppDataSource).create(),
      new RoomTypeFactory(AppDataSource).create(),
    ]);
  });

  it("should create a room", async () => {
    const roomData = {
      roomNumber: "101",
      buildingId: building.id,
      floorId: floor.id,
      roomTypeId: roomType.id,
    };

    const room = await createRoom(roomData);

    expect(room.roomNumber).toBe("101");
  });

  it("should fail with duplicate room number", async () => {
    // ... building, floor, roomType are already available
  });
});
```

### Testing with Relationships

```typescript
describe("Booking Service", () => {
  it("should create a booking with room and resident", async () => {
    // Create related entities
    const room = await new RoomFactory(AppDataSource)
      .withDependencies() // Factory method that creates building, floor, etc.
      .create();

    const resident = await new ResidentFactory(AppDataSource).create();

    const bookingData = {
      roomId: room.id,
      residentId: resident.id,
      checkInDate: new Date(),
      checkOutDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days later
    };

    const booking = await createBooking(bookingData);

    expect(booking.room.id).toBe(room.id);
    expect(booking.resident.id).toBe(resident.id);
  });
});
```

---

## Writing Unit Tests

Unit tests test individual functions in isolation without database calls.

### Example: Testing a Utility Function

```typescript
// src/utils/password.ts
export const generateHash = async (password: string): Promise<string> => {
  return bcrypt.hash(password, 10);
};

export const compareHash = async (
  password: string,
  hash: string,
): Promise<boolean> => {
  return bcrypt.compare(password, hash);
};
```

```typescript
// src/tests/unit/password.test.ts
import { generateHash, compareHash } from "@/utils/password";

describe("Password Utilities", () => {
  describe("generateHash", () => {
    it("should generate a hash for a password", async () => {
      const password = "MySecurePassword123";
      const hash = await generateHash(password);

      expect(hash).toBeDefined();
      expect(hash).not.toBe(password); // Hash should be different
      expect(hash.length).toBeGreaterThan(0);
    });

    it("should generate different hashes for the same password", async () => {
      const password = "MySecurePassword123";
      const hash1 = await generateHash(password);
      const hash2 = await generateHash(password);

      expect(hash1).not.toBe(hash2); // Salt makes them different
    });
  });

  describe("compareHash", () => {
    it("should return true for matching password", async () => {
      const password = "MySecurePassword123";
      const hash = await generateHash(password);

      const result = await compareHash(password, hash);
      expect(result).toBe(true);
    });

    it("should return false for wrong password", async () => {
      const password = "MySecurePassword123";
      const wrongPassword = "WrongPassword";
      const hash = await generateHash(password);

      const result = await compareHash(wrongPassword, hash);
      expect(result).toBe(false);
    });
  });
});
```

### Example: Testing Validation Schemas

```typescript
// src/validations/building.validation.ts
export const createSingleBuildingSchema = z.object({
  building: z.object({
    name: z.string().min(1, "Building name is required"),
    shortCode: z.string().min(2, "Short code must be at least 2 characters"),
  }),
});
```

```typescript
// src/tests/unit/validations/building.validation.test.ts
import { createSingleBuildingSchema } from "@/validations/building.validation";

describe("Building Validation Schema", () => {
  it("should validate correct building data", () => {
    const data = {
      building: {
        name: "Test Building",
        shortCode: "TB001",
      },
    };

    const result = createSingleBuildingSchema.safeParse(data);

    expect(result.success).toBe(true);
  });

  it("should fail validation with missing name", () => {
    const data = {
      building: {
        shortCode: "TB001",
      },
    };

    const result = createSingleBuildingSchema.safeParse(data);

    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.errors[0].message).toBe("Building name is required");
    }
  });

  it("should fail validation with short code too short", () => {
    const data = {
      building: {
        name: "Test Building",
        shortCode: "T",
      },
    };

    const result = createSingleBuildingSchema.safeParse(data);

    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.errors[0].message).toContain("at least 2 characters");
    }
  });
});
```

---

## Testing Services

Service tests verify business logic works correctly with the database.

### Example: Testing a Service Function

```typescript
// src/services/building.service.ts
export const addNewBuilding = async (
  data: CreateSingleBuildingRequest,
): Promise<BuildingTransformer> => {
  return AppDataSource.transaction(async (tx) => {
    // Check for duplicate name
    const existing = await getScopedRepository(Building, tx).exists({
      where: { name: data.building.name }
    });

    if (existing) {
      throw new BadRequestError(validationError.duplicateRecordPresent("Building"));
    }

    // Create building
    const building = await saveOne({
      entity: Building,
      data: {
        name: data.building.name,
        legalName: data.building.legalName,
        // ... other fields
      },
      transactionalEntityManager: tx,
    });

    // Create address if provided
    if (data.building.address) {
      await saveOne({
        entity: Address,
        data: {
          addressableId: building.id,
          addressableType: AddressTypeEnum.BUILDING,
          ...data.building.address,
        },
        transactionalEntityManager: tx,
      });
    }

    return plainToInstance(BuildingTransformer, building);
  });
};
```

```typescript
// src/tests/integration/v1/building/buildingService.test.ts
describe("Building Service - addNewBuilding", () => {
  it("should create a building successfully", async () => {
    // Arrange
    const city = await new CityFactory(AppDataSource).create();
    const payload = {
      building: {
        name: `Test Building ${faker.string.uuid()}`,
        legalName: "Test Legal Name",
        shortCode: "TEST01",
        status: BuildingStatus.ACTIVE,
        address: {
          addressLine: faker.location.streetAddress(),
          countryId: city.countryId,
          cityId: city.id,
          zipCode: faker.location.zipCode(),
        },
      },
    };

    // Act
    const result = await addNewBuilding(
      plainToInstance(CreateSingleBuildingRequest, payload)
    );

    // Assert
    expect(result.id).toBeTruthy();
    expect(result.name).toBe(payload.building.name);

    // Verify in database
    const building = await AppDataSource.getRepository(Building).findOne({
      where: { id: result.id },
    });
    expect(building).toBeDefined();
    expect(building?.name).toBe(payload.building.name);
  });

  it("should throw error when building name already exists", async () => {
    // Arrange
    const existingBuilding = await new BuildingFactory(AppDataSource).create();
    const payload = {
      building: {
        name: existingBuilding.name, // Duplicate name!
        legalName: "Different Legal Name",
        shortCode: "TEST02",
        status: BuildingStatus.ACTIVE,
      },
    };

    // Act & Assert
    await expect(
      addNewBuilding(plainToInstance(CreateSingleBuildingRequest, payload))
    ).rejects.toThrow(
      new BadRequestError(validationError.duplicateRecordPresent("Building"))
    );
  });

  it("should create building with address", async () => {
    // Arrange
    const city = await new CityFactory(AppDataSource).create();
    const payload = {
      building: {
        name: `Test Building ${faker.string.uuid()}`,
        legalName: "Test Legal Name",
        shortCode: "TEST01",
        status: BuildingStatus.ACTIVE,
        address: {
          addressLine: "123 Test Street",
          countryId: city.countryId,
          cityId: city.id,
          zipCode: "12345",
        },
      },
    };

    // Act
    const result = await addNewBuilding(
      plainToInstance(CreateSingleBuildingRequest, payload)
    );

    // Assert
    const address = await AppDataSource.getRepository(Address).findOne({
      where: {
        addressableId: result.id,
        addressableType: AddressTypeEnum.BUILDING,
      },
    });
    expect(address).toBeDefined();
    expect(address?.addressLine).toBe(payload.building.address.addressLine);
  });
});
```

---

## Testing Controllers

Controller tests verify HTTP request handling, but typically you test the service layer directly unless you need to test middleware behavior.

### Example: Testing a Controller with Supertest

```typescript
// src/tests/integration/v1/building/buildingController.test.ts
import request from "supertest";
import app from "@/app";
import { BuildingFactory } from "@/tests/factories/building.factory";
import { generateToken } from "@/utils/jwt";
import { InternalUserFactory } from "@/tests/factories/internalUser.factory";

describe("Building Controller", () => {
  let authToken: string;

  beforeEach(async () => {
    // Create a user and generate auth token
    const user = await new InternalUserFactory(AppDataSource).create({
      role: Role.SUPER_ADMIN,
    });
    authToken = generateToken(user.id, TokenType.ACCESS, user.role);
  });

  describe("POST /api/v1/buildings", () => {
    it("should create a new building", async () => {
      const city = await new CityFactory(AppDataSource).create();

      const payload = {
        building: {
          name: `Test Building ${faker.string.uuid()}`,
          legalName: "Test Legal Name",
          shortCode: "TEST01",
          address: {
            addressLine: "123 Test Street",
            countryId: city.countryId,
            cityId: city.id,
            zipCode: "12345",
          },
        },
      };

      const response = await request(app)
        .post("/api/v1/buildings")
        .set("Cookie", `accessToken=${authToken}`)
        .send(payload)
        .expect(201);

      expect(response.body.message).toBe("Building created successfully");
      expect(response.body.data.id).toBeTruthy();
      expect(response.body.data.name).toBe(payload.building.name);
    });

    it("should return 401 without authentication", async () => {
      const payload = {
        building: {
          name: "Test Building",
        },
      };

      await request(app)
        .post("/api/v1/buildings")
        .send(payload)
        .expect(401);
    });

    it("should return 400 with invalid data", async () => {
      const payload = {
        building: {
          // Missing required fields
        },
      };

      await request(app)
        .post("/api/v1/buildings")
        .set("Cookie", `accessToken=${authToken}`)
        .send(payload)
        .expect(400);
    });
  });
});
```

---

## Testing Error Cases

Every test should cover both success and failure scenarios.

### Testing Validation Errors

```typescript
describe("Building Validation", () => {
  it("should reject building with empty name", async () => {
    const payload = {
      building: {
        name: "",  // Invalid!
        legalName: "Test Legal Name",
        shortCode: "TEST01",
      },
    };

    await expect(
      addNewBuilding(plainToInstance(CreateSingleBuildingRequest, payload))
    ).rejects.toThrow();
  });

  it("should reject building with invalid status", async () => {
    const payload = {
      building: {
        name: "Test Building",
        status: "INVALID_STATUS",  // Not a valid enum value
      },
    };

    await expect(
      addNewBuilding(plainToInstance(CreateSingleBuildingRequest, payload))
    ).rejects.toThrow();
  });
});
```

### Testing Business Logic Errors

```typescript
describe("Room Service", () => {
  it("should prevent adding rooms to inactive buildings", async () => {
    const inactiveBuilding = await new BuildingFactory(AppDataSource)
      .inactive()
      .create();

    const roomData = {
      roomNumber: "101",
      buildingId: inactiveBuilding.id,
      floorId: faker.string.uuid(),
      roomTypeId: faker.string.uuid(),
    };

    await expect(createRoom(roomData)).rejects.toThrow(
      new BadRequestError("Cannot add rooms to inactive building")
    );
  });

  it("should prevent duplicate room numbers on same floor", async () => {
    const floor = await new FloorFactory(AppDataSource).create();
    const existingRoom = await new RoomFactory(AppDataSource)
      .withFloor(floor)
      .create({ roomNumber: "101" });

    const roomData = {
      roomNumber: "101",  // Duplicate!
      buildingId: floor.buildingId,
      floorId: floor.id,
      roomTypeId: existingRoom.roomTypeId,
    };

    await expect(createRoom(roomData)).rejects.toThrow(
      new BadRequestError("Room number already exists on this floor")
    );
  });
});
```

### Testing Not Found Errors

```typescript
describe("Building Service - getBuildingById", () => {
  it("should throw error for non-existent building", async () => {
    const nonExistentId = faker.string.uuid();

    await expect(getBuildingById(nonExistentId)).rejects.toThrow(
      new NotFoundError("Building not found")
    );
  });

  it("should return building for valid ID", async () => {
    const building = await new BuildingFactory(AppDataSource).create();

    const result = await getBuildingById(building.id);

    expect(result.id).toBe(building.id);
    expect(result.name).toBe(building.name);
  });
});
```

---

## Mocking External Services

Use Jest mocks to test code that calls external services.

### Mocking an Email Service

```typescript
// src/services/mailer.service.ts
export const sendWelcomeEmail = async (email: string, name: string) => {
  await transporter.sendMail({
    to: email,
    subject: "Welcome to QCare",
    html: `<h1>Welcome ${name}</h1>`,
  });
};
```

```typescript
// src/tests/integration/auth/authService.test.ts
import * as mailerService from "@/services/mailer.service";

describe("Auth Service", () => {
  beforeEach(() => {
    // Mock the email service before each test
    jest.spyOn(mailerService, "sendWelcomeEmail").mockResolvedValue();
  });

  afterEach(() => {
    // Restore all mocks after each test
    jest.restoreAllMocks();
  });

  it("should send welcome email after registration", async () => {
    const userData = {
      email: "test@example.com",
      name: "Test User",
      password: "SecurePass123",
    };

    await registerUser(userData);

    // Verify email was sent
    expect(mailerService.sendWelcomeEmail).toHaveBeenCalledWith(
      userData.email,
      userData.name
    );
    expect(mailerService.sendWelcomeEmail).toHaveBeenCalledTimes(1);
  });

  it("should not send email if registration fails", async () => {
    const userData = {
      email: "invalid-email",  // This will fail validation
      name: "Test User",
      password: "SecurePass123",
    };

    await expect(registerUser(userData)).rejects.toThrow();

    // Verify email was NOT sent
    expect(mailerService.sendWelcomeEmail).not.toHaveBeenCalled();
  });
});
```

### Mocking DocuSign API Calls

```typescript
describe("Booking Service", () => {
  it("should create DocuSign envelope", async () => {
    // Mock the DocuSign service
    const mockEnvelopeId = faker.string.uuid();
    jest.spyOn(docusignService, "createEnvelope").mockResolvedValue({
      envelopeId: mockEnvelopeId,
      status: "sent",
    });

    const booking = await new BookingFactory(AppDataSource).create();
    const agreement = await createRentalAgreement(booking.id);

    expect(docusignService.createEnvelope).toHaveBeenCalledWith(
      expect.objectContaining({
        bookingId: booking.id,
      })
    );
    expect(agreement.envelopeId).toBe(mockEnvelopeId);
  });
});
```

---

## Redis Cleanup in Tests

If your code uses Redis (rate limiting, caching, etc.), you need to clean up between tests.

### The Automatic Cleanup

The `testSetup.ts` already handles this for rate limit keys:

```typescript
afterEach(async () => {
  // Clean up Redis rate limit keys
  const keys = await redis.keys(`${OTP_RATE_LIMIT_KEY_PREFIX}*`);
  if (keys.length > 0) {
    await redis.del(...keys);
  }
});
```

### Adding Custom Redis Cleanup

If your tests use other Redis keys, add cleanup in your test file:

```typescript
describe("OTP Service", () => {
  const TEST_REDIS_PREFIX = "test:otp:";

  afterEach(async () => {
    // Clean up any keys your tests created
    const keys = await redis.keys(`${TEST_REDIS_PREFIX}*`);
    if (keys.length > 0) {
      await redis.del(...keys);
    }
  });

  it("should store OTP in Redis", async () => {
    const email = "test@example.com";
    const otp = "123456";

    await storeOTP(email, otp);

    const stored = await redis.get(`${TEST_REDIS_PREFIX}${email}`);
    expect(stored).toBe(otp);
  });
});
```

---

## Common Patterns

### Pattern 1: Arrange-Act-Assert

Every test should follow this clear structure:

```typescript
it("should update building name", async () => {
  // Arrange: Set up the test data
  const building = await new BuildingFactory(AppDataSource).create();
  const newName = "Updated Building Name";

  // Act: Execute the function being tested
  const updated = await updateBuildingName(building.id, newName);

  // Assert: Verify the results
  expect(updated.name).toBe(newName);

  // Also verify in database
  const dbBuilding = await AppDataSource.getRepository(Building).findOne({
    where: { id: building.id },
  });
  expect(dbBuilding?.name).toBe(newName);
});
```

### Pattern 2: Unique Data for Each Test

Use faker to avoid duplicate key errors:

```typescript
it("should create building", async () => {
  const building = await new BuildingFactory(AppDataSource).create({
    name: `Building ${faker.string.uuid()}`,  // Always unique!
  });
});
```

### Pattern 3: Parallel Entity Creation

Use `Promise.all` for faster test execution:

```typescript
// Slow: Sequential creation
const building = await new BuildingFactory(AppDataSource).create();
const city = await new CityFactory(AppDataSource).create();
const user = await new InternalUserFactory(AppDataSource).create();

// Fast: Parallel creation
const [building, city, user] = await Promise.all([
  new BuildingFactory(AppDataSource).create(),
  new CityFactory(AppDataSource).create(),
  new InternalUserFactory(AppDataSource).create(),
]);
```

### Pattern 4: Testing Transactional Operations

When testing code that uses transactions, verify everything commits or rolls back:

```typescript
describe("Booking Service", () => {
  it("should create booking and update room status in transaction", async () => {
    const room = await new RoomFactory(AppDataSource)
      .withDependencies()
      .create({ status: RoomStatus.AVAILABLE });

    const booking = await createBooking({
      roomId: room.id,
      residentId: faker.string.uuid(),
      checkInDate: new Date(),
    });

    // Verify booking was created
    expect(booking.id).toBeTruthy();

    // Verify room status was updated
    const updatedRoom = await AppDataSource.getRepository(Room).findOne({
      where: { id: room.id },
    });
    expect(updatedRoom?.status).toBe(RoomStatus.OCCUPIED);
  });

  it("should rollback if payment fails", async () => {
    const room = await new RoomFactory(AppDataSource).create();

    // Mock payment failure
    jest.spyOn(paymentService, "processPayment").mockRejectedValue(
      new Error("Payment failed")
    );

    await expect(
      createBooking({
        roomId: room.id,
        residentId: faker.string.uuid(),
        checkInDate: new Date(),
      })
    ).rejects.toThrow("Payment failed");

    // Verify booking was NOT created
    const booking = await AppDataSource.getRepository(Booking).exists({
      where: { roomId: room.id },
    });
    expect(booking).toBe(false);

    // Verify room status was NOT changed
    const updatedRoom = await AppDataSource.getRepository(Room).findOne({
      where: { id: room.id },
    });
    expect(updatedRoom?.status).toBe(RoomStatus.AVAILABLE);
  });
});
```

### Pattern 5: Testing Soft Deletes

When testing soft deletes, use `withDeleted()`:

```typescript
describe("Building Service", () => {
  it("should soft delete building", async () => {
    const building = await new BuildingFactory(AppDataSource).create();

    await deleteBuilding(building.id);

    // Regular query won't find it
    const notFound = await AppDataSource.getRepository(Building).findOne({
      where: { id: building.id },
    });
    expect(notFound).toBeNull();

    // Query with withDeleted() will find it
    const found = await AppDataSource.getRepository(Building).withDeleted().findOne({
      where: { id: building.id },
    });
    expect(found).toBeDefined();
    expect(found?.deletedAt).toBeTruthy();
  });
});
```

---

## Best Practices

### DO ✅

1. **Use factories for all test data**
   ```typescript
   const building = await new BuildingFactory(AppDataSource).create();
   ```

2. **Make tests independent** - each test should work alone
3. **Use descriptive test names**
   ```typescript
   it("should throw BadRequestError when building name already exists", async () => {
   ```

4. **Test both success and failure cases**
5. **Use faker for unique data**
   ```typescript
   name: `Building ${faker.string.uuid()}`
   ```

6. **Clean up mocks in afterEach**
   ```typescript
   afterEach(() => {
     jest.restoreAllMocks();
   });
   ```

7. **Use beforeEach for shared setup**
8. **Verify database state when testing services**
9. **Use Promise.all for parallel entity creation**
10. **Test one thing per test**

### DON'T ❌

1. **Don't depend on test execution order**
2. **Don't hardcode IDs or non-unique data**
   ```typescript
   // Bad - will fail on second run
   name: "Test Building"
   ```
3. **Don't use afterAll for cleanup** (transactions handle this)
4. **Don't test implementation details** (test behavior, not internals)
5. **Don't forget to test error cases**
6. **Don't create unnecessary test data** (only what you need)
7. **Don't use real external services** (always mock)
8. **Don't write tests that are too complex** (keep them simple and focused)

---

## Quick Reference

### Factory Cheat Sheet

```typescript
// Create with defaults
const entity = await new MyFactory(AppDataSource).create();

// Create with custom values
const entity = await new MyFactory(AppDataSource).create({ name: "Custom" });

// Create multiple
const entities = await new MyFactory(AppDataSource).createMany(5);

// Use state modifier
const entity = await new MyFactory(AppDataSource).inactive().create();
```

### Test Structure Template

```typescript
describe("Feature Name", () => {
  describe("functionName", () => {
    beforeEach(async () => {
      // Set up data used by multiple tests
    });

    afterEach(() => {
      // Clean up mocks
      jest.restoreAllMocks();
    });

    it("should succeed with valid data", async () => {
      // Arrange
      const testData = await new MyFactory(AppDataSource).create();

      // Act
      const result = await myFunction(testData);

      // Assert
      expect(result).toBeDefined();
    });

    it("should fail with invalid data", async () => {
      // Arrange
      const invalidData = { /* invalid */ };

      // Act & Assert
      await expect(myFunction(invalidData)).rejects.toThrow();
    });
  });
});
```

### Common Assertions

```typescript
// Truthiness
expect(result).toBeTruthy();
expect(result).toBeNull();
expect(result).toBeDefined();

// Equality
expect(result.name).toBe("Expected Name");
expect(result).toEqual(expectedObject);

// Numbers
expect(result.count).toBeGreaterThan(0);
expect(result.count).toBeLessThan(10);

// Arrays
expect(result.length).toBe(5);
expect(result).toContain(item);

// Async errors
await expect(promise).rejects.toThrow(Error);
await expect(promise).resolves.toBe(value);

// Functions
expect(mockFunction).toHaveBeenCalledWith(arg1, arg2);
expect(mockFunction).toHaveBeenCalledTimes(1);
expect(mockFunction).not.toHaveBeenCalled();
```

### Running Specific Tests

```bash
# Run specific file
npm test buildingService.test.ts

# Run tests matching pattern
npm test -- --testNamePattern="should create"

# Run tests in a file matching pattern
npm test -- building.test.ts

# Run with coverage
npm test -- --coverage
```

---

## Complete Example: Writing a Test from Scratch

Let's say you need to test a new `updateBuilding` function. Here's the complete process:

### Step 1: Understand What You're Testing

```typescript
// src/services/building.service.ts
export const updateBuilding = async (
  id: string,
  data: UpdateBuildingRequest,
): Promise<BuildingTransformer> => {
  const building = await getOneBuilding(id);

  if (!building) {
    throw new NotFoundError("Building not found");
  }

  // Check for duplicate name
  if (data.name && data.name !== building.name) {
    const existing = await AppDataSource.getRepository(Building).exists({
      where: { name: data.name },
    });
    if (existing) {
      throw new BadRequestError("Building name already exists");
    }
  }

  Object.assign(building, data);
  const updated = await AppDataSource.getRepository(Building).save(building);

  return plainToInstance(BuildingTransformer, updated);
};
```

### Step 2: Write the Test

```typescript
// src/tests/integration/v1/building/updateBuilding.test.ts
describe("Building Service - updateBuilding", () => {
  let building: Building;

  beforeEach(async () => {
    // Create a building to update
    building = await new BuildingFactory(AppDataSource).create({
      name: "Original Building Name",
      status: BuildingStatus.ACTIVE,
    });
  });

  describe("Success cases", () => {
    it("should update building name", async () => {
      // Arrange
      const newName = `Updated ${faker.string.uuid()}`;
      const updateData = plainToInstance(UpdateBuildingRequest, {
        name: newName,
      });

      // Act
      const result = await updateBuilding(building.id, updateData);

      // Assert
      expect(result.id).toBe(building.id);
      expect(result.name).toBe(newName);

      // Verify in database
      const dbBuilding = await AppDataSource.getRepository(Building).findOne({
        where: { id: building.id },
      });
      expect(dbBuilding?.name).toBe(newName);
    });

    it("should update multiple fields", async () => {
      // Arrange
      const updateData = plainToInstance(UpdateBuildingRequest, {
        name: `Updated ${faker.string.uuid()}`,
        legalName: "Updated Legal Name",
        status: BuildingStatus.INACTIVE,
      });

      // Act
      const result = await updateBuilding(building.id, updateData);

      // Assert
      expect(result.name).toBe(updateData.name);
      expect(result.legalName).toBe(updateData.legalName);
      expect(result.status).toBe(updateData.status);
    });

    it("should allow updating to same name", async () => {
      // Arrange
      const updateData = plainToInstance(UpdateBuildingRequest, {
        name: building.name, // Same name!
      });

      // Act
      const result = await updateBuilding(building.id, updateData);

      // Assert
      expect(result.name).toBe(building.name);
    });
  });

  describe("Error cases", () => {
    it("should throw NotFoundError for non-existent building", async () => {
      // Arrange
      const nonExistentId = faker.string.uuid();
      const updateData = plainToInstance(UpdateBuildingRequest, {
        name: "New Name",
      });

      // Act & Assert
      await expect(
        updateBuilding(nonExistentId, updateData)
      ).rejects.toThrow(new NotFoundError("Building not found"));
    });

    it("should reject duplicate building name", async () => {
      // Arrange
      const existingBuilding = await new BuildingFactory(AppDataSource).create();
      const updateData = plainToInstance(UpdateBuildingRequest, {
        name: existingBuilding.name, // Duplicate!
      });

      // Act & Assert
      await expect(
        updateBuilding(building.id, updateData)
      ).rejects.toThrow(new BadRequestError("Building name already exists"));
    });
  });
});
```

### Step 3: Run the Test

```bash
npm test updateBuilding.test.ts
```

---

## Summary

You now have everything you need to write tests for the QCare API:

1. **Factories** create test data easily
2. **Transactions** keep tests isolated
3. **Arrange-Act-Assert** structures tests clearly
4. **Mocks** handle external dependencies
5. **Both success and error cases** should be tested

Remember: Good tests are simple, focused, and test **behavior**, not implementation details.

Happy testing! 🚀
