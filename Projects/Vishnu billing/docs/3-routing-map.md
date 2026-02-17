# Routing Map (`app/`)

## Route Groups

- `(tabs)` is a pathless route group used for the bottom-tab experience.
- Files under `app/(tabs)/` map to user-facing paths without the `(tabs)` segment.

## Route Table

| Path | File | Purpose | Params | Top-level flow |
| --- | --- | --- | --- | --- |
| `/` | `app/(tabs)/index.tsx` | Home dashboard with invoice stats and a CTA to create an invoice | None | Dashboard |
| `/invoice` | `app/(tabs)/invoice.tsx` | Invoice history list, search, select/share, open invoice detail | None | Invoice list |
| `/contact` | `app/(tabs)/contact.tsx` | Contact list, search, quick details, open create/edit | None | Contact list |
| `/product` | `app/(tabs)/product.tsx` | Product list, search, quick details, open create/edit | None | Product list |
| `/settings` | `app/settings.tsx` | Global settings (archived item visibility toggles) | None | Settings |
| `/contact/create` | `app/contact/create.tsx` | Create a new contact | None | Contact create |
| `/contact/[id]` | `app/contact/[id].tsx` | Contact detail/edit/delete screen | `id` (dynamic Convex contact ID) | Contact edit/detail |
| `/product/create` | `app/product/create.tsx` | Create a new product | None | Product create |
| `/product/[id]` | `app/product/[id].tsx` | Product detail/edit/delete screen | `id` (dynamic Convex product ID) | Product edit/detail |
| `/invoice/create` | `app/invoice/create.tsx` | Create invoice workflow with customer/product selection and PDF generation | None | Invoice create |
| `/invoice/[id]` | `app/invoice/[id].tsx` | Invoice preview/detail with payment/archive/share actions | `id` (dynamic Convex invoice ID) | Invoice detail |

## Navigation Mechanics

Navigation is implemented with Expo Router and is mostly imperative (`router.push`, `router.back`, `router.dismiss`).

### 1) Tab Switching

- `app/(tabs)/_layout.tsx` defines the four tabs: `index`, `invoice`, `contact`, and `product`.
- Switching tabs is handled by the tab navigator itself (no manual `push` needed).

### 2) Forward Navigation (`router.push`)

- Home (`app/(tabs)/index.tsx`) -> `/invoice/create`
- Contact list (`app/(tabs)/contact.tsx`) -> `/settings`, `/contact/create`, `/contact/[id]`
- Product list (`app/(tabs)/product.tsx`) -> `/settings`, `/product/create`, `/product/[id]`
- Invoice list (`app/(tabs)/invoice.tsx`) -> `/settings`, `/invoice/[id]`
- Invoice create hook (`hooks/useCreateInvoice.ts`) -> `/contact/create` (create customer inline during invoice flow)

### 3) Back/Dismiss Navigation

- `router.back()` is used by settings and most create/edit/detail screens after save/cancel/delete.
- `router.dismiss()` is used for modal-style invoice creation exit paths:
  - Header back in `components/invoice/InvoiceCreateHeader.tsx`
  - Cancel confirmation in `hooks/useCreateInvoice.ts`

### 4) Dynamic Param Resolution

- `app/contact/[id].tsx`, `app/product/[id].tsx`, and `app/invoice/[id].tsx` read params via `useLocalSearchParams()`.
- Each normalizes `id` with array-safe handling (`Array.isArray(id) ? id[0] : id`) before querying Convex.

### 5) Link Components

- There are no `Link`/`href`-based route transitions in `app/`, `components/`, or `hooks/`.
- Navigation is function-driven from event handlers.

## Shared Layouts and Wrapping

### Root Layout (`app/_layout.tsx`)

Global wrappers and stack composition:

1. `GestureHandlerRootView`
2. `ConvexProvider`
3. `ThemeProvider`
4. `SafeAreaProvider`
5. `Stack` navigator

Stack configuration highlights:

- Registers `(tabs)` and all non-tab routes (`contact/*`, `product/*`, `invoice/*`, `settings`).
- Hides native headers for all registered routes.
- Sets `invoice/create` presentation to `modal`.
- Uses `unstable_settings.anchor = "(tabs)"` to anchor stack behavior around tab routes.

### Tabs Layout (`app/(tabs)/_layout.tsx`)

- Defines bottom tab navigator with shared tab bar styling/icons.
- Wraps these tab screens:
  - `app/(tabs)/index.tsx`
  - `app/(tabs)/invoice.tsx`
  - `app/(tabs)/contact.tsx`
  - `app/(tabs)/product.tsx`

## Top-Level Flows (Create/Edit/Detail/List)

- Invoice:
  - List: `/invoice`
  - Create: `/invoice/create` (modal)
  - Detail: `/invoice/[id]`
- Contact:
  - List: `/contact`
  - Create: `/contact/create`
  - Edit/Detail: `/contact/[id]`
- Product:
  - List: `/product`
  - Create: `/product/create`
  - Edit/Detail: `/product/[id]`
- Supporting:
  - Dashboard: `/`
  - Settings: `/settings`
