# ft_swifty_companion

Swifty Companion implemented with Flutter.

## Setup

1. Copy `.env.example` to `.env`.
2. Fill values from your 42 API app:
   - `INTRA_UID`
   - `INTRA_SECRET`
3. Install dependencies:
   - `flutter pub get`
4. Run:
   - `flutter run`

## Defense Quick Start

- `make check` - verify Flutter and `.env`.
- `make setup` - create `.env`, recreate `android/ios` if missing, install dependencies.
- `make install_flutter` - install Flutter with Homebrew (macOS).
- `make setup_auto` - auto-install Flutter (if needed) + dependencies.
- `make analyze` - static checks.
- `make test` - run tests.
- `make run` - launch on connected device/emulator.

## Mandatory coverage

- Two views: search view and profile view.
- Error handling: missing config, unknown login, API/network errors.
- Profile details include login, email, mobile, level, location, wallet, and avatar.
- Skills are displayed with level and percentage.
- Projects list includes passed and failed projects.
- Back navigation is handled by regular Flutter navigation.
- Responsive UI uses `LayoutBuilder`, `ConstrainedBox`, and `Wrap`.

## Bonus coverage

- OAuth token is cached and reused.
- Token is refreshed on expiration and retried on 401.
