/// Represents a generic item in a schedule view.  A [ScheduleItem]
/// could correspond to an event, task or appointment.  Only an id,
/// title and time are provided here for simplicity.
class ScheduleItem {
  final String? id;
  final String? title;
  final DateTime? dateTime;

  ScheduleItem({this.id, this.title, this.dateTime});
}