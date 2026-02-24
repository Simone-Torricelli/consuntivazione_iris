import 'package:flutter/material.dart';

class WorkCalendarUtils {
  const WorkCalendarUtils._();

  static bool isItalianPublicHoliday(DateTime date) {
    final day = DateUtils.dateOnly(date);
    final easterSunday = _calculateEasterSunday(day.year);
    final easterMonday = easterSunday.add(const Duration(days: 1));

    final holidays = <DateTime>[
      DateTime(day.year, 1, 1), // Capodanno
      DateTime(day.year, 1, 6), // Epifania
      DateTime(day.year, 4, 25), // Liberazione
      DateTime(day.year, 5, 1), // Festa del Lavoro
      DateTime(day.year, 6, 2), // Festa della Repubblica
      DateTime(day.year, 8, 15), // Ferragosto
      DateTime(day.year, 11, 1), // Ognissanti
      DateTime(day.year, 12, 8), // Immacolata
      DateTime(day.year, 12, 25), // Natale
      DateTime(day.year, 12, 26), // Santo Stefano
      easterMonday, // Pasquetta
    ];

    return holidays.any(
      (holiday) =>
          holiday.year == day.year &&
          holiday.month == day.month &&
          holiday.day == day.day,
    );
  }

  static DateTime _calculateEasterSunday(int year) {
    // Anonymous Gregorian algorithm.
    final a = year % 19;
    final b = year ~/ 100;
    final c = year % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = ((19 * a) + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + (2 * e) + (2 * i) - h - k) % 7;
    final m = (a + (11 * h) + (22 * l)) ~/ 451;
    final month = (h + l - (7 * m) + 114) ~/ 31;
    final day = ((h + l - (7 * m) + 114) % 31) + 1;
    return DateTime(year, month, day);
  }
}
