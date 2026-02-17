# Repo Overview Map

## Main domains

### Contact
- Purpose: Customer master data (name, phone, address, district, GSTIN, DL) with soft-delete.
- Main routes: `app/(tabs)/contact.tsx`, `app/contact/create.tsx`, `app/contact/[id].tsx`.
- UI layer: `components/contact/*`.
- Data layer: `hooks/useContacts.ts`.
- Backend layer: `convex/contacts.ts` on `contacts` table in `convex/schema.ts`.

### Product
- Purpose: Product catalog (name, unit, price in paise) with soft-delete.
- Main routes: `app/(tabs)/product.tsx`, `app/product/create.tsx`, `app/product/[id].tsx`.
- UI layer: `components/product/*`.
- Data layer: `hooks/useProducts.ts`.
- Backend layer: `convex/products.ts` on `products` table in `convex/schema.ts`.

### Invoice
- Purpose: Invoice list/search/select, create flow with discount/tax math, payment updates, archive, PDF generation/sharing.
- Main routes: `app/(tabs)/invoice.tsx`, `app/invoice/create.tsx`, `app/invoice/[id].tsx`.
- UI layer: `components/invoice/*`.
- Data layer: `hooks/useInvoices.ts`, `hooks/useCreateInvoice.ts`, `hooks/useInvoiceShare.ts`.
- Backend layer: `convex/invoices.ts` on `invoices` table in `convex/schema.ts`.
- Supporting utils: `utils/invoiceUtils.ts`, `utils/pdfTemplate.ts`, `utils/pdfService.ts`, `utils/currency.ts`.

### Home
- Purpose: Dashboard summary (payment donut chart + district map).
- Main route: `app/(tabs)/index.tsx`.
- UI layer: `components/home/*`.
- Data layer: `hooks/useUser.ts`, `hooks/useInvoices.ts`, `hooks/useDistrictStats.ts`.
- Backend layer: `convex/users.ts`, `convex/districtStats.ts`.

### Settings
- Purpose: Toggle visibility of archived contacts/products/invoices.
- Main route: `app/settings.tsx`.
- Data layer: `hooks/useSettings.ts`.
- Backend layer: `convex/systemMeta.ts` on `systemMeta` table in `convex/schema.ts`.

## Folder tour (high-level)
- `app/`: Expo Router route files (startup layout, tabs, create/detail pages, settings screen).
- `app/(tabs)/`: Primary tab navigation surfaces (`index`, `invoice`, `contact`, `product`).
- `app/contact`, `app/product`, `app/invoice`: Stack screens for create/edit/preview flows.
- `components/`: Reusable UI by domain (`contact`, `product`, `invoice`, `home`) plus `common`.
- `hooks/`: Screen-facing state/data hooks that bridge UI with Convex and local state.
- `convex/`: Backend schema + queries/mutations; includes `schema.ts` and per-domain function files.
- `types/`: App-level TypeScript models, including Convex doc aliases and UI-mapped types.
- `utils/`: Shared business logic (currency, validation, invoice math, map shaping, PDF generation).
- `styles/`: Centralized style objects by domain.
- `constants/`: Theme and static constants.
- `public/`: Static assets (including map GeoJSON used by home map).
- `scripts/`: Local utility scripts.
- `docs/`: Project documentation artifacts.

## Runtime flow (app launch -> routing -> data)

```text
npm run start
  -> Expo runtime
    -> package.json "main" = expo-router/entry
      -> app/_layout.tsx (root)
        -> polyfills + providers (GestureHandler, ConvexProvider, ThemeProvider, SafeAreaProvider)
        -> ConvexReactClient initialized from EXPO_PUBLIC_CONVEX_URL (utils/config.ts)
        -> Stack routes registered
           -> "(tabs)" (default anchor)
              -> app/(tabs)/_layout.tsx (tab navigator)
                 -> Home: app/(tabs)/index.tsx
                 -> Invoice: app/(tabs)/invoice.tsx
                 -> Contact: app/(tabs)/contact.tsx
                 -> Product: app/(tabs)/product.tsx
           -> non-tab stack routes (create/edit/detail/settings)
              -> app/contact/*, app/product/*, app/invoice/*, app/settings.tsx

Screen render cycle
  -> screen calls hook(s)
     -> hook calls Convex useQuery/useMutation with api.* (from convex/_generated/api)
        -> Convex query/mutation runs against tables in convex/schema.ts
           -> results returned to hook
              -> hook maps Convex docs to UI types
                 -> components render list/detail state

Invoice create/share special path
  -> app/invoice/create.tsx + hooks/useCreateInvoice.ts
     -> build totals/discounts in paise
     -> mutation: api.invoices.create
     -> generate HTML (utils/pdfTemplate.ts)
     -> generate/save/share PDF (utils/pdfService.ts)
```

## Main entry points (startup + navigation)
- Process/app startup entry: `package.json` (`"main": "expo-router/entry"`).
- Root app composition + provider entry: `app/_layout.tsx`.
- Primary navigation entry: `app/(tabs)/_layout.tsx`.
- Default first tab screen: `app/(tabs)/index.tsx` (home).
- Route expansion entry points (stack): `app/contact/*`, `app/product/*`, `app/invoice/*`, `app/settings.tsx`.
- Route transitions are handled by `router.push(...)` / `router.back()` calls inside screens and hooks.

## Most important 15 files (and why)
1. `package.json`: Declares app runtime entry (`expo-router/entry`) and core dev commands.
2. `app/_layout.tsx`: Root composition of providers + stack route registration; the real app bootstrap in code.
3. `app/(tabs)/_layout.tsx`: Defines top-level information architecture for user navigation.
4. `app/(tabs)/index.tsx`: Home dashboard aggregation point (user + invoice + district insights).
5. `app/invoice/create.tsx`: Central transaction flow for creating invoices and generating PDFs.
6. `app/settings.tsx`: User-facing control plane for archived-visibility behavior.
7. `hooks/useContacts.ts`: Contact query/search/mutation gateway used by contact screens.
8. `hooks/useProducts.ts`: Product query/search/mutation gateway used by product screens.
9. `hooks/useInvoices.ts`: Invoice list/search/selection/share-prep state model used by home/invoice screens.
10. `hooks/useCreateInvoice.ts`: Core invoice draft state machine (items, discounts, tax, totals, modals).
11. `hooks/useSettings.ts`: Persists and exposes archived toggle state to the rest of the app.
12. `convex/schema.ts`: Source of truth for tables, indexes, and data contracts.
13. `convex/contacts.ts`: Contact domain backend logic (list/search/create/update/soft-delete with invoice guard).
14. `convex/products.ts`: Product domain backend logic (list/search/create/update/soft-delete).
15. `convex/invoices.ts`: Invoice domain backend logic (create/search/status/payment/archive).

