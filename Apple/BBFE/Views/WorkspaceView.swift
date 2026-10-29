import SwiftUI

struct WorkspaceView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    PageHeading(eyebrow: "01 / The workspace", title: "Give your words a new address.",
                                subtitle: "Every Unicode scalar finds a place in the table. The original whitespace comes back with it.")
                    settings
                    if geometry.size.width > 860 {
                        HStack(alignment: .top, spacing: 20) {
                            inputCard
                            outputCard
                        }
                    } else {
                        inputCard
                        outputCard
                    }
                    Text("Import and export UTF-8 files. Messages stay on your device; processing is limited by available memory, with no fixed message-length cutoff.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(geometry.size.width < 500 ? 16 : 28)
                .frame(maxWidth: 1400)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var settings: some View {
        Card {
            FlowActions {
                Picker("Action", selection: $model.mode) {
                    ForEach(WorkspaceMode.allCases) { mode in Text(mode.rawValue).tag(mode) }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 300)
                Spacer(minLength: 0)
                Label(model.currentKeyName, systemImage: "key.horizontal")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            if model.mode == .encipher {
                Divider()
                FlowActions {
                    Picker("Padding", selection: $model.paddingBlockSize) {
                        Text("None").tag(0)
                        Text("64 tokens").tag(64)
                        Text("256 tokens").tag(256)
                        Text("1,024 tokens").tag(1024)
                    }
                    .frame(maxWidth: 250)
                    .disabled(model.legacyFormat)
                    Toggle("Legacy coordinates", isOn: $model.legacyFormat)
                        .toggleStyle(.switch)
                        .frame(maxWidth: 250)
                }
                Text(model.legacyFormat
                     ? "Raw A1B2 coordinates work with the original CLI and the same table. Legacy messages don’t include padding or a table identifier."
                     : "BBFE2 framing records the table and true length. Random extra coordinates fill the chosen block size; the header still reveals the original length.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Paste a BBFE2 message or legacy A1B2 coordinates. BBFE2 padding is removed automatically.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .disabled(model.isBusy)
    }

    private var inputCard: some View {
        Card {
            HStack {
                Label(model.mode == .encipher ? "Your message" : "Ciphertext", systemImage: "text.cursor")
                    .font(.headline)
                Spacer()
                Menu {
                    Button("Paste", systemImage: "doc.on.clipboard", action: model.pasteInput)
                    Button("Import UTF-8 file…", systemImage: "square.and.arrow.down") { model.beginImport(.message) }
                    Button("Load example", systemImage: "sparkles") { model.input = AppModel.example; model.mode = .encipher }
                    Divider()
                    Button("Clear", systemImage: "xmark") { model.input = "" }
                } label: { Image(systemName: "ellipsis.circle").font(.title3) }
                #if os(macOS)
                .menuStyle(.borderlessButton)
                #endif
                .fixedSize()
                .disabled(model.isBusy)
            }
            EditorBox(text: $model.input, label: model.mode == .encipher ? "Type or paste any Unicode text…" : "Paste your coordinate message…", minimumHeight: 300)
                .disabled(model.isBusy)
            FlowActions {
                Text("\(model.input.utf8.count.formatted()) UTF-8 bytes")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer()
                Button(action: model.process) {
                    Label(model.mode == .encipher ? "Encipher" : "Decipher", systemImage: model.mode == .encipher ? "arrow.right" : "arrow.uturn.backward")
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(model.isBusy || model.table == nil)
            }
        }
    }

    private var outputCard: some View {
        Card {
            HStack {
                Label("The result", systemImage: "text.alignleft")
                    .font(.headline)
                Spacer()
                if !model.output.isEmpty {
                    Text("READY")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(Theme.teal)
                }
            }
            EditorBox(text: $model.output, label: "Your result will appear here.", minimumHeight: 300)
                .disabled(model.isBusy)
            FlowActions {
                Button("Copy", systemImage: "doc.on.doc", action: model.copyOutput)
                Button("Export…", systemImage: "square.and.arrow.up", action: model.exportOutput)
                Spacer(minLength: 0)
                Button("Use as input", systemImage: "arrow.uturn.left", action: model.useOutputAsInput)
            }
            .buttonStyle(.bordered)
            .disabled(model.isBusy || model.output.isEmpty)
        }
    }
}
