//
//  XTTSettingsManager.swift
//  xiaokala — X Drive Log
//
//  User preferences persisted in UserDefaults.
//

import Foundation

final class XTTSettingsManager {

    static let shared = XTTSettingsManager()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let faceIDEnabled = "xtt.faceIDEnabled"
        static let autoLockEnabled = "xtt.autoLockEnabled"
        static let autoLockMinutes = "xtt.autoLockMinutes"
    }

    private init() {
        // Register sensible defaults.
        defaults.register(defaults: [
            Keys.faceIDEnabled: false,
            Keys.autoLockEnabled: false,
            Keys.autoLockMinutes: 1
        ])
    }

    var faceIDEnabled: Bool {
        get { defaults.bool(forKey: Keys.faceIDEnabled) }
        set { defaults.set(newValue, forKey: Keys.faceIDEnabled) }
    }

    var autoLockEnabled: Bool {
        get { defaults.bool(forKey: Keys.autoLockEnabled) }
        set { defaults.set(newValue, forKey: Keys.autoLockEnabled) }
    }

    /// Minutes of inactivity before the app locks.
    var autoLockMinutes: Int {
        get { max(0, defaults.integer(forKey: Keys.autoLockMinutes)) }
        set { defaults.set(newValue, forKey: Keys.autoLockMinutes) }
    }
}
