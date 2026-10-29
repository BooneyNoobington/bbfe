import BBFECore
import SwiftUI

struct AlphabetLabView: View {
    @EnvironmentObject private var model: AppModel
    @State private var search = ""
    @State private var showReplaceConfirmation = false

    private var sortedEntries: [AlphabetEntry] {
        model.alphabet.entries
            .filter { search.isEmpty || $0.displayName.localizedCaseInsensitiveContains(search) || $0.symbol.contains(search) || scalarCode($0.scalar).localizedCaseInsensitiveContains(search) }
            .sorted { $0.weight == $1.weight ? $0.scalar < $1.scalar : $0.weight > $1.weight }
    }

    private var totalWeight: Double { model.alphabet.entries.reduce(0) { $0 + $1.weight } }
    private var maxWeight: Double { model.alphabet.entries.map(\.weight).max() ?? 1 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                PageHeading(eyebrow: "02 / The alphabet lab", title: "Start with the way you write.",
                            subtitle: "Paste a representative sample. Every scalar becomes part of the alphabet, and its frequency shapes the table.")
                Card {
                    HStack {
                        Label("Example text", systemImage: "text.quote").font(.headline)
                        Spacer()
                        Button("Paste", systemImage: "doc.on.clipboard", action: model.pasteTrainingText)
                            .buttonStyle(.bordered)
                    }
                    EditorBox(text: $model.trainingText, label: "Paste text in any language, including tabs and line breaks…", minimumHeight: 200)
                    FlowActions {
                        Button("Build histogram", systemImage: "chart.bar", action: model.buildHistogram)
                            .buttonStyle(.borderedProminent)
                        Button("Basic Latin", action: model.useBasicLatin)
                            .buttonStyle(.bordered)
                        Spacer(minLength: 0)
                        Button("Import alphabet…", systemImage: "square.and.arrow.down") { model.beginImport(.alphabet) }
                            .buttonStyle(.bordered)
                    }
                }
                .disabled(model.isBusy)

                Card {
                    HStack {
                        Metric(value: model.alphabet.entries.count.formatted(), label: "distinct scalars")
                        Metric(value: totalWeight.formatted(.number.precision(.fractionLength(0...2))), label: "total weight")
                    }
                    Divider()
                    FlowActions {
                        Text("The current table stays in place until you generate a new one.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                        Button("Generate cipher table", systemImage: "shuffle") { showReplaceConfirmation = true }
                            .buttonStyle(.borderedProminent)
                        Button("Export alphabet…", systemImage: "square.and.arrow.up", action: model.exportAlphabet)
                            .buttonStyle(.bordered)
                    }
                    .disabled(model.isBusy || model.alphabet.entries.isEmpty)
                }

                Card {
                    HStack {
                        Text("Frequency histogram").font(.headline)
                        Spacer()
                        Text("BY UNICODE SCALAR")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1)
                            .foregroundStyle(.secondary)
                    }
                    TextField("Find a symbol, control character, or U+ code", text: $search)
                        .textFieldStyle(.roundedBorder)
                    LazyVStack(spacing: 13) {
                        ForEach(sortedEntries) { entry in
                            HistogramRow(entry: entry, total: totalWeight, maximum: maxWeight)
                        }
                    }
                    if sortedEntries.isEmpty {
                        ContentUnavailableView("No matching scalars", systemImage: "character.magnify")
                    }
                }
                Text("Include every symbol you want to encipher in your sample. BBFE counts Unicode scalars separately: an emoji sequence may contain several, and composed and decomposed letters stay distinct. JSON preserves the entire alphabet; legacy TSV can represent fewer control characters.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .frame(maxWidth: 1100)
            .frame(maxWidth: .infinity)
        }
        .confirmationDialog("Generate a new cipher table?", isPresented: $showReplaceConfirmation, titleVisibility: .visible) {
            Button("Generate new table", action: model.generateTable)
        } message: {
            Text("Save or export your current table first if you need to decipher its messages later. The new table will have different coordinates.")
        }
    }
}

private struct HistogramRow: View {
    let entry: AlphabetEntry
    let total: Double
    let maximum: Double

    var body: some View {
        HStack(spacing: 14) {
            Text(entry.displayName)
                .font(.system(.callout, design: .monospaced, weight: .medium))
                .lineLimit(1)
                .frame(width: 80, alignment: .leading)
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(scalarCode(entry.scalar)).font(.caption2.monospaced())
                    Spacer()
                    Text(entry.weight.formatted(.number.precision(.fractionLength(0...2))))
                        .font(.caption.monospacedDigit())
                    Text(total > 0 ? (entry.weight / total).formatted(.percent.precision(.fractionLength(1))) : "0%")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 55, alignment: .trailing)
                }
                GeometryReader { geometry in
                    Capsule().fill(Theme.teal.opacity(0.10))
                    Capsule().fill(Theme.teal.opacity(0.8))
                        .frame(width: max(3, geometry.size.width * min(1, entry.weight / max(1, maximum))))
                }
                .frame(height: 6)
                .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.displayName), \(scalarCode(entry.scalar)), weight \(entry.weight), \(total > 0 ? entry.weight / total * 100 : 0) percent")
    }
}

func scalarCode(_ scalar: UInt32) -> String {
    String(format: "U+%04X", scalar)
}
