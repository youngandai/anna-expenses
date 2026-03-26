import Foundation

enum TransactionSource: String, Codable {
    case manual
    case csvImport
}

struct Transaction: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var date: Date
    var amount: Double
    var currency: String = "AED"
    var description: String
    var studentID: UUID?
    var packageID: UUID?
    var source: TransactionSource = .manual
}
