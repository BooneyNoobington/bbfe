import BBFECore
import Foundation
import SwiftUI
import UniformTypeIdentifiers
#if os(macOS)
import AppKit
#else
import UIKit
#endif

enum WorkspaceMode: String, CaseIterable, Identifiable, Sendable {
    case encipher = "Encipher"
    case decipher = "Decipher"
    var id: Self { self }
}

enum ImportDestination: Sendable {
    case message, alphabet, table
}

enum TableReplacement {
    case importFile
    case load(SavedKeySummary)
}

struct TextFile: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText, .json, .data] }
    var text: String

    init(_ text: String = "") { self.text = text }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadInapplicableStringEncoding)
        }
        self.text = try UTF8Text.decode(data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}

@MainActor
final class AppModel: ObservableObject {
    static let example = "Hello, world! 👋\nTabs\tand line breaks belong here.\nGrüße · 你好 · café"

    @Published var mode: WorkspaceMode = .encipher
    @Published var input = AppModel.example
    @Published var output = ""
    @Published var trainingText = AppModel.example
    @Published var alphabet: Alphabet
    @Published var table: CipherTable?
    @Published var paddingBlockSize = 256
    @Published var legacyFormat = false
    @Published var isBusy = false
    @Published var activityLabel = ""
    @Published var errorMessage: String?
    @Published var notice: String?
    @Published var savedKeys: [SavedKeySummary] = []
    @Published var profileName = "My alphabet & table"
    @Published var synchronizeKey = false
    @Published var currentKeyName = "Unsaved starter table"
    @Published var showAbout = false
    @Published var showSaveKeySheet = false
    @Published var hasUnsavedTable = true
    @Published var pendingReplacement: TableReplacement?
    @Published var showImporter = false
    @Published var showExporter = false
    @Published var exportDocument = TextFile()
    @Published var exportType = UTType.plainText
    @Published var exportName = "bbfe-message.txt"

    private var importDestination = ImportDestination.message
    private var activity: Task<Void, Never>?
    private var activeTableAlphabet: Alphabet
    private var currentSavedStorageID: String?

    init() {
        let starter = Alphabet.histogram(from: Alphabet.basicLatin.entries.map(\.symbol).joined() + Self.example)
        alphabet = starter
        activeTableAlphabet = starter
        do {
            table = try CipherTable.generate(from: starter)
        } catch {
            table = nil
            errorMessage = error.localizedDescription
        }
    }

    func process() {
        guard let table else { return fail("Generate or load a cipher table first.") }
        let text = input
        let selectedMode = mode
        let block = legacyFormat ? 0 : paddingBlockSize
        let legacy = legacyFormat
        run(selectedMode == .encipher ? "Enciphering message…" : "Deciphering message…", operation: {
            let cipher = try BBFECipher(table: table)
            if selectedMode == .encipher {
                return try cipher.encode(text, paddingBlockSize: block, legacy: legacy)
            }
            return try cipher.decode(text)
        }, completion: { [weak self] result in
            self?.output = result
            self?.notice = selectedMode == .encipher ? "Message enciphered." : "Message deciphered exactly, including whitespace."
        })
    }

    func buildHistogram() {
        let sample = trainingText
        run("Counting Unicode scalars…", operation: {
            let alphabet = Alphabet.histogram(from: sample)
            return try alphabet.validated()
        }, completion: { [weak self] alphabet in
            self?.alphabet = alphabet
            self?.notice = "Alphabet updated. Generate a table to use this alphabet."
        })
    }

    func useBasicLatin() {
        alphabet = .basicLatin
        notice = "Basic Latin alphabet loaded. Generate a table to use it."
    }

    func generateTable() {
        let source = alphabet
        run("Shuffling a weighted cipher table…", operation: {
            try CipherTable.generate(from: source)
        }, completion: { [weak self] table in
            self?.table = table
            self?.activeTableAlphabet = source
            self?.hasUnsavedTable = true
            self?.currentSavedStorageID = nil
            self?.currentKeyName = "Unsaved table"
            self?.output = ""
            self?.notice = "New table generated. Save it before replacing it; old messages need their original table."
        })
    }

    func useOutputAsInput() {
        input = output
        output = ""
        mode = mode == .encipher ? .decipher : .encipher
        notice = nil
    }

    func pasteInput() { input = Self.clipboardText ?? "" }
    func pasteTrainingText() { trainingText = Self.clipboardText ?? "" }

    func copyOutput() {
        Self.copy(output)
        notice = "Output copied."
    }

    static func copy(_ text: String) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #else
        UIPasteboard.general.string = text
        #endif
    }

    private static var clipboardText: String? {
        #if os(macOS)
        NSPasteboard.general.string(forType: .string)
        #else
        UIPasteboard.general.string
        #endif
    }

    func beginImport(_ destination: ImportDestination) {
        if case .table = destination, hasUnsavedTable, table != nil {
            pendingReplacement = .importFile
            return
        }
        importDestination = destination
        showImporter = true
    }

    func confirmReplacement() {
        let replacement = pendingReplacement
        pendingReplacement = nil
        switch replacement {
        case .importFile:
            importDestination = .table
            showImporter = true
        case .load(let summary): loadKey(summary)
        case nil: break
        }
    }

    func receiveImport(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error): fail(error.localizedDescription)
        case .success(let urls):
            guard let url = urls.first else { return }
            let destination = importDestination
            run("Reading file…", operation: {
                let access = url.startAccessingSecurityScopedResource()
                defer { if access { url.stopAccessingSecurityScopedResource() } }
                let data = try Data(contentsOf: url)
                let text = try UTF8Text.decode(data)
                switch destination {
                case .message: return ImportedValue.message(text)
                case .alphabet:
                    if url.pathExtension.lowercased() == "json" {
                        return try .alphabet(JSONDecoder().decode(Alphabet.self, from: data).validated())
                    }
                    return try .alphabet(Alphabet.importLegacyTSV(text))
                case .table:
                    if url.pathExtension.lowercased() == "json" {
                        return try .table(JSONDecoder().decode(CipherTable.self, from: data).validated())
                    }
                    return try .table(CipherTable.importLegacyTSV(text))
                }
            }, completion: { [weak self] value in
                guard let self else { return }
                switch value {
                case .message(let text): input = text
                case .alphabet(let alphabet): self.alphabet = alphabet
                case .table(let table):
                    self.table = table
                    let counts = table.cells.reduce(into: [UInt32: Double]()) { $0[$1, default: 0] += 1 }
                    let alphabet = Alphabet(entries: counts.keys.sorted().map { AlphabetEntry(scalar: $0, weight: counts[$0]!) })
                    self.alphabet = alphabet
                    activeTableAlphabet = alphabet
                    hasUnsavedTable = true
                    currentSavedStorageID = nil
                    currentKeyName = url.deletingPathExtension().lastPathComponent
                    output = ""
                }
                notice = "Imported \(url.lastPathComponent)."
            })
        }
    }

    func exportOutput() { prepareExport(output, name: mode == .encipher ? "bbfe-ciphertext.txt" : "bbfe-plaintext.txt") }

    func exportAlphabet() {
        do { prepareExport(try Self.json(alphabet), name: "bbfe-alphabet.json", type: .json) }
        catch { fail(error.localizedDescription) }
    }

    func exportTable(legacy: Bool = false) {
        guard let table else { return fail("Generate or load a cipher table first.") }
        do {
            let text = legacy ? try table.exportLegacyTSV() : try Self.json(table)
            prepareExport(text,
                          name: legacy ? "bbfe-table.tsv" : "bbfe-table.json",
                          type: legacy ? .plainText : .json)
        } catch { fail(error.localizedDescription) }
    }

    private func prepareExport(_ text: String, name: String, type: UTType = .plainText) {
        exportDocument = TextFile(text)
        exportType = type
        exportName = name
        showExporter = true
    }

    private static func json<T: Encodable>(_ value: T) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(value)
        return String(decoding: data, as: UTF8.self)
    }

    func refreshKeys() {
        guard !isBusy else { return }
        run("Reading saved keys…", operation: { try KeychainVault().list() }, completion: { [weak self] keys in
            self?.savedKeys = keys
        })
    }

    func saveKey() {
        guard let table else { return fail("Generate or load a cipher table first.") }
        let name = profileName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return fail("Give your saved key a name.") }
        let profile = SavedProfile(name: name, alphabet: activeTableAlphabet, table: table)
        let sync = synchronizeKey
        run("Saving to Apple Keychain…", operation: {
            let vault = KeychainVault()
            try vault.save(profile, synchronizable: sync)
            return try vault.list()
        }, completion: { [weak self] keys in
            self?.savedKeys = keys
            self?.currentKeyName = name
            self?.hasUnsavedTable = false
            self?.currentSavedStorageID = "\(profile.id.uuidString):\(sync ? "icloud" : "local")"
            self?.notice = sync ? "Saved to Keychain with iCloud sync requested." : "Saved in this device’s Keychain."
        })
    }

    func requestLoadKey(_ summary: SavedKeySummary) {
        if hasUnsavedTable, table != nil {
            pendingReplacement = .load(summary)
        } else {
            loadKey(summary)
        }
    }

    private func loadKey(_ summary: SavedKeySummary) {
        run("Loading saved key…", operation: { try KeychainVault().load(summary) }, completion: { [weak self] profile in
            self?.alphabet = profile.alphabet
            self?.activeTableAlphabet = profile.alphabet
            self?.table = profile.table
            self?.hasUnsavedTable = false
            self?.currentSavedStorageID = summary.storageID
            self?.currentKeyName = profile.name
            self?.profileName = profile.name
            self?.synchronizeKey = summary.isSynchronizable
            self?.output = ""
            self?.notice = "Loaded \(profile.name)."
        })
    }

    func deleteKey(_ summary: SavedKeySummary) {
        run("Deleting saved key…", operation: {
            let vault = KeychainVault()
            try vault.delete(summary)
            return try vault.list()
        }, completion: { [weak self] keys in
            self?.savedKeys = keys
            if self?.currentSavedStorageID == summary.storageID {
                self?.currentSavedStorageID = nil
                self?.hasUnsavedTable = true
                self?.currentKeyName = "\(summary.name) (unsaved copy)"
            }
            self?.notice = "Deleted \(summary.name) from Keychain."
        })
    }

    func cancel() {
        activity?.cancel()
        notice = "Cancelling…"
    }

    func fail(_ message: String) { errorMessage = message }

    private func run<Value: Sendable>(
        _ label: String,
        operation: @escaping @Sendable () throws -> Value,
        completion: @escaping @MainActor (Value) -> Void
    ) {
        guard !isBusy else { return }
        isBusy = true
        activityLabel = label
        notice = nil
        let worker = Task.detached(priority: .userInitiated) {
            try Task.checkCancellation()
            let value = try operation()
            try Task.checkCancellation()
            return value
        }
        activity = Task { [weak self] in
            defer {
                self?.isBusy = false
                self?.activityLabel = ""
                self?.activity = nil
            }
            do {
                let value = try await withTaskCancellationHandler(operation: {
                    try await worker.value
                }, onCancel: {
                    worker.cancel()
                })
                try Task.checkCancellation()
                completion(value)
            } catch is CancellationError {
                self?.notice = "Operation cancelled."
            } catch {
                self?.fail(error.localizedDescription)
            }
        }
    }
}

private enum ImportedValue: Sendable {
    case message(String)
    case alphabet(Alphabet)
    case table(CipherTable)
}
