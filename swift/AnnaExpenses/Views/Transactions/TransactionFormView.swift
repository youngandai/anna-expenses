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
        RecordSheetContainer(title: "Add Transaction", width: 520) {
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

                formRow("Description") {
                    TextField("Description", text: $description)
                        .textFieldStyle(.roundedBorder)
                }

                Divider()

                formRow("Student (optional)") {
                    Picker("", selection: $studentID) {
                        Text("None").tag(UUID?.none)
                        ForEach(store.students.sorted { $0.name < $1.name }) { student in
                            Text(student.name).tag(UUID?.some(student.id))
                        }
                    }
                    .labelsHidden()
                    .frame(width: 170, alignment: .trailing)
                }
                .onChange(of: studentID) { _, _ in packageID = nil }

                Divider()

                formRow("Package (optional)") {
                    Picker("", selection: $packageID) {
                        Text("None").tag(UUID?.none)
                        ForEach(availablePackages) { pkg in
                            Text(pkg.name).tag(UUID?.some(pkg.id))
                        }
                    }
                    .labelsHidden()
                    .frame(width: 170, alignment: .trailing)
                }
            }
        } actions: {
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

struct RecordSheetContainer<Content: View, Actions: View>: View {
    let title: String
    let width: CGFloat
    @ViewBuilder let content: () -> Content
    @ViewBuilder let actions: () -> Actions

    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.title2.bold())
                .padding(.top, 4)

            content()

            actions()
        }
        .padding(24)
        .frame(width: width)
    }
}

struct RecordSheetCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            content()
        }
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        }
    }
}
