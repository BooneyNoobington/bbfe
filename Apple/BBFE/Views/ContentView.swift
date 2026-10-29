import SwiftUI
import UniformTypeIdentifiers

enum AppSection: String, CaseIterable, Identifiable {
    case workspace = "Workspace"
    case alphabet = "Alphabet Lab"
    case table = "Cipher Table"
    case keys = "Saved Keys"

    var id: Self { self }
    var symbol: String {
        switch self {
        case .workspace: "text.alignleft"
        case .alphabet: "chart.bar.xaxis"
        case .table: "square.grid.3x3"
        case .keys: "key.horizontal"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selection: AppSection? = .workspace
    @State private var dismissedTableID: UUID?

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section {
                    ForEach(AppSection.allCases) { section in
                        NavigationLink(value: section) {
                            Label(section.rawValue, systemImage: section.symbol)
                                .padding(.vertical, 6)
                        }
                    }
                } header: {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("bbfe").font(.system(size: 36, weight: .black, design: .rounded))
                            .foregroundStyle(.primary)
                        Text("A LITTLE CIPHER LAB")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1.5)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 22)
                    .textCase(nil)
                }
                Section {
                    VStack(alignment: .leading, spacing: 9) {
                        Label("Current key", systemImage: "circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.teal)
                        Text(model.currentKeyName)
                            .font(.callout.weight(.medium))
                            .lineLimit(2)
                        Text("Keep the table. It’s what brings your message back.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                Section {
                    Button { model.showAbout = true } label: {
                        Label("About this project", systemImage: "info.circle")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 220, ideal: 245, max: 300)
            .navigationTitle("bbfe")
        } detail: {
            Group {
                switch selection ?? .workspace {
                case .workspace: WorkspaceView()
                case .alphabet: AlphabetLabView()
                case .table: CipherTableView()
                case .keys: SavedKeysView()
                }
            }
            .background(Theme.background)
            .safeAreaInset(edge: .top, spacing: 0) {
                if model.hasUnsavedTable, let table = model.table, dismissedTableID != table.id {
                    unsavedKeyBanner
                }
            }
            .navigationTitle((selection ?? .workspace).rawValue)
            .toolbar {
                if model.isBusy {
                    ToolbarItem(placement: .primaryAction) { activityControls }
                }
            }
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        .onChange(of: model.hasUnsavedTable) { _, isUnsaved in
            if !isUnsaved { dismissedTableID = nil }
        }
        .fileImporter(isPresented: $model.showImporter,
                      allowedContentTypes: [.plainText, .json, .commaSeparatedText, .data],
                      allowsMultipleSelection: false,
                      onCompletion: model.receiveImport)
        .fileExporter(isPresented: $model.showExporter,
                      document: model.exportDocument,
                      contentType: model.exportType,
                      defaultFilename: model.exportName) { result in
            switch result {
            case .success: model.notice = "File exported."
            case .failure(let error): model.fail(error.localizedDescription)
            }
        }
        .alert("Couldn’t complete action", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
        .sheet(isPresented: $model.showAbout) { AboutView() }
        .sheet(isPresented: $model.showSaveKeySheet) {
            NavigationStack {
                SavedKeysView(showSavedKeys: false)
                    .navigationTitle("Save your current key")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { model.showSaveKeySheet = false }
                        }
                        if model.isBusy {
                            ToolbarItem(placement: .cancellationAction) { activityControls }
                        }
                    }
            }
            .frame(minWidth: 320, idealWidth: 650, minHeight: 450, idealHeight: 650)
        }
        .confirmationDialog("Replace the current unsaved table?", isPresented: Binding(
            get: { model.pendingReplacement != nil },
            set: { if !$0 { model.pendingReplacement = nil } }
        ), titleVisibility: .visible) {
            Button("Replace current table", role: .destructive, action: model.confirmReplacement)
        } message: {
            Text("Save to Keychain or export your current table first if you need to decipher its messages later. Its random coordinates cannot be recreated from the alphabet.")
        }
    }

    private var unsavedKeyBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Unsaved table", systemImage: "key.horizontal")
                        .font(.caption.weight(.semibold))
                    Text("Save or export this table before quitting.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Button {
                    dismissedTableID = model.table?.id
                } label: {
                    Image(systemName: "xmark")
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Dismiss unsaved table warning")
            }
            HStack(spacing: 12) {
                Button("Save key") { model.showSaveKeySheet = true }
                    .buttonStyle(.borderedProminent)
                Button("Export…") { model.exportTable() }
                    .buttonStyle(.bordered)
            }
            .controlSize(.small)
            .disabled(model.isBusy)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .background(Theme.accent.opacity(0.10))
    }

    private var activityControls: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
                .accessibilityLabel(model.activityLabel)
            Button("Cancel", action: model.cancel)
        }
        .fixedSize()
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("bbfe").font(.system(size: 56, weight: .black, design: .rounded))
                .foregroundStyle(Theme.accent)
            Text("Bad but (somewhat) fast encryption")
                .font(.title2.weight(.semibold))
            Text("A hobby cipher by Markus Roth, reimagined for Mac, iPhone, and iPad. Build an alphabet, scatter it across a weighted table, and turn a message into coordinates.")
            Text("BBFE is an educational substitution cipher. Use established encryption for secrets that need protection.")
                .font(.callout)
                .foregroundStyle(.secondary)
            Link("View the original project", destination: URL(string: "https://github.com/BooneyNoobington/bbfe")!)
            Text("GPL v3 · Made for experimenting")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Done", action: { dismiss() }).buttonStyle(.borderedProminent)
        }
        .padding(32)
        .frame(maxWidth: 540, alignment: .leading)
        .tint(Theme.accent)
    }
}
