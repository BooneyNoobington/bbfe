import SwiftUI

struct SavedKeysView: View {
    @EnvironmentObject private var model: AppModel
    @State private var pendingDeletion: SavedKeySummary?
    var showSavedKeys = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                PageHeading(eyebrow: "04 / The keychain", title: "Keep the key to your words.",
                            subtitle: "Save the alphabet and exact cipher table together in Apple Keychain. Load the same key whenever you want to bring a message back.")
                Card {
                    Label("Save the current key", systemImage: "key.horizontal").font(.headline)
                    TextField("Key name", text: $model.profileName)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel("Saved key name")
                    Toggle(isOn: $model.synchronizeKey) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sync with iCloud Keychain").font(.callout.weight(.medium))
                            Text("Requires iCloud Keychain enabled on your devices and the same signed app. Availability is managed by Apple.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .toggleStyle(.switch)
                    HStack {
                        Text("Saving creates a new named snapshot.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Save to Keychain", systemImage: "plus", action: model.saveKey)
                            .buttonStyle(.borderedProminent)
                            .disabled(model.table == nil || model.profileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .disabled(model.isBusy)

                if showSavedKeys { Card {
                    HStack {
                        Text("Saved keys").font(.headline)
                        Spacer()
                        Button("Refresh", systemImage: "arrow.clockwise", action: model.refreshKeys)
                            .buttonStyle(.bordered)
                            .disabled(model.isBusy)
                    }
                    if model.savedKeys.isEmpty {
                        ContentUnavailableView("A home for your cipher tables", systemImage: "key.horizontal", description: Text("Your saved keys will appear here. Messages and example text are never added to the vault."))
                    } else {
                        ForEach(model.savedKeys, id: \.storageID) { summary in
                            keyRow(summary)
                            if summary.storageID != model.savedKeys.last?.storageID { Divider() }
                        }
                    }
                } }
                Text("These are private app records in Apple Keychain. They are managed here and do not appear as password entries in Apple’s Passwords app. Exported alphabet and table JSON files are readable files, so choose where you save them.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .frame(maxWidth: 1000)
            .frame(maxWidth: .infinity)
        }
        .task { model.refreshKeys() }
        .confirmationDialog("Delete saved key?", isPresented: Binding(
            get: { pendingDeletion != nil },
            set: { if !$0 { pendingDeletion = nil } }
        ), titleVisibility: .visible) {
            if let summary = pendingDeletion {
                Button("Delete \(summary.name)", role: .destructive) {
                    model.deleteKey(summary)
                    pendingDeletion = nil
                }
            }
        } message: {
            Text(pendingDeletion?.isSynchronizable == true
                 ? "This deletes the synced Keychain record across your devices. Messages still need this exact table to be deciphered."
                 : "Messages still need this exact table to be deciphered. Export it first if you need to keep a copy.")
        }
    }

    private func keyRow(_ summary: SavedKeySummary) -> some View {
        FlowActions {
            HStack(spacing: 12) {
                Image(systemName: summary.isSynchronizable ? "icloud" : "key.horizontal")
                    .font(.title2)
                    .foregroundStyle(Theme.teal)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 5) {
                    Text(summary.name).font(.callout.weight(.semibold))
                    Text("\(summary.isSynchronizable ? "iCloud Keychain" : "This device") · \(summary.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            HStack {
                Button("Load") { model.requestLoadKey(summary) }.buttonStyle(.bordered)
                Button(role: .destructive) { pendingDeletion = summary } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Delete \(summary.name)")
            }
            .disabled(model.isBusy)
        }
        .padding(.vertical, 5)
    }
}
