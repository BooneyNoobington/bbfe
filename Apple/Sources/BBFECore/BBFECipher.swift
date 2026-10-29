import Foundation

/// BBFE is a randomized coordinate substitution experiment, not authenticated encryption.
public struct BBFECipher: Sendable {
    public let table: CipherTable
    private let positions: [UInt32: [Int]]

    public init(table: CipherTable) throws {
        self.table = try table.validated()
        var positions: [UInt32: [Int]] = [:]
        for (index, scalar) in table.cells.enumerated() { positions[scalar, default: []].append(index) }
        self.positions = positions
    }

    /// Padding is measured in coordinate tokens, not encoded UTF-8 bytes.
    /// The public framing header records the exact original scalar count.
    public func encode(_ text: String, paddingBlockSize: Int = 0, legacy: Bool = false) throws -> String {
        guard paddingBlockSize >= 0 else { throw BBFEError("Padding must be zero or a positive block size.") }
        guard !legacy || paddingBlockSize == 0 else { throw BBFEError("Legacy messages do not support padding. Use BBFE2 format.") }
        let count = text.unicodeScalars.count
        let paddedCount: Int
        if paddingBlockSize > 0 {
            let remainder = count % paddingBlockSize
            let extra = remainder == 0 ? 0 : paddingBlockSize - remainder
            let (value, overflow) = count.addingReportingOverflow(extra)
            guard !overflow else { throw BBFEError("The padded message would be too large.") }
            paddedCount = value
        } else { paddedCount = count }
        var output = legacy ? "" : "BBFE2:\(table.id.uuidString):\(count):\(paddedCount)\n"
        var random = SystemRandomNumberGenerator()
        for (index, scalar) in text.unicodeScalars.enumerated() {
            try checkCancellation(at: index)
            guard let choices = positions[scalar.value] else {
                let entry = AlphabetEntry(scalar: scalar.value, weight: 1)
                throw BBFEError("The table does not contain \(entry.displayName) (\(String(format: "U+%04X", scalar.value))) at scalar \(index + 1). Build an alphabet from this text and generate a new table.")
            }
            appendCoordinate(choices.randomElement(using: &random)!, to: &output)
        }
        for index in count..<paddedCount {
            try checkCancellation(at: index)
            appendCoordinate(Int.random(in: table.cells.indices, using: &random), to: &output)
        }
        return output
    }

    /// Accepts BBFE2 or raw A1B2… coordinates. Payload whitespace may be added freely.
    public func decode(_ ciphertext: String) throws -> String {
        let payload: Substring
        var originalCount: Int?
        var expectedCount: Int?
        // Preserve the header's newline even when an empty message has no payload.
        let trimmed = ciphertext.drop(while: { $0.isWhitespace })
        if trimmed.hasPrefix("BBFE") {
            guard let newline = trimmed.utf8.firstIndex(of: 10) else { throw BBFEError("The BBFE2 message header is missing its payload separator.") }
            let header = trimmed[..<newline].trimmingCharacters(in: .whitespacesAndNewlines)
            let fields = header.split(separator: ":", omittingEmptySubsequences: false)
            guard fields.count == 4, fields[0] == "BBFE2",
                  let identifier = UUID(uuidString: String(fields[1])),
                  let original = parseUnsignedDecimal(fields[2]),
                  let padded = parseUnsignedDecimal(fields[3]), original <= padded else {
                throw BBFEError("Invalid or unsupported BBFE2 message header.")
            }
            guard identifier == table.id else { throw BBFEError("This message belongs to a different cipher table. Load the matching key.") }
            originalCount = original; expectedCount = padded
            payload = trimmed[trimmed.utf8.index(after: newline)...]
        } else { payload = trimmed[...] }

        var output = String.UnicodeScalarView()
        var tokenCount = 0
        var column: Int?
        var row = 0
        var digits = 0
        var whitespaceAfterDigits = false

        func emit() throws {
            guard let currentColumn = column, digits > 0, row > 0, row <= table.rowCount else {
                throw BBFEError("Invalid or out-of-range coordinate near token \(tokenCount + 1).")
            }
            if let expectedCount, tokenCount >= expectedCount { throw BBFEError("The message has more coordinates than its header declares.") }
            if originalCount == nil || tokenCount < originalCount! {
                output.append(Unicode.Scalar(table.cells[(row - 1) * CipherTable.columns + currentColumn])!)
            }
            tokenCount += 1
        }

        for (offset, byte) in payload.utf8.enumerated() {
            try checkCancellation(at: offset)
            switch byte {
            case 65...90, 97...122:
                if column != nil { try emit() }
                column = Int(byte >= 97 ? byte - 97 : byte - 65)
                row = 0; digits = 0; whitespaceAfterDigits = false
            case 48...57:
                guard column != nil, !whitespaceAfterDigits else { throw BBFEError("A coordinate needs a column letter followed by one uninterrupted row number.") }
                let (product, multiplicationOverflow) = row.multipliedReportingOverflow(by: 10)
                let (next, additionOverflow) = product.addingReportingOverflow(Int(byte - 48))
                guard !multiplicationOverflow, !additionOverflow else { throw BBFEError("A coordinate row number is too large.") }
                row = next; digits += 1
            case 9, 10, 13, 32:
                if digits > 0 { whitespaceAfterDigits = true }
            default:
                throw BBFEError("Invalid character in the coordinate payload. Only A–Z, row numbers, and whitespace are allowed.")
            }
        }
        if column != nil { try emit() }
        if let expectedCount, expectedCount != tokenCount { throw BBFEError("The message is truncated: its coordinate count does not match the header.") }
        return String(output)
    }

    private func appendCoordinate(_ index: Int, to output: inout String) {
        output.unicodeScalars.append(Unicode.Scalar(65 + index % CipherTable.columns)!)
        output += String(index / CipherTable.columns + 1)
    }

    private func parseUnsignedDecimal(_ value: Substring) -> Int? {
        guard !value.isEmpty, value.utf8.allSatisfy({ (48...57).contains($0) }) else { return nil }
        return Int(value)
    }
}
