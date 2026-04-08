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
        RecordSheetContainer(title: "Add Expense", width: 520) {
            RecordSheetCard {
                formRow("Date") {
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .frame(width: 140, alignment: .trailing)
                }

                Divider()

                formRow("Amount") {
                    HStack(spacing: 10) {
                        TextField("Amount", text: $amount)
                            .textFieldStyle(.roundedBorder)

                        Picker("Currency", selection: $currency) {
                            Text("AED").tag("AED")
                            Text("RUB").tag("RUB")
                            Text("USD").tag("USD")
                        }
                        .labelsHidden()
                        .frame(width: 92)
                    }
                }

                Divider()

                formRow("Category") {
                    Picker("", selection: $category) {
                        ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 170, alignment: .trailing)
                }

                Divider()

                formRow("Description") {
                    TextField("Description", text: $description)
                        .textFieldStyle(.roundedBorder)
                }

                Divider()

                formRow("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2...4)
                }
            }
        } actions: {
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
        }
    }

    @ViewBuilder
    private func formRow<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Text(label)
                .frame(width: 150, alignment: .leading)

            content()
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
