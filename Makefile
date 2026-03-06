SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

FLUTTER ?= $(shell command -v flutter 2>/dev/null || echo $$HOME/flutter/bin/flutter)
FLUTTER_VERSION ?= 3.41.4
ENV_FILE := .env
ENV_EXAMPLE := .env.example
MOBILE_PLATFORMS := android,ios
DESKTOP_WEB_PLATFORMS := macos,web

.PHONY: help doctor check check_flutter check_env init_env install_flutter install_flutter_macos install_flutter_linux install_flutter_local \
	setup setup_auto deps platforms_mobile platforms_desktop_web \
	run run_device run_macos run_web \
	devices emulators start_emulator analyze test clean

help:
	@echo "Available targets:"
	@echo "  make check               - Check Flutter and .env presence"
	@echo "  make doctor              - Run flutter doctor -v"
	@echo "  make install_flutter     - Install Flutter (macOS/Linux auto-detect)"
	@echo "  make install_flutter_macos - Install Flutter via Homebrew"
	@echo "  make install_flutter_linux - Install Flutter via snap"
	@echo "  make install_flutter_local - Install Flutter to $$HOME/flutter (Linux, no sudo)"
	@echo "  make setup               - Init .env, recreate android/ios, pub get"
	@echo "  make setup_auto          - Install Flutter (if needed) + setup"
	@echo "  make run                 - Run on connected mobile device/emulator"
	@echo "  make run_device DEVICE=<id> - Run on specific device"
	@echo "  make run_macos           - Enable macOS platform and run"
	@echo "  make run_web             - Enable web platform and run in Chrome"
	@echo "  make devices             - List Flutter devices"
	@echo "  make emulators           - List emulators"
	@echo "  make start_emulator EMULATOR=<id> - Launch emulator"
	@echo "  make analyze             - Run static analysis"
	@echo "  make test                - Run tests"
	@echo "  make clean               - flutter clean"

check_flutter:
	@if [[ ! -x "$(FLUTTER)" ]]; then \
		echo "Error: Flutter is not installed or not in PATH."; \
		echo "Run: make install_flutter (or make install_flutter_local on Linux)"; \
		exit 1; \
	fi
	@echo "Flutter SDK found: $$($(FLUTTER) --version | sed -n '1p')"

check_env:
	@if [[ ! -f "$(ENV_FILE)" ]]; then \
		echo "Warning: $(ENV_FILE) is missing."; \
		if [[ -f "$(ENV_EXAMPLE)" ]]; then \
			echo "Run: make setup (it will create $(ENV_FILE) from $(ENV_EXAMPLE))."; \
		fi; \
	fi
	@echo "Environment check completed."

check: check_flutter check_env

doctor: check_flutter
	$(FLUTTER) doctor -v

install_flutter:
	@if [[ "$$(uname -s)" == "Darwin" ]]; then \
		$(MAKE) install_flutter_macos; \
	elif [[ "$$(uname -s)" == "Linux" ]]; then \
		if command -v snap >/dev/null 2>&1; then \
			$(MAKE) install_flutter_linux; \
		else \
			$(MAKE) install_flutter_local; \
		fi; \
	else \
		echo "Error: unsupported OS for automatic installation."; \
		echo "Install Flutter manually: https://docs.flutter.dev/get-started/install"; \
		exit 1; \
	fi

install_flutter_macos:
	@if ! command -v brew >/dev/null 2>&1; then \
		echo "Error: Homebrew is not installed. See https://brew.sh"; \
		exit 1; \
	fi
	brew install --cask flutter
	@echo "Flutter installed. You can now run: make setup"

install_flutter_linux:
	@if ! command -v snap >/dev/null 2>&1; then \
		echo "Error: snap is not installed."; \
		echo "Run: make install_flutter_local (no sudo install in HOME)."; \
		exit 1; \
	fi
	sudo snap install flutter --classic
	@echo "Flutter installed. You can now run: make setup"

install_flutter_local:
	@if [[ "$$(uname -s)" != "Linux" ]]; then \
		echo "Error: install_flutter_local is for Linux only."; \
		exit 1; \
	fi
	@ARCH="$$(uname -m)"; \
	if [[ "$$ARCH" == "x86_64" ]]; then ARCH="x64"; \
	elif [[ "$$ARCH" == "aarch64" || "$$ARCH" == "arm64" ]]; then ARCH="arm64"; \
	else echo "Error: unsupported Linux arch $$ARCH"; exit 1; fi; \
	URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_$$ARCH_$(FLUTTER_VERSION)-stable.tar.xz"; \
	echo "Downloading Flutter $(FLUTTER_VERSION) for $$ARCH..."; \
	curl -L "$$URL" -o /tmp/flutter-$(FLUTTER_VERSION)-stable.tar.xz; \
	rm -rf "$$HOME/flutter"; \
	tar xf /tmp/flutter-$(FLUTTER_VERSION)-stable.tar.xz -C "$$HOME"; \
	rm -f /tmp/flutter-$(FLUTTER_VERSION)-stable.tar.xz; \
	echo "Installed to $$HOME/flutter"; \
	echo 'Add to PATH: export PATH="$$HOME/flutter/bin:$$PATH"'

init_env:
	@if [[ ! -f "$(ENV_FILE)" ]]; then \
		if [[ -f "$(ENV_EXAMPLE)" ]]; then \
			cp "$(ENV_EXAMPLE)" "$(ENV_FILE)"; \
			echo "Created $(ENV_FILE) from $(ENV_EXAMPLE)."; \
		else \
			echo "Warning: $(ENV_EXAMPLE) not found, cannot auto-create $(ENV_FILE)."; \
		fi; \
	fi

platforms_mobile: check_flutter
	@if [[ ! -d "android" || ! -d "ios" ]]; then \
		echo "Mobile platforms missing. Recreating android/ios..."; \
		$(FLUTTER) create --platforms=$(MOBILE_PLATFORMS) .; \
	fi

platforms_desktop_web: check_flutter
	@if [[ ! -d "macos" || ! -d "web" ]]; then \
		echo "Desktop/web platforms missing. Recreating macos/web..."; \
		$(FLUTTER) create --platforms=$(DESKTOP_WEB_PLATFORMS) .; \
	fi

deps: check_flutter
	$(FLUTTER) pub get

setup: check_flutter init_env platforms_mobile deps
	@echo "Setup completed."

setup_auto:
	@if ! command -v "$(FLUTTER)" >/dev/null 2>&1; then \
		$(MAKE) install_flutter; \
	fi
	@$(MAKE) setup

run: setup
	$(FLUTTER) run

run_device: setup
	@if [[ -z "$(DEVICE)" ]]; then \
		echo "Usage: make run_device DEVICE=<flutter_device_id>"; \
		exit 1; \
	fi
	$(FLUTTER) run -d "$(DEVICE)"

run_macos: check_flutter init_env platforms_desktop_web deps
	$(FLUTTER) run -d macos

run_web: check_flutter init_env platforms_desktop_web deps
	$(FLUTTER) run -d chrome

devices: check_flutter
	$(FLUTTER) devices

emulators: check_flutter
	$(FLUTTER) emulators

start_emulator: check_flutter
	@if [[ -z "$(EMULATOR)" ]]; then \
		echo "Usage: make start_emulator EMULATOR=<emulator_id>"; \
		exit 1; \
	fi
	$(FLUTTER) emulators --launch "$(EMULATOR)"

analyze: setup
	$(FLUTTER) analyze

test: setup
	$(FLUTTER) test

clean: check_flutter
	$(FLUTTER) clean
