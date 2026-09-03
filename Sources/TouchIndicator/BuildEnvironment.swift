//
//  BuildEnvironment.swift
//  TouchIndicator
//
//  Build-environment detection and the enable() gate. This is the only real
//  logic in the package, so it is kept pure and injectable for unit tests.
//

import Foundation

/// Where the running binary came from.
public enum BuildEnvironment: Equatable {
    /// Built with `DEBUG` defined (Xcode Run, simulator).
    case debug
    /// Distributed through TestFlight (sandbox receipt).
    case testFlight
    /// Distributed through the App Store.
    case appStore

    /// The environment of the running binary.
    public static var current: BuildEnvironment {
        resolve(receiptURL: receiptURL)
    }

    /// Whether `TouchIndicator.enable()` may proceed in this environment.
    ///
    /// Indicators visible to App Review are a Guideline 2.2 rejection risk,
    /// so App Store builds refuse unless the host explicitly opts in from
    /// behind its own gate (a whitelisted dev menu).
    public func allowsEnabling(allowInAppStore: Bool) -> Bool {
        switch self {
        case .debug, .testFlight: return true
        case .appStore: return allowInAppStore
        }
    }

    /// Resolver behind `current`. The receipt URL is injectable so the
    /// TestFlight / App Store branches can be exercised under unit tests.
    ///
    /// The DEBUG branch is decided at compile time: when the package is built
    /// with DEBUG defined (which includes its own test target) every input
    /// resolves to `.debug`, matching what the host sees when run from Xcode.
    static func resolve(receiptURL: URL?) -> BuildEnvironment {
        #if DEBUG
        return .debug
        #else
        // TestFlight installs carry a sandbox receipt; App Store installs a
        // regular one. Standard idiom, no private API, works on first launch.
        return receiptURL?.lastPathComponent == "sandboxReceipt" ? .testFlight : .appStore
        #endif
    }

    // `Bundle.appStoreReceiptURL` is deprecated in iOS 18 in favour of
    // StoreKit 2's `AppTransaction.shared.environment`. That API is async and
    // iOS 16+, so the receipt URL stays until the deployment target moves.
    // The wrapper below scopes the deprecation warning to this one accessor.
    @available(iOS, deprecated: 18.0, message: "Move to AppTransaction.shared.environment once the deployment target is iOS 16+")
    private static var receiptURL: URL? {
        Bundle.main.appStoreReceiptURL
    }
}
