import Foundation

struct Teacher: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var email: String?
    var paymentDetails: String?
}
