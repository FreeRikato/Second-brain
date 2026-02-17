# Startup Configuration Trace

## Boot Sequence (Startup to First Screen)

1. Expo starts from `package.json` with `"main": "expo-router/entry"`, so Expo Router controls app bootstrap (`package.json:3`).
2. Expo Router resolves the root layout in `app/_layout.tsx`, which is the app-level composition point (`app/_layout.tsx:20`).
3. Startup polyfills load before other runtime code: `react-native-get-random-values`, `react-native-url-polyfill/auto`, and `text-encoding` (`app/_layout.tsx:1`, `app/_layout.tsx:2`, `app/_layout.tsx:3`, `app/_layout.tsx:4`).
4. Theme signal is read through `useColorScheme` (`app/_layout.tsx:11`, `app/_layout.tsx:21`).
5. Environment config is read and validated in `utils/config.ts`:
   - Schema expects `CONVEX_URL` as non-empty string (`utils/config.ts:3`, `utils/config.ts:4`).
   - Value is sourced from `process.env.EXPO_PUBLIC_CONVEX_URL` (`utils/config.ts:8`).
   - `envSchema.parse(...)` performs runtime validation and can throw on invalid/missing input (`utils/config.ts:7`).
6. Convex client is initialized with validated config and then injected via provider:
   - Client creation: `new ConvexReactClient(config.CONVEX_URL, ...)` (`app/_layout.tsx:24`).
   - Provider: `<ConvexProvider client={convex}>` (`app/_layout.tsx:30`).
7. Root providers/wrappers are composed in this order:
   - `GestureHandlerRootView` (`app/_layout.tsx:29`)
   - `ConvexProvider` (`app/_layout.tsx:30`)
   - `ThemeProvider` (`app/_layout.tsx:31`)
   - `SafeAreaProvider` (`app/_layout.tsx:33`)
8. Root navigation stack is registered in `app/_layout.tsx` using Expo Router `<Stack>` with tabs and detail/create routes (`app/_layout.tsx:34`, `app/_layout.tsx:35`, `app/_layout.tsx:37`, `app/_layout.tsx:43`, `app/_layout.tsx:49`, `app/_layout.tsx:55`, `app/_layout.tsx:61`, `app/_layout.tsx:68`, `app/_layout.tsx:74`).
9. Tabs are anchored by `unstable_settings.anchor = "(tabs)"`, making the tab group the main root flow (`app/_layout.tsx:16`, `app/_layout.tsx:17`).
10. Bottom tab navigator is configured in `app/(tabs)/_layout.tsx` (`app/(tabs)/_layout.tsx:3`, `app/(tabs)/_layout.tsx:13`), mapping to `index`, `invoice`, `contact`, and `product` tabs (`app/(tabs)/_layout.tsx:23`, `app/(tabs)/_layout.tsx:32`, `app/(tabs)/_layout.tsx:45`, `app/(tabs)/_layout.tsx:55`).
11. The home tab (`app/(tabs)/index.tsx`) executes initial data hooks (`useUser`, `useInvoices`) that hit Convex via `useQuery`/`useMutation` (`app/(tabs)/index.tsx:17`, `app/(tabs)/index.tsx:18`, `hooks/useUser.ts:7`, `hooks/useUser.ts:8`, `hooks/useInvoices.ts:15`, `hooks/useInvoices.ts:23`).

## Environment Config and Convex URL Validation

- Config read location: `utils/config.ts`.
- Validation mechanism: Zod schema + parse.
- Validation rule currently implemented: non-empty string only.

Flow:

1. `process.env.EXPO_PUBLIC_CONVEX_URL` is read into `CONVEX_URL` (`utils/config.ts:8`).
2. `envSchema.parse(...)` validates it (`utils/config.ts:7`).
3. Parsed config is exported and imported by root layout (`utils/config.ts:11`, `app/_layout.tsx:12`).
4. Result is used directly to initialize `ConvexReactClient` (`app/_layout.tsx:24`).

## Platform-Specific Behavior

### iOS / Android / Web conditionals

- Web-specific color-scheme hydration path:
  - Native builds re-export RN hook (`hooks/use-color-scheme.ts:1`).
  - Web build delays return until hydration (`hooks/use-color-scheme.web.ts:8`, `hooks/use-color-scheme.web.ts:17`, `hooks/use-color-scheme.web.ts:21`).
- Font families are selected per platform via `Platform.select` (`constants/theme.ts:30`).
- Device type classification uses `Platform.select` and width breakpoint (`utils/responsive.ts:35`, `utils/responsive.ts:38`).
- Keyboard handling switches by platform (`Platform.OS === "ios" ? "padding" : "height"`):
  - `components/common/ScreenLayout.tsx:89`
  - `components/invoice/PaymentModal.tsx:187`
  - `components/invoice/DiscountModal.tsx:253`
- iOS-specific bottom padding in style layers:
  - `styles/common.ts:120`
  - `styles/contacts.ts:190`
- App-level platform config in Expo manifest:
  - iOS tablet support (`app.json:11`, `app.json:12`)
  - Android edge-to-edge and predictive back config (`app.json:21`, `app.json:22`)
  - Web static output (`app.json:24`, `app.json:25`)

### Permissions and capability-related behavior (camera/files/printing/sharing)

- Camera:
  - No camera module usage found.
  - No camera permission declarations found in `app.json`.
- Files:
  - Uses `expo-file-system/legacy` for app document directory copy/getInfo/delete (`utils/pdfService.ts:1`, `utils/pdfService.ts:57`, `utils/pdfService.ts:59`, `utils/pdfService.ts:121`, `utils/pdfService.ts:133`).
- Printing:
  - Uses `expo-print` `printToFileAsync` for PDF generation (`utils/pdfService.ts:2`, `utils/pdfService.ts:45`).
- Sharing:
  - Uses `expo-sharing` with runtime availability check (`utils/pdfService.ts:3`, `utils/pdfService.ts:95`, `utils/pdfService.ts:100`).
  - Invoice share flows invoke PDF generation + share from hook/screen paths (`hooks/useInvoiceShare.ts:58`, `hooks/useInvoiceShare.ts:61`, `app/invoice/[id].tsx:179`).
- Explicit runtime permission request APIs:
  - None found for camera/media/files in app code.

### Third-Party Native Modules and Expo Plugins

- Expo plugins configured:
  - `expo-router` (`app.json:29`)
  - `expo-splash-screen` (`app.json:31`)
  - `expo-font` (`app.json:42`)
- Native/bridged modules imported in app code:
  - `convex/react` (`app/_layout.tsx:7`)
  - `expo-router` (`app/_layout.tsx:8`)
  - `expo-status-bar` (`app/_layout.tsx:9`)
  - `react-native-gesture-handler` (`app/_layout.tsx:10`)
  - `react-native-safe-area-context` (`app/_layout.tsx:14`)
  - `react-native-reanimated` (`app/_layout.tsx:13`)
  - `react-native-worklets` (`app/settings.tsx:18`)
  - `expo-file-system/legacy`, `expo-print`, `expo-sharing` (`utils/pdfService.ts:1`, `utils/pdfService.ts:2`, `utils/pdfService.ts:3`)
  - `react-native-svg` (`components/home/TamilNaduMap.tsx:3`)
- Startup polyfill imports:
  - `react-native-get-random-values`, `react-native-url-polyfill/auto`, `text-encoding` (`app/_layout.tsx:2`, `app/_layout.tsx:3`, `app/_layout.tsx:4`)
- Babel plugin for worklets:
  - `react-native-worklets/plugin` (`babel.config.js:7`)

## Platform-Difference Risks and Assumptions (No Fixes)

1. `EXPO_PUBLIC_CONVEX_URL` is required at runtime; missing or empty value will fail during `envSchema.parse(...)` at startup (`utils/config.ts:7`, `utils/config.ts:8`).
2. URL validation is minimal (non-empty string only), so malformed-but-non-empty endpoints can pass config validation and fail later during network use (`utils/config.ts:4`).
3. ThemeProvider currently passes `DarkTheme` for both branches of the color-scheme condition, so startup theming behavior appears effectively dark-only (`app/_layout.tsx:31`).
4. Two root `StatusBar` declarations with different styles may create platform-dependent status bar behavior (`app/_layout.tsx:32`, `app/_layout.tsx:80`).
5. Web color scheme returns `null` until hydration, so initial theme-dependent UI can differ between first render and hydrated render (`hooks/use-color-scheme.web.ts:17`, `hooks/use-color-scheme.web.ts:21`).
6. Keyboard avoidance and bottom insets are tuned with iOS/Android branches, which may not behave uniformly across all device classes (small phones, tablets, gesture-nav Android) (`components/common/ScreenLayout.tsx:89`, `components/invoice/PaymentModal.tsx:37`, `styles/common.ts:120`).
7. Printing and file-system based PDF flows depend on platform support for `expo-print`, `expo-file-system`, and `expo-sharing`; unsupported environments rely on runtime fallback behavior (`utils/pdfService.ts:45`, `utils/pdfService.ts:57`, `utils/pdfService.ts:95`).
8. Sharing success is platform-dependent and guarded by availability checks; unsupported platforms return unsuccessful share attempts (`utils/pdfService.ts:95`, `utils/pdfService.ts:97`).
9. App config intentionally diverges by platform (Android predictive back disabled, iOS tablet enabled, web static output), so navigation and layout expectations differ across targets (`app.json:12`, `app.json:22`, `app.json:25`).
10. Responsive device-type heuristics are width-based and may misclassify edge cases (split screen/foldables), affecting platform-tailored sizing assumptions (`utils/responsive.ts:35`, `utils/responsive.ts:38`).
