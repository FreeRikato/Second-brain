## 1. The Core Problem: Precision Mismatch
The fundamental reason we represent `BIGINT` as `string` in TypeScript is a mismatch between the data limits of PostgreSQL and JavaScript.

*   **PostgreSQL `BIGINT`**: A 64-bit signed integer. Max value: $2^{63}-1$ ($9,223,372,036,854,775,807$).
*   **JavaScript `Number`**: A 64-bit float (IEEE 754). It can only safely represent integers up to $2^{53}-1$ ($9,007,199,254,740,991$).
*   **The Conflict**: If a database ID exceeds the "Safe Integer" limit in JavaScript, the number will be rounded/truncated, leading to data corruption and broken relationships.

## 2. The Solution: String Representation
To preserve absolute precision, large numeric values are handled as **strings** within the application layer.

*   **Principle**: Data integrity is more important than type "correctness" (using a number type for a number value).
*   **Implementation**: Use the `string` type in TypeScript entities while maintaining the `bigint` type in the database schema.

## 3. The Mechanics: Who, Where, and When?
The conversion does not happen in TypeORM or the application logic; it happens at the **Database Driver** level.

### The Actor: `node-postgres` (`pg`)
TypeORM uses the `pg` driver to communicate with PostgreSQL. This driver includes a built-in type parser for various PostgreSQL Object Identifiers (OIDs).

### The Flow:
1.  **Reading (DB → App)**:
    *   PostgreSQL returns a `BIGINT` (OID 20).
    *   The `pg` driver intercepts this and automatically converts it to a `string`.
    *   TypeORM receives the string and assigns it to the entity property.
2.  **Writing (App → DB)**:
    *   The application provides a `string` (e.g., `"12345"`).
    *   The `pg` driver sends this string to PostgreSQL.
    *   PostgreSQL implicitly casts the string into the `BIGINT` column during the `INSERT`/`UPDATE` operation.

## 4. Entity Pattern
When defining entities, the decorator and the property type serve two different masters:

```typescript
@Column({ type: "bigint", nullable: true })
// ^ Tells TypeORM/PostgreSQL what to store in the DB.
modifiedBy: string | null;
// ^ Tells TypeScript what the data will look like in the code.
```

### Key Takeaways
*   **Safety First**: Always type `BIGINT` as `string` in TypeScript to avoid the "9-quadrillion" limit.
*   **Automatic Parsing**: You don't need manual `toString()` or `parseInt()` calls; the `pg` driver handles the bridge.
*   **Consistency**: Follow the pattern used in `BaseSerialEntity` where `id` is a `bigint` column but typed as `string`.