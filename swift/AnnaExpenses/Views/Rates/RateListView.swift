import SwiftUI

struct RateListView: View {
    @Environment(DataStore.self) private var store
    @State private var showingAddSheet = false
    @State private var showingBulkImport = false
    @State private var searchText = ""

    private var filteredRates: [Rate] {
        let sorted = store.rates.sorted {
            let t0 = store.teacher(for: $0.teacherID)?.name ?? ""
            let t1 = store.teacher(for: $1.teacherID)?.name ?? ""
            if t0 != t1 { return t0 < t1 }
            return $0.durationMinutes < $1.durationMinutes
        }
        if searchText.isEmpty { return sorted }
        return sorted.filter { rate in
            let teacherName = store.teacher(for: rate.teacherID)?.name ?? ""
            return teacherName.localizedCaseInsensitiveContains(searchText) ||
                   rate.subject.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groupedByTeacher: [(teacher: Teacher?, rates: [Rate])] {
        let grouped = Dictionary(grouping: filteredRates) { $0.teacherID }
        return grouped.map { (teacherID, rates) in
            (teacher: store.teacher(for: teacherID), rates: rates)
        }.sorted { ($0.teacher?.name ?? "") < ($1.teacher?.name ?? "") }
    }

    var body: some View {
        List {
            ForEach(groupedByTeacher, id: \.teacher?.id) { group in
                Section(group.teacher?.name ?? "Unknown Teacher") {
                    ForEach(group.rates) { rate in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(rate.subject)
                                    .font(.headline)
                                Text("\(rate.durationMinutes) minutes")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(String(format: "%.2f %@", rate.amount, rate.currency))
                                .font(.headline)
                                .monospacedDigit()
                            if let note = rate.notes, !note.isEmpty {
                                Image(systemName: "note.text")
                                    .foregroundStyle(.secondary)
                                    .help(note)
                            }
                        }
                        .contextMenu {
                            Button("Delete", role: .destructive) {
                                if let idx = store.rates.firstIndex(where: { $0.id == rate.id }) {
                                    store.rates.remove(at: idx)
                                    store.save()
                                }
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search by teacher or subject")
        .navigationTitle("Rates")
        .toolbar {
            Button(action: { showingBulkImport = true }) {
                Label("Bulk Import", systemImage: "square.and.arrow.down")
            }
            .help("Import Rates (Cmd+I)")
            Button(action: { showingAddSheet = true }) {
                Label("Add Rate", systemImage: "plus")
            }
            .help("New Item (Cmd+N)")
        }
        .sheet(isPresented: $showingAddSheet) {
            RateFormView()
        }
        .sheet(isPresented: $showingBulkImport) {
            RateBulkImportView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .triggerAddItem)) { _ in
            showingAddSheet = true
        }
    }
}
