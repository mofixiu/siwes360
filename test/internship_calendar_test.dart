import 'package:flutter_test/flutter_test.dart';
import 'package:siwes360/utils/internship_calendar.dart';

// The app and the backend (utils/weeks.js) must agree on week numbers, or a
// supervisor would sign off a different week from the one the student sees.
void main() {
  // Starts on a Wednesday, so week 1 is the Monday-to-Sunday week holding 9 Sep.
  final calendar = InternshipCalendar(DateTime(2026, 9, 9), DateTime(2027, 2, 19));

  test('week 1 is the Monday-to-Sunday week that holds the start date', () {
    expect(calendar.weekOf(DateTime(2026, 9, 7)), 1); // Monday before the start
    expect(calendar.weekOf(DateTime(2026, 9, 13)), 1); // Sunday
    expect(calendar.weekOf(DateTime(2026, 9, 14)), 2); // next Monday
    expect(calendar.weekStart(10), DateTime(2026, 11, 9));
    expect(calendar.weekEnd(10), DateTime(2026, 11, 15));
  });

  test('day count includes the first and last day', () {
    expect(calendar.dayNumber(DateTime(2026, 9, 9)), 1);
    expect(calendar.totalDays, 164);
    expect(calendar.dayNumber(DateTime(2030, 1, 1)), calendar.totalDays);
  });

  test('dates parse without a time zone shift', () {
    expect(parseDay('2026-11-02'), DateTime(2026, 11, 2));
    expect(parseDay('2026-11-02T00:00:00.000Z'), DateTime(2026, 11, 2));
    expect(parseDay(null), isNull);
    expect(apiDay(DateTime(2026, 1, 5)), '2026-01-05');
  });

  test('initials for stamps', () {
    expect(initialsOf('Ngozi Okafor'), 'N.O.');
    expect(initialsOf('Ngozi Ada Okafor'), 'N.O.');
    expect(initialsOf('Ngozi'), 'N.');
    expect(initialsOf(null), '');
  });
}
