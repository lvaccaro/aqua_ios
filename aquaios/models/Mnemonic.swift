import Foundation
import LocalAuthentication

/// Keychain errors we might encounter.
struct KeychainError: Error {
    var status: OSStatus

    var localizedDescription: String {
        return SecCopyErrorMessageString(status, nil) as String? ?? "Unknown error."
    }
}

class Mnemonic {

    static func generate() throws -> String {
        return try generateMnemonic12()
    }

    /// Stores mnemonic
    static func write(_ mnemonic: String, safe: Bool = false) throws {
        // Create an access control instance that dictates how the item can be read later.
        let access = SecAccessControlCreateWithFlags(nil, // Use the default allocator.
                                                     kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly, // the item isn’t eligible for the iCloud keychain and won’t be included if the user restores a device backup to a new device.
                                                     .userPresence, // request biometric authentication, or to fall back on the device passcode, whenever the item is later read from the keychain.
                                                     nil) // Ignore any error.

        // Allow a device unlock in the last 10 seconds to be used to get at keychain items.
        let context = LAContext()
        context.touchIDAuthenticationAllowableReuseDuration = 10

        // Build the query for use in the add operation.
        var query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrLabel as String: Constants.Keys.mnemonic,
                                    kSecValueData as String: mnemonic.data(using: String.Encoding.utf8)!]
        if safe {
            query[kSecAttrAccessControl as String] = access as Any
            query[kSecUseAuthenticationContext as String] = context
        }

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError(status: status) }
    }

    /// Reads the stored mnemonic
    static func read() throws -> String {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecMatchLimit as String: kSecMatchLimitOne,
                                    kSecReturnAttributes as String: true,
                                    kSecAttrLabel as String: Constants.Keys.mnemonic,
                                    kSecUseOperationPrompt as String: "Access your mnemonic on the keychain",
                                    kSecReturnData as String: true]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else { throw KeychainError(status: status) }

        guard let existingItem = item as? [String: Any],
            let data = existingItem[kSecValueData as String] as? Data,
            let mnemonic = String(data: data, encoding: String.Encoding.utf8)
            else {
                throw KeychainError(status: errSecInternalError)
        }
        return mnemonic
    }

    /// Check exist the stored mnemonic
    static func exist() -> Bool {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrLabel as String: Constants.Keys.mnemonic,
                                    kSecUseAuthenticationUI as String: kSecUseAuthenticationUIFail]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecInteractionNotAllowed {
            return true
        } else if status == errSecItemNotFound {
            return false
        } else {
            print("status: \(status)")
            return false
        }
    }

    /// Deletes mnemonic
    static func delete() throws {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrLabel as String: Constants.Keys.mnemonic]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess else { throw KeychainError(status: status) }
    }
}