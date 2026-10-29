# bbfe · a little cipher lab

**Bad but (somewhat) fast encryption**, originally written by Markus Roth. BBFE scatters a weighted alphabet across a table with columns A–Z, then replaces each symbol with a randomly chosen coordinate.

The repository now includes a native **macOS, iOS, and iPadOS app**, a shared Swift engine, and a new command-line tool. The original C++, Python, and R implementations are preserved.

## Run the Apple app

1. Install **Xcode 16 or newer**, launch it once, and let it install its required components.
2. Open [`Apple/BBFE.xcodeproj`](Apple/BBFE.xcodeproj).
3. Select the **BBFE** scheme and **My Mac**, an iPhone simulator, or an iPad simulator. Press **⌘R**.
4. For Keychain access and installation on your own devices, choose your Apple development team under **BBFE → Signing & Capabilities**. Keep the same bundle identifier and team on your devices for shared iCloud Keychain records.

Requires **macOS 14+** or **iOS/iPadOS 17+**. No third-party dependencies, server, or API key is needed. Install a simulator runtime from Xcode's Settings → Components if none is available.

## Features

- **Workspace:** encipher and decipher pasted text or UTF-8 files, copy/export results, and choose optional padding.
- **Alphabet Lab:** paste example text, inspect a Unicode scalar histogram, and generate a weighted random table. Import alphabets from JSON or the original histogram TSV format.
- **Cipher Table:** inspect coordinates, search symbols, and import/export JSON or compatible legacy TSV.
- **Saved Keys:** store named alphabet/table pairs in Apple Keychain, optionally request iCloud Keychain sync, and load or delete saved keys.

**Save or export a table before closing the app or generating a replacement.** New tables are random. Old messages require their original table; the alphabet alone cannot recreate it. Messages and training text are held in memory and are not automatically saved.

Unicode scalar handling preserves tabs, line breaks, emoji, combining marks, and NUL without normalization. There is no fixed message-length cutoff; this version holds input and output in memory. Build an alphabet containing the symbols you want to encipher from representative text, or import a suitable alphabet.

Profiles are managed **inside BBFE** using Apple Keychain. Arbitrary tables are not Passwords app login entries. See [Apple's Keychain documentation](https://developer.apple.com/documentation/security/using-the-keychain-to-manage-user-secrets).

BBFE remains an **educational substitution cipher** without authentication or modern encryption guarantees. Padding fills coordinate-token blocks; the BBFE2 header still exposes the original scalar count.

## Swift command line

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
cd Apple
swift test
swift build -c release
.build/release/bbfe --help

# Learn an alphabet, retain a key, and round-trip a UTF-8 file.
.build/release/bbfe histogram --input sample.txt --output alphabet.json
.build/release/bbfe table --alphabet alphabet.json --output key.json
.build/release/bbfe encipher --table key.json --input sample.txt --padding 256 --output message.bbfe
.build/release/bbfe decipher --table key.json --input message.bbfe --output recovered.txt
cmp sample.txt recovered.txt
```

Input/output support standard input/output using `-`. JSON keys work with the app and new CLI. See [`Apple/README.md`](Apple/README.md) for formats, legacy interoperability, build checks, and signing.

## Repository

| Path | Contents |
| --- | --- |
| `Apple/BBFE/` | Shared SwiftUI application and Keychain vault |
| `Apple/Sources/BBFECore/` | Unicode alphabet, weighted tables, coordinate cipher |
| `Apple/Sources/bbfe/` | Swift CLI |
| `Apple/Tests/` | Engine regression tests |
| `c++/`, `python/`, `R/` | Original implementations |
| `share/` | Original sample alphabet histogram |

The original instructions are retained in [`docs/legacy-cli.md`](docs/legacy-cli.md). Original implementations retain their limitations; Swift is the maintained Apple implementation.

## License

GNU GPL v3, as declared by the original project. See the [GNU GPL v3 license](https://www.gnu.org/licenses/gpl-3.0.html). Original author: **Markus Roth**. Original acknowledgments: Stack Overflow and Prof. Hannah Bast's C++ lectures.
