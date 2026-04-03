import Foundation

enum CSVImportError: LocalizedError {
    case invalidFormat(String)
    case emptyFile

    var errorDescription: String? {
        switch self {
        case .invalidFormat(let detail): return "Invalid CSV format: \(detail)"
        case .emptyFile: return "The file is empty"
        }
    }
}

enum CSVImporter {
    // MARK: - Bank Transactions

    /// Parses a CSV with columns: date, amount, description
    static func parseTransactions(from csvString: String, dateFormat: String = "yyyy-MM-dd") throws -> [Transaction] {
        let lines = csvString.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard lines.count > 1 else { throw CSVImportError.emptyFile }

        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat

        var transactions: [Transaction] = []

        // Skip header row
        for line in lines.dropFirst() {
            let columns = parseLine(line)
            guard columns.count >= 3 else { continue }

            let dateStr = columns[0].trimmingCharacters(in: .whitespaces)
            let amountStr = columns[1].trimmingCharacters(in: .whitespaces)
            let desc = columns[2].trimmingCharacters(in: .whitespaces)

            guard let date = formatter.date(from: dateStr),
                  let amount = Double(amountStr) else { continue }

            transactions.append(Transaction(
                date: date,
                amount: amount,
                description: desc,
                source: .csvImport
            ))
        }

        return transactions
    }

    // MARK: - Attendance

    /// Parses a CSV with columns: date, student_name, teacher_name
    /// Returns tuples since we need to match names to IDs
    static func parseAttendance(from csvString: String, dateFormat: String = "yyyy-MM-dd") throws -> [(date: Date, studentName: String, teacherName: String)] {
        let lines = csvString.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard lines.count > 1 else { throw CSVImportError.emptyFile }

        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat

        var records: [(date: Date, studentName: String, teacherName: String)] = []

        for line in lines.dropFirst() {
            let columns = parseLine(line)
            guard columns.count >= 3 else { continue }

            let dateStr = columns[0].trimmingCharacters(in: .whitespaces)
            let studentName = columns[1].trimmingCharacters(in: .whitespaces)
            let teacherName = columns[2].trimmingCharacters(in: .whitespaces)

            guard let date = formatter.date(from: dateStr) else { continue }
            records.append((date: date, studentName: studentName, teacherName: teacherName))
        }

        return records
    }

    // MARK: - CSV Parsing Helper

    static func parseLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false

        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                result.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        result.append(current)
        return result
    }
}
