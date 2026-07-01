//
//  XTTBiometricManager.swift
//  xiaokala — X Drive Log
//
//  Face ID / Touch ID unlock via LocalAuthentication.
//

import Foundation
import LocalAuthentication

final class XTTBiometricManager {

    static let shared = XTTBiometricManager()
    private init() {}

    /// Whether the device exposes any biometric that can be evaluated.
    var isBiometricAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    /// A human-readable label for the available biometric type.
    var biometryLabel: String {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return "Biometrics"
        }
        switch context.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        default: return "Biometrics"
        }
    }

    /// Prompts for biometric authentication, falling back to device passcode.
    func authenticate(reason: String, completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        context.localizedFallbackTitle = "Enter Passcode"

        var error: NSError?
        let policy: LAPolicy = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
            ? .deviceOwnerAuthenticationWithBiometrics
            : .deviceOwnerAuthentication

        guard context.canEvaluatePolicy(policy, error: &error) else {
            // No auth available at all — treat as success so the user is not locked out.
            DispatchQueue.main.async { completion(true) }
            return
        }

        context.evaluatePolicy(policy, localizedReason: reason) { success, _ in
            DispatchQueue.main.async { completion(success) }
        }
    }
}
