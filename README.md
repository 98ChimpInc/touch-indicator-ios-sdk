# TouchIndicator iOS SDK

Zero-dependency Swift package that draws a circle under every finger, so any app can show touch locations in demo videos and screen recordings without re-implementing it.

- Circle follows drags and fades on lift; one circle per finger, so pinches and multi-touch read correctly.
- Works inside presented sheets and alerts, not only the key window.
- No swizzling. A window-level `UIGestureRecognizer` observes touches and never consumes, delays or competes with the host's own handling. Buttons, scroll views and pinch gestures behave exactly as before.
- Never installs itself. The host calls `enable()`, and a build-environment gate decides whether that is allowed.

## Requirements

- iOS 15.0+
- Swift 5.9+
- No dependencies

## Installation

```swift
.package(url: "https://github.com/98ChimpInc/touch-indicator-ios-sdk.git", from: "1.0.0")
```

Then add `TouchIndicator` to your app target.

## Usage

```swift
import TouchIndicator

TouchIndicator.enable()     // draws indicators on every window
TouchIndicator.disable()    // removes recognisers, observers and any visible indicators
TouchIndicator.isEnabled    // true between a successful enable() and the next disable()
```

Both calls are `@MainActor`. `enable()` can be called again with a new configuration; it replaces the previous installation.

### Configuration

```swift
TouchIndicator.enable(configuration: .init(
    color: .systemPink,                              // nil (default) uses the host tint, i.e. AccentColor
    diameter: 44,                                    // default 50
    borderColor: UIColor.white.withAlphaComponent(0.8)
))
```

The circle is drawn at 60% alpha with a 2pt border, animates in over 0.2s from 0.6× and fades out over 0.4s to 1.3×.

## Gating

`enable()` checks the build environment before attaching anything:

| Build | Behaviour |
|---|---|
| DEBUG | allowed |
| TestFlight | allowed |
| App Store | **refused**, unless the caller passes `allowInAppStore: true` |

Indicators visible to App Review are a Guideline 2.2 rejection risk ("pre-release, test, or trial version"), so App Store builds refuse by default. Capturing a demo from a near-release build is still a legitimate need, so the refusal is overridable rather than absolute. A refused call logs an error under the `com.98chimp.TouchIndicator` subsystem and leaves `isEnabled` false.

Detection: `#if DEBUG` → DEBUG; otherwise a `sandboxReceipt` receipt URL → TestFlight; otherwise App Store. `BuildEnvironment.current` exposes the result if the host wants it.

### Wiring `allowInAppStore` to a whitelist-gated dev menu

Pass `allowInAppStore: true` only from behind a gate the host already controls, so a reviewer never sees the toggle. With Argus that is a dev menu shown only to `config_dev_menu_whitelisted_users`:

```swift
import SwiftUI
import TouchIndicator

struct DevMenu: View {
    @AppStorage("showTapIndicators") private var showTapIndicators = false

    var body: some View {
        Toggle("Show tap indicators", isOn: $showTapIndicators)
            .onAppear(perform: apply)
            .onChange(of: showTapIndicators) { _ in apply() }
    }

    private func apply() {
        if showTapIndicators {
            // This view only exists for whitelisted users, so the App Store
            // override is safe here and nowhere else.
            TouchIndicator.enable(allowInAppStore: true)
        } else {
            TouchIndicator.disable()
        }
    }
}
```

The package takes a plain `Bool` and stays dependency-free; it never reads Argus or any other flag service itself.

## Demo app

`Example/` contains a SwiftUI app exercising buttons, scrolling, pinch, a sheet and an alert with indicators on. The Xcode project is generated:

```bash
brew install xcodegen
cd Example && xcodegen generate && open TouchIndicatorDemo.xcodeproj
```

## Tests

The build-environment gate is the only real logic in the package, so it is what the tests cover: allowed in DEBUG and TestFlight, refused in App Store, allowed in App Store with the override, plus `enable()`/`disable()` leaving no recogniser or view behind.

```bash
xcodebuild test -scheme TouchIndicator -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## Releasing

SemVer tags via the `/release-sdk` skill. Consumers pin with `from:`.
