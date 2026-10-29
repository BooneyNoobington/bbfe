import Foundation
import BBFECore

let help = """
bbfe — Unicode coordinate cipher experiment

Usage:
  bbfe histogram [--input FILE|-] [--output FILE|-]
  bbfe table [--alphabet FILE] [--slots N] [--legacy] [--output FILE|-]
  bbfe encipher --table FILE [--input FILE|-] [--output FILE|-] [--padding N] [--legacy]
  bbfe decipher --table FILE [--input FILE|-] [--output FILE|-]

Input and output default to stdin/stdout. Text files must be valid UTF-8.
Alphabets and keys use JSON; --alphabet and --table also accept legacy TSV.
Without --alphabet, table uses printable ASCII plus TAB, LF, and CR.
--slots defaults to 4096, rounded up to a complete row of 26.
--legacy exports TSV tables or raw coordinate messages (no padding).
--padding rounds the number of coordinate tokens to a multiple of N.
The BBFE2 header records the original length; padding does not conceal it.
BBFE is for study, not secure encryption. Keep your cipher table private.
"""

struct Options {
    let command: String
    var values: [String: String] = [:]
    var legacy = false

    init(_ arguments: [String]) throws {
        guard let command = arguments.first else { throw BBFEError("Missing command. Use --help.") }
        self.command = command
        guard ["histogram", "table", "encipher", "decipher"].contains(command) else { throw BBFEError("Unknown command: \(command). Use --help.") }
        let allowed: Set<String>
        switch command {
        case "histogram": allowed = ["--input", "--output"]
        case "table": allowed = ["--alphabet", "--slots", "--output", "--legacy"]
        case "encipher": allowed = ["--table", "--input", "--output", "--padding", "--legacy"]
        default: allowed = ["--table", "--input", "--output"]
        }
        var index = 1
        while index < arguments.count {
            let flag = arguments[index]
            guard allowed.contains(flag) else { throw BBFEError("Unknown option for \(command): \(flag).") }
            if flag == "--legacy" {
                guard !legacy else { throw BBFEError("Repeated option --legacy.") }
                legacy = true; index += 1; continue
            }
            guard values[flag] == nil else { throw BBFEError("Repeated option \(flag).") }
            guard index + 1 < arguments.count, !arguments[index + 1].hasPrefix("--") else { throw BBFEError("Missing value for \(flag).") }
            values[flag] = arguments[index + 1]; index += 2
        }
    }

    func integer(_ flag: String, default fallback: Int) throws -> Int {
        guard let text = values[flag] else { return fallback }
        guard let number = Int(text) else { throw BBFEError("\(flag) requires an integer.") }
        return number
    }
}

func read(_ path: String) throws -> Data {
    if path == "-" { return FileHandle.standardInput.readDataToEndOfFile() }
    return try Data(contentsOf: URL(fileURLWithPath: path))
}

func utf8(_ data: Data) throws -> String {
    try UTF8Text.decode(data)
}

func loadTable(_ path: String?) throws -> CipherTable {
    guard let path else { throw BBFEError("--table FILE is required.") }
    let data = try read(path)
    if data.first(where: { ![UInt8(9), 10, 13, 32].contains($0) }) == 123 {
        return try JSONDecoder().decode(CipherTable.self, from: data).validated()
    }
    return try CipherTable.importLegacyTSV(utf8(data))
}

func run() throws {
    let arguments = Array(CommandLine.arguments.dropFirst())
    if arguments.isEmpty || arguments == ["--help"] || arguments == ["-h"] { print(help); return }
    let options = try Options(arguments)
    let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let result: Data
    switch options.command {
    case "histogram":
        let alphabet = Alphabet.histogram(from: try utf8(read(options.values["--input"] ?? "-")))
        try alphabet.validated()
        result = try encoder.encode(alphabet)
    case "table":
        let alphabet: Alphabet
        if let path = options.values["--alphabet"] {
            let data = try read(path)
            if data.first(where: { ![UInt8(9), 10, 13, 32].contains($0) }) == 123 {
                alphabet = try JSONDecoder().decode(Alphabet.self, from: data).validated()
            } else { alphabet = try Alphabet.importLegacyTSV(utf8(data)) }
        } else { alphabet = .basicLatin }
        let table = try CipherTable.generate(from: alphabet, minimumSlots: options.integer("--slots", default: 4096))
        result = options.legacy ? Data(try table.exportLegacyTSV().utf8) : try encoder.encode(table)
    case "encipher":
        guard options.values["--table"] != "-" || options.values["--input"] != nil && options.values["--input"] != "-" else {
            throw BBFEError("A key and message cannot both be read from stdin.")
        }
        let cipher = try BBFECipher(table: loadTable(options.values["--table"]))
        result = Data(try cipher.encode(utf8(read(options.values["--input"] ?? "-")), paddingBlockSize: options.integer("--padding", default: 0), legacy: options.legacy).utf8)
    default:
        guard options.values["--table"] != "-" || options.values["--input"] != nil && options.values["--input"] != "-" else {
            throw BBFEError("A key and message cannot both be read from stdin.")
        }
        let cipher = try BBFECipher(table: loadTable(options.values["--table"]))
        result = Data(try cipher.decode(utf8(read(options.values["--input"] ?? "-"))).utf8)
    }
    if let path = options.values["--output"], path != "-" {
        try result.write(to: URL(fileURLWithPath: path), options: .atomic)
    } else { try FileHandle.standardOutput.write(contentsOf: result) }
}

do { try run() }
catch {
    try? FileHandle.standardError.write(contentsOf: Data("bbfe: \(error.localizedDescription)\n".utf8))
    exit(EXIT_FAILURE)
}
