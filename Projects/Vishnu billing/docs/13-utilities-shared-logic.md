# Utilities And Shared Logic Audit (`utils/`, `constants/`)

## Scope

Audited all files in:

- `utils/`
- `constants/`

Also traced caller files in `app/`, `components/`, `hooks/`, and `styles/` to identify central/shared utilities and assumptions.

## Utility/Constant Inventory

| Module | Key exports | Main purpose | Importer files |
| --- | --- | --- | --- |
| `utils/responsive.ts` | `scale`, `verticalScale`, `moderateScale`, `SCREEN_DIMENSIONS`, `IS_TABLET`, `DEVICE_TYPE` | Device-size based scaling helpers | 44 |
| `utils/currency.ts` | money/unit conversion + formatting helpers | Paise/rupee conversion, discount and tax math | 16 |
| `utils/pdfService.ts` | `PdfService` object | PDF generation/save/share wrapper | 3 |
| `utils/pdfTemplate.ts` | `generateInvoiceHtml`, `generateMergedInvoiceHtml` | Invoice HTML generation for PDF | 3 |
| `utils/contactUtils.ts` | `COLORS`, `generateInitials`, `generateRandomColor` | Contact avatar helpers | 3 |
| `utils/validation.ts` | Zod schemas + `validate*` helpers | Form validation | 2 |
| `utils/invoiceUtils.ts` | `calculateDiscountAmount` | Shared invoice discount calculation | 2 |
| `constants/home.ts` | `HOME_CONSTANTS` | Home screen constants/theme tokens | 2 |
| `constants/theme.ts` | `Colors`, `Fonts` | App color/font constants | 2 |
| `utils/config.ts` | default `config` | Environment parsing/validation | 1 |
| `utils/colorScale.ts` | `getDistrictColor`, `MAP_LEGEND_COLORS` | District map color bands | 1 |
| `utils/districtList.ts` | `TAMIL_NADU_DISTRICTS` | District picker source data | 1 |
| `utils/mapUtils.ts` | `geoCoordinatesToSVGPath` + GeoJSON types | GeoJSON -> SVG conversion | 1 |

## Most Central Modules (By Usage)

1. `utils/responsive.ts` (44 importer files)
2. `utils/currency.ts` (16 importer files)
3. `utils/pdfService.ts`, `utils/pdfTemplate.ts`, `utils/contactUtils.ts` (3 each)
4. `utils/validation.ts`, `utils/invoiceUtils.ts`, `constants/home.ts`, `constants/theme.ts` (2 each)

## Formatting / Date / Money / Invoice Logic

| Category | Where it lives | Notes |
| --- | --- | --- |
| Money formatting | `utils/currency.ts:49` | `formatCurrency` formats paise as `₹` + fixed 2 decimals (no locale grouping). |
| Money conversion | `utils/currency.ts:19`, `utils/currency.ts:34` | Uses paise integers for storage and rupees for display. |
| Discount math | `utils/invoiceUtils.ts:14` | Handles flat/percent discounts; percent uses basis points. |
| Invoice totals | `hooks/useCreateInvoice.ts:100` | Subtotal/discount/tax/total are computed in paise using shared discount util. |
| Invoice HTML formatting | `utils/pdfTemplate.ts:301` | Formats invoice rows/totals and embeds strings into HTML. |
| Date handling in utils/constants | `utils/pdfService.ts:144` | Only filename timestamp (`Date.now()`) in utilities. No dedicated date utility module. |
| Date formatting (outside utils) | `hooks/useInvoices.ts:57`, `hooks/useInvoiceShare.ts:32` | UI/share date formatting currently happens in hooks using `toLocaleDateString("en-US", ...)`. |

## Important Utilities: Signatures, Callers, Assumptions

### 1) `utils/responsive.ts`

Signatures:

- `scale(size: number): number` (`utils/responsive.ts:13`)
- `verticalScale(size: number): number` (`utils/responsive.ts:20`)
- `moderateScale(size: number, factor = 0.5): number` (`utils/responsive.ts:29`)
- `SCREEN_DIMENSIONS: { width: number; height: number }` (`utils/responsive.ts:32`)

Callers:

- `app/(tabs)/_layout.tsx`, `app/(tabs)/index.tsx`, `app/contact/[id].tsx`, `app/contact/create.tsx`, `app/invoice/[id].tsx`, `app/settings.tsx`
- `components/common/BaseSelectionModal.tsx`, `components/common/FormField.tsx`, `components/common/ScreenLayout.tsx`, `components/common/SkeletonLoader.tsx`
- `components/contact/ColorPicker.tsx`, `components/contact/ContactHeader.tsx`, `components/contact/ContactItem.tsx`, `components/contact/DeleteContactButton.tsx`, `components/contact/SearchBar.tsx`
- `components/home/CreateInvoiceButton.tsx`
- `components/invoice/ContactPickerModal.tsx`, `components/invoice/CustomerSelection.tsx`, `components/invoice/DiscountModal.tsx`, `components/invoice/FloatingShareButton.tsx`, `components/invoice/InvoiceActionBar.tsx`, `components/invoice/InvoiceCreateCustomerSelection.tsx`, `components/invoice/InvoiceCreateFooter.tsx`, `components/invoice/InvoiceCreateHeader.tsx`, `components/invoice/InvoiceCreateSummary.tsx`, `components/invoice/InvoiceErrorState.tsx`, `components/invoice/InvoiceHeader.tsx`, `components/invoice/InvoiceItem.tsx`, `components/invoice/InvoicePreviewHeader.tsx`, `components/invoice/InvoiceProductCard.tsx`, `components/invoice/InvoiceProductsSection.tsx`, `components/invoice/PaymentModal.tsx`, `components/invoice/PreviewButton.tsx`, `components/invoice/ProductItem.tsx`, `components/invoice/ProductList.tsx`, `components/invoice/ProductPickerModal.tsx`, `components/invoice/ZoomHint.tsx`
- `components/product/ProductDeleteSection.tsx`, `components/product/ProductItem.tsx`
- `styles/common.ts`, `styles/contacts.ts`, `styles/home.ts`, `styles/invoice.ts`, `styles/products.ts`

Implicit assumptions:

- Base design size is iPhone-like (`375x812`) (`utils/responsive.ts:5`-`utils/responsive.ts:6`).
- `Dimensions.get("window")` is read once at module load; no live orientation re-scaling.
- `IS_TABLET`/`DEVICE_TYPE` are exported but currently not used by app code.

### 2) `utils/currency.ts`

Key signatures:

- `paiseToDecimal(paise: number): number` (`utils/currency.ts:19`)
- `decimalToPaise(rupees: number): number` (`utils/currency.ts:34`)
- `formatCurrency(paise: number, currencySymbol = "₹"): string` (`utils/currency.ts:49`)
- `percentToBasisPoints(percent: number): number` (`utils/currency.ts:93`)
- `basisPointsToPercent(basisPoints: number): number` (`utils/currency.ts:106`)

Callers:

- `paiseToDecimal`: `app/invoice/create.tsx`, `app/product/[id].tsx`, `components/invoice/DiscountModal.tsx`, `components/invoice/InvoicePreviewCard.tsx`, `components/invoice/PaymentModal.tsx`
- `decimalToPaise`: `app/product/[id].tsx`, `app/product/create.tsx`, `components/invoice/PaymentModal.tsx`
- `formatCurrency`: `app/(tabs)/product.tsx`, `components/home/InvoiceStatsChart.tsx`, `components/invoice/DiscountModal.tsx`, `components/invoice/InvoiceCreateSummary.tsx`, `components/invoice/InvoiceProductCard.tsx`, `components/invoice/InvoiceSummary.tsx`, `components/invoice/PaymentModal.tsx`, `components/invoice/ProductPickerModal.tsx`, `components/product/ProductItem.tsx`, `hooks/useDistrictStats.ts`, `hooks/useInvoices.ts`
- `percentToBasisPoints`: `hooks/useCreateInvoice.ts`
- `basisPointsToPercent`: `components/invoice/DiscountModal.tsx`, `components/invoice/InvoiceCreateSummary.tsx`, `components/invoice/InvoicePreviewCard.tsx`, `components/invoice/InvoiceProductCard.tsx`

Implicit assumptions:

- Storage unit is paise; display unit is rupees.
- Percent discounts/tax are represented in basis points (10000 = 100%).
- Formatting is fixed decimal string; no locale separators or INR locale rules.
- Several exported helpers are currently unused (`multiplyPaise`, `calculatePercentDiscount`, `addPaise`, `subtractPaise`, `calculateTax`, `numberToWords`).

### 3) `utils/invoiceUtils.ts`

Signature:

- `calculateDiscountAmount(itemTotalInPaise: number, discount?: Discount): number` (`utils/invoiceUtils.ts:14`)

Callers:

- `hooks/useCreateInvoice.ts`
- `components/invoice/DiscountModal.tsx` (imported as alias `coreCalculateDiscountAmount`)

Implicit assumptions:

- Flat discounts are paise; percent discounts are basis points.
- Percent path does not clamp to 100% inside util; callers are expected to sanitize.
- Flat discount is clamped to item total (`Math.min`), preventing negative line totals.

### 4) `utils/pdfTemplate.ts`

Signatures:

- `generateInvoiceHtml(senderName, invoiceNumber, date, customer, items, summary)` (`utils/pdfTemplate.ts:301`)
- `generateMergedInvoiceHtml(invoices, senderName)` (`utils/pdfTemplate.ts:332`)

Callers:

- `app/invoice/create.tsx`
- `app/invoice/[id].tsx`
- `hooks/useInvoiceShare.ts`

Implicit assumptions:

- Monetary inputs are paise and converted internally for display.
- `date` is expected to be preformatted display text by caller.
- Tax row label is hardcoded as `Tax (5%)` in template (`utils/pdfTemplate.ts:192`).
- Template interpolation is plain string replacement; user-provided text is not HTML-escaped.

### 5) `utils/pdfService.ts`

Key signatures:

- `generatePdf(html: string): Promise<string>` (`utils/pdfService.ts:44`)
- `generateAndSavePdf(html: string, fileName: string): Promise<{ tempUri: string; savedPath?: string } | null>` (`utils/pdfService.ts:73`)
- `sharePdf(uri: string, title: string): Promise<{ success: boolean; cancelled?: boolean }>` (`utils/pdfService.ts:90`)
- `generateFileName(prefix: string): string` (`utils/pdfService.ts:144`)

Callers:

- `app/invoice/create.tsx`
- `app/invoice/[id].tsx`
- `hooks/useInvoiceShare.ts`

Implicit assumptions:

- Expo print/file-system/sharing APIs are available on target platform.
- Cancellation detection depends on error message containing `"cancelled"` (`utils/pdfService.ts:108`).
- `InvoicePdfData` interface is exported but currently unused (`utils/pdfService.ts:10`).

### 6) `utils/validation.ts`

Key signatures:

- `validateContact(data: unknown): { success: true; data: ContactInput } | { success: false; error: string }` (`utils/validation.ts:137`)
- `validateProduct(data: unknown): { success: true; data: ProductInput } | { success: false; error: string }` (`utils/validation.ts:151`)

Callers:

- `validateContact`: `app/contact/create.tsx`
- `validateProduct`: `app/product/create.tsx`

Implicit assumptions:

- Validation is used on create flows, but edit flows perform manual checks instead (`app/contact/[id].tsx`, `app/product/[id].tsx`), so rules can diverge.
- Phone validation is length-based, not strict digit/format validation.
- Many exported schemas/helpers are currently unused in app code (`validateInvoice`, `getValidationError`, raw schema exports).

### 7) `utils/config.ts`

Signature:

- Default export `config` with validated `CONVEX_URL` (`utils/config.ts:11`)

Caller:

- `app/_layout.tsx` (`ConvexReactClient(config.CONVEX_URL)`)

Implicit assumptions:

- Missing/empty `EXPO_PUBLIC_CONVEX_URL` causes startup-time parse failure via Zod.
- Config validation happens at module import, not deferred.

### 8) Domain-specific map/contact helpers

`utils/colorScale.ts`

- Signature: `getDistrictColor(paidRatio: number, hasData: boolean): string` (`utils/colorScale.ts:7`)
- Caller: `components/home/TamilNaduMap.tsx`
- Assumptions: fixed threshold bands (`0.2`, `0.5`, `0.8`) and hardcoded color values.

`utils/mapUtils.ts`

- Signature: `geoCoordinatesToSVGPath(geometry, bounds): string` (`utils/mapUtils.ts:25`)
- Caller: `components/home/TamilNaduMap.tsx`
- Assumptions: static Tamil Nadu bounding box and first-ring polygon rendering (holes/interiors ignored).

`utils/contactUtils.ts`

- Signatures: `generateInitials(name: string): string` (`utils/contactUtils.ts:26`), `generateRandomColor(): string` (`utils/contactUtils.ts:38`)
- Callers: `app/contact/create.tsx`, `app/contact/[id].tsx`, `components/contact/ColorPicker.tsx`
- Assumptions: first two initials only; split by space. Color generation duplicates server-side palette logic in `convex/contacts.ts`.

## Constants Audit

`constants/home.ts`

- Export: `HOME_CONSTANTS` (`constants/home.ts:1`)
- Callers: `app/(tabs)/index.tsx`, `styles/home.ts`
- Notes: `STYLES.*` is actively used; `USER_ID` and `ALERT_MESSAGES.CLOUD_SYNC` appear unused.

`constants/theme.ts`

- Exports: `Colors` (`constants/theme.ts:11`), `Fonts` (`constants/theme.ts:30`)
- Callers: `Colors` is used by `app/(tabs)/_layout.tsx` and `hooks/use-theme-color.ts`; `Fonts` has no current imports
- Notes: `useThemeColor` hook exists but appears unused outside its own file.

## Notable Drift / Cleanup Candidates

1. `MAP_LEGEND_COLORS` is unused while map legend in `components/home/TamilNaduMap.tsx` repeats hardcoded colors.
2. `Fonts` in `constants/theme.ts` is currently unused.
3. Several `utils/currency.ts` helpers are exported but unused.
4. Several `utils/validation.ts` exports are unused; create/edit validation is inconsistent across screens.
5. `InvoicePdfData` in `utils/pdfService.ts` is unused.
