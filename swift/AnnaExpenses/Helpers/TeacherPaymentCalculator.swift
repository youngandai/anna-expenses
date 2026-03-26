import Foundation

struct TeacherPayment: Identifiable {
    var id: UUID { teacherID }
    let teacherID: UUID
    let amount: Double
    let sessionCount: Int
    let breakdown: [PackageBreakdown]

    struct PackageBreakdown {
        let packageID: UUID
        let sessionsForTeacher: Int
        let totalSessions: Int
        let packagePrice: Double
        let teacherShare: Double
    }
}

enum TeacherPaymentCalculator {
    static func calculate(
        sessions: [ClassSession],
        packages: [Package],
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

        let packageMap = Dictionary(uniqueKeysWithValues: packages.map { ($0.id, $0) })

        // Group sessions by package, then by teacher
        let byPackage = Dictionary(grouping: monthlySessions) { $0.packageID }

        var teacherTotals: [UUID: (amount: Double, count: Int, breakdowns: [TeacherPayment.PackageBreakdown])] = [:]

        for (packageID, packageSessions) in byPackage {
            guard let pkg = packageMap[packageID] else { continue }

            let totalForPackage = packageSessions.count
            let byTeacher = Dictionary(grouping: packageSessions) { $0.teacherID }

            for (teacherID, teacherSessions) in byTeacher {
                let ratio = Double(teacherSessions.count) / Double(totalForPackage)
                let share = pkg.pricePaid * ratio

                let breakdown = TeacherPayment.PackageBreakdown(
                    packageID: packageID,
                    sessionsForTeacher: teacherSessions.count,
                    totalSessions: totalForPackage,
                    packagePrice: pkg.pricePaid,
                    teacherShare: share
                )

                var existing = teacherTotals[teacherID] ?? (0, 0, [])
                existing.amount += share
                existing.count += teacherSessions.count
                existing.breakdowns.append(breakdown)
                teacherTotals[teacherID] = existing
            }
        }

        return teacherTotals.map { (teacherID, info) in
            TeacherPayment(
                teacherID: teacherID,
                amount: info.amount,
                sessionCount: info.count,
                breakdown: info.breakdowns
            )
        }.sorted { $0.amount > $1.amount }
    }
}
