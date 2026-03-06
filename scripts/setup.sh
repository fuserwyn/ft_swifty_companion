#!/usr/bin/env bash

set -euo pipefail

CHECK_ONLY=false
INSTALL_FLUTTER=false

for arg in "$@"; do
  case "$arg" in
    --check-only)
      CHECK_ONLY=true
      ;;
    --install-flutter)
      INSTALL_FLUTTER=true
      ;;
    *)
      echo "Unknown option: $arg"
      echo "Usage: ./scripts/setup.sh [--check-only] [--install-flutter]"
      exit 1
      ;;
  esac
done

if ! command -v flutter >/dev/null 2>&1; then
  if [[ "${INSTALL_FLUTTER}" == "true" ]]; then
    if [[ "$(uname -s)" != "Darwin" ]]; then
      echo "Error: Auto-install supports macOS only (Homebrew)."
      exit 1
    fi
    if ! command -v brew >/dev/null 2>&1; then
      echo "Error: Homebrew is not installed."
      echo "Install Homebrew first: https://brew.sh"
      exit 1
    fi

    echo "Flutter is missing. Installing via Homebrew..."
    brew install --cask flutter
  else
    echo "Error: Flutter is not installed or not in PATH."
    echo "Install Flutter SDK or run: make install_flutter"
    exit 1
  fi
fi

echo "Flutter SDK found: $(flutter --version | sed -n '1p')"

if [[ "${CHECK_ONLY}" == "true" ]]; then
  if [[ ! -f ".env" ]]; then
    echo "Warning: .env is missing."
    if [[ -f ".env.example" ]]; then
      echo "Run: make setup (it will create .env from .env.example)."
    fi
  fi
  echo "Environment check completed."
  exit 0
fi

if [[ ! -f ".env" ]]; then
  if [[ -f ".env.example" ]]; then
    cp .env.example .env
    echo "Created .env from .env.example."
  else
    echo "Warning: .env is missing and .env.example not found."
  fi
fi

if [[ ! -d "android" || ! -d "ios" ]]; then
  echo "Mobile platform folders are missing. Recreating android/ios..."
  flutter create --platforms=android,ios .
fi

echo "Installing dependencies..."
flutter pub get

echo "Setup completed."
