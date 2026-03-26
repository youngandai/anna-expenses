import Foundation

struct Student: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var email: String?
    var phone: String?
    var notes: String?
}
