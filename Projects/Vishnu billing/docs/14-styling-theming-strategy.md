# Styling and Theming Strategy

## `styles/` structure and conventions

The styling system is organized by feature, with a shared base:

- `styles/common.ts`: cross-feature primitives and shared blocks (screen containers, headers, form controls, loading/empty states, modal shells, FAB/nav patterns).
- `styles/contacts.ts`: contact screen and contact-related component styles.
- `styles/products.ts`: product card/delete styles.
- `styles/invoice.ts`: the largest style file; includes create flow, modals, list rows, action bars, and invoice preview card (both dark UI and white paper preview styles).
- `styles/home.ts`: home/dashboard, chart/map cards, and related modal container styles.
- `styles/index.ts`: re-export barrel for ergonomic imports (`@/styles`).

Conventions used across files:

- Most styles are declared once with `StyleSheet.create`.
- Feature styles are named `*Styles` (`homeStyles`, `invoiceStyles`, etc.).
- Shared categories are sometimes re-exported as grouped aliases (`listStyles`, `fabStyles`, `modalStyles`, `navStyles`) in `styles/common.ts`.
- Style names are semantic to component intent (`sectionTitle`, `addButtonSelected`, `summaryRow`) rather than generic utility names.

## Theme tokens, spacing, and typography

### Theme/color tokens currently present

- `constants/theme.ts` defines `Colors.light`/`Colors.dark` and `Fonts` (platform-specific font families).
- `constants/home.ts` defines home-specific color constants (`HOME_CONSTANTS.STYLES.*`).
- Additional domain palettes exist in utils:
  - `utils/contactUtils.ts` (`COLORS` avatar palette),
  - `utils/colorScale.ts` (district map/legend colors).

Important practical note:

- The app currently uses a dark-first visual language with many hardcoded color hex values directly in style files.
- `Colors` and `useThemeColor` exist, but `useThemeColor` is not actively used by UI components right now.

### Spacing and sizing system

Spacing/sizing is responsive-first and centralized through `utils/responsive.ts`:

- `scale(size)`: width-based scaling (padding, margin, widths, icon sizes).
- `verticalScale(size)`: height-based scaling (vertical spacing/heights).
- `moderateScale(size, factor)`: softened scaling, commonly used for font sizes.

Most style files use these helpers heavily, so raw numeric literals are less common for layout.

### Typography patterns

- No global typography object (like `typography.h1/h2/body`) is enforced yet.
- Font sizing is mostly `moderateScale(...)` (sometimes `scale(...)` in local files like `app/settings.tsx`).
- Weight conventions are consistent via string weights (`"500"`, `"600"`, `"700"`, `"800"`, `"900"`).
- `constants/theme.ts` defines platform fonts, but most components rely on default RN font family unless explicitly overridden.

## How components apply styles

The repository uses a hybrid but consistent approach:

### 1) Primary pattern: imported feature `StyleSheet` objects

Most components import from `@/styles` or `@/styles/<feature>` and apply style keys directly:

- Example pattern: `style={invoiceStyles.section}`.
- Keeps visual rules centralized and reusable.

### 2) Conditional composition with style arrays

Common state-driven pattern:

- `style={[baseStyle, condition && variantStyle, dynamicInlineObject]}`
- Used for selected/pressed/error states and small overrides.

Examples in repo:

- selection buttons in picker modals,
- pressed row backgrounds via `Pressable` callback,
- status-based color variants in invoice items,
- safe-area dependent footer padding.

### 3) Local component-level `StyleSheet.create` when scope is narrow

Some components define small local style sheets for hyper-local behavior:

- `app/settings.tsx` (`settingsStyles`),
- `components/invoice/PaymentModal.tsx` (`paymentModalStyles`),
- `components/invoice/DiscountModal.tsx` (`discountModalStyles`),
- `components/home/DistrictDetailModal.tsx` (`modalStyles`),
- `components/invoice/InvoiceItem.tsx` (`invoiceItemStyles`).

This is used when styles are tightly coupled to component internals/animation logic.

### 4) Inline style objects for one-off adjustments

Inline styles are used intentionally for:

- tiny one-off layout wrappers,
- runtime values (e.g., from props/data),
- simple color/opacity toggles.

Examples: avatar color tint, map legend dot colors, quick wrapper spacing blocks, gesture root `flex: 1`.

## Dark mode and platform differences

### Dark mode

- There is infrastructure for scheme detection:
  - `hooks/use-color-scheme.ts` + web hydration-safe variant,
  - `hooks/use-theme-color.ts`,
  - `constants/theme.ts` with `Colors.light/dark`.
- Tabs consume `useColorScheme` for active tint color (`app/(tabs)/_layout.tsx`).
- Root `ThemeProvider` exists (`app/_layout.tsx`) but currently passes `DarkTheme` for both branches.
- Most screens/components use fixed dark palette values directly, so UI is effectively dark-first rather than fully dual-themed.
- Some specific surfaces (invoice print/preview card) are intentionally light (`#ffffff`) independent of app shell.

### Platform differences

Platform handling is pragmatic and targeted:

- `Platform.OS` checks for keyboard and bottom spacing:
  - `KeyboardAvoidingView` behavior (`"padding"` on iOS, `"height"` elsewhere),
  - iOS-specific bottom nav padding,
  - Android extra modal bottom padding in payment modal.
- Safe area is handled via `SafeAreaView` + `useSafeAreaInsets` for final footer padding.
- Font token definitions in `constants/theme.ts` use `Platform.select`.
- Responsive helpers adapt layout/typography to screen dimensions.

## Rules of thumb for reading UI code in this repo

1. Start from route files in `app/` to see page composition and navigation wiring.
2. Jump from route to feature components in `components/<feature>/`.
3. For visuals, open matching style file first (`styles/<feature>.ts`), then local component styles if needed.
4. Expect dark-first defaults and hex colors in style sheets.
5. Treat `scale`/`verticalScale`/`moderateScale` as the spacing/type system; interpret all sizes through that lens.
6. Read style arrays as state machines: first base, then variants, then inline overrides.
7. Check `Pressable style={({ pressed }) => ...}` and conditional style arrays for interaction feedback.
8. For keyboard/modal behavior, scan for `Platform.OS`, `KeyboardAvoidingView`, and `SafeAreaView` usage.
9. If a style key is missing in a component, search both the feature style file and local `StyleSheet.create` blocks.
10. For theme-related changes, verify both actual usage and infra status (`useThemeColor` exists but is currently mostly unused).

## Quick references

- Theme primitives: `constants/theme.ts`
- Responsive sizing: `utils/responsive.ts`
- Shared style primitives: `styles/common.ts`
- Feature style maps: `styles/home.ts`, `styles/contacts.ts`, `styles/products.ts`, `styles/invoice.ts`
- Root and tabs theming hooks: `app/_layout.tsx`, `app/(tabs)/_layout.tsx`, `hooks/use-color-scheme.ts`, `hooks/use-theme-color.ts`
