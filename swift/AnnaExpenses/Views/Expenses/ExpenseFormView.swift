import SwiftUI

struct ExpenseFormView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date()
    @State private var amount = ""
    @State private var currency = "AED"
    @State private var category: ExpenseCategory = .other
    @State private var description = ""
    @State private var notes = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Add Expense")
                .font(.title2.bold())

            Form {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                HStack {
                    TextField("Amount", text: $amount)
                    Picker("Currency", selection: $currency) {
                        Text("AED").tag("AED")
                        Text("RUB").tag("RUB")
                        Text("USD").tag("USD")
                    }
                    .frame(width: 100)
                }
                Picker("Category", selection: $category) {
                    ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                        Text(cat.rawValue).tag(cat)
                    }
                }
                TextField("Description", text: $description)
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(2)
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") {
                    guard let amt = Double(amount) else { return }
                    let expense = Expense(
                        date: date,
                        amount: amt,
                        currency: currency,
                        category: category,
                        description: description,
                        notes: notes.isEmpty ? nil : notes
                    )
                    store.expenses.append(expense)
                    store.save()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(description.isEmpty || Double(amount) == nil)
            }
            .padding()
        }
        .frame(width: 450, height: 380)
    }
}
