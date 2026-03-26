import Foundation

struct Package: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var studentID: UUID
    var name: String
    var totalClasses: Int
    var pricePaid: Double
    var currency: String = "AED"
    var purchaseDate: Date
    var notes: String?
}
