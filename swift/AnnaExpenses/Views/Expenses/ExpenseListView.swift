import SwiftUI

struct ExpenseListView: View {
    @Environment(DataStore.self) private var store
    @State private var showingAddSheet = false
    @State private var searchText = ""

    private var filteredExpenses: [Expense] {
        let sorted = store.expenses.sorted { $0.date > $1.date }
        if searchText.isEmpty { return sorted }
        return sorted.filter {
            $0.description.localizedCaseInsensitiveContains(searchText) ||
            $0.category.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var total: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        VStack {
            List {
                ForEach(filteredExpenses) { expense in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(expense.description)
                                .font(.headline)
                            Text(expense.category.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(categoryColor(expense.category).opacity(0.1))
                                .clipShape(Capsule())
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(String(format: "%.2f %@", expense.amount, expense.currency))
                                .font(.headline)
                                .foregroundStyle(.red)
                            Text(expense.date, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            if let idx = store.expenses.firstIndex(where: { $0.id == expense.id }) {
                                store.expenses.remove(at: idx)
                                store.save()
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search expenses")

            HStack {
                Spacer()
                Text("Total: \(String(format: "%.2f", total))")
                    .font(.headline)
                    .padding()
            }
        }
        .navigationTitle("Expenses")
        .toolbar {
            Button(action: { showingAddSheet = true }) {
                Label("Add Expense", systemImage: "plus")
            }
            .help("New Item (Cmd+N)")
        }
        .sheet(isPresented: $showingAddSheet) {
            ExpenseFormView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .triggerAddItem)) { _ in
            showingAddSheet = true
        }
    }

    private func categoryColor(_ category: ExpenseCategory) -> Color {
        switch category {
        case .marketing: return .purple
        case .rent: return .orange
        case .admin: return .blue
        case .teacherPayment: return .green
        case .other: return .gray
        }
    }
}
