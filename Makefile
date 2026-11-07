SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

PROJECT   := SwiftyCompanion.xcodeproj
SCHEME    := SwiftyCompanion
SIMULATOR ?= iPhone 17
DEST      := platform=iOS Simulator,name=$(SIMULATOR)
SECRETS   := .env

.PHONY: help env project open build test run clean

help:
	@echo "make env      - create .env from .env.example"
	@echo "make project  - regenerate $(PROJECT) from project.yml (needs xcodegen)"
	@echo "make open     - open the project in Xcode"
	@echo "make build    - build for simulator ($(SIMULATOR))"
	@echo "make test     - run unit tests"
	@echo "make run      - build, install and launch in simulator"
	@echo "make clean    - remove build artifacts"

env:
	@if [[ -f "$(SECRETS)" ]]; then echo "$(SECRETS) already exists."; \
	else cp .env.example "$(SECRETS)"; echo "Created $(SECRETS) - fill INTRA_UID and INTRA_SECRET."; fi

project:
	xcodegen generate

open:
	open $(PROJECT)

build:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -destination '$(DEST)' -derivedDataPath build build

test:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -destination '$(DEST)' -derivedDataPath build test

run: build
	xcrun simctl boot "$(SIMULATOR)" 2>/dev/null || true
	open -a Simulator
	xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/$(SCHEME).app
	xcrun simctl launch booted fr.fortytwo.swiftycompanion

clean:
	rm -rf build
