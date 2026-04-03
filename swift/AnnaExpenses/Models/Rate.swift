import Foundation

struct Rate: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var teacherID: UUID
    var amount: Double
    var currency: String = "RUB"
    var durationMinutes: Int = 60
    var subject: String = "English"
    var notes: String?
}
