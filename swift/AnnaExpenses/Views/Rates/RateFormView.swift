import SwiftUI

struct RateFormView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var teacherID: UUID?
    @State private var amount = ""
    @State private var currency = "RUB"
    @State private var durationMinutes = 60
    @State private var subject = "English"
    @State private var notes = ""

    private let currencies = ["RUB", "AED", "USD"]
    private let durations = [30, 45, 60, 90, 120]

    var body: some View {
        RecordSheetContainer(title: "Add Rate", width: 520) {
            RecordSheetCard {
                formRow("Teacher") {
                    Picker("", selection: $teacherID) {
                        Text("Select Teacher").tag(UUID?.none)
                        ForEach(store.teachers.sorted { $0.name < $1.name }) { teacher in
                            Text(teacher.name).tag(UUID?.some(teacher.id))
                        }
                    }
                    .labelsHidden()
                    .frame(width: 200, alignment: .trailing)
                }

                Divider()

                formRow("Amount") {
                    HStack(spacing: 10) {
                        TextField("Amount", text: $amount)
                            .textFieldStyle(.roundedBorder)

                        Picker("Currency", selection: $currency) {
                            ForEach(currencies, id: \.self) { c in
                                Text(c).tag(c)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 92)
                    }
                }

                Divider()

                formRow("Duration") {
                    Picker("", selection: $durationMinutes) {
                        ForEach(durations, id: \.self) { d in
                            Text("\(d) min").tag(d)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 120, alignment: .trailing)
                }

                Divider()

                formRow("Subject") {
                    TextField("Subject", text: $subject)
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
                    guard let tid = teacherID, let amt = Double(amount) else { return }
                    let rate = Rate(
                        teacherID: tid,
                        amount: amt,
                        currency: currency,
                        durationMinutes: durationMinutes,
                        subject: subject,
                        notes: notes.isEmpty ? nil : notes
                    )
                    store.rates.append(rate)
                    store.save()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(teacherID == nil || Double(amount) == nil)
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
