import Foundation

/// Represents a task that needs to be completed by a family member.
///
/// A task includes a title, optional description, optional due date and
/// an optional reference to the member responsible for the task. Tasks
/// conform to `Identifiable` for use in SwiftUI lists and `Codable` for
/// persistence.
struct Task: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var description: String?
    var dueDate: Date?
    var assignedMemberID: UUID?
}
