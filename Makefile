.PHONY: help check setup setup_auto install_flutter run analyze test clean

help:
	@echo "Available targets:"
	@echo "  make check    - Check Flutter and local env setup"
	@echo "  make setup    - Install dependencies"
	@echo "  make setup_auto - Setup with auto Flutter install (brew)"
	@echo "  make install_flutter - Install Flutter via Homebrew"
	@echo "  make run      - Run app on connected device"
	@echo "  make analyze  - Run static analysis"
	@echo "  make test     - Run tests"
	@echo "  make clean    - Clean build artifacts"

check:
	@./scripts/setup.sh --check-only

setup:
	@./scripts/setup.sh

setup_auto:
	@./scripts/setup.sh --install-flutter

install_flutter:
	@./scripts/setup.sh --check-only --install-flutter

run: setup
	flutter run

analyze: setup
	flutter analyze

test: setup
	flutter test

clean:
	flutter clean
