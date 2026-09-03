//
//  TouchIndicator.swift
//  TouchIndicator
//
//  Public API. Draws a circle under every finger, on every window, for demo
//  videos and screen recordings. Never installs itself: the host calls
//  `enable()` and the build-environment gate decides whether that is allowed.
//

import os
import UIKit

public enum TouchIndicator {

    public struct Configuration {
        /// Fill colour (drawn at 60% alpha). `nil` uses the host's tint colour,
        /// which is the asset catalog's `AccentColor` when one is set.
        public var color: UIColor?
        /// Circle diameter in points.
        public var diameter: CGFloat
        /// 2pt border colour. Defaults to white at 80%.
        public var borderColor: UIColor

        public init(
            color: UIColor? = nil,
            diameter: CGFloat = 50,
            borderColor: UIColor = UIColor.white.withAlphaComponent(0.8)
        ) {
            self.color = color
            self.diameter = diameter
            self.borderColor = borderColor
        }
    }

    private static let logger = Logger(subsystem: "com.98chimp.TouchIndicator", category: "TouchIndicator")

    private static var recognizers: [TouchObservingGestureRecognizer] = []
    private static var windowObserver: NSObjectProtocol?
    private static var configuration = Configuration()

    /// `true` between a successful `enable()` and the next `disable()`.
    public static var isEnabled: Bool { windowObserver != nil }

    /// Starts drawing indicators on every visible window, including windows
    /// UIKit creates later for sheets and alerts.
    ///
    /// Refused in App Store builds unless `allowInAppStore` is `true`. Pass
    /// that only from behind the host's own gate (a whitelisted dev menu), so
    /// App Review never sees the toggle.
    @MainActor
    public static func enable(configuration: Configuration = .init(), allowInAppStore: Bool = false) {
        enable(configuration: configuration, allowInAppStore: allowInAppStore, environment: .current)
    }

    /// Removes every recogniser, observer and visible indicator.
    @MainActor
    public static func disable() {
        if let windowObserver {
            NotificationCenter.default.removeObserver(windowObserver)
        }
        windowObserver = nil
        for recognizer in recognizers {
            guard let window = recognizer.view else { continue }
            window.subviews.filter { $0 is TouchIndicatorView }.forEach { $0.removeFromSuperview() }
            window.removeGestureRecognizer(recognizer)
        }
        recognizers.removeAll()
        logger.info("Touch indicators disabled")
    }

    /// Internal entry point with an injectable environment so the gate is
    /// unit-testable without an App Store build.
    @MainActor
    static func enable(configuration: Configuration, allowInAppStore: Bool, environment: BuildEnvironment) {
        guard environment.allowsEnabling(allowInAppStore: allowInAppStore) else {
            logger.error("enable() refused: App Store build without allowInAppStore. Indicators stay off.")
            return
        }
        // Re-enabling with a new configuration replaces the old installation.
        disable()
        self.configuration = configuration

        windowObserver = NotificationCenter.default.addObserver(
            forName: UIWindow.didBecomeVisibleNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let window = notification.object as? UIWindow else { return }
            // Observer runs on the main queue already; the hop only satisfies
            // actor isolation and lands long before a finger can reach the window.
            Task { @MainActor in attach(to: window) }
        }
        visibleWindows().filter { !$0.isHidden }.forEach(attach(to:))
        logger.info("Touch indicators enabled on \(recognizers.count) window(s)")
    }

    @MainActor
    private static func attach(to window: UIWindow) {
        // Windows UIKit has already torn down (a dismissed sheet) leave a
        // recogniser with no view behind; drop those before adding more.
        recognizers.removeAll { $0.view == nil }
        guard !recognizers.contains(where: { $0.view === window }) else { return }
        let recognizer = TouchObservingGestureRecognizer(configuration: configuration)
        window.addGestureRecognizer(recognizer)
        recognizers.append(recognizer)
    }

    /// Windows already on screen when `enable()` is called. Overridable so
    /// tests can supply windows: the bare xctest host has no window scene.
    @MainActor
    static var visibleWindows: () -> [UIWindow] = {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
    }
}
