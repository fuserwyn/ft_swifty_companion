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
- `make install_flutter` - install Flutter automatically for macOS/Linux.
- `make install_flutter_macos` - install Flutter with Homebrew.
- `make install_flutter_linux` - install Flutter with snap (`sudo` required).
- `make install_flutter_local` - install Flutter in `$HOME/flutter` (Linux, no sudo).
- `make setup_auto` - auto-install Flutter (if needed) + dependencies.
- `make devices` - list detected devices.
- `make emulators` - list available emulators.
- `make start_emulator EMULATOR=<id>` - launch an emulator.
- `make analyze` - static checks.
- `make test` - run tests.
- `make run` - launch on connected device/emulator.
- `make run_device DEVICE=<id>` - run on a specific device.
- `make run_macos` / `make run_web` - recreate and run desktop/web targets.

## Build Instructions (Makefile)

1. Install Flutter (only if not installed):
   - `make install_flutter`
   - Linux alternative: `make install_flutter_linux`
   - Linux without sudo: `make install_flutter_local`
   - macOS alternative: `make install_flutter_macos`
2. Prepare project after clone:
   - `make setup`
   - This command auto-creates `.env` from `.env.example` and recreates `android/ios` if they were removed from the repository.
3. Add your 42 API credentials in `.env`:
   - `INTRA_UID=...`
   - `INTRA_SECRET=...`
4. Verify project:
   - `make analyze`
   - `make test`
5. Run app:
   - `make run` (connected mobile device/emulator)
   - or `make run_device DEVICE=<id>`

### Minimal Repository Workflow

- The repository can stay minimal (without generated platform folders).
- On defense machine, run `make setup` to regenerate required folders and install dependencies.
- Generated folders (`android/`, `ios/`, `.dart_tool/`, `build/`) can be removed locally anytime and recreated with `make setup`.

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
