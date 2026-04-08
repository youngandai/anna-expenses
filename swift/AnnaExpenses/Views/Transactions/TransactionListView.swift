import SwiftUI

struct TransactionListView: View {
    @Environment(DataStore.self) private var store
    @State private var showingAddSheet = false
    @State private var searchText = ""

    private var filteredTransactions: [Transaction] {
        let sorted = store.transactions.sorted { $0.date > $1.date }
        if searchText.isEmpty { return sorted }
        return sorted.filter { $0.description.localizedCaseInsensitiveContains(searchText) }
    }

    private var total: Double {
        filteredTransactions.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        VStack {
            List {
                ForEach(filteredTransactions) { txn in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(txn.description)
                                .font(.headline)
                            HStack(spacing: 8) {
                                if let sid = txn.studentID, let student = store.student(for: sid) {
                                    Text(student.name)
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(.blue.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                                if txn.source == .csvImport {
                                    Text("CSV Import")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(String(format: "%.2f %@", txn.amount, txn.currency))
                                .font(.headline)
                                .foregroundStyle(.green)
                            Text(txn.date, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            if let idx = store.transactions.firstIndex(where: { $0.id == txn.id }) {
                                store.transactions.remove(at: idx)
                                store.save()
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search transactions")

            HStack {
                Spacer()
                Text("Total: \(String(format: "%.2f", total))")
                    .font(.headline)
                    .padding()
            }
        }
        .navigationTitle("Transactions")
        .toolbar {
            Button(action: { showingAddSheet = true }) {
                Label("Add Transaction", systemImage: "plus")
            }
            .help("New Item (Cmd+N)")
        }
        .sheet(isPresented: $showingAddSheet) {
            TransactionFormView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .triggerAddItem)) { _ in
            showingAddSheet = true
        }
    }
}
