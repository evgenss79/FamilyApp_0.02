/// Represents a person who is a friend of the user.  This model is
/// intentionally simple and may be expanded as needed.  It is not
/// persisted via Hive in this example.
class Friend {
  /// Unique identifier for the friend.
  final String? id;

  /// Display name of the friend.
  final String? name;

  Friend({this.id, this.name});
}