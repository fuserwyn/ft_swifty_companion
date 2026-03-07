SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

FLUTTER ?= $(shell command -v flutter 2>/dev/null || echo $$HOME/flutter/bin/flutter)
ENV_FILE := .env
ENV_EXAMPLE := .env.example

.PHONY: help check setup devices run run_device apk unapk analyze test clean

help:
	@echo "Available targets:"
	@echo "  make setup                     - Validate config and install dependencies"
	@echo "  make check                     - Validate Flutter and .env configuration"
	@echo "  make devices                   - List detected Flutter devices"
	@echo "  make run                       - Run app on default selected device"
	@echo "  make run_device DEVICE=<id>    - Run app on a specific device"
	@echo "  make apk                       - Build release APK"
	@echo "  make unapk                     - Remove APK/build artifacts"
	@echo "  make analyze                   - Run static analysis"
	@echo "  make test                      - Run tests"
	@echo "  make clean                     - flutter clean"

_check_flutter:
	@if [[ ! -x "$(FLUTTER)" ]]; then \
		echo "Error: Flutter is not installed or not in PATH."; \
		echo "Install Flutter: https://docs.flutter.dev/get-started/install"; \
		exit 1; \
	fi
	@echo "Flutter SDK found: $$($(FLUTTER) --version | sed -n '1p')"

_check_env:
	@if [[ ! -f "$(ENV_FILE)" ]]; then \
		echo "Error: $(ENV_FILE) is missing."; \
		if [[ -f "$(ENV_EXAMPLE)" ]]; then \
			echo "Run: cp $(ENV_EXAMPLE) $(ENV_FILE)"; \
		else \
			echo "Create $(ENV_FILE) with:"; \
			echo "  INTRA_UID=..."; \
			echo "  INTRA_SECRET=..."; \
		fi; \
		exit 1; \
	fi
	@if ! grep -q '^INTRA_UID=' "$(ENV_FILE)" || ! grep -q '^INTRA_SECRET=' "$(ENV_FILE)"; then \
		echo "Error: $(ENV_FILE) must contain INTRA_UID and INTRA_SECRET."; \
		exit 1; \
	fi

check: _check_flutter _check_env
	@echo "Environment check completed."

setup: check
	$(FLUTTER) pub get
	@echo "Setup completed."

devices: _check_flutter
	$(FLUTTER) devices

run: setup
	$(FLUTTER) run

run_device: setup
	@if [[ -z "$(DEVICE)" ]]; then \
		echo "Usage: make run_device DEVICE=<flutter_device_id>"; \
		exit 1; \
	fi
	$(FLUTTER) run -d "$(DEVICE)"

apk: setup
	$(FLUTTER) build apk

unapk: _check_flutter
	$(FLUTTER) clean
	rm -rf build .dart_tool
	@echo "APK and build artifacts removed."

analyze: setup
	$(FLUTTER) analyze

test: setup
	$(FLUTTER) test

clean: _check_flutter
	$(FLUTTER) clean
