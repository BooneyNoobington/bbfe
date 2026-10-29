import BBFECore
import SwiftUI

struct CipherTableView: View {
    @EnvironmentObject private var model: AppModel
    @State private var search = ""
    @State private var page = 0
    private let pageSize = 260

    private func positions(in table: CipherTable) -> [Int] {
        guard !search.isEmpty else { return Array(table.cells.indices) }
        return table.cells.indices.filter { index in
            let entry = AlphabetEntry(scalar: table.cells[index], weight: 1)
            return entry.displayName.localizedCaseInsensitiveContains(search)
                || entry.symbol.contains(search)
                || scalarCode(entry.scalar).localizedCaseInsensitiveContains(search)
                || coordinate(index).localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                PageHeading(eyebrow: "03 / The cipher table", title: "A place for every possibility.",
                            subtitle: "More frequent scalars get more coordinates. Each enciphering picks randomly from their available places.")
                if let table = model.table {
                    tableContent(table)
                } else {
                    ContentUnavailableView("No cipher table", systemImage: "square.grid.3x3", description: Text("Build an alphabet in Alphabet Lab, then generate a table."))
                }
                FlowActions {
                    Button("Import table…", systemImage: "square.and.arrow.down") { model.beginImport(.table) }
                    Button("Export JSON…", systemImage: "square.and.arrow.up") { model.exportTable() }
                        .disabled(model.table == nil)
                    Menu("Legacy format") {
                        Button("Export original CLI TSV…") { model.exportTable(legacy: true) }
                    }
                    .disabled(model.table == nil)
                }
                .buttonStyle(.bordered)
                .disabled(model.isBusy)
                Text("Use JSON to preserve BBFE2 table identifiers, Unicode, and control characters. Legacy TSV is for raw coordinates and cannot preserve tabs or line breaks in table cells.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .frame(maxWidth: 1200)
            .frame(maxWidth: .infinity)
        }
        .onChange(of: search) { _, _ in page = 0 }
        .onChange(of: model.table?.id) { _, _ in page = 0 }
    }

    @ViewBuilder
    private func tableContent(_ table: CipherTable) -> some View {
        Card {
            HStack {
                Metric(value: table.cells.count.formatted(), label: "coordinate slots")
                Metric(value: Set(table.cells).count.formatted(), label: "distinct scalars")
                Metric(value: table.rowCount.formatted(), label: "rows · 26 columns")
            }
            Divider()
            Text(model.currentKeyName).font(.headline)
            Text(table.id.uuidString)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
            Text("Generated \(table.createdAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        Card {
            HStack {
                Text("Coordinate explorer").font(.headline)
                Spacer()
                Image(systemName: "square.grid.3x3").foregroundStyle(Theme.teal)
            }
            TextField("Find a symbol, U+ code, or coordinate", text: $search)
                .textFieldStyle(.roundedBorder)
            let matches = positions(in: table)
            let pageCount = max(1, (matches.count + pageSize - 1) / pageSize)
            let safePage = min(page, pageCount - 1)
            let start = safePage * pageSize
            let end = min(start + pageSize, matches.count)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 85, maximum: 120), spacing: 8)], spacing: 8) {
                ForEach(Array(matches[start..<end]), id: \.self) { index in
                    let entry = AlphabetEntry(scalar: table.cells[index], weight: 1)
                    VStack(alignment: .leading, spacing: 7) {
                        Text(coordinate(index))
                            .font(.caption2.monospaced().weight(.bold))
                            .foregroundStyle(Theme.teal)
                        Text(entry.displayName)
                            .font(.system(.body, design: .monospaced, weight: .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                    }
                    .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
                    .padding(10)
                    .background(Theme.background, in: RoundedRectangle(cornerRadius: 9))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(coordinate(index)): \(entry.displayName), \(scalarCode(entry.scalar))")
                    .help("\(entry.displayName) · \(scalarCode(entry.scalar))")
                }
            }
            if matches.isEmpty {
                ContentUnavailableView("No matching coordinates", systemImage: "magnifyingglass")
            }
            HStack {
                Text("\(matches.count.formatted()) coordinates · page \(safePage + 1) of \(pageCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button { page = max(0, safePage - 1) } label: { Image(systemName: "chevron.left") }
                    .disabled(safePage == 0)
                    .accessibilityLabel("Previous coordinates")
                Button { page = min(pageCount - 1, safePage + 1) } label: { Image(systemName: "chevron.right") }
                    .disabled(safePage + 1 >= pageCount)
                    .accessibilityLabel("Next coordinates")
            }
            .buttonStyle(.bordered)
        }
    }

    private func coordinate(_ index: Int) -> String {
        "\(UnicodeScalar(65 + index % CipherTable.columns)!)\(index / CipherTable.columns + 1)"
    }
}
