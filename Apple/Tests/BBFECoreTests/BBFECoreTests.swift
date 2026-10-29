import Foundation
import Testing
@testable import BBFECore

private func cipher(for text: String) throws -> BBFECipher {
    try BBFECipher(table: .generate(from: .histogram(from: text), minimumSlots: 260))
}

@Test func exactUnicodeAndControlRoundTrip() throws {
    let text = "\u{FEFF}Grüße\n\t\r\n\0é e\u{301} 👩🏽‍💻 🇩🇪 \u{FEFF}\u{2028}漢字 العربية 𝄞"
    let cipher = try cipher(for: text)
    let decoded = try cipher.decode(cipher.encode(text))
    #expect(Array(decoded.utf8) == Array(text.utf8))
    #expect(Alphabet.histogram(from: "é e\u{301}").entries.contains(where: { $0.scalar == 0x301 }))
}

@Test func strictUTF8LoadingPreservesBOMAndRejectsMalformedBytes() throws {
    let bytes = Data([0xEF, 0xBB, 0xBF, 65, 0, 9, 13, 10])
    #expect(Array(try UTF8Text.decode(bytes).utf8) == Array(bytes))
    #expect(try UTF8Text.decode(Data()).isEmpty)
    for malformed in [[UInt8(0xFF)], [0xC0, 0x80], [0xED, 0xA0, 0x80], [0xF4, 0x90, 0x80, 0x80], [0xE2, 0x82]] {
        #expect(throws: (any Error).self) { try UTF8Text.decode(Data(malformed)) }
    }
}

@Test func longMessagesAndRowsBeyondByteRange() throws {
    let text = String(repeating: "ab\n\t😀e\u{301}", count: 20_000)
    let table = try CipherTable.generate(from: .histogram(from: text), minimumSlots: 26 * 300)
    #expect(table.rowCount == 300)
    let cipher = try BBFECipher(table: table)
    #expect(Array(try cipher.decode(cipher.encode(text)).utf8) == Array(text.utf8))
    #expect(try cipher.decode("A300Z300").unicodeScalars.count == 2)
}

@Test func paddingIsExactAndRemovedWithoutTrimmingText() throws {
    let text = " hi \n\t\0"
    let cipher = try cipher(for: text)
    let encoded = try cipher.encode(text, paddingBlockSize: 64)
    let header = encoded.split(separator: "\n", maxSplits: 1)[0].split(separator: ":")
    #expect(Int(header[2]) == text.unicodeScalars.count)
    #expect(header[3] == "64")
    #expect(Array(try cipher.decode(encoded).utf8) == Array(text.utf8))
    #expect(Array(try cipher.decode(encoded.replacingOccurrences(of: "\n", with: "\r\n")).utf8) == Array(text.utf8))
    #expect(try cipher.decode(cipher.encode("", paddingBlockSize: 64)) == "")
    #expect(try cipher.decode(cipher.encode(String(repeating: "h", count: 64), paddingBlockSize: 64)).count == 64)
    #expect(throws: (any Error).self) { try cipher.encode(text, paddingBlockSize: -1) }
    #expect(throws: (any Error).self) { try cipher.encode(text, paddingBlockSize: 64, legacy: true) }
}

@Test func histogramWeightsDoNotInflateTables() throws {
    let alphabet = Alphabet.histogram(from: String(repeating: "a", count: 100_000) + "b")
    let table = try CipherTable.generate(from: alphabet, minimumSlots: 260)
    #expect(table.cells.count == 260)
    #expect(table.cells.filter { $0 == 98 }.count >= 1)
    #expect(table.cells.filter { $0 == 97 }.count > table.cells.filter { $0 == 98 }.count)
    let tiny = Alphabet(entries: [.init(scalar: 97, weight: Double.leastNonzeroMagnitude), .init(scalar: 98, weight: Double.greatestFiniteMagnitude)])
    #expect(Set(try CipherTable.generate(from: tiny, minimumSlots: 26).cells) == [97, 98])
    #expect(throws: (any Error).self) { try CipherTable.generate(from: alphabet, minimumSlots: Int.max) }
    #expect(throws: (any Error).self) { try CipherTable.generate(from: .histogram(from: "a"), minimumSlots: Int.max - 26) }
}

@Test func everyUnicodeScalarCanBeRepresented() throws {
    let values = Array(UInt32(0)...UInt32(0x1200)) + [UInt32(0x10FFFF)]
    let alphabet = Alphabet(entries: values.map { .init(scalar: $0, weight: 1) })
    let table = try CipherTable.generate(from: alphabet, minimumSlots: 26)
    #expect(Set(table.cells).isSuperset(of: values))
    let text = String(String.UnicodeScalarView(values.compactMap(Unicode.Scalar.init)))
    let cipher = try BBFECipher(table: table)
    #expect(Array(try cipher.decode(cipher.encode(text)).utf8) == Array(text.utf8))
}

@Test func malformedInputsFailWithoutPartialPlaintext() throws {
    let cipher = try cipher(for: "hello ")
    for invalid in ["A", "1A", "A0", "A-1", "[1", "A9999999999999999999999999999999", "A99999", "A1!", "A1 2", "AA1"] {
        #expect(throws: (any Error).self) { try cipher.decode(invalid) }
    }
    let encoded = try cipher.encode("hello")
    let lastCoordinate = encoded.lastIndex(where: { $0.isASCII && $0.isLetter })!
    #expect(throws: (any Error).self) { try cipher.decode(String(encoded[..<lastCoordinate])) }
    #expect(throws: (any Error).self) { try cipher.decode(encoded + "A1") }
    #expect(throws: (any Error).self) { try cipher.decode("BBFE3:invalid\nA1") }
    let wrongCipher = try selfCipherDifferentTable()
    #expect(throws: (any Error).self) { try wrongCipher.decode(encoded) }
    #expect(throws: (any Error).self) { try cipher.encode("missing: 🦄") }
}

private func selfCipherDifferentTable() throws -> BBFECipher { try cipher(for: "hello ") }

@Test func JSONAndValidationRejectInvalidKeys() throws {
    let original = try CipherTable.generate(from: .basicLatin, minimumSlots: 104)
    let decoded = try JSONDecoder().decode(CipherTable.self, from: JSONEncoder().encode(original)).validated()
    #expect(decoded.id == original.id)
    #expect(decoded.cells == original.cells)
    #expect(throws: (any Error).self) { try CipherTable(cells: [0xD800]).validated() }
    #expect(throws: (any Error).self) { try CipherTable(cells: [UInt32](repeating: 0x110000, count: 26)).validated() }
    #expect(throws: (any Error).self) { try Alphabet(entries: []).validated() }
    #expect(throws: (any Error).self) { try Alphabet(entries: [.init(scalar: 65, weight: 0)]).validated() }
    #expect(throws: (any Error).self) { try Alphabet(entries: [.init(scalar: 65, weight: .infinity)]).validated() }
    #expect(throws: (any Error).self) { try Alphabet(entries: [.init(scalar: 65, weight: 1), .init(scalar: 65, weight: 2)]).validated() }
    var badVersion = original; badVersion.version = 3
    #expect(throws: (any Error).self) { try badVersion.validated() }
}

@Test func legacyCoordinatesAndTSVRoundTrip() throws {
    let row = Array(UInt32(65)...UInt32(90)).map { String(Unicode.Scalar($0)!) }.joined(separator: "\t")
    let table = try CipherTable.importLegacyTSV(row + "\n" + row.lowercased() + "\n")
    let cipher = try BBFECipher(table: table)
    #expect(try cipher.decode("A1B1Z1a2b2z2") == "ABZabz")
    #expect(try cipher.decode("  A1\n B1\t Z1\r\n") == "ABZ")
    #expect(try cipher.decode("A 1 B\t1 Z\n1") == "ABZ")
    #expect(try cipher.encode("ABZabz", legacy: true) == "A1B1Z1A2B2Z2")
    #expect(try table.exportLegacyTSV() == row + "\n" + row.lowercased() + "\n")
    #expect(try CipherTable.importLegacyTSV(table.exportLegacyTSV()).cells == table.cells)
    let reimported = try CipherTable.importLegacyTSV(table.exportLegacyTSV())
    #expect(reimported.id == table.id)
    #expect(try BBFECipher(table: reimported).decode(cipher.encode("ABZabz")) == "ABZabz")
    #expect(throws: (any Error).self) { try CipherTable.generate(from: .basicLatin).exportLegacyTSV() }
    #expect(throws: (any Error).self) { try CipherTable.importLegacyTSV("a\tb") }
}

@Test func originalAlphabetFixtureImports() throws {
    let url = Bundle.module.url(forResource: "alphabet_histogram", withExtension: "tsv", subdirectory: "Fixtures")!
    let alphabet = try Alphabet.importLegacyTSV(String(contentsOf: url, encoding: .utf8))
    #expect(alphabet.entries.count == 101)
    #expect(alphabet.entries.first(where: { $0.scalar == 0x1E9E })?.weight == 0.31)
    #expect(alphabet.entries.contains(where: { $0.scalar == 32 }))
    #expect(throws: (any Error).self) { try Alphabet.importLegacyTSV("place\tletter\tabundance\n1\tAB\t1\n") }
}

@Test func framedPayloadCountAndOverflowValidation() throws {
    let cipher = try cipher(for: "a")
    let id = cipher.table.id.uuidString
    for header in ["BBFE2:\(id):2:1\nA1", "BBFE2:\(id):-1:1\nA1", "BBFE2:\(id):1:99999999999999999999999\nA1", "BBFE2:\(id):1:2\nA1", "BBFE2:\(id):0:0\nA1"] {
        #expect(throws: (any Error).self) { try cipher.decode(header) }
    }
    #expect(try cipher.decode("BBFE2:\(id):0:0\n") == "")
}
