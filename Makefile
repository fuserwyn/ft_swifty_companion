SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

FLUTTER ?= $(shell command -v flutter 2>/dev/null || echo $$HOME/flutter/bin/flutter)
FLUTTER_VERSION ?= 3.41.4
ANDROID_SDK_ROOT ?= $(HOME)/Library/Android/sdk
JAVA17_HOME ?= /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
ENV_FILE := .env
ENV_EXAMPLE := .env.example
MOBILE_PLATFORMS := android,ios

.PHONY: help check install_flutter install_flutter_macos install_flutter_linux install_flutter_local \
	setup_android_phone setup devices run run_device run_android analyze test clean \
	bootstrap validate ready all

help:
	@echo "Available targets:"
	@echo "  make all                 - Full pipeline (bootstrap + validate)"
	@echo "  make ready               - One-command setup + checks"
	@echo "  make bootstrap           - Install tooling and prepare project"
	@echo "  make validate            - Run check + analyze + test"
	@echo "  make install_flutter      - Install Flutter (macOS/Linux auto-detect)"
	@echo "  make setup_android_phone  - Install Android tools and configure SDK (macOS)"
	@echo "  make setup                - Create .env, recreate android/ios, pub get"
	@echo "  make check                - Validate Flutter and .env presence"
	@echo "  make devices              - List detected Flutter devices"
	@echo "  make run_android          - Run on first Android device"
	@echo "  make run_device DEVICE=<id> - Run on a specific device id"
	@echo "  make analyze              - Run static analysis"
	@echo "  make test                 - Run tests"
	@echo "  make clean                - flutter clean"

bootstrap:
	$(MAKE) install_flutter
	@if [[ "$$(uname -s)" == "Darwin" ]]; then $(MAKE) setup_android_phone; fi
	$(MAKE) setup

validate:
	$(MAKE) check
	$(MAKE) analyze
	$(MAKE) test

ready:
	$(MAKE) bootstrap
	$(MAKE) validate

all:
	$(MAKE) ready

_check_flutter:
	@if [[ ! -x "$(FLUTTER)" ]]; then \
		echo "Error: Flutter is not installed or not in PATH."; \
		echo "Run: make install_flutter"; \
		exit 1; \
	fi
	@echo "Flutter SDK found: $$($(FLUTTER) --version | sed -n '1p')"

_check_env:
	@if [[ ! -f "$(ENV_FILE)" ]]; then \
		echo "Warning: $(ENV_FILE) is missing."; \
		echo "Run: make setup"; \
	fi

check: _check_flutter _check_env
	@echo "Environment check completed."

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
		echo "Unsupported OS. Install manually: https://docs.flutter.dev/get-started/install"; \
		exit 1; \
	fi

install_flutter_macos:
	brew install --cask flutter

install_flutter_linux:
	sudo snap install flutter --classic

install_flutter_local:
	@if [[ "$$(uname -s)" != "Linux" ]]; then \
		echo "install_flutter_local is Linux-only."; \
		exit 1; \
	fi
	@ARCH="$$(uname -m)"; \
	if [[ "$$ARCH" == "x86_64" ]]; then ARCH="x64"; \
	elif [[ "$$ARCH" == "aarch64" || "$$ARCH" == "arm64" ]]; then ARCH="arm64"; \
	else echo "Unsupported Linux arch $$ARCH"; exit 1; fi; \
	URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_$$ARCH_$(FLUTTER_VERSION)-stable.tar.xz"; \
	curl -L "$$URL" -o /tmp/flutter-$(FLUTTER_VERSION)-stable.tar.xz; \
	rm -rf "$$HOME/flutter"; \
	tar xf /tmp/flutter-$(FLUTTER_VERSION)-stable.tar.xz -C "$$HOME"; \
	rm -f /tmp/flutter-$(FLUTTER_VERSION)-stable.tar.xz; \
	echo 'Add to PATH: export PATH="$$HOME/flutter/bin:$$PATH"'

setup_android_phone:
	@if [[ "$$(uname -s)" != "Darwin" ]]; then \
		echo "setup_android_phone is for macOS only."; \
		exit 1; \
	fi
	brew install android-platform-tools openjdk@17
	brew install --cask android-commandlinetools
	@mkdir -p "$(ANDROID_SDK_ROOT)"
	$(FLUTTER) config --android-sdk "$(ANDROID_SDK_ROOT)"
	@export JAVA_HOME="$(JAVA17_HOME)"; \
	export PATH="$$JAVA_HOME/bin:$$PATH"; \
	yes | /opt/homebrew/share/android-commandlinetools/cmdline-tools/latest/bin/sdkmanager \
		--sdk_root="$(ANDROID_SDK_ROOT)" \
		"cmdline-tools;latest" \
		"platform-tools" \
		"platforms;android-36" \
		"build-tools;36.0.0" \
		"build-tools;28.0.3"; \
	yes | /opt/homebrew/share/android-commandlinetools/cmdline-tools/latest/bin/sdkmanager \
		--sdk_root="$(ANDROID_SDK_ROOT)" --licenses >/dev/null
	@echo "Android phone toolchain is ready."

setup: _check_flutter
	@if [[ ! -f "$(ENV_FILE)" && -f "$(ENV_EXAMPLE)" ]]; then cp "$(ENV_EXAMPLE)" "$(ENV_FILE)"; fi
	@if [[ ! -d "android" || ! -d "ios" ]]; then $(FLUTTER) create --platforms=$(MOBILE_PLATFORMS) .; fi
	$(FLUTTER) pub get
	@echo "Setup completed."

devices: _check_flutter
	$(FLUTTER) devices

run: setup
	@export JAVA_HOME="$(JAVA17_HOME)"; \
	export PATH="$$JAVA_HOME/bin:$$PATH"; \
	$(FLUTTER) run

run_device: setup
	@if [[ -z "$(DEVICE)" ]]; then echo "Usage: make run_device DEVICE=<flutter_device_id>"; exit 1; fi
	@export JAVA_HOME="$(JAVA17_HOME)"; \
	export PATH="$$JAVA_HOME/bin:$$PATH"; \
	$(FLUTTER) run -d "$(DEVICE)"

run_android: setup
	@export JAVA_HOME="$(JAVA17_HOME)"; \
	export PATH="$$JAVA_HOME/bin:$$PATH"; \
	$(FLUTTER) run -d android

analyze: setup
	$(FLUTTER) analyze

test: setup
	$(FLUTTER) test

clean: _check_flutter
	$(FLUTTER) clean
