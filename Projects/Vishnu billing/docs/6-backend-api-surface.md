# Backend API Surface (`convex/*`)

## Function Inventory

| Scope | Queries | Mutations | Actions |
|---|---:|---:|---:|
| Public (`api.*`) | 15 | 17 | 0 |
| Internal (`internal.*`) | 0 | 1 | 0 |

- Note: there are no Convex `action`/`internalAction` functions in this repo.

## API Catalog

### `contacts`

| Function | Args | Returns | Side effects | Called by screens/components |
|---|---|---|---|---|
| `contacts.list` (query) | `{ includeDeleted?: boolean }` | `contacts[]` (max 50) | Reads `contacts`; filters `deletedAt` via index when `includeDeleted` is false | `hooks/useContacts.ts` -> `app/(tabs)/contact.tsx`, `app/contact/create.tsx`; `hooks/useCreateInvoice.ts` -> `app/invoice/create.tsx` |
| `contacts.search` (query) | `{ query: string; includeDeleted?: boolean }` | `contacts[]` (max 50) | Search index read (`search_name`), optional deleted filtering | No current caller |
| `contacts.get` (query) | `{ id: Id<"contacts"> }` | `contact | null` | Point read by id | `app/contact/[id].tsx` |
| `contacts.create` (mutation) | `{ name: string; phone: string; address: string; district?: string; gstin?: string; dlNo?: string }` | `contact | null` | Inserts contact; server generates `initials` and random `color` | Exposed by `hooks/useContacts.ts`; invoked in `app/contact/create.tsx` |
| `contacts.update` (mutation) | `{ id: Id<"contacts">; name?: string; phone?: string; address?: string; district?: string; gstin?: string; dlNo?: string; color?: string }` | `contact | null` | Patches mutable fields; recomputes `initials` if `name` changes | Invoked in `app/contact/[id].tsx` (also bound in `hooks/useContacts.ts`) |
| `contacts.remove` (mutation) | `{ id: Id<"contacts"> }` | `{ success: true }` or `{ success: false; reason: "has_invoices" }` | Checks non-deleted invoices by `customerId`; soft-deletes contact via `deletedAt` | Invoked in `app/contact/[id].tsx` (also bound in `hooks/useContacts.ts`) |

### `products`

| Function | Args | Returns | Side effects | Called by screens/components |
|---|---|---|---|---|
| `products.list` (query) | `{ includeDeleted?: boolean }` | `products[]` (max 50) | Reads `products`; filters `deletedAt` via index when `includeDeleted` is false | `hooks/useProducts.ts` -> `app/(tabs)/product.tsx`, `app/product/create.tsx`; `hooks/useCreateInvoice.ts` -> `app/invoice/create.tsx` |
| `products.search` (query) | `{ query: string; includeDeleted?: boolean }` | `products[]` (max 50) | Search index read (`search_name`), optional deleted filtering | No current caller |
| `products.get` (query) | `{ id: Id<"products"> }` | `product | null` | Point read by id | `app/product/[id].tsx` |
| `products.create` (mutation) | `{ name: string; price: number; unit: string }` | `product | null` | Inserts product | Exposed by `hooks/useProducts.ts`; invoked in `app/product/create.tsx` |
| `products.update` (mutation) | `{ id: Id<"products">; name?: string; price?: number; unit?: string }` | `product | null` | Patches product | Invoked in `app/product/[id].tsx` (also bound in `hooks/useProducts.ts`) |
| `products.remove` (mutation) | `{ id: Id<"products"> }` | `{ success: true }` | Soft-deletes product via `deletedAt` | Invoked in `app/product/[id].tsx` (also bound in `hooks/useProducts.ts`) |

### `invoices`

| Function | Args | Returns | Side effects | Called by screens/components |
|---|---|---|---|---|
| `invoices.list` (query) | `{ includeDeleted?: boolean }` | `invoices[]` (max 50) | Reads `invoices`; filters `deletedAt` via index when `includeDeleted` is false | `hooks/useInvoices.ts` -> `app/(tabs)/invoice.tsx`, `app/(tabs)/index.tsx` |
| `invoices.search` (query) | `{ query: string; status?: "unpaid" \| "partial" \| "paid"; includeDeleted?: boolean }` | `invoices[]` (max 50) | Search index read (`search_customerName`), optional deleted/status filtering | `hooks/useInvoices.ts` (used when search text is non-empty) -> `app/(tabs)/invoice.tsx`, `app/(tabs)/index.tsx` |
| `invoices.get` (query) | `{ id: Id<"invoices"> }` | `invoice | null` | Point read by id | `app/invoice/[id].tsx` |
| `invoices.getByNumber` (query) | `{ invoiceNumber: string }` | `invoice | null` | Indexed lookup on `by_invoiceNumber` | No current caller |
| `invoices.create` (mutation) | `{ customerId, customerName, customerPhone, customerAddress, customerGstin?, customerDlNo?, subtotal, totalDiscount, tax, total, amountPaid, date, items[] }` | `invoice | null` | Generates `invoiceNumber`; calculates `status`; backfills missing line-item ids; inserts invoice | Invoked in `app/invoice/create.tsx` |
| `invoices.updateStatus` (mutation) | `{ id: Id<"invoices">; status: "unpaid" \| "partial" \| "paid" }` | `{ success: true }` | Patches invoice status | No current caller |
| `invoices.updatePayment` (mutation) | `{ id: Id<"invoices">; amountPaid: number }` | `{ success: false }` or `{ success: true; newStatus: "unpaid" \| "partial" \| "paid"; newAmountPaid: number }` | Reads invoice, clamps `amountPaid >= 0`, recalculates `status`, patches invoice | Invoked in `app/invoice/[id].tsx` (also bound in `hooks/useInvoices.ts`) |
| `invoices.attachPdf` (mutation) | `{ invoiceId: Id<"invoices">; storageId: Id<"_storage"> }` | `{ success: true }` | Patches `invoices.pdfStorageId` | No current caller |
| `invoices.remove` (mutation) | `{ id: Id<"invoices"> }` | `{ success: true }` | Soft-deletes invoice via `deletedAt` | Invoked in `app/invoice/[id].tsx` (also bound in `hooks/useInvoices.ts`) |

### `files`

| Function | Args | Returns | Side effects | Called by screens/components |
|---|---|---|---|---|
| `files.generateUploadUrl` (mutation) | `{}` | `string` (upload URL) | Calls `ctx.storage.generateUploadUrl()` | No current caller |
| `files.attachPdfToInvoice` (mutation) | `{ invoiceId: Id<"invoices">; storageId: Id<"_storage"> }` | `{ success: true }` | Patches `invoices.pdfStorageId` | No current caller |
| `files.getInvoicePdfUrl` (query) | `{ invoiceId: Id<"invoices"> }` | `string \| null` | Reads invoice; calls `ctx.storage.getUrl` if `pdfStorageId` exists | No current caller |

### `users`

| Function | Args | Returns | Side effects | Called by screens/components |
|---|---|---|---|---|
| `users.getCurrent` (query) | `{}` | `user \| null` | Reads first `users` record | `hooks/useUser.ts` -> `app/(tabs)/index.tsx` |
| `users.ensureDefault` (mutation) | `{}` | `user` (existing or newly inserted default `{ name: "User" }`) | Inserts default user only when table is empty | `hooks/useUser.ts` (inside effect) -> `app/(tabs)/index.tsx` |

### `systemMeta`

| Function | Args | Returns | Side effects | Called by screens/components |
|---|---|---|---|---|
| `systemMeta.getSettings` (query) | `{}` | `Record<string, string>` | Reads all `systemMeta` and materializes key/value map | `hooks/useSettings.ts` -> `app/settings.tsx`; also indirectly via `hooks/useContacts.ts`, `hooks/useProducts.ts`, `hooks/useInvoices.ts` -> `app/(tabs)/contact.tsx`, `app/contact/create.tsx`, `app/(tabs)/product.tsx`, `app/product/create.tsx`, `app/(tabs)/invoice.tsx`, `app/(tabs)/index.tsx` |
| `systemMeta.getSetting` (query) | `{ key: string }` | `string \| null` | Indexed lookup on `by_key` | No current caller |
| `systemMeta.updateSetting` (mutation) | `{ key: string; value: string }` | `{ success: true }` | Upsert-like update/insert on `systemMeta` | Bound in `hooks/useSettings.ts` as `_updateSetting` but not invoked |
| `systemMeta.toggleSetting` (mutation) | `{ key: string }` | `{ success: true; value: "true" \| "false" }` | Flips string boolean (`"true"`/`"false"`), creating key if missing | `hooks/useSettings.ts` -> invoked by `app/settings.tsx` toggle UI |

### `districtStats`

| Function | Args | Returns | Side effects | Called by screens/components |
|---|---|---|---|---|
| `districtStats.getByDistrict` (query) | `{}` | `DistrictStats[]` with `{ district, totalInvoices, totalAmount, paidAmount, paidRatio }` | Reads all non-deleted invoices; reads each invoice's contact; computes aggregate map in memory | `hooks/useDistrictStats.ts` -> `components/home/TamilNaduMap.tsx` -> `app/(tabs)/index.tsx` |

### `migrations` (operational)

| Function | Args | Returns | Side effects | Called by screens/components |
|---|---|---|---|---|
| `migrations.runAddInvoiceItemIdsMigration` (mutation) | `{}` | `{ success: true; updatedCount: number; totalItemsUpdated: number; totalInvoices: number; message: string }` | Scans all invoices; patches `items[]` to add missing line-item ids | No app caller; intended manual run from Convex dashboard |

### `migrations/addInvoiceItemIds` (internal)

| Function | Args | Returns | Side effects | Called by screens/components |
|---|---|---|---|---|
| `migrations/addInvoiceItemIds.addInvoiceItemIds` (internalMutation) | `{}` | `{ updatedCount: number; totalItemsUpdated: number; totalInvoices: number }` | Scans all invoices; patches `items[]` to add missing line-item ids | No app caller; internal-only function |

## Auth / Permissions Patterns

- No function checks `ctx.auth`, user identity, roles, or per-record ownership.
- All exported app-facing functions are public (`api.*`) except one internal migration function.
- Effective access model today: anyone with client access can call public queries/mutations.
- There is business-rule validation in mutations (for example `contacts.remove` blocks deletion when non-deleted invoices exist), but this is not authentication/authorization.

## Pagination / Sorting / Search Patterns

### Pagination

- No cursor-based pagination (`paginate`) is implemented.
- Contacts/products/invoices `list` and `search` endpoints hard-cap results with `.take(50)`.
- `districtStats.getByDistrict` and migration functions use `.collect()` over full datasets.

### Sorting

- No explicit sort order is applied in backend queries.
- Returned order is Convex default/index order; there is no API-level `sortBy` argument.
- UI layers shown here also do not apply explicit post-fetch sorting for contacts/products/invoices.

### Search

- Backend search indexes exist and are used by:
  - `contacts.search` via `search_name`
  - `products.search` via `search_name`
  - `invoices.search` via `search_customerName`
- `invoices.search` also supports optional `status` filtering server-side.
- Current UI behavior:
  - Contacts/products screens use client-side filtering (`hooks/useSearch`) over `list` results.
  - Invoice screen uses backend `invoices.search` when search text is non-empty.
- Soft-delete filtering is consistently controlled by `includeDeleted` and `deletedAt` checks.

## Unused API Surface (Current App)

- Unused queries: `contacts.search`, `products.search`, `invoices.getByNumber`, `systemMeta.getSetting`, `files.getInvoicePdfUrl`.
- Unused mutations: `invoices.updateStatus`, `invoices.attachPdf`, all `files.*` mutations, `migrations.runAddInvoiceItemIdsMigration` (in-app), and `systemMeta.updateSetting` (bound but not invoked).
- No actions are defined.
