# Changelog

All notable changes to the TouchIndicator iOS SDK are documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- `TouchIndicator.enable(configuration:allowInAppStore:)` / `disable()` / `isEnabled`.
- Window-level `UIGestureRecognizer` observer that never consumes touches (no swizzling).
- Indicators on every visible window, including windows UIKit creates for sheets and alerts.
- Build-environment gate: allowed in DEBUG and TestFlight, refused in App Store unless `allowInAppStore: true`.
- `Configuration` for colour (defaults to the host tint / `AccentColor`), diameter and border colour.
- Demo app under `Example/`.
