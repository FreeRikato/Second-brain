# Type System Map

## Types directory: files and exports

| File | Exports |
|---|---|
| `types/contact.ts` | `Contact`, `ContactId`, `ContactUI` |
| `types/invoice.ts` | `InvoiceDoc`, `ContactId`, `ProductId`, `InvoiceId`, `InvoiceUI`, `Customer`, `InvoiceStatus`, `DiscountType`, `Discount`, `InvoiceProduct`, `InvoiceSummary`, `InvoiceWithItems`, `isInvoiceStatus`, `isDiscountType` |
| `types/map.ts` | `DistrictStats`, `DistrictStatsUI`, `MapInteraction`, `MapLegendItem` |
| `types/product.ts` | `Product`, `ProductId`, `ProductUI` |
| `types/user.ts` | `User`, `UserId`, `UserUI` |
| `types/index.ts` | Re-exports aliases for UI-first usage: `ContactConvex`, `Contact`, `ContactUI`, `Customer`, `Discount`, `DiscountType`, `InvoiceConvex`, `InvoiceId`, `InvoiceProduct`, `InvoiceStatus`, `InvoiceSummary`, `Invoice`, `InvoiceUI`, `InvoiceWithItems`, `ProductConvex`, `Product`, `ProductUI`, `UserConvex`, `User`, `UserUI` |

Notes:
- `types/index.ts` does not re-export `ContactId`, `ProductId`, `InvoiceDoc`, `DistrictStats`, `DistrictStatsUI`, `MapInteraction`, or `MapLegendItem`.
- In `types/index.ts`, `Contact`, `Product`, `User`, and `Invoice` are UI aliases (not raw Convex document shapes).

## How Convex generated types are used

Yes, Convex generated types are actively used.

### 1) Canonical schema-backed types (`Doc` and `Id`)
- `Doc` and `Id` come from `convex/_generated/dataModel.d.ts`.
- Domain aliases in `types/` are built on top of those:
  - `Contact = Doc<"contacts">` in `types/contact.ts`
  - `Product = Doc<"products">` in `types/product.ts`
  - `User = Doc<"users">` in `types/user.ts`
  - `InvoiceDoc = Doc<"invoices">` in `types/invoice.ts`

### 2) Typed API surface from generated `api`
- `api` from `convex/_generated/api` is used by hooks and screens (`hooks/useInvoices.ts`, `hooks/useContacts.ts`, `hooks/useProducts.ts`, `hooks/useCreateInvoice.ts`, `hooks/useUser.ts`, `hooks/useDistrictStats.ts`, etc.).
- `useQuery(api.module.fn, args)` and `useMutation(api.module.fn)` get typed args/returns from Convex generation.

### 3) Typed route-param casts using generated `Id`
- Detail screens cast route params to Convex ids before querying/mutating:
  - `app/contact/[id].tsx` uses `Id<"contacts">`
  - `app/product/[id].tsx` uses `Id<"products">`
  - `app/invoice/[id].tsx` uses `Id<"invoices">`

### 4) Backend functions use generated server helpers
- Convex modules (`convex/contacts.ts`, `convex/products.ts`, `convex/invoices.ts`, etc.) use `query`/`mutation` from `convex/_generated/server`, which are parameterized by the generated `DataModel`.

### 5) Practical friction point
- UI types convert `_id` to `id: string` (`ContactUI`, `ProductUI`, `UserUI`), so some flows cast back to typed ids (example: `hooks/useCreateInvoice.ts` casts `product.id as ProductId`).

## Duplicated or overlapping types

| Type(s) | Overlap | Impact |
|---|---|---|
| `ContactId` (`types/contact.ts`, `types/invoice.ts`) | Same alias: `Id<"contacts">` in two places | Redundant definitions can drift and confuse imports |
| `ProductId` (`types/product.ts`, `types/invoice.ts`) | Same alias: `Id<"products">` in two places | Same redundancy risk |
| `DistrictStats` (`types/map.ts`, `convex/districtStats.ts`) | Same raw shape defined on both frontend and backend | Duplicate contracts; easy to diverge over time |
| `InvoiceWithItems` vs `InvoiceDoc` (`types/invoice.ts`) | `InvoiceWithItems = InvoiceDoc` | Semantic alias only; not wrong, but overlapping |
| `InvoiceStatus`, `DiscountType` vs schema unions (`convex/schema.ts`, `convex/invoices.ts`) | Same value sets represented in multiple places | Drift risk if one side changes |
| `Contact` / `Product` / `User` / `Invoice` names | Different meaning based on import path (`@/types` UI alias vs module raw type) | Readability risk; easy to use wrong shape |

Other findings:
- `MapInteraction` and `MapLegendItem` appear currently unused.
- `isDiscountType` appears currently unused.

## Type glossary (name -> meaning -> where used)

| Type name | Meaning | Where used |
|---|---|---|
| `Contact` (from `@/types/contact`) | Raw Convex contact document (`Doc<"contacts">`) | `hooks/useContacts.ts`, `hooks/useCreateInvoice.ts` |
| `ContactUI` | Contact document adapted for UI (`id` instead of `_id`) | `hooks/useContacts.ts` |
| `Contact` (from `@/types`) | Barrel alias to `ContactUI` | `app/(tabs)/contact.tsx`, `components/contact/ContactList.tsx`, `components/contact/ContactItem.tsx` |
| `ContactConvex` | Barrel alias to raw contact doc type | Exported in `types/index.ts`, currently not imported elsewhere |
| `ContactId` | Typed Convex contact id (`Id<"contacts">`) | Defined in `types/contact.ts` and `types/invoice.ts` |
| `Product` (from `@/types/product`) | Raw Convex product document (`Doc<"products">`) | `hooks/useProducts.ts`, `hooks/useCreateInvoice.ts` |
| `ProductUI` | Product document adapted for UI (`id` instead of `_id`) | `hooks/useProducts.ts`, `hooks/useCreateInvoice.ts` |
| `Product` (from `@/types`) | Barrel alias to `ProductUI` | `app/(tabs)/product.tsx`, `components/product/ProductList.tsx`, `components/invoice/InvoiceProductsSection.tsx` |
| `ProductConvex` | Barrel alias to raw product doc type | Exported in `types/index.ts`, currently not imported elsewhere |
| `ProductId` | Typed Convex product id (`Id<"products">`) | `hooks/useCreateInvoice.ts`, plus duplicate alias definitions |
| `User` (from `@/types/user`) | Raw Convex user document (`Doc<"users">`) | Mainly foundational for `UserUI`; rarely imported directly |
| `UserUI` | User document adapted for UI (`id` instead of `_id`) | `hooks/useUser.ts` |
| `User` (from `@/types`) | Barrel alias to `UserUI` | `components/home/HomeHeader.tsx` |
| `UserConvex` | Barrel alias to raw user doc type | Exported in `types/index.ts`, currently not imported elsewhere |
| `UserId` | Typed Convex user id (`Id<"users">`) | Defined in `types/user.ts`, currently not imported elsewhere |
| `InvoiceDoc` | Raw Convex invoice document (`Doc<"invoices">`) | `hooks/useInvoices.ts`, `components/home/InvoiceStatsChart.tsx` |
| `InvoiceWithItems` | Alias of `InvoiceDoc` for item-rich invoice flows | `hooks/useInvoiceShare.ts`, `components/invoice/InvoicePreviewCard.tsx` |
| `InvoiceUI` | Invoice list card/view model with formatted strings + `checked` state | Produced in `hooks/useInvoices.ts` |
| `Invoice` (from `@/types`) | Barrel alias to `InvoiceUI` | `app/(tabs)/invoice.tsx`, `components/invoice/InvoiceList.tsx`, `components/invoice/InvoiceItem.tsx` |
| `InvoiceConvex` | Barrel alias to `InvoiceDoc` | Exported in `types/index.ts`, currently not imported elsewhere |
| `InvoiceId` | Typed Convex invoice id (`Id<"invoices">`) | Defined in `types/invoice.ts`, exported in barrel |
| `InvoiceStatus` | Invoice payment state union: `"unpaid" | "partial" | "paid"` | `types/invoice.ts`, `hooks/useInvoices.ts` via guard |
| `DiscountType` | Discount mode union: `"percent" | "flat"` | `hooks/useCreateInvoice.ts`, `components/invoice/DiscountModal.tsx` |
| `Discount` | Discount payload `{ value, type }` used for item/global discounts | `hooks/useCreateInvoice.ts`, `components/invoice/InvoiceCreateSummary.tsx`, `utils/invoiceUtils.ts` |
| `InvoiceProduct` | Invoice line item model (`name`, `price`, `qty`, optional `discount`) | `hooks/useCreateInvoice.ts`, invoice product components, `utils/pdfTemplate.ts` |
| `InvoiceSummary` | Derived totals in paise (`subtotal`, `totalDiscount`, `tax`, `total`) | `hooks/useCreateInvoice.ts`, `components/invoice/InvoiceSummary.tsx`, `utils/pdfTemplate.ts` |
| `Customer` | Invoice-create customer projection of contact data | `hooks/useCreateInvoice.ts`, `components/invoice/ContactPickerModal.tsx`, `components/invoice/InvoiceCreateCustomerSelection.tsx` |
| `isInvoiceStatus` | Type guard from string to `InvoiceStatus` | `hooks/useInvoices.ts` |
| `isDiscountType` | Type guard from nullable string to `DiscountType` | Defined in `types/invoice.ts`, currently not imported elsewhere |
| `DistrictStats` | Raw district-level stats model (numeric amounts) | Duplicated in `types/map.ts` and `convex/districtStats.ts`; frontend mostly uses inferred query result directly |
| `DistrictStatsUI` | Formatted district stats for UI display | `hooks/useDistrictStats.ts`, `components/home/DistrictDetailModal.tsx` |
| `MapInteraction` | Map selection/detail interaction state | Declared in `types/map.ts`, currently not imported elsewhere |
| `MapLegendItem` | Map legend row model (`label`, `color`, `range`) | Declared in `types/map.ts`, currently not imported elsewhere |

## Top 10 most important types

1. `InvoiceDoc`: canonical persisted invoice shape powering list, chart, preview, and share.
2. `InvoiceProduct`: core line-item contract across create flow, UI cards, and PDF rendering.
3. `InvoiceSummary`: single source for totals shown in create UI and sent to backend/PDF.
4. `Discount`: shared discount contract used in calculations and editing UI.
5. `Customer`: bridge type between contacts domain and invoice creation.
6. `Invoice` (`@/types` alias to `InvoiceUI`): primary type for invoice list interactions and selection state.
7. `Contact` (`@/types` alias to `ContactUI`): primary type for contact tab list/edit navigation.
8. `Product` (`@/types` alias to `ProductUI`): primary type for product tab list/edit and invoice product selection.
9. `DistrictStatsUI`: drives district analytics modal and map-adjacent dashboard experience.
10. `User` (`@/types` alias to `UserUI`): drives home header personalization and default-user flow.

## Suggested cleanup (optional)

1. Centralize id aliases (`ContactId`, `ProductId`) in one module and re-export.
2. Export map types from `types/index.ts` for consistent import style.
3. Consider deriving `InvoiceStatus`/`DiscountType` from Convex schema-facing types to reduce drift.
4. Remove or wire up currently-unused exports (`MapInteraction`, `MapLegendItem`, `isDiscountType`, possibly `*Convex` aliases).
