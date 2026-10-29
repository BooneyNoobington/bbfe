import Foundation
import CryptoKit

/// Cells are row-major: index 0 is A1, index 25 is Z1, index 26 is A2.
public struct CipherTable: Codable, Sendable {
    public static let columns = 26
    public var version: Int
    public var id: UUID
    public var createdAt: Date
    public var cells: [UInt32]
    public var rowCount: Int { cells.count / Self.columns }

    public init(id: UUID = UUID(), createdAt: Date = Date(), cells: [UInt32]) {
        self.version = 2; self.id = id; self.createdAt = createdAt; self.cells = cells
    }

    @discardableResult public func validated() throws -> CipherTable {
        guard version == 2 else { throw BBFEError("Unsupported cipher table version \(version).") }
        guard !cells.isEmpty, cells.count.isMultiple(of: Self.columns) else {
            throw BBFEError("The cipher table must have complete rows of 26 cells.")
        }
        guard cells.allSatisfy({ Unicode.Scalar($0) != nil }) else { throw BBFEError("The table contains an invalid Unicode scalar.") }
        guard createdAt.timeIntervalSince1970.isFinite else { throw BBFEError("The table has an invalid creation date.") }
        return self
    }

    /// Every symbol receives a slot; remaining slots are apportioned by weight.
    /// Counts are normalized, so a large corpus cannot explode the table size.
    public static func generate(from alphabet: Alphabet, minimumSlots: Int = 4096) throws -> CipherTable {
        try alphabet.validated()
        guard minimumSlots > 0 else { throw BBFEError("The requested table size must be positive.") }
        let target = max(minimumSlots, alphabet.entries.count)
        let (rounded, overflow) = target.addingReportingOverflow(Self.columns - 1)
        guard !overflow else { throw BBFEError("The requested table size is too large.") }
        let count = (rounded / Self.columns) * Self.columns
        let remaining = count - alphabet.entries.count
        let maximum = alphabet.entries.map(\.weight).max()!
        let normalized = alphabet.entries.map { $0.weight / maximum }
        let total = normalized.reduce(0, +)
        var allocation = [Int](repeating: 1, count: alphabet.entries.count)
        var assigned = 0
        var fractions: [(Int, Double)] = []
        for index in alphabet.entries.indices {
            try checkCancellation(at: index)
            let expected = Double(remaining) * (normalized[index] / total)
            guard expected.isFinite, expected < Double(Int.max) else { throw BBFEError("The requested table size is too large.") }
            let extra = min(remaining - assigned, Int(expected.rounded(.down)))
            allocation[index] += extra; assigned += extra
            fractions.append((index, expected - Double(extra)))
        }
        fractions.sort { $0.1 == $1.1 ? $0.0 < $1.0 : $0.1 > $1.1 }
        for index in 0..<(remaining - assigned) { allocation[fractions[index % fractions.count].0] += 1 }
        var cells: [UInt32] = []
        cells.reserveCapacity(count)
        for index in alphabet.entries.indices {
            try checkCancellation(at: index)
            cells.append(contentsOf: repeatElement(alphabet.entries[index].scalar, count: allocation[index]))
        }
        var random = SystemRandomNumberGenerator()
        cells.shuffle(using: &random)
        return CipherTable(cells: cells)
    }

    public static func importLegacyTSV(_ text: String) throws -> CipherTable {
        var lines = text.components(separatedBy: "\n")
        if lines.last == "" { lines.removeLast() }
        var cells: [UInt32] = []
        for (row, rawLine) in lines.enumerated() {
            let line = rawLine.hasSuffix("\r") ? String(rawLine.dropLast()) : rawLine
            let fields = line.components(separatedBy: "\t")
            guard fields.count == columns else { throw BBFEError("Legacy table row \(row + 1) must contain 26 tab-separated symbols.") }
            for field in fields {
                guard field.unicodeScalars.count == 1, let scalar = field.unicodeScalars.first else {
                    throw BBFEError("Every legacy table cell must contain one Unicode scalar. Use JSON for control characters.")
                }
                cells.append(scalar.value)
            }
        }
        let table = try CipherTable(cells: cells).validated()
        // TSV has no metadata. Derive a stable identity so loading the same legacy
        // key in separate CLI runs can still decipher a framed BBFE2 message.
        var bytes = Data("BBFE-table-v2:26:".utf8)
        for scalar in cells {
            bytes.append(UInt8(truncatingIfNeeded: scalar >> 24))
            bytes.append(UInt8(truncatingIfNeeded: scalar >> 16))
            bytes.append(UInt8(truncatingIfNeeded: scalar >> 8))
            bytes.append(UInt8(truncatingIfNeeded: scalar))
        }
        let digest = Array(SHA256.hash(data: bytes).prefix(16))
        let id = UUID(uuid: (digest[0], digest[1], digest[2], digest[3], digest[4], digest[5], digest[6], digest[7], digest[8], digest[9], digest[10], digest[11], digest[12], digest[13], digest[14], digest[15]))
        return CipherTable(id: id, createdAt: table.createdAt, cells: cells)
    }

    public func exportLegacyTSV() throws -> String {
        try validated()
        guard !cells.contains(where: { $0 == 9 || $0 == 10 || $0 == 13 }) else {
            throw BBFEError("Legacy TSV cannot represent tabs or line breaks. Export this table as JSON instead.")
        }
        var output = ""
        for (index, value) in cells.enumerated() {
            output.unicodeScalars.append(Unicode.Scalar(value)!)
            output += (index + 1).isMultiple(of: Self.columns) ? "\n" : "\t"
        }
        return output
    }
}
