import SwiftUI

struct TransactionFormView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date()
    @State private var amount = ""
    @State private var currency = "AED"
    @State private var description = ""
    @State private var studentID: UUID?
    @State private var packageID: UUID?

    private var availablePackages: [Package] {
        guard let sid = studentID else { return [] }
        return store.packages(for: sid)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Add Transaction")
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
                TextField("Description", text: $description)

                Picker("Student (optional)", selection: $studentID) {
                    Text("None").tag(UUID?.none)
                    ForEach(store.students.sorted { $0.name < $1.name }) { student in
                        Text(student.name).tag(UUID?.some(student.id))
                    }
                }
                .onChange(of: studentID) { _, _ in packageID = nil }

                Picker("Package (optional)", selection: $packageID) {
                    Text("None").tag(UUID?.none)
                    ForEach(availablePackages) { pkg in
                        Text(pkg.name).tag(UUID?.some(pkg.id))
                    }
                }
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") {
                    guard let amt = Double(amount) else { return }
                    let txn = Transaction(
                        date: date,
                        amount: amt,
                        currency: currency,
                        description: description,
                        studentID: studentID,
                        packageID: packageID,
                        source: .manual
                    )
                    store.transactions.append(txn)
                    store.save()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(description.isEmpty || Double(amount) == nil)
            }
            .padding()
        }
        .frame(width: 450, height: 400)
    }
}
