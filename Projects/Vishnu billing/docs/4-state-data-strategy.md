# State and Data Strategy

## 1) State Model: Local vs Shared

This app uses a **hook-first + Convex-backed** state model. There is no Redux/Zustand-style global client store.

### Local state (component/hook instance scoped)

Local state is used for UI interaction and transient form state:

- Screen form state: `formData`, picker/modal visibility, edit buffers
  - `app/contact/create.tsx`
  - `app/contact/[id].tsx`
  - `app/product/create.tsx`
  - `app/product/[id].tsx`
- Invoice creation workflow state:
  - selected customer, selected items, per-item/global discounts, modal visibility
  - `hooks/useCreateInvoice.ts`
- Invoice list UI state:
  - selection mode, checked rows, search text
  - `hooks/useInvoices.ts`
- Share flow state:
  - `isSharing`
  - `hooks/useInvoiceShare.ts`
- Gesture/animation UI state:
  - pinch scale, pan offset, toggle thumb position
  - `hooks/usePinchToZoom.ts`, `app/settings.tsx`

Important: when a hook uses `useState`, that state is **per hook call site**. For example, `useInvoices()` in Home and `useInvoices()` in Invoice tab do not share `searchText`/selection state.

### Shared state (server-backed, reactive)

Shared cross-screen state lives in Convex and is accessed through `useQuery`/`useMutation` under `ConvexProvider`:

- Provider setup: `app/_layout.tsx`
- Data domains:
  - `contacts`, `products`, `invoices`, `users`, `systemMeta`
  - schema: `convex/schema.ts`

Because reads are via Convex queries, screens get reactive updates after mutations without manual cache syncing.

## 2) Where Server State Lives

Server state is implemented in Convex functions and consumed from hooks/screens.

### Convex read/write map

- Contacts
  - Reads: `api.contacts.list`, `api.contacts.search`, `api.contacts.get`
  - Writes: `api.contacts.create`, `api.contacts.update`, `api.contacts.remove`
  - Server file: `convex/contacts.ts`
- Products
  - Reads: `api.products.list`, `api.products.search`, `api.products.get`
  - Writes: `api.products.create`, `api.products.update`, `api.products.remove`
  - Server file: `convex/products.ts`
- Invoices
  - Reads: `api.invoices.list`, `api.invoices.search`, `api.invoices.get`, `api.invoices.getByNumber`
  - Writes: `api.invoices.create`, `api.invoices.updatePayment`, `api.invoices.updateStatus`, `api.invoices.attachPdf`, `api.invoices.remove`
  - Server file: `convex/invoices.ts`
- Settings / app preferences
  - Reads: `api.systemMeta.getSettings`, `api.systemMeta.getSetting`
  - Writes: `api.systemMeta.toggleSetting`, `api.systemMeta.updateSetting`
  - Server file: `convex/systemMeta.ts`
- User bootstrap
  - Reads: `api.users.getCurrent`
  - Writes: `api.users.ensureDefault`
  - Server file: `convex/users.ts`
- Analytics/derived
  - Reads: `api.districtStats.getByDistrict`
  - Server file: `convex/districtStats.ts`

### Data-shape strategy in backend

- Soft delete is used (`deletedAt`) for contacts/products/invoices.
- Invoice rows denormalize customer snapshot fields and embed line items.
- Monetary values are stored as integers in paise.

## 3) How Key Hooks Work

## `useInvoices` (`hooks/useInvoices.ts`)

What it abstracts:

- Invoice list loading (all vs search)
- Archived filter integration from settings
- UI mapping (`InvoiceDoc -> InvoiceUI`)
- Selection state for batch actions
- Invoice mutations used in list/detail flows

How it works:

1. Reads `showArchivedInvoices` from `useSettings()`.
2. Calls `api.invoices.list` for base data.
3. Calls `api.invoices.search` only when `searchText` is non-empty (`"skip"` otherwise).
4. Chooses search results when present, otherwise base list.
5. Builds:
   - `invoices` (formatted UI rows)
   - `invoicesMap` (id -> full Convex invoice doc) for share/export flows.
6. Manages local selection state (`selectionMode`, `checkedIds`).

Return value:

- `invoices`
- `invoicesMap`
- `loading`
- `selectionMode`
- `searchText`
- `setSearchText`
- `toggleInvoice`
- `enableSelectionMode`
- `getSelectedCount`
- `cancelSelection`
- `updatePayment` (mutation fn)
- `deleteInvoice` (mutation fn)

## `useProducts` (`hooks/useProducts.ts`)

What it abstracts:

- Product list fetch (with archived filter)
- UI id-mapping (`_id -> id`)
- Client-side search via `useSearch`
- Product CRUD mutation handles

How it works:

1. Reads `showArchivedProducts` from `useSettings()`.
2. Fetches products from `api.products.list`.
3. Maps each product to `ProductUI` (`id` field for UI components).
4. Filters results with `useSearch` (`name`-based).

Return value:

- `searchText`
- `setSearchText`
- `products` (filtered `ProductUI[]`)
- `loading`
- `createProduct` (mutation fn)
- `updateProduct` (mutation fn)
- `deleteProduct` (mutation fn)

## 4) Data Flow Narrative (Typical Screen)

Screen chosen: `app/(tabs)/invoice.tsx` (Invoice History tab).

### End-to-end narrative

1. App bootstraps Convex client in `app/_layout.tsx` and wraps the tree in `ConvexProvider`.
2. Invoice tab mounts and calls `useInvoices()` + `useInvoiceShare()`.
3. `useInvoices()` reads archived preference from `useSettings()` (`api.systemMeta.getSettings`).
4. `useInvoices()` subscribes to `api.invoices.list`.
5. User types in SearchBar:
   - `searchText` updates locally.
   - `api.invoices.search` becomes active when query is non-empty.
   - UI rows (`invoices`) are remapped from server docs on each query result update.
6. User long-presses an invoice:
   - local `selectionMode` turns on.
   - checkbox toggles update local `checkedIds`.
7. Share button press:
   - selected UI ids -> full docs via `invoicesMap`.
   - passed to `useInvoiceShare().shareInvoices()`.
   - hook shows confirm alert, generates merged invoice HTML/PDF, opens OS share sheet.
   - local `isSharing` drives `LoadingOverlay`.
8. If any invoice is changed elsewhere (e.g., archived/paid in `app/invoice/[id].tsx`), Convex query subscriptions refresh the list automatically.

### Dependency chain

`InvoiceScreen` -> `useInvoices` -> `useSettings` -> `api.systemMeta.getSettings`

`InvoiceScreen` -> `useInvoices` -> `api.invoices.list` / `api.invoices.search`

`InvoiceScreen` -> `useInvoiceShare` -> `PdfService` + `generateMergedInvoiceHtml`

## 5) All Hooks in `hooks/` and What They Abstract

- `use-color-scheme.ts`
  - Re-export of React Native `useColorScheme` for native platforms.
- `use-color-scheme.web.ts`
  - Web-safe color-scheme hook with hydration guard (returns `null` until hydrated).
- `use-theme-color.ts`
  - Resolves themed color tokens with optional per-theme override props.
- `useContacts.ts`
  - Contacts list fetch + archived filtering + client search + contact CRUD mutations.
- `useCreateInvoice.ts`
  - Full invoice composition state machine (customer selection, line items, discounts, totals, modal orchestration).
- `useDistrictStats.ts`
  - District-level invoice aggregate query + UI formatting + lookup map helper.
- `useInvoiceShare.ts`
  - Selection-to-PDF share workflow and sharing progress state.
- `useInvoices.ts`
  - Invoice list/search + selection state + invoice mapping + invoice mutations.
- `usePinchToZoom.ts`
  - Pinch/pan/double-tap gesture composition and animated transform style.
- `useProducts.ts`
  - Product list fetch + archived filtering + client search + product CRUD mutations.
- `useSearch.ts`
  - Generic debounced in-memory list filtering.
- `useSettings.ts`
  - Reads/toggles archive visibility preferences from Convex `systemMeta`.
- `useUser.ts`
  - Reads current user and ensures a default user exists.
- `index.ts`
  - Barrel export file (not a hook, but re-exports selected hooks).

## 6) Practical Summary

- **Local state** handles immediate UI interaction (forms, modals, gestures, selection).
- **Shared state** is primarily Convex server state, accessed reactively via `useQuery` and modified via `useMutation`.
- **Custom hooks** are the app’s main abstraction layer that blend server data, local UI state, and view-model mapping for screens.
