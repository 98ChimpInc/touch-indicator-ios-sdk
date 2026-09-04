# Changelog

All notable changes to the TouchIndicator iOS SDK are documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project adheres to [Semantic Versioning](https://semver.org/).

## [1.0.2] - 2026-09-04

### Added

- MIT licence, Swift Package Index configuration and README badges. (#5)

## [1.0.1] - 2026-09-03

### Fixed

- Quick taps read faint: the indicator now starts at 30% alpha and holds 0.1s after lift before fading, matching the reference implementation. (#3)

## [1.0.0] - 2026-09-03

### Added

- `TouchIndicator.enable(configuration:allowInAppStore:)` / `disable()` / `isEnabled`.
- Window-level `UIGestureRecognizer` observer that never consumes touches (no swizzling).
- Indicators on every visible window, including windows UIKit creates for sheets and alerts.
- Build-environment gate: allowed in DEBUG and TestFlight, refused in App Store unless `allowInAppStore: true`.
- `Configuration` for colour (defaults to the host tint / `AccentColor`), diameter and border colour.
- Demo app under `Example/`.

[1.0.2]: https://github.com/98ChimpInc/touch-indicator-ios-sdk/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/98ChimpInc/touch-indicator-ios-sdk/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/98ChimpInc/touch-indicator-ios-sdk/releases/tag/v1.0.0
