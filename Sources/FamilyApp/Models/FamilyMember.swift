import Foundation

/// Represents a member of the family.
///
/// Each family member has a unique identifier, a name, a relationship
/// descriptor (for example, "Mother" or "Cousin"), and an optional
/// birthday. Conforming to `Identifiable` allows this type to be used
/// directly in SwiftUI lists, and `Codable` conformance enables easy
/// persistence to disk.
struct FamilyMember: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var relationship: String
    var birthday: Date?
}
