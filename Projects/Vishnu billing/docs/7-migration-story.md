# Convex Migration Story

## Scope Reviewed

- `convex/migrations.ts`
- `convex/migrations/addInvoiceItemIds.ts`
- `convex/schema.ts`
- `convex/invoices.ts`
- Git history for the files above

## Timeline Of Schema Evolution

| Date | Commit | What changed | File references |
| --- | --- | --- | --- |
| 2026-01-30 | `973c089` | Initial Convex schema landed. Invoices stored embedded `items` but item-level `id` was not part of the schema validator yet. | `convex/schema.ts` (introduced in this commit) |
| 2026-01-30 | `4c3fc50` | Invoice item `id` was added to schema as required at this point. Invoice create flow also started generating `id` when client input omitted it. | `convex/schema.ts` (invoice item validator), `convex/invoices.ts` (create normalization logic) |
| 2026-01-31 | `5742815` | Performance/indexing update: added search/index coverage, including phone/customer search and several invoice composite indexes. | `convex/schema.ts` |
| 2026-01-31 | `0d6b49a` | Added soft-delete fields/indexes to contacts and products. Invoice item `id` in schema was intentionally relaxed from required to optional to support migration window. | `convex/schema.ts` |
| 2026-01-31 | `f6499ff` | Added migration functions to backfill missing `items[].id` values on existing invoices. | `convex/migrations.ts`, `convex/migrations/addInvoiceItemIds.ts` |
| 2026-02-03 | `8b6630e` | Added optional `district` to contacts schema (additive change, no mandatory data rewrite). | `convex/schema.ts` |

## Backward Compatibility Expectations

1. Invoice item IDs are in a compatibility phase.
   - Current schema keeps `items[].id` optional and labels it temporary for migration (`convex/schema.ts:6`).
   - New invoice writes auto-fill missing item IDs (`convex/invoices.ts:145`).
   - Existing invoices without IDs are handled by backfill migrations (`convex/migrations.ts:29`, `convex/migrations/addInvoiceItemIds.ts:12`).

2. Migration behavior is idempotent and safe to re-run.
   - Both migration implementations only patch invoices where an item is missing `id` (`convex/migrations.ts:31`, `convex/migrations/addInvoiceItemIds.ts:14`).
   - ID generation is deterministic per run shape: `item-${invoice._id}-${index}` (`convex/migrations.ts:34`, `convex/migrations/addInvoiceItemIds.ts:17`).

3. Soft-delete and district fields are additive.
   - `contacts.deletedAt` and `products.deletedAt` are optional, so older rows remain valid (`convex/schema.ts:36`, `convex/schema.ts:48`).
   - `contacts.district` is optional, so no backfill is required (`convex/schema.ts:33`).

## How Migrations Relate To Current Schema

1. Main relationship: invoice item ID backfill.
   - The schema currently allows missing `items[].id` (`convex/schema.ts:6`) because legacy invoices may still exist.
   - Migration code exists to remove that legacy state by patching old documents (`convex/migrations.ts:20`, `convex/migrations/addInvoiceItemIds.ts:3`).

2. Current schema is intentionally more permissive than the likely target state.
   - Temporary comment in schema indicates eventual tightening (`convex/schema.ts:6`).
   - `convex/migrations.ts` is explicitly marked temporary and intended for deletion after successful run (`convex/migrations.ts:4`).

3. Practical expectation after migration completion.
   - Verify no invoice items are missing IDs.
   - Tighten `items[].id` back to required in schema.
   - Remove temporary migration trigger(s) once rollout is confirmed.

## Notes

- There are two migration implementations with nearly identical logic:
  - Public/manual trigger: `convex/migrations.ts`
  - Internal mutation: `convex/migrations/addInvoiceItemIds.ts`
- In the current codebase, no other file invokes `addInvoiceItemIds` directly; operationally, the documented manual trigger is `runAddInvoiceItemIdsMigration`.
