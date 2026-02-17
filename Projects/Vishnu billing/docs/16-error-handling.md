# Error Handling Map

## Overview
The codebase uses a pragmatic, local error-handling model:
- Route/screen-level `try/catch` around async mutations and PDF/share operations.
- User-facing feedback is primarily `Alert.alert(...)`.
- A few route-level fallback UIs for loading/not-found.
- Backend mutations generally return structured results (`{ success: boolean, reason?: ... }`) rather than throwing custom domain errors.

There is no global error boundary, no toast/snackbar system, and no analytics/error-reporting SDK integration.

## Try/catch and failure handling patterns

### 1) Local `try/catch` around async side effects
Main usage sites:
- `app/contact/create.tsx`
- `app/contact/[id].tsx`
- `app/product/create.tsx`
- `app/product/[id].tsx`
- `app/invoice/create.tsx`
- `app/invoice/[id].tsx`
- `hooks/useInvoiceShare.ts`
- `utils/pdfService.ts`

Pattern:
1. Validate inputs (if any).
2. Await Convex mutation or PDF/share call.
3. On known falsey/`success:false`, show user-friendly alert.
4. On exception, `console.error(...)` + generic `Alert.alert("Error", ...)`.

### 2) Conditional response-contract checks
Backend methods often return explicit outcomes and the UI branches on them:
- `convex/contacts.ts` -> `remove` can return `{ success: false, reason: "has_invoices" }`.
- `convex/invoices.ts` -> `updatePayment` returns `{ success: false }` when invoice is missing.
- `convex/products.ts` and `convex/invoices.ts` soft-delete flows return `{ success: true }` on success.

UI then maps these to alerts in screens such as:
- `app/contact/[id].tsx`
- `app/product/[id].tsx`
- `app/invoice/[id].tsx`

### 3) Query-state fallback rendering (loading/not-found)
- `app/invoice/[id].tsx`:
  - loading (`invoice === undefined`) -> `InvoiceLoadingOverlay`
  - missing (`!invoice`) -> `InvoiceErrorState`
- `app/contact/[id].tsx` / `app/product/[id].tsx`:
  - loading indicator placeholder while query unresolved
  - simple `"Contact not found"` / `"Product not found"` text when missing
- List screens/components show spinners while fetching:
  - `components/contact/ContactList.tsx`
  - `components/product/ProductList.tsx`

### 4) Client-side validation before backend calls
- `utils/validation.ts` (`validateContact`, `validateProduct`, `validateInvoice`) returns `{ success, error }` contracts.
- Forms show first validation message through `Alert.alert("Error", validation.error)` in:
  - `app/contact/create.tsx`
  - `app/product/create.tsx`

### 5) Inline field-level guard inside modal flow
- `components/invoice/PaymentModal.tsx` keeps a local `error` state:
  - invalid numeric input -> inline `"Invalid amount"`
  - overpayment -> inline `"Cannot exceed ..."`
  - save button disabled while `error` exists
  - additional guard alert in `handleSave` if overpayment is attempted

## Error boundaries, toast/snackbar, and global handlers

### Error boundaries
- No React Error Boundary component is wired at app root or route level.
- `app/_layout.tsx` does not define a boundary wrapper.
- Result: render/runtime exceptions rely on default React Native/Expo behavior.

### Toast/snackbar
- No toast/snackbar library or component usage found.
- User notifications are modal alerts (`Alert.alert`) and inline text in a few components.

### Global logging/analytics tools
- No Sentry/Bugsnag/Datadog/Firebase Analytics instrumentation found in dependencies or code.
- Logging is via `console.error(...)` in local catch blocks.
- No centralized logger utility found.

## Backend error surfacing in UI

Primary surfacing strategies:
1. Backend returns structured failure (`success:false`, optional `reason`) -> UI chooses specific alert.
2. Mutation/query throws (network/runtime/validation) -> local `catch` logs and shows generic alert.
3. Missing resource in query (`null`) -> not-found UI state rendered by screen.

Examples:
- Business-rule failure: contact deletion blocked by linked invoices (`reason: "has_invoices"`) -> explicit "Cannot Delete" alert in `app/contact/[id].tsx`.
- Missing invoice for payment update: `api.invoices.updatePayment` returns `success:false` -> "Failed to update payment" alert in `app/invoice/[id].tsx`.
- Share/PDF exception: caught in screen/hook/service -> console log + generic error alert.

## Error-handling utilities/components
- `utils/validation.ts`: Zod schemas + helper wrappers that return first human-readable validation message.
- `utils/pdfService.ts`: wraps PDF save/share/delete in `try/catch` and returns safe values (`null`/`{ success: false }`) instead of crashing UI.
- `components/invoice/InvoiceErrorState.tsx`: dedicated invoice not-found error view.
- `components/invoice/PaymentModal.tsx`: inline error state, guardrails, and disabled action behavior.
- `components/common/ScreenLayout.tsx`: reusable `isLoading`/`isError` rendering API (currently available but not actively used with `isError` in routes).
- `components/common/LoadingOverlay.tsx`: blocking spinner used during async operations (e.g., batch share).
- `Alert.alert` pattern across screens: primary user-facing error/success feedback mechanism.

## Five example failure scenarios and current UI behavior

| Scenario | Where it happens | What fails | What the UI does |
|---|---|---|---|
| 1. User tries to create invoice without customer or products | `app/invoice/create.tsx` | Client precondition check fails | Immediate `Alert.alert("Error", ...)`; creation stops before backend call |
| 2. Contact delete is blocked because invoices exist | `convex/contacts.ts` -> `app/contact/[id].tsx` | Backend returns `{ success:false, reason:"has_invoices" }` | Specific alert: "Cannot Delete" with guidance to delete invoices first |
| 3. Payment input exceeds invoice total | `components/invoice/PaymentModal.tsx` | Client validation fails | Inline red error message, Save button disabled; guard alert shown if invalid save path is reached |
| 4. Invoice ID does not exist / was archived and route opened | `app/invoice/[id].tsx` | Query result is `null` | Renders `InvoiceErrorState` (`"Invoice not found"`) instead of crashing |
| 5. PDF generate/share fails (permission, native share failure, print failure, etc.) | `app/invoice/[id].tsx`, `app/invoice/create.tsx`, `hooks/useInvoiceShare.ts`, `utils/pdfService.ts` | Exception during PDF or share operation | `console.error(...)` for debug + generic `Alert.alert("Error", ...)` to user |

## Notable gaps
- No centralized error boundary for unexpected render/runtime failures.
- No toast/snackbar layer for non-blocking feedback; alerts are modal and interruptive.
- No telemetry pipeline (Sentry/analytics) for production error aggregation.
- Some mutations are called without explicit `await`/`catch` in settings toggles (`hooks/useSettings.ts`), so transient failures are not surfaced to users.
