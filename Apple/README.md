# BBFE for Apple platforms

## Project and signing

Open `BBFE.xcodeproj` with Xcode 16+. One SwiftUI target runs natively on macOS 14+, iOS 17+, and iPadOS 17+. The adjacent Swift package supplies `BBFECore` without fetching dependencies.

Choose a development team in Signing & Capabilities for Keychain and real-device builds. The bundle identifier is `com.BooneyNoobington.bbfe`; change it if your account needs a unique identifier. The Mac app uses App Sandbox with access to user-selected files. Separate platform entitlements use the same Keychain access-group expression.

An unsigned build verifies compilation, not Keychain access. Xcode may need to register the identifier or enable Keychain Sharing for your team. Use a consistent team, identifier, and access group across devices for iCloud records. Changing these can make previous records inaccessible; export tables before changing them. No team ID or signing credentials are included in the repository.

## Workflow and persistence

1. Try the starter message. Its random table includes printable Basic Latin, TAB, LF, CR, and the example's Unicode scalars.
2. Paste a corpus in Alphabet Lab and build its histogram. Counts become relative weights.
3. Generate a table: every symbol receives at least one slot, and remaining slots follow the weights. The default is 4,108 cells (4,096 rounded up to rows of 26).
4. Save the alphabet/table pair to Keychain or export JSON. A draft alphabet does not change the active table; profiles save the alphabet used for that table.
5. Encipher using BBFE2, with optional block padding. Use the result as input to decipher it.
6. Load the matching table to recover an existing message on another device.

Unsaved tables are temporary; the interface warns before replacement. Save or export before closing the app. Exported JSON contains plaintext key material. Messages and training corpora are not automatically saved.

## Unicode and memory

Symbols are **Unicode scalars**, not grapheme clusters. Joined emoji can contain several symbols. Precomposed and decomposed accents stay distinct. Valid UTF-8 sequences, including NUL and control characters, are supported; invalid UTF-8 files are rejected. Alphabets can contain any valid scalar but do not automatically contain all Unicode code points.

The engine indexes positions once, processes messages in linear time, and uses Swift `Int` counters without legacy 8-bit or 16-bit limits. Long operations run away from the UI thread and support cancellation. Editors, file operations, and the CLI materialize messages in memory; multi-gigabyte files need a future streaming interface. “No fixed cutoff” does not mean unlimited memory.

## Formats

### Alphabet JSON

An object with `entries`, each containing a numeric `scalar` and positive finite `weight`. Scalars must be unique. Numeric scalars preserve control characters and normalization differences. Weights may be counts or relative frequencies; generation normalizes them to a slot budget.

```json
{
  "entries": [
    { "scalar": 10, "weight": 1 },
    { "scalar": 65, "weight": 3 },
    { "scalar": 128075, "weight": 1 }
  ]
}
```

### Table JSON

Version 2 tables contain `version`, `id` (UUID), `createdAt`, and `cells`. Cells are numeric scalars in row order: index 0 is A1, index 25 is Z1, index 26 is A2. A positive multiple of 26 cells is required. `createdAt` uses Foundation's default Codable date representation, seconds since 2001-01-01 UTC.

JSON preserves table UUIDs. Importing legacy TSV derives a stable identifier from the ordered cells, so separate CLI invocations can read the same table. Exporting a generated JSON table as TSV still loses its original UUID; retain JSON for existing framed messages, and use TSV with raw legacy coordinates.

### BBFE2 messages

```text
BBFE2:<table UUID>:<original scalar count>:<total coordinate count>
A1B2C3...
```

Coordinates use an A–Z column and positive decimal row. ASCII spaces, tabs, and line breaks may separate coordinates. Decode checks the table UUID and both counts, rejects invalid coordinates, and removes padding. Raw legacy coordinates are accepted too.

Padding rounds the **coordinate-token count**, not byte count, to a multiple of the block size using random valid coordinates. Empty or already aligned messages need no extra tokens. The public header exposes exact original length: this padding **does not hide length**. There is no authentication tag; changed valid coordinates can yield changed plaintext without error.

### Legacy compatibility

- Import `share/alphabet_histogram.csv` as legacy TSV; its actual delimiter is a tab.
- Legacy tables have 26 single-scalar tab-separated columns, without a header.
- Choose **Legacy coordinates**, or CLI `--legacy`, for raw A1B2 messages compatible with an original CLI using the same table.
- Legacy TSV cannot represent TAB, CR, or LF as cells. Export JSON for these alphabets. Basic Latin includes these controls; use a control-free alphabet for TSV export.
- Raw messages have neither table UUID nor padding metadata. A wrong table can silently give different plaintext. Original CLIs retain their Unicode and length limitations.

## Keychain

Named profiles use app-specific generic-password records containing alphabet/table JSON. Metadata allows listing names, dates, and storage location. Key material is never stored in UserDefaults. No messages or corpora are stored in the vault.

Local items do not request synchronization. iCloud items request `kSecAttrSynchronizable` and depend on iCloud Keychain being enabled; delivery is asynchronous. Builds need the same signing team and access group. Local and synced records are separate copies; deleting an iCloud record can propagate to other devices. Repeated saves create distinct profiles rather than overwriting by display name.

Keychain is designed for small secrets. Very large tables may exceed practical item sizes. Errors are shown without silently falling back to plaintext storage; JSON export remains available. App-specific profiles are managed within BBFE and are not promised to appear in Passwords.

Apple references: [Mac Keychain guidance](https://developer.apple.com/documentation/technotes/tn3137-on-mac-keychains), [synchronizable items](https://developer.apple.com/documentation/security/ksecattrsynchronizable), and [Keychain Sharing](https://developer.apple.com/documentation/xcode/configuring-keychain-sharing).

## Build and validation

From the repository root:

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
swift test --package-path Apple
swift build --package-path Apple -c release
xcodebuild -project Apple/BBFE.xcodeproj -scheme BBFE -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project Apple/BBFE.xcodeproj -scheme BBFE -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

The `DEVELOPER_DIR` setting selects Xcode's complete toolchain for this shell, including Swift Testing plugins, without changing the system's `xcode-select` setting. Adjust the path if Xcode is installed elsewhere. CI runs package tests and builds both platforms.

The engine tests cover byte-exact Unicode, controls, long messages, padding, invalid input, and legacy formats. Signed device tests remain necessary for Keychain: save, relaunch, load, and decode an existing message; repeat on a second device with iCloud enabled, and verify separate local/synced records and deletion.

The coordinate-inspired icon is reproducible from `scripts/generate-icon.swift` using AppKit without external artwork.
