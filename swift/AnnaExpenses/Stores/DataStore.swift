import Foundation
import Observation

@Observable
class DataStore {
    var students: [Student] = []
    var teachers: [Teacher] = []
    var packages: [Package] = []
    var sessions: [ClassSession] = []
    var transactions: [Transaction] = []
    var expenses: [Expense] = []
    var rates: [Rate] = []

    private let fileManager = FileManager.default

    private var storageDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        #if DEBUG
        let folderName = "AnnaExpenses-Dev"
        #else
        let folderName = "AnnaExpenses"
        #endif
        let dir = appSupport.appendingPathComponent(folderName, isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    init() {
        load()
    }

    func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted

        func write<T: Encodable>(_ data: T, to filename: String) {
            if let encoded = try? encoder.encode(data) {
                let url = storageDirectory.appendingPathComponent(filename)
                try? encoded.write(to: url)
            }
        }

        write(students, to: "students.json")
        write(teachers, to: "teachers.json")
        write(packages, to: "packages.json")
        write(sessions, to: "sessions.json")
        write(transactions, to: "transactions.json")
        write(expenses, to: "expenses.json")
        write(rates, to: "rates.json")
    }

    func load() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        func read<T: Decodable>(_ type: T.Type, from filename: String) -> T? {
            let url = storageDirectory.appendingPathComponent(filename)
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? decoder.decode(type, from: data)
        }

        students = read([Student].self, from: "students.json") ?? []
        teachers = read([Teacher].self, from: "teachers.json") ?? []
        packages = read([Package].self, from: "packages.json") ?? []
        sessions = read([ClassSession].self, from: "sessions.json") ?? []
        transactions = read([Transaction].self, from: "transactions.json") ?? []
        expenses = read([Expense].self, from: "expenses.json") ?? []
        rates = read([Rate].self, from: "rates.json") ?? []
    }

    // MARK: - Convenience lookups

    func student(for id: UUID) -> Student? {
        students.first { $0.id == id }
    }

    func teacher(for id: UUID) -> Teacher? {
        teachers.first { $0.id == id }
    }

    func package(for id: UUID) -> Package? {
        packages.first { $0.id == id }
    }

    func sessions(for packageID: UUID) -> [ClassSession] {
        sessions.filter { $0.packageID == packageID }
    }

    func packages(for studentID: UUID) -> [Package] {
        packages.filter { $0.studentID == studentID }
    }

    func classesUsed(for packageID: UUID) -> Int {
        sessions.filter { $0.packageID == packageID }.count
    }

    func rates(for teacherID: UUID) -> [Rate] {
        rates.filter { $0.teacherID == teacherID }
    }
}
