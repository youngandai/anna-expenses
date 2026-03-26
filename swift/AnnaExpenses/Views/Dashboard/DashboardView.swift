import SwiftUI

struct DashboardView: View {
    @Environment(DataStore.self) private var store
    @State private var selectedMonth = Date()

    private var calendar: Calendar { Calendar.current }

    private var monthlyTransactions: [Transaction] {
        let month = calendar.component(.month, from: selectedMonth)
        let year = calendar.component(.year, from: selectedMonth)
        return store.transactions.filter {
            calendar.component(.month, from: $0.date) == month &&
            calendar.component(.year, from: $0.date) == year
        }
    }

    private var monthlyExpenses: [Expense] {
        let month = calendar.component(.month, from: selectedMonth)
        let year = calendar.component(.year, from: selectedMonth)
        return store.expenses.filter {
            calendar.component(.month, from: $0.date) == month &&
            calendar.component(.year, from: $0.date) == year
        }
    }

    private var totalIncome: Double {
        monthlyTransactions.reduce(0) { $0 + $1.amount }
    }

    private var totalExpenses: Double {
        monthlyExpenses.reduce(0) { $0 + $1.amount }
    }

    private var teacherPayments: [TeacherPayment] {
        TeacherPaymentCalculator.calculate(
            sessions: store.sessions,
            packages: store.packages,
            month: selectedMonth
        )
    }

    private var totalTeacherPayments: Double {
        teacherPayments.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Month selector
                HStack {
                    Button(action: { changeMonth(by: -1) }) {
                        Image(systemName: "chevron.left")
                    }
                    Text(selectedMonth, format: .dateTime.month(.wide).year())
                        .font(.title2.bold())
                        .frame(minWidth: 200)
                    Button(action: { changeMonth(by: 1) }) {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding(.bottom, 10)

                // Summary cards
                HStack(spacing: 16) {
                    SummaryCard(title: "Income", value: totalIncome, color: .green)
                    SummaryCard(title: "Expenses", value: totalExpenses, color: .red)
                    SummaryCard(title: "Teacher Payments", value: totalTeacherPayments, color: .orange)
                    SummaryCard(title: "Net", value: totalIncome - totalExpenses - totalTeacherPayments, color: .blue)
                }

                // Quick stats
                HStack(spacing: 16) {
                    StatCard(title: "Students", count: store.students.count, icon: "person.2")
                    StatCard(title: "Teachers", count: store.teachers.count, icon: "person.crop.rectangle")
                    StatCard(title: "Active Packages", count: store.packages.count, icon: "shippingbox")
                    StatCard(title: "Classes This Month", count: monthlySessions.count, icon: "calendar")
                }

                // Expense breakdown
                if !monthlyExpenses.isEmpty {
                    GroupBox("Expense Breakdown") {
                        ForEach(ExpenseCategory.allCases, id: \.self) { category in
                            let total = monthlyExpenses.filter { $0.category == category }.reduce(0) { $0 + $1.amount }
                            if total > 0 {
                                HStack {
                                    Text(category.rawValue)
                                    Spacer()
                                    Text(String(format: "%.2f", total))
                                        .monospacedDigit()
                                }
                            }
                        }
                    }
                }

                // Teacher payment summary
                if !teacherPayments.isEmpty {
                    GroupBox("Teacher Payment Summary") {
                        ForEach(teacherPayments) { payment in
                            HStack {
                                Text(store.teacher(for: payment.teacherID)?.name ?? "Unknown")
                                Spacer()
                                Text("\(payment.sessionCount) classes")
                                    .foregroundStyle(.secondary)
                                Text(String(format: "%.2f", payment.amount))
                                    .monospacedDigit()
                                    .bold()
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Dashboard")
    }

    private var monthlySessions: [ClassSession] {
        let month = calendar.component(.month, from: selectedMonth)
        let year = calendar.component(.year, from: selectedMonth)
        return store.sessions.filter {
            calendar.component(.month, from: $0.date) == month &&
            calendar.component(.year, from: $0.date) == year
        }
    }

    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: selectedMonth) {
            selectedMonth = newDate
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(String(format: "%.2f", value))
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

struct StatCard: View {
    let title: String
    let count: Int
    let icon: String

    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("\(count)")
                .font(.title3.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}
