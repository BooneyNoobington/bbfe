import Foundation

public struct BBFEError: Error, LocalizedError, Sendable {
    public let message: String
    public init(_ message: String) { self.message = message }
    public var errorDescription: String? { message }
}

public struct AlphabetEntry: Codable, Hashable, Sendable, Identifiable {
    public var scalar: UInt32
    public var weight: Double
    public init(scalar: UInt32, weight: Double) { self.scalar = scalar; self.weight = weight }
    public var id: UInt32 { scalar }
    public var symbol: String { Unicode.Scalar(scalar).map(String.init) ?? "�" }
    public var displayName: String {
        switch scalar {
        case 0: return "NUL \\0"
        case 9: return "TAB \\t"
        case 10: return "LF \\n"
        case 13: return "CR \\r"
        case 32: return "SPACE"
        case 0...31, 127...159: return String(format: "U+%04X", scalar)
        default: return symbol
        }
    }
}

/// A weighted alphabet of Unicode scalar values. No Unicode normalization occurs.
public struct Alphabet: Codable, Sendable {
    public var entries: [AlphabetEntry]
    public init(entries: [AlphabetEntry]) { self.entries = entries }

    public static func histogram(from text: String) -> Alphabet {
        var counts: [UInt32: Int] = [:]
        for scalar in text.unicodeScalars { counts[scalar.value, default: 0] += 1 }
        return Alphabet(entries: counts.keys.sorted().map { AlphabetEntry(scalar: $0, weight: Double(counts[$0]!)) })
    }

    public static var basicLatin: Alphabet {
        Alphabet(entries: ([UInt32(9), 10, 13] + Array(UInt32(32)...UInt32(126)))
            .map { AlphabetEntry(scalar: $0, weight: 1) })
    }

    @discardableResult public func validated() throws -> Alphabet {
        guard !entries.isEmpty else { throw BBFEError("The alphabet is empty. Paste sample text or add symbols first.") }
        var seen: Set<UInt32> = []
        for entry in entries {
            guard Unicode.Scalar(entry.scalar) != nil else { throw BBFEError("The alphabet contains an invalid Unicode scalar.") }
            guard entry.weight.isFinite, entry.weight > 0 else { throw BBFEError("Every symbol must have a finite, positive weight.") }
            guard seen.insert(entry.scalar).inserted else { throw BBFEError("The alphabet contains a duplicate symbol: \(entry.displayName).") }
        }
        return self
    }

    public static func importLegacyTSV(_ text: String) throws -> Alphabet {
        var lines = text.components(separatedBy: "\n")
        if lines.last == "" { lines.removeLast() }
        guard let header = lines.first, header.trimmingCharacters(in: .newlines) == "place\tletter\tabundance" else {
            throw BBFEError("Expected a legacy alphabet with the header place, letter, abundance (tab separated).")
        }
        var entries: [AlphabetEntry] = []
        for (index, rawLine) in lines.dropFirst().enumerated() {
            let line = rawLine.hasSuffix("\r") ? String(rawLine.dropLast()) : rawLine
            let fields = line.components(separatedBy: "\t")
            guard fields.count == 3, fields[1].unicodeScalars.count == 1,
                  let scalar = fields[1].unicodeScalars.first,
                  let weight = Double(fields[2]) else {
                throw BBFEError("Invalid legacy alphabet row \(index + 2). Use JSON for tabs and line breaks.")
            }
            entries.append(AlphabetEntry(scalar: scalar.value, weight: weight))
        }
        return try Alphabet(entries: entries).validated()
    }
}

@inline(__always) func checkCancellation(at index: Int) throws {
    if index & 4095 == 0, Task<Never, Never>.isCancelled { throw CancellationError() }
}
