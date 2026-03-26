import Foundation

enum ExpenseCategory: String, Codable, CaseIterable {
    case marketing = "Marketing"
    case rent = "Rent"
    case admin = "Admin"
    case teacherPayment = "Teacher Payment"
    case other = "Other"
}

struct Expense: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var date: Date
    var amount: Double
    var currency: String = "AED"
    var category: ExpenseCategory
    var description: String
    var notes: String?
}
