import Foundation
import Security
import BBFECore

/// The key material is kept in the Keychain payload, never in preferences.
struct SavedProfile: Codable, Sendable {
    let id: UUID
    let name: String
    let createdAt: Date
    let alphabet: Alphabet
    let table: CipherTable

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        alphabet: Alphabet,
        table: CipherTable
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.alphabet = alphabet
        self.table = table
    }

    fileprivate func validate() throws {
        try VaultMetadata(id: id, name: name, createdAt: createdAt).validate()
        _ = try alphabet.validated()
        _ = try table.validated()
        guard Set(table.cells).isSuperset(of: alphabet.entries.map(\.scalar)) else {
            throw KeychainVaultError.alphabetMismatch
        }
    }
}

struct SavedKeySummary: Identifiable, Sendable {
    let id: UUID
    let name: String
    let createdAt: Date
    let isSynchronizable: Bool

    /// Local and iCloud records with the same profile UUID are distinct items.
    var storageID: String {
        "\(id.uuidString):\(isSynchronizable ? "icloud" : "local")"
    }
}

enum KeychainVaultError: LocalizedError, Sendable {
    case invalidName
    case invalidDate
    case invalidRecord
    case recordMismatch
    case alphabetMismatch
    case missingRecord
    case system(OSStatus)

    var errorDescription: String? {
        switch self {
        case .invalidName:
            return "Give this key a name of up to 512 UTF-8 bytes. The name cannot be blank."
        case .invalidDate:
            return "This key has an invalid creation date."
        case .invalidRecord:
            return "A saved BBFE key could not be read. Its stored data is invalid."
        case .recordMismatch:
            return "The saved key does not match its Keychain record."
        case .alphabetMismatch:
            return "The cipher table must contain every symbol in the saved alphabet. Generate a new table before saving this key."
        case .missingRecord:
            return "This key is no longer available in Keychain. Refresh the saved keys and try again."
        case .system(let status):
            let message = SecCopyErrorMessageString(status, nil) as String? ?? "Unknown Keychain error"
            return "Keychain: \(message) (\(status))."
        }
    }
}

/// Named key profiles backed by Apple's data protection Keychain.
///
/// Synchronization is part of a Keychain item's identity. Saving in another
/// location creates a separate copy; it does not silently delete the first one.
struct KeychainVault: Sendable {
    private let service = "com.booneynoobington.bbfe.profiles.v1"

    func list() throws -> [SavedKeySummary] {
        var query = baseQuery()
        query[kSecAttrSynchronizable as String] = kSecAttrSynchronizableAny
        query[kSecReturnAttributes as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitAll

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return [] }
        try check(status)
        guard let records = result as? [[String: Any]] else {
            throw KeychainVaultError.invalidRecord
        }

        let summaries = try records.map { record in
            guard
                let account = record[kSecAttrAccount as String] as? String,
                let id = UUID(uuidString: account),
                let data = record[kSecAttrGeneric as String] as? Data
            else { throw KeychainVaultError.invalidRecord }

            let metadata: VaultMetadata
            do {
                metadata = try JSONDecoder().decode(VaultMetadata.self, from: data)
            } catch {
                throw KeychainVaultError.invalidRecord
            }
            try metadata.validate()
            guard metadata.id == id else { throw KeychainVaultError.recordMismatch }
            let synchronizable = (record[kSecAttrSynchronizable as String] as? NSNumber)?.boolValue ?? false
            return SavedKeySummary(
                id: id,
                name: metadata.name,
                createdAt: metadata.createdAt,
                isSynchronizable: synchronizable
            )
        }

        return summaries.sorted {
            let comparison = $0.name.localizedStandardCompare($1.name)
            if comparison != .orderedSame { return comparison == .orderedAscending }
            if $0.createdAt != $1.createdAt { return $0.createdAt > $1.createdAt }
            return $0.storageID < $1.storageID
        }
    }

    func save(_ profile: SavedProfile, synchronizable: Bool) throws {
        try profile.validate()
        let payload = try JSONEncoder().encode(profile)
        let metadata = try JSONEncoder().encode(VaultMetadata(
            id: profile.id,
            name: profile.name,
            createdAt: profile.createdAt
        ))
        let query = identityQuery(id: profile.id, synchronizable: synchronizable)
        let attributes: [String: Any] = [
            kSecValueData as String: payload,
            kSecAttrGeneric as String: metadata,
            kSecAttrLabel as String: "BBFE — \(profile.name)",
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var addition = query.merging(attributes) { _, new in new }
            addition[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked
            try check(SecItemAdd(addition as CFDictionary, nil))
        } else {
            try check(status)
        }
    }

    func load(_ summary: SavedKeySummary) throws -> SavedProfile {
        var query = identityQuery(id: summary.id, synchronizable: summary.isSynchronizable)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { throw KeychainVaultError.missingRecord }
        try check(status)
        guard let data = result as? Data else { throw KeychainVaultError.invalidRecord }

        let profile: SavedProfile
        do {
            profile = try JSONDecoder().decode(SavedProfile.self, from: data)
        } catch {
            throw KeychainVaultError.invalidRecord
        }
        try profile.validate()
        guard profile.id == summary.id else { throw KeychainVaultError.recordMismatch }
        return profile
    }

    func delete(_ summary: SavedKeySummary) throws {
        let query = identityQuery(id: summary.id, synchronizable: summary.isSynchronizable)
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecItemNotFound { try check(status) }
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecUseDataProtectionKeychain as String: true,
        ]
    }

    private func identityQuery(id: UUID, synchronizable: Bool) -> [String: Any] {
        var query = baseQuery()
        query[kSecAttrAccount as String] = id.uuidString
        query[kSecAttrSynchronizable as String] = synchronizable
        return query
    }

    private func check(_ status: OSStatus) throws {
        guard status == errSecSuccess else { throw KeychainVaultError.system(status) }
    }
}

/// Searchable metadata deliberately excludes the alphabet and cipher table.
private struct VaultMetadata: Codable {
    let id: UUID
    let name: String
    let createdAt: Date

    func validate() throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              name.utf8.count <= 512 else {
            throw KeychainVaultError.invalidName
        }
        guard createdAt.timeIntervalSinceReferenceDate.isFinite else {
            throw KeychainVaultError.invalidDate
        }
    }
}
