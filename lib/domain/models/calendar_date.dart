import 'package:equatable/equatable.dart';

/// A day on the calendar, without time or time zone. "Today" is the
/// device's local date (PRD §32).
class CalendarDate extends Equatable implements Comparable<CalendarDate> {
  const CalendarDate(this.year, this.month, this.day);

  factory CalendarDate.fromDateTime(DateTime time) =>
      CalendarDate(time.year, time.month, time.day);

  final int year;
  final int month;
  final int day;

  static final _keyPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  /// Parses a [key] such as `2026-11-09`; null if malformed.
  static CalendarDate? tryParse(String key) {
    final m = _keyPattern.firstMatch(key);
    if (m == null) return null;
    // The pattern guarantees three digit groups.
    final date = CalendarDate(
      int.parse(m[1] ?? ''),
      int.parse(m[2] ?? ''),
      int.parse(m[3] ?? ''),
    );
    // Rejects 2026-02-30 and similar.
    final check = date.toDateTime();
    return check.month == date.month && check.day == date.day ? date : null;
  }

  /// `yyyy-MM-dd`. Also the storage document id (`days/{key}`).
  String get key =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  /// Local midnight at the start of this date.
  DateTime toDateTime() => DateTime(year, month, day);

  @override
  int compareTo(CalendarDate other) => key.compareTo(other.key);

  @override
  List<Object?> get props => [year, month, day];

  @override
  String toString() => key;
}
