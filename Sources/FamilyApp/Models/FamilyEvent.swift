import Foundation

/// Represents a scheduled event involving the family.
///
/// An event has a unique identifier, a title, a date when it occurs and
/// a description providing additional details. Like other models it is
/// both identifiable and codable for UI presentation and persistence.
struct FamilyEvent: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var date: Date
    var description: String?
}
