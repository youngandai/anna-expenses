import Foundation

struct ClassSession: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var packageID: UUID
    var studentID: UUID
    var teacherID: UUID
    var date: Date
    var durationMinutes: Int?
    var notes: String?
}
