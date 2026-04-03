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
        VStack(spacing: 16) {
            Text("Add Rate")
                .font(.title2.bold())

            Form {
                Picker("Teacher", selection: $teacherID) {
                    Text("Select Teacher").tag(UUID?.none)
                    ForEach(store.teachers.sorted { $0.name < $1.name }) { teacher in
                        Text(teacher.name).tag(UUID?.some(teacher.id))
                    }
                }

                TextField("Amount", text: $amount)

                Picker("Currency", selection: $currency) {
                    ForEach(currencies, id: \.self) { c in
                        Text(c).tag(c)
                    }
                }

                Picker("Duration (minutes)", selection: $durationMinutes) {
                    ForEach(durations, id: \.self) { d in
                        Text("\(d) min").tag(d)
                    }
                }

                TextField("Subject", text: $subject)
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(2)
            }
            .formStyle(.grouped)

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
            .padding()
        }
        .frame(width: 450, height: 420)
    }
}
