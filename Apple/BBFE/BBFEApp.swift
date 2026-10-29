import SwiftUI

@main
struct BBFEApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .tint(Theme.accent)
        }
        #if os(macOS)
        .defaultSize(width: 1180, height: 820)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About BBFE") { model.showAbout = true }
            }
            CommandGroup(after: .newItem) {
                Button("Import Message…") { model.beginImport(.message) }
                    .keyboardShortcut("o", modifiers: .command)
                    .disabled(model.isBusy)
                Button("Export Output…") { model.exportOutput() }
                    .keyboardShortcut("s", modifiers: [.command, .shift])
                    .disabled(model.isBusy || model.output.isEmpty)
            }
        }
        #endif
    }
}
