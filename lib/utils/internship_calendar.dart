import 'package:intl/intl.dart';

/// The internship calendar, with the same rules as the backend (utils/weeks.js):
/// weeks run Monday to Sunday, week 1 is the week that holds the start date, and
/// working days are Monday to Friday. Dates are calendar days with no time zone.
class InternshipCalendar {
  InternshipCalendar(this.start, this.end);

  final DateTime start;
  final DateTime end;

  /// Builds one from the student record's date strings, or null if not set.
  static InternshipCalendar? from(dynamic start, dynamic end) {
    final s = parseDay(start);
    final e = parseDay(end);
    if (s == null || e == null) return null;
    return InternshipCalendar(s, e);
  }

  static DateTime mondayOf(DateTime day) => dayOnly(day).subtract(Duration(days: day.weekday - 1));

  int weekOf(DateTime day) => (mondayOf(day).difference(mondayOf(start)).inDays / 7).floor() + 1;

  int get totalWeeks => weekOf(end);

  DateTime weekStart(int week) => mondayOf(start).add(Duration(days: 7 * (week - 1)));

  DateTime weekEnd(int week) => weekStart(week).add(const Duration(days: 6));

  /// The calendar day count shown as "Day 18 of 180".
  int get totalDays => end.difference(start).inDays + 1;

  int dayNumber(DateTime today) => (dayOnly(today).difference(start).inDays + 1).clamp(0, totalDays);

  bool contains(DateTime day) => !dayOnly(day).isBefore(start) && !dayOnly(day).isAfter(end);
}

/// 'YYYY-MM-DD' (or a longer ISO string) to a plain calendar day.
DateTime? parseDay(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  if (text.length < 10) return null;
  final parts = text.substring(0, 10).split('-').map(int.tryParse).toList();
  if (parts.length != 3 || parts.contains(null)) return null;
  return DateTime(parts[0]!, parts[1]!, parts[2]!);
}

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime today() => dayOnly(DateTime.now());

bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

bool isWorkingDay(DateTime d) => d.weekday <= DateTime.friday;

/// 'YYYY-MM-DD' for the API.
String apiDay(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

/// Date formats used across the app (shown in IBM Plex Mono).
class Dates {
  Dates._();

  /// Tue 17 Dec
  static String short(DateTime d) => DateFormat('EEE d MMM').format(d);

  /// 17 Dec
  static String dayMonth(DateTime d) => DateFormat('d MMM').format(d);

  /// 17 Dec 2026
  static String full(DateTime d) => DateFormat('d MMM yyyy').format(d);

  /// 13 Oct – 19 Oct
  static String range(DateTime a, DateTime b) => '${dayMonth(a)} – ${dayMonth(b)}';

  /// "today", "yesterday", or a short date.
  static String relative(DateTime d) {
    final diff = today().difference(dayOnly(d)).inDays;
    if (diff == 0) return 'today';
    if (diff == 1) return 'yesterday';
    return short(d);
  }
}

/// "Ngozi Okafor" -> "N.O."
String initialsOf(String? name) {
  final parts = (name ?? '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '';
  final picked = parts.length == 1 ? [parts.first] : [parts.first, parts.last];
  return picked.map((p) => '${p[0].toUpperCase()}.').join();
}

String firstNameOf(String? name) => (name ?? '').trim().split(RegExp(r'\s+')).first;

String plural(int n, String one, [String? many]) => '$n ${n == 1 ? one : (many ?? '${one}s')}';
