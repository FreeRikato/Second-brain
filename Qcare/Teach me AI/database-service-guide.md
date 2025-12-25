# Database Service Functions Guide

This guide explains all the helper functions in `src/services/database.ts` and how to use them effectively in the QCare codebase.

## Table of Contents

1. [Repository Functions](#repository-functions)
2. [Query Functions](#query-functions)
3. [Insert/Update Functions](#insertupdate-functions)
4. [Delete Functions](#delete-functions)
5. [Utility Functions](#utility-functions)
6. [Advanced Patterns](#advanced-patterns)

---

## Repository Functions

### `getRepository`

Gets a TypeORM repository for an entity. Use this for simple operations outside of transactions.

```typescript
import { getRepository } from "@/services/database";
import { Building } from "@/database/entities/Building";

// Get a repository
const buildingRepo = getRepository(Building);
const buildings = await buildingRepo.find();
```

### `getScopedRepository`

Gets a transaction-aware repository. This is the preferred method as it works seamlessly with transactions.

```typescript
import { getScopedRepository } from "@/services/database";
import { Building } from "@/database/entities/Building";

// Without transaction
const repo1 = getScopedRepository(Building);

// With transaction
await AppDataSource.transaction(async (tx) => {
  const repo2 = getScopedRepository(Building, tx);
  // Operations here are part of the transaction
});
```

---

## Query Functions

### `findOne`

Find a single entity by criteria.

```typescript
import { findOne } from "@/services/database";
import { Building } from "@/database/entities/Building";

// Basic usage
const building = await findOne<Building>({
  entity: Building,
  options: {
    where: { id: "123" },
    relations: ["address", "floors"],
  },
});

// With transaction
await AppDataSource.transaction(async (tx) => {
  const building = await findOne<Building>({
    entity: Building,
    options: { where: { id: "123" } },
    transactionalEntityManager: tx,
  });
});
```

### `findMany`

Find multiple entities by criteria.

```typescript
import { findMany } from "@/services/database";
import { Room } from "@/database/entities/Room";

// Find all active rooms
const rooms = await findMany<Room>({
  entity: Room,
  options: {
    where: { status: RoomStatus.ACTIVE },
    relations: ["building", "floor"],
    order: { createdAt: "DESC" },
  },
});

// With specific select
const rooms = await findMany<Room>({
  entity: Room,
  options: {
    select: ["id", "name", "status"],
    where: { status: RoomStatus.ACTIVE },
  },
});
```

### `findManyWithPagination`

Find entities with pagination metadata.

```typescript
import { findManyWithPagination } from "@/services/database";
import { Building } from "@/database/entities/Building";
import { BasePaginationOption } from "@/shared/transformers/pagination.transformer";

// Paginated results
const result = await findManyWithPagination<Building>({
  entity: Building,
  options: {
    where: { status: BuildingStatus.ACTIVE },
    relations: ["address"],
  },
  paginationOptions: new BasePaginationOption({
    page: 1,
    limit: 10,
  }),
});

// Result structure:
// {
//   data: [Building, Building, ...],
//   meta: {
//     totalDoc: 45,
//     limit: 10,
//     currPage: 1,
//     totalPage: 5,
//     prevPage: 0,
//     nextPage: 2,
//     hasPrevPage: false,
//     hasNextPage: true
//   }
// }
```

### `findOneOrFail`

Find a single entity or throw an error if not found.

```typescript
import { findOneOrFail } from "@/services/database";
import { Building } from "@/database/entities/Building";

try {
  const building = await findOneOrFail<Building>({
    entity: Building,
    options: { where: { id: "123" } },
    errorText: "Building not found",
  });
  // Use building
} catch (error) {
  // Handle error - throws ApiError with custom message
}

// Real example from service
export const getOneBuilding = async (id: string) => {
  return findOneOrFail<Building>({
    entity: Building,
    options: {
      where: { id },
      relations: ["address", "blocks", "floors"],
    },
    errorText: "Building does not exist",
  });
};
```

### `findManyOrFail`

Find multiple entities or throw an error if none found.

```typescript
import { findManyOrFail } from "@/services/database";
import { Floor } from "@/database/entities/Floor";

try {
  const floors = await findManyOrFail<Floor>({
    entity: Floor,
    options: {
      where: { building: { id: "123" } },
    },
    errorText: "No floors found for this building",
  });
  // Use floors
} catch (error) {
  // Handle error
}
```

### `count`

Count entities (excludes soft-deleted records).

```typescript
import { count } from "@/services/database";
import { Room } from "@/database/entities/Room";

// Count active rooms
const activeCount = await count<Room>({
  entity: Room,
  options: {
    where: { status: RoomStatus.ACTIVE },
  },
});

// Count with relations
const count = await count<Room>({
  entity: Room,
  options: {
    where: { building: { id: "123" } },
  },
});
```

### `countWithDeleted`

Count entities including soft-deleted records.

```typescript
import { countWithDeleted } from "@/services/database";
import { Room } from "@/database/entities/Room";

// Count all rooms including deleted
const totalCount = await countWithDeleted<Room>({
  entity: Room,
  options: {
    where: { building: { id: "123" } },
  },
});
```

### `findByIds`

Find entities by a list of IDs.

```typescript
import { findByIds } from "@/services/database";
import { Room } from "@/database/entities/Room";

const roomIds = ["1", "2", "3"];
const rooms = await findByIds<Room>(
  Room,
  {
    where: { id: In(roomIds) },
    relations: ["building"],
  },
);
```

---

## Insert/Update Functions

### `saveOne`

Save a single entity (create or update).

```typescript
import { saveOne } from "@/services/database";
import { Building } from "@/database/entities/Building";

// Create new building
const newBuilding = await saveOne<Building>({
  entity: Building,
  data: {
    name: "Sunrise Apartments",
    status: BuildingStatus.ACTIVE,
    numberOfFloors: 5,
  },
});

// Update existing building
const updatedBuilding = await saveOne<Building>({
  entity: Building,
  data: {
    id: "123",
    name: "Updated Building Name",
    status: BuildingStatus.ACTIVE,
  },
});

// With transaction
await AppDataSource.transaction(async (tx) => {
  const building = await saveOne<Building>({
    entity: Building,
    data: buildingData,
    transactionalEntityManager: tx,
  });

  // Related entities are part of the same transaction
  await saveOne<Address>({
    entity: Address,
    data: addressData,
    transactionalEntityManager: tx,
  });
});
```

### `saveMany`

Save multiple entities in a single operation.

```typescript
import { saveMany } from "@/services/database";
import { Room } from "@/database/entities/Room";

// Create multiple rooms
const rooms = await saveMany<Room>({
  entity: Room,
  data: [
    {
      name: "Room 101",
      floor: { id: "1" },
      roomType: { id: "1" },
    },
    {
      name: "Room 102",
      floor: { id: "1" },
      roomType: { id: "1" },
    },
  ],
});

// With save options (reload, chunk, etc.)
const rooms = await saveMany<Room>({
  entity: Room,
  data: roomDataArray,
  options: {
    reload: true, // Return updated entities
  },
});
```

### `update`

Update entities matching criteria without loading them first.

```typescript
import { update } from "@/services/database";
import { Building } from "@/database/entities/Building";

// Update building status
const result = await update<Building>({
  entity: Building,
  options: { id: "123" },
  data: {
    status: BuildingStatus.INACTIVE,
    updatedAt: new Date(),
  },
});

// Update multiple records
const result = await update<Building>({
  entity: Building,
  options: {
    status: BuildingStatus.ACTIVE,
  },
  data: {
    updatedAt: new Date(),
  },
});

// Result contains: { generatedMaps: [], raw: [], affected: number }
```

---

## Delete Functions

### `softDeleteOne`

Soft delete a single entity by criteria.

```typescript
import { softDeleteOne } from "@/services/database";
import { Building } from "@/database/entities/Building";

try {
  await softDeleteOne<Building>({
    entity: Building,
    where: { id: "123" },
  });
  // Building's deletedAt timestamp is set
} catch (error) {
  // Error thrown if entity not found
}

// With transaction
await AppDataSource.transaction(async (tx) => {
  await softDeleteOne<Building>({
    entity: Building,
    where: { id: "123" },
    transactionalEntityManager: tx,
  });
  // Other transactional operations
});
```

### `softDeleteMany`

Soft delete multiple entities by criteria.

```typescript
import { softDeleteMany } from "@/services/database";
import { Room } from "@/database/entities/Room";

try {
  await softDeleteMany<Room>({
    entity: Room,
    where: {
      floor: { id: "456" },
    },
  });
  // All rooms on floor 456 are soft deleted
} catch (error) {
  // Error if no entities found
}
```

---

## Utility Functions

### `getPaginationMeta`

Calculate pagination metadata from total count.

```typescript
import { getPaginationMeta } from "@/services/database";

const meta = getPaginationMeta(45, 10, 1);
// Returns:
// {
//   totalDoc: 45,
//   limit: 10,
//   currPage: 1,
//   totalPage: 5,
//   prevPage: 0,
//   nextPage: 2,
//   hasPrevPage: false,
//   hasNextPage: true
// }
```

### `ensureEntitiesExist`

Verify that all entities with given IDs exist. Throws error if any are missing.

```typescript
import { ensureEntitiesExist } from "@/services/database";
import { getRepository } from "@/services/database";
import { Room } from "@/database/entities/Room";

const roomRepo = getRepository(Room);
const roomIds = ["1", "2", "3"];

try {
  const rooms = await ensureEntitiesExist(
    roomRepo,
    roomIds,
    (missingIds) => `Rooms not found: ${missingIds.join(", ")}`
  );
  // All rooms exist, use them
} catch (error) {
  // Some rooms were not found
}

// Real example: Validate room availability
export const validateRoomIds = async (roomIds: string[]) => {
  const roomRepo = getScopedRepository(Room);
  return await ensureEntitiesExist(
    roomRepo,
    roomIds,
    (missing) => `The following rooms are not available: ${missing.join(", ")}`
  );
};
```

### `fetchAllIds`

Fetch all IDs from an entity table. Throws error if table is empty.

```typescript
import { fetchAllIds } from "@/services/database";
import { getRepository } from "@/services/database";
import { Building } from "@/database/entities/Building";

const buildingRepo = getRepository(Building);

try {
  const allBuildingIds = await fetchAllIds(
    buildingRepo,
    "No buildings found in the system"
  );
  // Use the IDs: ["1", "2", "3", ...]
} catch (error) {
  // Table is empty
}
```

---

## Advanced Patterns

### `findWithQueryBuilder`

Use QueryBuilder for complex queries with dynamic conditions.

```typescript
import { findWithQueryBuilder } from "@/services/database";
import { Room } from "@/database/entities/Room";

// Find rooms with complex conditions
const rooms = await findWithQueryBuilder<Room>({
  entity: Room,
  buildWhere: (qb) => {
    return qb
      .where("entity.status = :status", { status: RoomStatus.ACTIVE })
      .andWhere("entity.building = :buildingId", { buildingId: "123" })
      .orderBy("entity.name", "ASC");
  },
  includeSoftDeleted: false,
});

// With joins
const rooms = await findWithQueryBuilder<Room>({
  entity: Room,
  buildWhere: (qb) => {
    return qb
      .leftJoinAndSelect("entity.building", "building")
      .leftJoinAndSelect("entity.floor", "floor")
      .where("building.city = :city", { city: "New York" })
      .andWhere("floor.floorNumber >= :minFloor", { minFloor: 3 });
  },
});
```

### `findDuplicates`

Helper for finding duplicate values (case-insensitive, ignores spaces).

```typescript
import { findDuplicates } from "@/services/database";
import { Room } from "@/database/entities/Room";

// Check for duplicate room names
const roomRepo = getRepository(Room);
let qb = roomRepo.createQueryBuilder("room");

qb = findDuplicates(
  qb,
  "room",
  "name",
  "Room 101", // Value to check (will be normalized)
  "123",      // Exclude current room ID (for updates)
  "building", // Reference column
  "456",      // Reference ID
  true        // Include soft-deleted records
);

const duplicates = await qb.getMany();
// Returns any rooms with name matching "room 101" (case-insensitive, no spaces)
```

---

## Complete Real-World Examples

### Example 1: Create Building with Address (Transaction)

```typescript
import { saveOne } from "@/services/database";
import { Building } from "@/database/entities/Building";
import { Address } from "@/database/entities/Address";
import AppDataSource from "@/database/dataSource";
import { AddressTypeEnum } from "@/shared/constants/address.constants";

export const createBuildingWithAddress = async (
  buildingData: Partial<Building>,
  addressData: Partial<Address>
) => {
  return AppDataSource.transaction(async (tx) => {
    // Save building first
    const building = await saveOne<Building>({
      entity: Building,
      data: buildingData,
      transactionalEntityManager: tx,
    });

    // Save address linked to building
    const address = await saveOne<Address>({
      entity: Address,
      data: {
        ...addressData,
        addressableId: building.id,
        addressableType: AddressTypeEnum.BUILDING,
      },
      transactionalEntityManager: tx,
    });

    return { building, address };
  });
};
```

### Example 2: Get Active Rooms with Pagination

```typescript
import { findManyWithPagination } from "@/services/database";
import { Room } from "@/database/entities/Room";
import { BasePaginationOption } from "@/shared/transformers/pagination.transformer";
import { RoomStatus } from "@/shared/constants/room.constants";

export const getActiveRoomsPaginated = async (
  buildingId: string,
  page: number,
  limit: number
) => {
  const { data, meta } = await findManyWithPagination<Room>({
    entity: Room,
    options: {
      where: {
        building: { id: buildingId },
        status: RoomStatus.ACTIVE,
      },
      relations: ["building", "floor", "roomType"],
    },
    paginationOptions: new BasePaginationOption({ page, limit }),
  });

  return { data, meta };
};
```

### Example 3: Update Building Status with Validation

```typescript
import { findOneOrFail, update } from "@/services/database";
import { Building } from "@/database/entities/Building";
import { BadRequestError } from "@/utils/apiErrors";
import { BuildingStatus } from "@/shared/constants/building.constants";

export const updateBuildingStatus = async (
  buildingId: string,
  newStatus: BuildingStatus
) => {
  // Verify building exists
  const building = await findOneOrFail<Building>({
    entity: Building,
    options: { where: { id: buildingId } },
    errorText: "Building not found",
  });

  // Business rule validation
  if (building.status === BuildingStatus.INACTIVE && newStatus === BuildingStatus.ACTIVE) {
    // Check if building has active floors
    const floorCount = await count<Floor>({
      entity: Floor,
      options: {
        where: {
          building: { id: buildingId },
          status: FloorStatus.ACTIVE,
        },
      },
    });

    if (floorCount === 0) {
      throw new BadRequestError("Cannot activate building without active floors");
    }
  }

  // Perform update
  await update<Building>({
    entity: Building,
    options: { id: buildingId },
    data: { status: newStatus },
  });

  return { ...building, status: newStatus };
};
```

### Example 4: Soft Delete with Cascade Check

```typescript
import { findOneOrFail, softDeleteOne, count } from "@/services/database";
import { Building } from "@/database/entities/Building";
import { Room } from "@/database/entities/Room";
import { BadRequestError } from "@/utils/apiErrors";

export const deleteBuilding = async (buildingId: string) => {
  // Verify building exists
  await findOneOrFail<Building>({
    entity: Building,
    options: { where: { id: buildingId } },
    errorText: "Building not found",
  });

  // Check for active rooms
  const activeRoomCount = await count<Room>({
    entity: Room,
    options: {
      where: {
        building: { id: buildingId },
      },
    },
  });

  if (activeRoomCount > 0) {
    throw new BadRequestError(
      "Cannot delete building with active rooms. Please remove all rooms first."
    );
  }

  // Safe to delete
  await softDeleteOne<Building>({
    entity: Building,
    where: { id: buildingId },
  });

  return { message: "Building deleted successfully" };
};
```

### Example 5: Bulk Operation with Transaction

```typescript
import { saveMany, findOneOrFail } from "@/services/database";
import { Room } from "@/database/entities/Room";
import AppDataSource from "@/database/dataSource";

export const assignRoomsToFloor = async (
  floorId: string,
  roomNames: string[],
  roomTypeId: string
) => {
  // Verify floor exists
  await findOneOrFail<Floor>({
    entity: Floor,
    options: { where: { id: floorId } },
    errorText: "Floor not found",
  });

  return AppDataSource.transaction(async (tx) => {
    // Prepare room data
    const roomData = roomNames.map((name) => ({
      name,
      floor: { id: floorId },
      roomType: { id: roomTypeId },
      status: RoomStatus.AVAILABLE,
    }));

    // Save all rooms in single operation
    const rooms = await saveMany<Room>({
      entity: Room,
      data: roomData,
      transactionalEntityManager: tx,
    });

    return {
      message: `Successfully created ${rooms.length} rooms`,
      rooms,
    };
  });
};
```

---

## Best Practices

### ✅ DO

1. **Use transactions for multi-entity operations**
   ```typescript
   AppDataSource.transaction(async (tx) => {
     // All operations here are atomic
   });
   ```

2. **Use `getScopedRepository` for transactional code**
   ```typescript
   const repo = getScopedRepository(Entity, txManager);
   ```

3. **Use `findOneOrFail` when entity must exist**
   ```typescript
   const entity = await findOneOrFail({
     entity: Building,
     errorText: "Building not found",
   });
   ```

4. **Include proper error messages**
   ```typescript
   errorText: "Building with ID 123 not found"
   ```

5. **Use relations in options, not separate queries**
   ```typescript
   options: {
     relations: ["building", "floor", "roomType"]
   }
   ```

### ❌ DON'T

1. **Don't query database in controllers**
   - Keep queries in services

2. **Don't forget transactionalEntityManager in transactions**
   ```typescript
   // Wrong
   saveOne({ entity: Building, data }) // in transaction

   // Right
   saveOne({ entity: Building, data, transactionalEntityManager: tx })
   ```

3. **Don't use `update` for single entities you need to return**
   - Use `saveOne` instead

4. **Don't forget `withDeleted: true` when checking soft-deleted records**
   ```typescript
   // Wrong
   const entity = await findOne({ entity: Building, options: { where: { id: "1" } } })

   // Right
   const entity = await findOne({
     entity: Building,
     options: { where: { id: "1" }, withDeleted: true }
   })
   ```

5. **Don't ignore error handling for `*OrFail` functions**
   - Always use try-catch or let them bubble up

---

## Type Safety

All functions are fully typed with generics:

```typescript
// TypeScript infers return type
const building: Building = await findOneOrFail<Building>({
  entity: Building,
  options: { where: { id: "123" } },
  errorText: "Not found",
});

// Arrays are properly typed
const buildings: Building[] = await findMany<Building>({
  entity: Building,
});

// Pagination returns typed result
const { data, meta }: {
  data: Building[];
  meta: PaginationMeta;
} = await findManyWithPagination<Building>({
  entity: Building,
  paginationOptions: new BasePaginationOption({ page: 1, limit: 10 }),
});
```

---

## Error Handling

```typescript
import { ApiError } from "@/utils/apiErrors";

// findOneOrFail and findManyOrFail throw ApiError
try {
  const building = await findOneOrFail<Building>({
    entity: Building,
    errorText: "Custom error message",
  });
} catch (error) {
  if (error instanceof ApiError) {
    // Handle custom API error
  }
}

// softDeleteOne/softDeleteMany throw Error if entity not found
try {
  await softDeleteOne<Building>({
    entity: Building,
    where: { id: "123" },
  });
} catch (error) {
  // Handle case where entity doesn't exist
}
```

---

## Summary

| Function | Purpose | Returns |
|----------|---------|---------|
| `getRepository` | Get repository | `Repository<Entity>` |
| `getScopedRepository` | Get tx-aware repository | `Repository<Entity>` |
| `findOne` | Find one entity | `Entity \| null` |
| `findMany` | Find many entities | `Entity[]` |
| `findManyWithPagination` | Find with pagination | `{ data, meta }` |
| `findOneOrFail` | Find or throw | `Entity` |
| `findManyOrFail` | Find many or throw | `Entity[]` |
| `saveOne` | Save single entity | `Entity` |
| `saveMany` | Save multiple | `Entity[]` |
| `update` | Update by criteria | `UpdateResult` |
| `softDeleteOne` | Soft delete one | `Entity` |
| `softDeleteMany` | Soft delete many | `Entity[]` |
| `count` | Count (no soft deletes) | `number` |
| `countWithDeleted` | Count all | `number` |
| `findByIds` | Find by IDs | `Entity[]` |
| `ensureEntitiesExist` | Validate IDs exist | `Entity[]` |
| `fetchAllIds` | Get all IDs | `string[]` |
| `findWithQueryBuilder` | Complex queries | `Entity[]` |
| `findDuplicates` | Check duplicates | `SelectQueryBuilder` |
| `getPaginationMeta` | Calculate metadata | `PaginationMeta` |
