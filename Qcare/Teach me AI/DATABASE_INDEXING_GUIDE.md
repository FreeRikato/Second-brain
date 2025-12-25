# Database Indexing Guide - QCare API

A comprehensive guide to creating and managing database indexes in the QCare TypeORM codebase.

## Table of Contents
1. [What is an Index?](#what-is-an-index)
2. [When to Add Indexes](#when-to-add-indexes)
3. [Types of Indexes](#types-of-indexes)
4. [Entity-Level Indexing](#entity-level-indexing)
5. [Migration-Level Indexing](#migration-level-indexing)
6. [Real-World Examples from Codebase](#real-world-examples-from-codebase)
7. [Best Practices](#best-practices)
8. [Common Pitfalls](#common-pitfalls)

---

## What is an Index?

An index is a database structure that improves the speed of data retrieval operations on a table at the cost of additional writes and storage space.

**Think of it like a book index:**
- Without index: You scan every page to find a topic (slow)
- With index: You jump directly to the page number (fast)

---

## When to Add Indexes

Add indexes when you have:

### ✅ Good Candidates for Indexing

1. **Columns frequently used in WHERE clauses**
   ```typescript
   // If you frequently query by status
   repository.find({ where: { status: 'ACTIVE' } })
   ```

2. **Columns used in JOIN conditions**
   ```typescript
   // Foreign keys used in relations
   @ManyToOne(() => Building)
   @JoinColumn({ name: 'building' })
   building: Building;
   ```

3. **Columns used in ORDER BY clauses**
   ```typescript
   repository.find({
     order: { createdAt: 'DESC' }
   })
   ```

4. **Composite queries (multiple columns together)**
   ```typescript
   // If you always query by both columns
   repository.find({
     where: { addressableId: '123', addressableType: 'BUILDING' }
   })
   ```

### ❌ Don't Index

- Columns with very low cardinality (e.g., boolean flags with only 2 values)
- Columns that are frequently updated
- Small tables (< 1000 rows)
- Tables that are write-heavy but rarely read

---

## Types of Indexes

### 1. Single Column Index

Index on a single column:

```typescript
@Entity({ name: 'users' })
@Index(['email'])  // Single column index
export class User {
  @Column()
  email: string;
}
```

### 2. Composite (Multi-Column) Index

Index on multiple columns:

```typescript
@Entity({ name: 'address' })
@Index(['addressableId', 'addressableType'])  // Composite index
export class Address {
  @Column()
  addressableId: string;

  @Column()
  addressableType: string;
}
```

**Important:** The order of columns in a composite index matters!
- Query must use the leftmost column(s) to benefit
- `@Index(['col1', 'col2'])` helps queries for: `col1`, `col1 + col2`, but NOT `col2` alone

### 3. Unique Index

Ensures no duplicate values:

```typescript
@Entity({ name: 'buildings' })
@Unique(['name'])  // Unique index
export class Building {
  @Column()
  name: string;
}
```

### 4. Column-Level Unique

```typescript
export class User {
  @Column({ unique: true })  // Direct on column
  email: string;
}
```

---

## Entity-Level Indexing

### Method 1: Using @Index Decorator

**Basic Usage:**

```typescript
import { Entity, Index, Column } from 'typeorm';

@Entity({ name: 'cities' })
@Index(['name', 'country'])  // Composite index on name + country
export class City extends BaseSerialEntity {
  @Column({ type: 'varchar' })
  name!: string;

  @ManyToOne(() => Country, (country) => country.id, { nullable: false })
  @JoinColumn({ name: 'country' })
  country!: Country;
}
```

**Named Index:**

```typescript
@Entity({ name: 'rooms' })
@Index(['building', 'floor'], { name: 'idx_room_location' })  // Custom name
export class Room {
  @Column()
  building!: string;

  @Column()
  floor!: string;
}
```

**Unique Index:**

```typescript
@Entity({ name: 'floors' })
@Unique(['type', 'block', 'building'])  // Unique constraint
export class Floor extends BaseSerialEntity {
  @Column({ type: 'enum', enum: FloorTypeEnum })
  type!: FloorTypeEnum;

  @ManyToOne(() => Block)
  @JoinColumn({ name: 'block' })
  block?: Block;

  @ManyToOne(() => Building)
  @JoinColumn({ name: 'building' })
  building?: Building;
}
```

**Multiple Indexes:**

```typescript
@Entity({ name: 'apartments' })
@Index(['floor'])  // First index
@Unique(['floor', 'number'])  // Second index (unique)
export class Apartment extends BaseSerialEntity {
  @Column()
  floor!: string;

  @Column()
  number!: string;

  @Column()
  status!: string;
}
```

### Method 2: Column-Level Index

```typescript
@Entity({ name: 'rooms' })
export class Room {
  @Index()  // Single column index
  @Column()
  meterNumber!: string;

  @Column({ unique: true })  // Unique constraint
  roomIdentifier!: string;
}
```

---

## Migration-Level Indexing

Sometimes you need to add indexes to existing tables without changing the entity. Use migrations for this.

### Creating an Index in Migration

```typescript
import { MigrationInterface, QueryRunner, TableIndex } from 'typeorm';

export class AddIndexesToBookingTable1234567890
  implements MigrationInterface
{
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.createIndex(
      'bookings',
      new TableIndex({
        name: 'idx_booking_status',  // Explicit name
        columnNames: ['status', 'created_at'],  // Composite
      })
    );

    await queryRunner.createIndex(
      'bookings',
      new TableIndex({
        name: 'idx_booking_user',
        columnNames: ['user_id'],
        isUnique: false,
      })
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropIndex('bookings', 'idx_booking_status');
    await queryRunner.dropIndex('bookings', 'idx_booking_user');
  }
}
```

### Dropping an Index in Migration

```typescript
public async down(queryRunner: QueryRunner): Promise<void> {
  await queryRunner.dropIndex('table_name', 'index_name');
}
```

---

## Real-World Examples from Codebase

### Example 1: Polymorphic Relationship Index

**File:** `src/database/entities/Address.entity.ts`

```typescript
@Entity({ name: 'address' })
@Index(['addressableId', 'addressableType'])  // Composite index for polymorphic queries
export class Address extends BaseSerialEntity {
  @Column({ type: 'bigint' })
  addressableId!: string;

  @Column({ type: 'enum', enum: AddressTypeEnum })
  addressableType!: AddressTypeEnum;
}
```

**Why this index?**
- Queries frequently filter by both `addressableId` AND `addressableType`
- Pattern: `WHERE addressableId = ? AND addressableType = ?`
- Composite index is perfect for this

### Example 2: Building-Block Hierarchy Index

**File:** `src/database/entities/Block.entity.ts`

```typescript
@Entity({ name: 'blocks' })
@Index(['name', 'building'])  // Block names are unique within a building
export class Block extends BaseSerialEntity {
  @Column({ type: 'varchar' })
  name!: string;

  @ManyToOne(() => Building, (building) => building.id, { nullable: false })
  @JoinColumn({ name: 'building' })
  building!: Building;
}
```

**Why this index?**
- Business rule: Block names must be unique within a building
- Query pattern: Find blocks by name in a specific building
- `WHERE name = ? AND building = ?`

### Example 3: Unique Floor Type Combinations

**File:** `src/database/entities/Floor.entity.ts`

```typescript
@Entity({ name: 'floors' })
@Unique(['type', 'block', 'building'])  // Unique combination constraint
export class Floor extends BaseSerialEntity {
  @Column({ type: 'enum', enum: FloorTypeEnum })
  type!: FloorTypeEnum;

  @ManyToOne(() => Block, (block) => block.floors)
  @JoinColumn({ name: 'block' })
  block?: Block;

  @ManyToOne(() => Building, (building) => building.floors)
  @JoinColumn({ name: 'building' })
  building?: Building;
}
```

**Why this unique index?**
- Business rule: Can't have duplicate floor types in same block/building
- Prevents data integrity issues
- Ensures only one "Ground Floor" per block

### Example 4: Apartment Number per Floor

**File:** `src/database/entities/Apartment.entity.ts`

```typescript
@Entity({ name: 'apartments' })
@Unique(['floor', 'number'])  // Apartment numbers are unique per floor
export class Apartment extends BaseSerialEntity {
  @ManyToOne(() => Floor, (floor) => floor.apartments, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'floor' })
  floor!: Floor;

  @Column({ type: 'varchar' })
  number!: string;
}
```

**Why this unique index?**
- Business rule: Apartment numbers must be unique within a floor
- Floor 1 can have Apartment 101, Floor 2 can also have Apartment 101
- But Floor 1 cannot have two Apartment 101s

---

## Best Practices

### 1. Index Foreign Keys

Always index foreign key columns used in relationships:

```typescript
@Entity({ name: 'rooms' })
@Index(['building'])  // Index the foreign key
export class Room {
  @ManyToOne(() => Building)
  @JoinColumn({ name: 'building' })
  building!: Building;
}
```

### 2. Use Composite Indexes for Multi-Column Queries

If you always query columns together, use a composite index:

```typescript
// Bad: Two separate indexes
@Index(['status'])
@Index(['createdAt'])

// Good: One composite index (if queried together)
@Index(['status', 'createdAt'])
```

### 3. Name Your Indexes Explicitly

This makes debugging easier:

```typescript
@Entity({ name: 'users' })
@Index(['email'], { name: 'idx_user_email' })  // Explicit name
export class User {
  @Column()
  email!: string;
}
```

### 4. Match Index to Query Pattern

Think about how you query:

```typescript
// Query: WHERE email = ? AND status = ?
@Index(['email', 'status'])  // Correct order

// Query: WHERE status = ? (without email)
@Index(['status'])  // Separate index needed
```

### 5. Consider Write Performance

Remember: Every index slows down INSERT/UPDATE/DELETE operations. Only add indexes you actually need.

### 6. Use Unique Constraints for Business Rules

Enforce data integrity with unique indexes:

```typescript
@Unique(['username'])  // No duplicate usernames
@Unique(['email'])  // No duplicate emails
```

---

## Common Pitfalls

### ❌ Pitfall 1: Indexing Low-Cardinality Columns

```typescript
// Bad: Status only has 3 values (ACTIVE, INACTIVE, PENDING)
@Index(['status'])  // Won't help much

// Better: Composite with another column
@Index(['status', 'createdAt'])  // More selective
```

### ❌ Pitfall 2: Wrong Column Order in Composite Index

```typescript
// Index defined as:
@Index(['firstName', 'lastName'])

// Query:
WHERE lastName = 'Smith'  // Won't use the index efficiently!

// Correct: Match index order to query pattern
// Or create separate index for lastName
```

### ❌ Pitfall 3: Duplicate Indexes

```typescript
// Bad: Same index twice
@Index(['building'])
@Index(['building', 'floor'])  // This includes the first index

// The composite index covers the single column queries too
```

### ❌ Pitfall 4: Over-Indexing

Don't index everything. Indexes have costs:
- Storage space
- Slower INSERT/UPDATE/DELETE
- Maintenance overhead

---

## Quick Reference

### Entity Decorator Syntax

```typescript
// Single column
@Index(['column_name'])

// Composite index
@Index(['col1', 'col2', 'col3'])

// Named index
@Index(['col1'], { name: 'idx_custom_name' })

// Unique constraint
@Unique(['col1', 'col2'])

// Multiple indexes
@Index(['col1'])
@Index(['col2'])
@Unique(['col3'])
```

### Column-Level Syntax

```typescript
// Index on single column
@Index()
@Column()
email: string;

// Unique on single column
@Column({ unique: true })
username: string;
```

### Migration Syntax

```typescript
// Create index
await queryRunner.createIndex(
  'table_name',
  new TableIndex({
    name: 'idx_name',
    columnNames: ['col1', 'col2'],
    isUnique: false,
  })
);

// Drop index
await queryRunner.dropIndex('table_name', 'idx_name');
```

---

## Checklist: Adding an Index

Before adding an index, ask yourself:

1. [ ] Is this column frequently queried?
2. [ ] Will this index actually improve query performance?
3. [ ] Is the table write-heavy? (consider index cost)
4. [ ] Are there existing indexes that cover this query?
5. [ ] Should this be a unique constraint?
6. [ ] What should I name this index?
7. [ ] Do I need to add this in a migration or can I update the entity?

---

## Further Reading

- **TypeORM Documentation on Indexes:** https://typeorm.io/#/entities/indexes
- **PostgreSQL Index Types:** https://www.postgresql.org/docs/current/indexes-types.html
- **Database Performance Tuning:** Consider using `EXPLAIN ANALYZE` to verify index usage

---

## Summary

**Key Takeaways:**

1. **@Index()** for regular indexes
2. **@Unique()** for unique constraints
3. **Composite indexes** for multi-column queries
4. **Column order matters** in composite indexes
5. **Index foreign keys** used in relationships
6. **Name your indexes** for better debugging
7. **Use migrations** for existing tables

**Happy Indexing! 🚀**
