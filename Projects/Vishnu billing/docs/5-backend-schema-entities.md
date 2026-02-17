# Backend Schema Entities (`convex/schema.ts`)

## ERD-like Description

```text
users
  - standalone profile-like record (currently treated as a single default user)

contacts (customers)
  1 ───────────────< many
                      invoices
                        - required FK: customerId -> contacts._id
                        - embedded items[] (no separate invoice_items table)

products
  1 ───────────────< many (optional links)
                      invoices.items[].productId -> products._id

invoices
  0..1 ────────────> _storage
                      invoices.pdfStorageId -> _storage._id

systemMeta
  - standalone key/value settings table
```

## Tables / Collections

### `users`

| Field | Type | Required | Notes |
|---|---|---|---|
| `name` | `string` | Yes | Display name |

Indexes:
- `by_name` on `[name]`

---

### `contacts`

| Field | Type | Required | Notes |
|---|---|---|---|
| `name` | `string` | Yes | Customer name |
| `phone` | `string` | Yes | Customer phone |
| `initials` | `string` | Yes | Auto-generated from name |
| `color` | `string` | Yes | Auto-generated color token (hex) |
| `address` | `string` | Yes | Customer address |
| `district` | `string` | No | Tamil Nadu district |
| `gstin` | `string` | No | Tax id |
| `dlNo` | `string` | No | Drug license number |
| `deletedAt` | `string` | No | ISO timestamp for soft delete |

Indexes:
- `by_name` on `[name]`
- `by_deletedAt` on `[deletedAt]`

Search indexes:
- `search_name` on `name`
- `search_phone` on `phone`

---

### `products`

| Field | Type | Required | Notes |
|---|---|---|---|
| `name` | `string` | Yes | Product name |
| `price` | `number` | Yes | Stored in paise |
| `unit` | `string` | Yes | Unit label (kg, pcs, etc.) |
| `deletedAt` | `string` | No | ISO timestamp for soft delete |

Indexes:
- `by_name` on `[name]`
- `by_deletedAt` on `[deletedAt]`

Search indexes:
- `search_name` on `name`

---

### `invoices`

| Field | Type | Required | Notes |
|---|---|---|---|
| `invoiceNumber` | `string` | Yes | Generated as `INV-{timestamp}-{random}` |
| `customerId` | `id("contacts")` | Yes | Required reference to contact |
| `customerName` | `string` | Yes | Snapshot value |
| `customerPhone` | `string` | Yes | Snapshot value |
| `customerAddress` | `string` | Yes | Snapshot value |
| `customerGstin` | `string` | No | Snapshot value |
| `customerDlNo` | `string` | No | Snapshot value |
| `subtotal` | `number` | Yes | Paise |
| `totalDiscount` | `number` | Yes | Paise |
| `tax` | `number` | Yes | Paise |
| `total` | `number` | Yes | Paise |
| `amountPaid` | `number` | Yes | Paise |
| `date` | `string` | Yes | ISO/local date string |
| `status` | `"unpaid" \| "partial" \| "paid"` | Yes | Derived from `amountPaid` vs `total` in mutations |
| `items` | `Array<InvoiceItem>` | Yes | Embedded line items |
| `pdfStorageId` | `id("_storage")` | No | Optional file pointer |
| `deletedAt` | `string` | No | ISO timestamp for soft delete |

`InvoiceItem` (embedded object):
- `id?: string` (currently optional for migration compatibility)
- `productId?: id("products")`
- `name: string`
- `description: string`
- `price: number` (paise)
- `quantity: number`
- `discount?: { value: number; type: "flat" | "percent" }`

Indexes:
- `by_deletedAt` on `[deletedAt]`
- `by_customer` on `[customerId]`
- `by_date` on `[date]`
- `by_status` on `[status]`
- `by_invoiceNumber` on `[invoiceNumber]`
- `by_customer_date` on `[customerId, date]`
- `by_status_date` on `[status, date]`
- `by_customer_status` on `[customerId, status]`
- `by_date_deletedAt` on `[date, deletedAt]`

Search indexes:
- `search_customerName` on `customerName`

---

### `systemMeta`

| Field | Type | Required | Notes |
|---|---|---|---|
| `key` | `string` | Yes | Setting key |
| `value` | `string` | Yes | Setting value (booleans stored as strings) |

Indexes:
- `by_key` on `[key]`

## Relationships

- `invoices.customerId -> contacts._id` (required, many invoices per contact).
- `invoices.items[].productId -> products._id` (optional, many invoice items can point to one product).
- `invoices.pdfStorageId -> _storage._id` (optional attachment).
- `contacts` and `products` are soft-deleted, not hard-deleted.
- Invoice items are denormalized/embedded under `invoices` (no standalone `invoiceItems` table).

## Invariants (Schema + Behavior)

1. Required core entities:
- Contact requires `name`, `phone`, `address`, plus generated `initials` and `color`.
- Product requires `name`, `price`, `unit`.
- Invoice requires customer reference, customer snapshot fields, totals, status, date, and `items[]`.

2. Monetary values:
- Financial fields are stored as integer paise (`price`, `subtotal`, `tax`, `total`, `amountPaid`, etc.).

3. Soft-delete convention:
- `contacts`, `products`, and `invoices` use `deletedAt` for archival.
- List/search queries default to non-deleted unless `includeDeleted` is enabled.

4. Referential constraints (application-level):
- Contact deletion is blocked when non-deleted invoices still reference that contact (`has_invoices`).
- Product deletion is allowed even if referenced by historical invoice items because invoice items carry denormalized `name/description/price`.

5. Derived invoice status:
- `status` is computed from payment state (`unpaid`/`partial`/`paid`) in create/update-payment mutations.
- Payment updates clamp `amountPaid >= 0`.

6. Invoice numbering and item IDs:
- `invoiceNumber` is generated server-side.
- Invoice item `id` is optional in schema for migration compatibility; create flow backfills missing ids.

7. Snapshot semantics:
- Invoice stores customer data (`customerName`, `customerPhone`, etc.) as immutable snapshot fields, so later contact edits do not rewrite historical invoice data.

8. Settings/user bootstrap behavior:
- `systemMeta` toggles are persisted as string values (`"true"`/`"false"`).
- `users` table is treated as a single-record profile and auto-seeded via `ensureDefault` if empty.

## Frontend Impact (Where Entities Are Used)

### Domain Entities

| Entity | App Domain | Primary UI/Hooks |
|---|---|---|
| `contacts` | Contacts + Invoice customer selection | `hooks/useContacts.ts`, `app/(tabs)/contact.tsx`, `app/contact/create.tsx`, `app/contact/[id].tsx`, `hooks/useCreateInvoice.ts`, `app/invoice/create.tsx` |
| `products` | Product catalog + Invoice line items | `hooks/useProducts.ts`, `app/(tabs)/product.tsx`, `app/product/create.tsx`, `app/product/[id].tsx`, `hooks/useCreateInvoice.ts`, `app/invoice/create.tsx` |
| `invoices` | Invoice lifecycle (create/list/detail/pay/share/archive) | `hooks/useInvoices.ts`, `app/(tabs)/invoice.tsx`, `app/invoice/create.tsx`, `app/invoice/[id].tsx`, `hooks/useInvoiceShare.ts`, `app/(tabs)/index.tsx`, `components/home/InvoiceStatsChart.tsx` |

### Supporting Entities

| Entity | Purpose | Primary UI/Hooks |
|---|---|---|
| `systemMeta` | Settings toggles (show archived contacts/products/invoices) | `hooks/useSettings.ts`, `app/settings.tsx`, indirectly used by `hooks/useContacts.ts`, `hooks/useProducts.ts`, `hooks/useInvoices.ts` |
| `users` | Home greeting / simple profile seed | `hooks/useUser.ts`, `app/(tabs)/index.tsx`, `components/home/HomeHeader.tsx` |
| `_storage` via `invoices.pdfStorageId` | Optional invoice PDF attachment | backend available in `convex/files.ts` and `convex/invoices.ts` (no active UI path currently) |

### Cross-domain Read Models

- District analytics combines invoices + contacts (`invoice.customerId -> contact.district`) for the map view:
- `convex/districtStats.ts`
- `hooks/useDistrictStats.ts`
- `components/home/TamilNaduMap.tsx`

## Domain Mapping Summary

- `contacts` table maps to the **Contacts** domain.
- `products` table maps to the **Products** domain.
- `invoices` table (with embedded `items`) maps to the **Invoices/Billing** domain.
- `systemMeta` and `users` are supporting system-domain entities.
