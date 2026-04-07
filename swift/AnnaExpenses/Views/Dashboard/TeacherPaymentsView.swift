import SwiftUI

struct TeacherPaymentsView: View {
    @Environment(DataStore.self) private var store
    @State private var selectedMonth = Date()

    private var calendar: Calendar { Calendar.current }

    private var payments: [TeacherPayment] {
        TeacherPaymentCalculator.calculate(
            sessions: store.sessions,
            rates: store.rates,
            month: selectedMonth
        )
    }

    private var totalPayments: Double {
        payments.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Month selector
            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                }
                Text(selectedMonth, format: .dateTime.month(.wide).year())
                    .font(.title3.bold())
                    .frame(minWidth: 200)
                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                }
                Spacer()
                Text("Total: \(String(format: "%.2f", totalPayments))")
                    .font(.headline)
            }
            .padding()

            if payments.isEmpty {
                Spacer()
                Text("No class sessions recorded for this month")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                List {
                    ForEach(payments) { payment in
                        DisclosureGroup {
                            ForEach(payment.breakdown.indices, id: \.self) { idx in
                                let bd = payment.breakdown[idx]
                                HStack {
                                    Text(bd.date, style: .date)
                                        .frame(width: 100, alignment: .leading)
                                    Text("\(bd.durationMinutes)min")
                                        .frame(width: 50)
                                    Text(bd.rateName)
                                    Spacer()
                                    if bd.rateAmount > 0 {
                                        Text(String(format: "%.2f", bd.payment))
                                            .monospacedDigit()
                                    } else {
                                        Text("—")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .font(.caption)
                            }
                        } label: {
                            HStack {
                                Text(store.teacher(for: payment.teacherID)?.name ?? "Unknown")
                                    .font(.headline)
                                Spacer()
                                Text("\(payment.sessionCount) classes")
                                    .foregroundStyle(.secondary)
                                let hours = Double(payment.totalMinutes) / 60.0
                                Text(String(format: "%.1fh", hours))
                                    .foregroundStyle(.secondary)
                                Text(String(format: "%.2f %@", payment.amount, payment.currency))
                                    .font(.headline)
                                    .monospacedDigit()
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Teacher Payments")
        .onReceive(NotificationCenter.default.publisher(for: .navigatePreviousMonth)) { _ in
            changeMonth(by: -1)
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateNextMonth)) { _ in
            changeMonth(by: 1)
        }
    }

    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: selectedMonth) {
            selectedMonth = newDate
        }
    }
}
