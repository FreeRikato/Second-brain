# Domain CRUD Flows (Contacts, Products, Invoices)

## Scope

This document traces the implemented create/edit/list/detail behavior for:
- Contacts
- Products
- Invoices

Primary sources:
- UI routes in `app/`
- UI composition in `components/`
- Data orchestration in `hooks/`
- Validation helpers in `utils/validation.ts`
- Convex mutations/queries in `convex/`

## Forms and Validation

### Contacts

#### Create flow (`app/contact/create.tsx`)

1. Entry:
- From `app/(tabs)/contact.tsx` via `router.push("/contact/create")`.

2. Form/default state:
- `name`, `phone`, `address`, `gstin`, `dlNo`, `district`, `initials` default to `""`.
- `color` defaults to `generateRandomColor()` (client-side preview only).
- `initials` are recomputed on each name change via `generateInitials`.

3. Validation:
- Uses `validateContact` (`utils/validation.ts`) before submit.
- Zod requirements: name min length, phone min length, address required.

4. Submit behavior:
- Calls `createContact` from `hooks/useContacts.ts`.
- Mutation path: `api.contacts.create` -> `convex/contacts.ts:create`.
- Server generates authoritative `initials` and `color`, inserts contact, returns saved doc.
- No optimistic update.

5. Success/error behavior:
- Success: `Alert.alert("Success", ...)` then `router.back()`.
- Validation failure: `Alert.alert("Error", validation.error)`.
- Mutation failure: catch -> `Alert.alert("Error", "Failed to create contact")`.

#### Edit flow (`app/contact/[id].tsx`)

1. Entry:
- From contact row edit action (`router.push(`/contact/${contact.id}`)`).

2. Fetch and defaults:
- Fetch by id via `useQuery(api.contacts.get, { id })`.
- `useEffect` copies fetched values into local `formData`.

3. Validation:
- Manual required checks in screen:
- `name` non-empty
- `phone` non-empty
- `address` non-empty
- Does not call `validateContact` in edit path.

4. Submit behavior:
- Calls `updateContact` (`api.contacts.update`) with optional trimmed fields.
- No optimistic update.

5. Success/error behavior:
- Success alert + `router.back()`.
- Failed/null result alert.
- Exceptions alert.

6. Delete behavior (same screen):
- Confirm dialog -> `api.contacts.remove`.
- Server blocks delete if active invoices exist (`reason: "has_invoices"`), otherwise soft-deletes via `deletedAt`.
- UI surfaces special blocked-delete message when `has_invoices`.

---

### Products

#### Create flow (`app/product/create.tsx`)

1. Entry:
- From `app/(tabs)/product.tsx` via `router.push("/product/create")`.

2. Form/default state:
- `name`, `price`, `unit` default to `""`.

3. Validation:
- Parses `price` as float.
- Uses `validateProduct` (`utils/validation.ts`).
- Zod checks name/unit constraints; price must be numeric and non-negative.

4. Submit behavior:
- Converts rupees -> paise via `decimalToPaise`.
- Calls `createProduct` (`api.products.create` -> `convex/products.ts:create`).
- No optimistic update.

5. Success/error behavior:
- Success alert + `router.back()`.
- Validation/mutation exceptions surface with `Alert.alert`.

#### Edit flow (`app/product/[id].tsx`)

1. Entry:
- From product row edit action (`router.push(`/product/${product.id}`)`).

2. Fetch and defaults:
- Fetch by id with `api.products.get`.
- `useEffect` preloads form with existing values.
- Price is converted from paise -> decimal string via `paiseToDecimal`.

3. Validation:
- Manual checks in screen:
- `name` non-empty
- `price` numeric and `>= 0`
- `unit` non-empty
- Does not call `validateProduct` in edit path.

4. Submit behavior:
- Converts edited price decimal -> paise.
- Calls `updateProduct` (`api.products.update`).
- No optimistic update.

5. Success/error behavior:
- Success alert + `router.back()`.
- Error/null result -> error alert.
- Exceptions -> error alert.

6. Delete behavior:
- Confirm dialog -> `api.products.remove`.
- Soft delete only (`deletedAt`), no dependency check.

---

### Invoices

#### Create flow (`app/invoice/create.tsx` + `hooks/useCreateInvoice.ts`)

1. Entry:
- Typically from home CTA (`app/(tabs)/index.tsx` -> `router.push("/invoice/create")`).

2. Data and defaults:
- Contacts/products loaded from Convex (`api.contacts.list`, `api.products.list`, both non-archived).
- Initial local state:
- `selectedCustomer = null`
- `invoiceItems = []`
- `globalDiscount = undefined`
- modal visibility flags `false`
- item selection id `null`
- Date comes from `getLocalDateString()` at submit time.

3. Form shape (composed UI, not a single text form):
- Customer picker: `InvoiceCreateCustomerSelection` + `ContactPickerModal`.
- Product picker + line items: `InvoiceProductsSection`, `InvoiceProductCard`, `ProductPickerModal`.
- Discount editing: `DiscountModal` (percent/flat).
- Summary panel: `InvoiceCreateSummary` (derived totals).

4. Validation:
- Pre-submit guards in `handlePreviewPDF`:
- customer must be selected
- at least one invoice item required
- `validateInvoice`/`CreateInvoiceSchema` exists but is not used in the submit path.
- Discount constraints enforced in `DiscountModal`:
- percent capped to 100
- flat discount capped to line/global subtotal

5. Submit behavior:
- Maps UI items into mutation payload.
- Calls `createInvoice` (`api.invoices.create` -> `convex/invoices.ts:create`).
- Server derives:
- `invoiceNumber`
- `status` from `amountPaid` vs `total`
- line item ids for missing ids
- After DB write, app generates HTML/PDF locally and saves file (`PdfService.generateAndSavePdf`).
- No optimistic update.

6. Success/error behavior:
- Success alert then `router.back()`.
- Mutation failure or null result -> error alert.
- PDF generation failure -> error alert.
- Important behavior: invoice is created before PDF generation, so PDF failure can leave a persisted invoice.

#### Edit flow (implemented as payment/archive on detail, no full invoice edit screen)

There is no dedicated invoice edit form route (no screen for editing customer/items/totals after creation).

Implemented editable actions on `app/invoice/[id].tsx`:

1. Payment update (`PaymentModal`):
- Defaults amount input from current paid amount.
- Inline validation:
- invalid number detection
- cannot exceed invoice total
- Save disabled when validation error exists.
- Submit calls `api.invoices.updatePayment`.
- Server clamps negative values to `0` and recomputes status.
- Success/error shown via `Alert.alert`.

2. Archive:
- Confirmation alert then `api.invoices.remove` (soft delete).

3. Share:
- Generates PDF from loaded invoice and opens share sheet (no DB mutation).

## Submit Strategy Summary (All Domains)

| Domain | Create mutation | Edit mutation | Optimistic UI | Navigation after success |
|---|---|---|---|---|
| Contacts | `api.contacts.create` | `api.contacts.update` | No | `router.back()` |
| Products | `api.products.create` | `api.products.update` | No | `router.back()` |
| Invoices | `api.invoices.create` | `api.invoices.updatePayment` (payment edit) | No | `router.back()` on create; detail stays open on payment |

Error presentation pattern:
- Primary: `Alert.alert(...)`.
- Inline validation UI exists in `PaymentModal` (invoice payment).
- Detail screens include loading/not-found states for id-based queries.

## List and Detail Screens

## Contacts list/detail

### List (`app/(tabs)/contact.tsx`)

Fetch/filter/sort/paginate:
- Fetch: `hooks/useContacts.ts` -> `api.contacts.list({ includeDeleted })`.
- Filter: client-side via `useSearch` (debounced 300ms), matches `name` or `phone`.
- Sort: no explicit sort in hook/query.
- Pagination: no cursor pagination; backend query caps to first 50 (`take(50)`).

Row composition:
- `ContactList` renders `FlatList` rows.
- Each row is `ContactItem` (avatar color/initials, name, phone, edit icon).

Refetch/rerender triggers:
- Settings toggle changes `includeDeleted` arg (`systemMeta`).
- Contact mutations (create/update/remove) update subscribed query results.
- Search text + debounce state changes rerender filtered rows.
- Local list animations rerun for remounted rows.

Detail (`app/contact/[id].tsx`):
- Fetches by id with `api.contacts.get`.
- Loading state + not-found state handled in-screen.
- Mutations: update + remove.

## Products list/detail

### List (`app/(tabs)/product.tsx`)

Fetch/filter/sort/paginate:
- Fetch: `hooks/useProducts.ts` -> `api.products.list({ includeDeleted })`.
- Filter: client-side via `useSearch` by product name.
- Sort: no explicit sort.
- Pagination: no cursor pagination; backend caps at 50.

Row composition:
- `ProductList` (`FlatList`) -> `ProductItem` row.
- Row displays name, unit, formatted price, trailing chevron/edit action.

Refetch/rerender triggers:
- Settings archive toggle (`showArchivedProducts`) changes query args.
- Product create/update/remove mutation changes subscribed list data.
- Search text debounce updates filtered `results`.

Detail (`app/product/[id].tsx`):
- Fetch by id with `api.products.get`.
- Loading + not-found branches.
- Update/remove mutations.

## Invoices list/detail

### List (`app/(tabs)/invoice.tsx`)

Fetch/filter/sort/paginate:
- Base fetch: `hooks/useInvoices.ts` -> `api.invoices.list({ includeDeleted })`.
- Search fetch: when `searchText.trim()` is non-empty, also calls `api.invoices.search`.
- Search semantics: backend search index is on `customerName` (status filter exists server-side but UI does not pass status).
- Sort: no explicit sort in hook/screen.
- Pagination: no cursor pagination; list/search both cap at 50.

Row composition:
- `InvoiceList` (`FlatList`) -> `InvoiceItem` row.
- Row includes customer name, invoice number, formatted date, total/remaining amount, status badge.
- In selection mode row also renders checkbox affordances.

Refetch/rerender triggers:
- Search text changes query path (list-only vs search query).
- Archive setting toggle changes includeDeleted query args.
- Invoice mutations (create/remove/updatePayment) update live query data.
- Local UI state: `selectionMode`, `checkedIds`, share progress (`isSharing`).

Detail (`app/invoice/[id].tsx`):
- Fetch by id with `api.invoices.get`.
- Loading overlay + not-found error component.
- Renders `InvoicePreviewCard`.
- Mutations/actions: `updatePayment`, `remove` (archive), PDF share.

## Dependency Graphs (Main List Screens)

### Contacts main list

```mermaid
flowchart TD
  A[app/(tabs)/contact.tsx] --> B[hooks/useContacts.ts]
  B --> C[hooks/useSettings.ts]
  C --> D[api.systemMeta.getSettings]
  B --> E[api.contacts.list includeDeleted]
  B --> F[hooks/useSearch name or phone debounce 300ms]
  A --> G[components/contact/SearchBar.tsx]
  A --> H[components/contact/ContactList.tsx]
  H --> I[components/contact/ContactItem.tsx]
  I --> J[router.push /contact/[id]]
  A --> K[router.push /contact/create]
```

### Products main list

```mermaid
flowchart TD
  A[app/(tabs)/product.tsx] --> B[hooks/useProducts.ts]
  B --> C[hooks/useSettings.ts]
  C --> D[api.systemMeta.getSettings]
  B --> E[api.products.list includeDeleted]
  B --> F[hooks/useSearch name debounce 300ms]
  A --> G[components/contact/SearchBar.tsx]
  A --> H[components/product/ProductList.tsx]
  H --> I[components/product/ProductItem.tsx]
  I --> J[router.push /product/[id]]
  A --> K[router.push /product/create]
```

### Invoices main list

```mermaid
flowchart TD
  A[app/(tabs)/invoice.tsx] --> B[hooks/useInvoices.ts]
  B --> C[hooks/useSettings.ts]
  C --> D[api.systemMeta.getSettings]
  B --> E[api.invoices.list includeDeleted]
  B --> F[api.invoices.search when search text exists]
  B --> G[local transform to InvoiceUI + checked state]
  A --> H[components/contact/SearchBar.tsx]
  A --> I[components/invoice/InvoiceList.tsx]
  I --> J[components/invoice/InvoiceItem.tsx]
  A --> K[hooks/useInvoiceShare.ts]
  K --> L[utils/pdfTemplate.ts + utils/pdfService.ts]
  J --> M[router.push /invoice/[id]]
```

## Notable Implementation Characteristics

1. Contact/product list/search queries exist server-side (`convex/contacts.search`, `convex/products.search`) but list screens currently use client-side filtering after fetching up to 50 rows.
2. Invoice search UI placeholder says "Search by name or date", but backend search is customer-name text search.
3. `loading` flags in `useContacts`, `useProducts`, and `useInvoices` are derived after `?? []`, so they effectively stay `false`.
4. No explicit optimistic update strategy is implemented in create/edit flows.
