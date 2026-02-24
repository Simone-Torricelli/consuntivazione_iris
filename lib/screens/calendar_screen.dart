import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateUtils.dateOnly(DateTime.now());
  DateTime? _selectedDay = DateUtils.dateOnly(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final dataService = context.watch<DataService>();
    final userId = authService.currentUser?.id ?? '';

    final monthStart = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final monthEnd = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final monthEntries = dataService.getEntriesForUser(
      userId,
      monthStart,
      monthEnd,
    );
    final salaryDay = dataService.getPenultimateWorkingDay(_focusedDay);

    final totalMonthHours = monthEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.hours,
    );
    final workingDaysWithEntries = monthEntries
        .map((entry) => DateUtils.dateOnly(entry.date))
        .toSet()
        .length;
    final workingDaysInMonth = dataService.getWorkingDaysInMonth(_focusedDay);
    final perfectDays = dataService.getPerfectDaysCount(
      userId: userId,
      startDate: monthStart,
      endDate: monthEnd,
    );

    final projectHours = <String, double>{};
    for (final entry in monthEntries) {
      projectHours[entry.projectId] =
          (projectHours[entry.projectId] ?? 0) + entry.hours;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Calendario e Analytics')),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF4F8FF), Color(0xFFEAF3FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MonthOverviewCard(
                focusedDay: _focusedDay,
                totalMonthHours: totalMonthHours,
                workingDaysWithEntries: workingDaysWithEntries,
                perfectDays: perfectDays,
                workingDaysInMonth: workingDaysInMonth,
                salaryDay: salaryDay,
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFDCE8F9)),
                ),
                padding: const EdgeInsets.all(8),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2035, 12, 31),
                  focusedDay: _focusedDay,
                  locale: 'it',
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  calendarFormat: CalendarFormat.month,
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Mese',
                  },
                  eventLoader: (day) =>
                      dataService.getEntriesForDate(userId, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = DateUtils.dateOnly(selectedDay);
                      _focusedDay = DateUtils.dateOnly(focusedDay);
                    });
                  },
                  onPageChanged: (focusedDay) {
                    setState(() {
                      _focusedDay = DateUtils.dateOnly(focusedDay);
                    });
                  },
                  headerStyle: const HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: false,
                    titleTextStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    outsideTextStyle: TextStyle(
                      color: AppTheme.textLightColor.withOpacity(0.6),
                    ),
                    weekendTextStyle: const TextStyle(
                      color: AppTheme.textLightColor,
                      fontWeight: FontWeight.w600,
                    ),
                    todayDecoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.16),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: AppTheme.secondaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    prioritizedBuilder: (context, day, focusedDay) {
                      if (!isSameDay(day, salaryDay)) {
                        return null;
                      }

                      final isSelected = isSameDay(day, _selectedDay);
                      return Container(
                        margin: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? null
                              : AppTheme.sunriseGradient,
                          color: isSelected ? AppTheme.primaryColor : null,
                          shape: BoxShape.circle,
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Text(
                                '${day.day}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const Positioned(
                              right: 3,
                              top: 3,
                              child: Icon(
                                Icons.payments_outlined,
                                color: Colors.white,
                                size: 11,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    markerBuilder: (context, date, events) {
                      if (events.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      final dayHours = dataService.getDailyHours(userId, date);
                      final markerColor = dayHours >= 8.0
                          ? AppTheme.successColor
                          : (dayHours >= 4.0
                                ? AppTheme.warningColor
                                : AppTheme.secondaryColor);

                      return Positioned(
                        bottom: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: markerColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${dayHours.toStringAsFixed(1)}h',
                            style: const TextStyle(
                              fontSize: 8,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const _LegendRow(),
              const SizedBox(height: 18),
              if (projectHours.isNotEmpty) ...[
                const Text(
                  'Distribuzione per progetto',
                  style: AppTheme.heading3,
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFDCE8F9)),
                  ),
                  child: Column(
                    children: projectHours.entries.map((entry) {
                      final project = dataService.getProjectById(entry.key);
                      final projectColor = _projectColor(project?.color);
                      final percentage = totalMonthHours == 0
                          ? 0.0
                          : (entry.value / totalMonthHours).clamp(0.0, 1.0);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: projectColor,
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          project?.name ?? 'Progetto',
                                          style: AppTheme.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${entry.value.toStringAsFixed(1)}h',
                                  style: AppTheme.bodyMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                minHeight: 8,
                                value: percentage,
                                backgroundColor: AppTheme.surfaceMutedColor,
                                color: projectColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              if (_selectedDay != null) ...[
                const SizedBox(height: 18),
                Text(
                  'Dettaglio ${DateFormat('d MMMM', 'it').format(_selectedDay!)}',
                  style: AppTheme.heading3,
                ),
                const SizedBox(height: 10),
                ...dataService.getEntriesForDate(userId, _selectedDay!).map((
                  entry,
                ) {
                  final project = dataService.getProjectById(entry.projectId);
                  final projectColor = _projectColor(project?.color);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFDCE8F9)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: projectColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.folder, color: projectColor),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                project?.name ?? 'Progetto',
                                style: AppTheme.bodyLarge,
                              ),
                              if ((entry.notes ?? '').trim().isNotEmpty)
                                Text(entry.notes!, style: AppTheme.bodySmall),
                            ],
                          ),
                        ),
                        Text(
                          '${entry.hours.toStringAsFixed(1)}h',
                          style: AppTheme.heading3.copyWith(
                            color: projectColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _projectColor(String? rawColor) {
    if (rawColor == null) {
      return AppTheme.secondaryColor;
    }

    try {
      return Color(int.parse(rawColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppTheme.secondaryColor;
    }
  }
}

class _MonthOverviewCard extends StatelessWidget {
  final DateTime focusedDay;
  final double totalMonthHours;
  final int workingDaysWithEntries;
  final int perfectDays;
  final int workingDaysInMonth;
  final DateTime salaryDay;

  const _MonthOverviewCard({
    required this.focusedDay,
    required this.totalMonthHours,
    required this.workingDaysWithEntries,
    required this.perfectDays,
    required this.workingDaysInMonth,
    required this.salaryDay,
  });

  @override
  Widget build(BuildContext context) {
    final completion = workingDaysInMonth == 0
        ? 0.0
        : (perfectDays / workingDaysInMonth).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('MMMM yyyy', 'it').format(focusedDay),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _InfoStat(
                  label: 'Ore mese',
                  value: totalMonthHours.toStringAsFixed(1),
                ),
              ),
              Expanded(
                child: _InfoStat(
                  label: 'Giorni registrati',
                  value: '$workingDaysWithEntries/$workingDaysInMonth',
                ),
              ),
              Expanded(
                child: _InfoStat(
                  label: 'Giorni perfetti',
                  value: perfectDays.toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: completion,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Stipendio: ${DateFormat('d MMM', 'it').format(salaryDay)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoStat extends StatelessWidget {
  final String label;
  final String value;

  const _InfoStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.82),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: const [
        _LegendDot(color: AppTheme.successColor, label: '>=8h'),
        _LegendDot(color: AppTheme.warningColor, label: '4-7.5h'),
        _LegendDot(color: AppTheme.secondaryColor, label: '<4h'),
        _LegendDot(color: AppTheme.accentColor, label: 'Payday'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: AppTheme.caption),
      ],
    );
  }
}
