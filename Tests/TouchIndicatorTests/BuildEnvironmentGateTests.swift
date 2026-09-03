//
//  BuildEnvironmentGateTests.swift
//  TouchIndicatorTests
//
//  The enable() gate is the only real logic in the package, so it is the one
//  thing that must be covered: allowed in debug and TestFlight, refused in
//  App Store, allowed in App Store with `allowInAppStore: true`.
//

import UIKit
import XCTest
@testable import TouchIndicator

@MainActor
final class BuildEnvironmentGateTests: XCTestCase {

    override func setUp() {
        super.setUp()
        TouchIndicator.visibleWindows = { [weak self] in self?.windows ?? [] }
    }

    override func tearDown() {
        TouchIndicator.disable()
        windows.removeAll()
        super.tearDown()
    }

    // MARK: - Pure gate

    func testDebugAllowsEnabling() {
        XCTAssertTrue(BuildEnvironment.debug.allowsEnabling(allowInAppStore: false))
    }

    func testTestFlightAllowsEnabling() {
        XCTAssertTrue(BuildEnvironment.testFlight.allowsEnabling(allowInAppStore: false))
    }

    func testAppStoreRefusesEnablingByDefault() {
        XCTAssertFalse(BuildEnvironment.appStore.allowsEnabling(allowInAppStore: false))
    }

    func testAppStoreAllowsEnablingWithExplicitOverride() {
        XCTAssertTrue(BuildEnvironment.appStore.allowsEnabling(allowInAppStore: true))
    }

    // MARK: - Environment detection

    func testResolveReturnsDebugWhenBuiltWithDebug() {
        #if DEBUG
        let sandbox = URL(fileURLWithPath: "/Application/ABC/StoreKit/sandboxReceipt")
        let appStore = URL(fileURLWithPath: "/Application/ABC/StoreKit/receipt")
        XCTAssertEqual(BuildEnvironment.resolve(receiptURL: nil), .debug)
        XCTAssertEqual(BuildEnvironment.resolve(receiptURL: sandbox), .debug)
        XCTAssertEqual(BuildEnvironment.resolve(receiptURL: appStore), .debug)
        XCTAssertEqual(BuildEnvironment.current, .debug)
        #else
        XCTFail("Test target must be built with DEBUG defined; the receipt-URL branches are untestable otherwise")
        #endif
    }

    // MARK: - enable() / disable() against a real window

    func testEnableInAppStoreWithoutOverrideAttachesNothing() {
        let window = makeVisibleWindow()
        TouchIndicator.enable(configuration: .init(), allowInAppStore: false, environment: .appStore)
        XCTAssertFalse(TouchIndicator.isEnabled)
        XCTAssertEqual(observerCount(on: window), 0)
    }

    func testEnableInAppStoreWithOverrideAttachesToVisibleWindow() {
        let window = makeVisibleWindow()
        TouchIndicator.enable(configuration: .init(), allowInAppStore: true, environment: .appStore)
        XCTAssertTrue(TouchIndicator.isEnabled)
        XCTAssertEqual(observerCount(on: window), 1)
    }

    func testWindowShownAfterEnableGetsRecognizer() {
        TouchIndicator.enable(configuration: .init(), allowInAppStore: false, environment: .debug)
        let lateWindow = makeVisibleWindow()
        settle()
        XCTAssertEqual(observerCount(on: lateWindow), 1)
    }

    func testDisableLeavesNothingBehind() {
        let window = makeVisibleWindow()
        TouchIndicator.enable(configuration: .init(), allowInAppStore: false, environment: .testFlight)
        window.addSubview(TouchIndicatorView(configuration: .init()))
        TouchIndicator.disable()
        XCTAssertFalse(TouchIndicator.isEnabled)
        XCTAssertEqual(observerCount(on: window), 0)
        XCTAssertFalse(window.subviews.contains { $0 is TouchIndicatorView })
        // A window shown after disable() must not be picked up.
        let lateWindow = makeVisibleWindow()
        settle()
        XCTAssertEqual(observerCount(on: lateWindow), 0)
    }

    func testRecognizerNeverConsumesTouches() throws {
        let window = makeVisibleWindow()
        TouchIndicator.enable(configuration: .init(), allowInAppStore: false, environment: .debug)
        let recognizer = try XCTUnwrap(window.gestureRecognizers?.first { $0 is TouchObservingGestureRecognizer })
        XCTAssertFalse(recognizer.cancelsTouchesInView)
        XCTAssertFalse(recognizer.delaysTouchesBegan)
        XCTAssertFalse(recognizer.delaysTouchesEnded)
        XCTAssertTrue(recognizer.delegate?.gestureRecognizer?(recognizer, shouldRecognizeSimultaneouslyWith: UITapGestureRecognizer()) ?? false)
        XCTAssertFalse(recognizer.canPrevent(UITapGestureRecognizer()))
        XCTAssertFalse(recognizer.canBePrevented(by: UITapGestureRecognizer()))
    }

    // MARK: - Helpers

    private var windows: [UIWindow] = []

    private func makeVisibleWindow() -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        windows.append(window)
        window.isHidden = false
        return window
    }

    /// Lets the `didBecomeVisibleNotification` observer's main-actor hop land.
    private func settle() {
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
    }

    private func observerCount(on window: UIWindow) -> Int {
        (window.gestureRecognizers ?? []).filter { $0 is TouchObservingGestureRecognizer }.count
    }
}
