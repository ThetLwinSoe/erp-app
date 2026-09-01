# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Flutter mobile app for Sales Representatives to perform sales operations against a separate ERP System backend (not in this repo). Sale Reps have restricted access: only their own sales, read-only customers/products, no purchases/inventory.

## Commands

```bash
flutter pub get                    # install dependencies
flutter run                        # run on connected device/emulator
flutter test                       # run all tests
flutter test test/widget_test.dart # run a single test file
flutter analyze                    # lint/static analysis (uses analysis_options.yaml)
flutter build apk --release        # Android production build
flutter build ios --release        # iOS production build
```

## Backend configuration

The API base URL is hardcoded in [lib/config/constants.dart](lib/config/constants.dart) (`AppConstants.baseUrl`). There's no `.env`/flavor system — switching between local backend, Android emulator (`10.0.2.2`), iOS simulator (`localhost`), a physical device, and the deployed Render URL means editing this constant directly (other options are left commented out inline).

## Architecture

Layered structure, one directory per layer, repeated per domain (auth, sales, customers, products):

```
services/  -> raw API calls (Dio), return ApiResponse<T> / PaginatedResponse<T>
providers/ -> ChangeNotifier state holders, call services, expose getters + notifyListeners()
screens/   -> Consumer/context.read<Provider>() widgets, grouped by domain in subfolders
models/    -> plain Dart classes with fromJson/toJson
```

- **`ApiService`** ([lib/services/api_service.dart](lib/services/api_service.dart)) is a singleton wrapping Dio. It injects the bearer token from `flutter_secure_storage` on every request via an interceptor, and defines the shared `ApiResponse<T>` / `PaginatedResponse<T>` wrapper types every service returns.
- Each `*Service` (e.g. `AuthService`, `SalesService`) calls `ApiService`, catches `DioException`, and maps it to a user-facing message string inside `ApiResponse.error(...)`. Screens never talk to Dio directly.
- Each `*Provider` mirrors this: holds loading/error/pagination state, calls its service, and calls `notifyListeners()` after every state change (including on failure, to surface `errorMessage`). Follow the existing pattern in [lib/providers/sales_provider.dart](lib/providers/sales_provider.dart) when adding provider methods (set loading → call service → update state or error → clear loading → notify).
- Providers are registered app-wide via `MultiProvider` in [lib/main.dart](lib/main.dart) (`AuthProvider`, `SalesProvider`, `CustomerProvider`, `ProductProvider`) — no per-screen provider scoping.
- Auth/session flow: `AuthWrapper` in [lib/main.dart](lib/main.dart) drives navigation off `AuthProvider.status` (`initial`/`loading` → splash, `authenticated` → `HomeScreen`, `unauthenticated`/`error` → `LoginScreen`). JWT token and last-known user JSON are persisted in `flutter_secure_storage`; `checkAuthStatus()` tries a live `/auth/me` call first and falls back to the cached user if that fails (so the app can open while offline if previously logged in).
- Pagination follows a consistent shape across list providers: `currentPage`/`totalPages`/`totalItems` plus `hasNextPage`/`loadNextPage()`/`refreshSales()`-style methods that append vs. replace `_sales` depending on `refresh`/`page` — replicate this shape for any new paginated list rather than inventing a new one.
