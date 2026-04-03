import SwiftUI

struct TeacherDetailView: View {
    @Environment(DataStore.self) private var store
    let teacher: Teacher

    private var teacherRates: [Rate] {
        store.rates(for: teacher.id)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(teacher.name)
                    .font(.title.bold())
                if let email = teacher.email {
                    Label(email, systemImage: "envelope")
                }
                if let details = teacher.paymentDetails {
                    Label(details, systemImage: "creditcard")
                }

                if !teacherRates.isEmpty {
                    GroupBox("Rates") {
                        ForEach(teacherRates) { rate in
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
                                    .monospacedDigit()
                            }
                        }
                    }
                } else {
                    Text("No rates configured")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            .padding()
        }
    }
}
