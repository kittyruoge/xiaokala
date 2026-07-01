//
//  XTTAuthManager.swift
//  xiaokala — X Drive Log
//
//  Local-only account + session management. Passwords are salted and
//  hashed with SHA256; plain text is never persisted.
//

import Foundation
import CryptoKit

enum XTTSessionState {
    case signedOut
    case guest
    case authenticated
}

final class XTTAuthManager {

    static let shared = XTTAuthManager()

    private let accountKey = "xtt.account"        // Keychain
    private let sessionFlagKey = "xtt.hasSession" // UserDefaults
    private let demoSeededKey = "xtt.demoSeeded"  // UserDefaults

    private(set) var state: XTTSessionState = .signedOut

    private init() {}

    // MARK: - Demo account bootstrap

    /// Creates a ready-to-use demo account (`test` / `abc123`) with rich sample
    /// data on first launch. Idempotent — runs only once per install.
    func bootstrapDemoAccountIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: demoSeededKey) else { return }
        UserDefaults.standard.set(true, forKey: demoSeededKey)

        // Only seed if no account exists yet, so we never clobber a real user.
        guard loadAccount() == nil else { return }

        let salt = makeSalt()
        let account = XTTAccount(email: "test",
                                 displayName: "Test Driver",
                                 passwordHash: hash("abc123", salt: salt),
                                 salt: salt,
                                 createdAt: Date())
        saveAccount(account)
        XTTDataStore.shared.seedDemoDataToDisk()
    }

    // MARK: - Account persistence

    private func loadAccount() -> XTTAccount? {
        guard let json = XTTKeychain.get(accountKey),
              let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(XTTAccount.self, from: data)
    }

    private func saveAccount(_ account: XTTAccount) {
        guard let data = try? JSONEncoder().encode(account),
              let json = String(data: data, encoding: .utf8) else { return }
        XTTKeychain.set(json, for: accountKey)
    }

    var hasRegisteredAccount: Bool {
        loadAccount() != nil
    }

    var currentDisplayName: String {
        loadAccount()?.displayName ?? "Driver"
    }

    var currentEmail: String {
        loadAccount()?.email ?? ""
    }

    // MARK: - Hashing

    private func makeSalt() -> String {
        var bytes = [UInt8](repeating: 0, count: 16)
        let result = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        if result != errSecSuccess {
            // Fallback: derive from UUID if secure RNG is unavailable.
            return UUID().uuidString
        }
        return Data(bytes).base64EncodedString()
    }

    private func hash(_ password: String, salt: String) -> String {
        let salted = salt + password
        let digest = SHA256.hash(data: Data(salted.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Auth actions

    enum XTTAuthError: LocalizedError {
        case invalidEmail
        case weakPassword
        case accountExists
        case noAccount
        case wrongCredentials

        var errorDescription: String? {
            switch self {
            case .invalidEmail: return "Please enter a valid email address."
            case .weakPassword: return "Password must be at least 6 characters."
            case .accountExists: return "An account already exists on this device."
            case .noAccount: return "No account found. Please register first."
            case .wrongCredentials: return "Email or password is incorrect."
            }
        }
    }

    func register(email: String, displayName: String, password: String) throws {
        guard isValidEmail(email) else { throw XTTAuthError.invalidEmail }
        guard password.count >= 6 else { throw XTTAuthError.weakPassword }
        guard loadAccount() == nil else { throw XTTAuthError.accountExists }

        let salt = makeSalt()
        let account = XTTAccount(email: email.lowercased(),
                                 displayName: displayName.isEmpty ? "Driver" : displayName,
                                 passwordHash: hash(password, salt: salt),
                                 salt: salt,
                                 createdAt: Date())
        saveAccount(account)
        beginAuthenticatedSession()
    }

    func login(email: String, password: String) throws {
        guard let account = loadAccount() else { throw XTTAuthError.noAccount }
        // Case-insensitive match on the stored identifier (email or username).
        guard account.email == email.lowercased(),
              account.passwordHash == hash(password, salt: account.salt) else {
            throw XTTAuthError.wrongCredentials
        }
        beginAuthenticatedSession()
    }

    func continueAsGuest() {
        state = .guest
        UserDefaults.standard.set(false, forKey: sessionFlagKey)
        XTTDataStore.shared.startGuestSession()
    }

    private func beginAuthenticatedSession() {
        state = .authenticated
        UserDefaults.standard.set(true, forKey: sessionFlagKey)
        XTTDataStore.shared.startAuthenticatedSession()
    }

    /// Restores a prior authenticated session if one was active.
    func restoreSessionIfPossible() -> Bool {
        if UserDefaults.standard.bool(forKey: sessionFlagKey), hasRegisteredAccount {
            beginAuthenticatedSession()
            return true
        }
        return false
    }

    func signOut() {
        if state == .guest {
            XTTDataStore.shared.endGuestSession()
        }
        state = .signedOut
        UserDefaults.standard.set(false, forKey: sessionFlagKey)
    }

    // MARK: - Validation

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return email.range(of: pattern, options: .regularExpression) != nil
    }
}
