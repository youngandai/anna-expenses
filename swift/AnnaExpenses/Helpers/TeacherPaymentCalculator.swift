import Foundation

struct TeacherPayment: Identifiable {
    var id: UUID { teacherID }
    let teacherID: UUID
    let amount: Double
    let currency: String
    let sessionCount: Int
    let totalMinutes: Int
    let breakdown: [SessionBreakdown]

    struct SessionBreakdown {
        let sessionID: UUID
        let date: Date
        let durationMinutes: Int
        let rateName: String
        let rateAmount: Double
        let payment: Double
    }
}

enum TeacherPaymentCalculator {
    /// Calculate teacher payments based on their rates and sessions taught.
    /// Groups results by currency since teachers may have rates in different currencies.
    static func calculate(
        sessions: [ClassSession],
        rates: [Rate],
        month: Date
    ) -> [TeacherPayment] {
        let calendar = Calendar.current
        let targetMonth = calendar.component(.month, from: month)
        let targetYear = calendar.component(.year, from: month)

        let monthlySessions = sessions.filter { session in
            let m = calendar.component(.month, from: session.date)
            let y = calendar.component(.year, from: session.date)
            return m == targetMonth && y == targetYear
        }

        let ratesByTeacher = Dictionary(grouping: rates) { $0.teacherID }
        let byTeacher = Dictionary(grouping: monthlySessions) { $0.teacherID }

        var payments: [TeacherPayment] = []

        for (teacherID, teacherSessions) in byTeacher {
            let teacherRates = ratesByTeacher[teacherID] ?? []

            // Group by currency — a teacher might have rates in multiple currencies
            var byCurrency: [String: (amount: Double, minutes: Int, breakdowns: [TeacherPayment.SessionBreakdown])] = [:]

            for session in teacherSessions {
                let sessionDuration = session.durationMinutes ?? 60

                // Find best matching rate: match by duration first, then fallback to any rate
                let matchedRate = bestRate(for: sessionDuration, from: teacherRates)

                if let rate = matchedRate {
                    // Rate-based: prorate if session duration differs from rate duration
                    let payment: Double
                    if rate.durationMinutes == sessionDuration {
                        payment = rate.amount
                    } else {
                        // Prorate: e.g., 30min session with 60min rate = 0.5 * rate
                        payment = rate.amount * (Double(sessionDuration) / Double(rate.durationMinutes))
                    }

                    let breakdown = TeacherPayment.SessionBreakdown(
                        sessionID: session.id,
                        date: session.date,
                        durationMinutes: sessionDuration,
                        rateName: "\(rate.subject) (\(rate.durationMinutes)min)",
                        rateAmount: rate.amount,
                        payment: payment
                    )

                    var entry = byCurrency[rate.currency] ?? (0, 0, [])
                    entry.amount += payment
                    entry.minutes += sessionDuration
                    entry.breakdowns.append(breakdown)
                    byCurrency[rate.currency] = entry
                } else {
                    // No rate found — record session with zero payment
                    let breakdown = TeacherPayment.SessionBreakdown(
                        sessionID: session.id,
                        date: session.date,
                        durationMinutes: sessionDuration,
                        rateName: "No rate set",
                        rateAmount: 0,
                        payment: 0
                    )
                    var entry = byCurrency["—"] ?? (0, 0, [])
                    entry.minutes += sessionDuration
                    entry.breakdowns.append(breakdown)
                    byCurrency["—"] = entry
                }
            }

            for (currency, info) in byCurrency {
                payments.append(TeacherPayment(
                    teacherID: teacherID,
                    amount: info.amount,
                    currency: currency,
                    sessionCount: info.breakdowns.count,
                    totalMinutes: info.minutes,
                    breakdown: info.breakdowns.sorted { $0.date < $1.date }
                ))
            }
        }

        return payments.sorted { $0.amount > $1.amount }
    }

    /// Find the best matching rate for a given session duration.
    /// Prefers exact duration match, then the closest duration.
    private static func bestRate(for durationMinutes: Int, from rates: [Rate]) -> Rate? {
        guard !rates.isEmpty else { return nil }
        // Exact match first
        if let exact = rates.first(where: { $0.durationMinutes == durationMinutes }) {
            return exact
        }
        // Closest duration
        return rates.min(by: {
            abs($0.durationMinutes - durationMinutes) < abs($1.durationMinutes - durationMinutes)
        })
    }
}
