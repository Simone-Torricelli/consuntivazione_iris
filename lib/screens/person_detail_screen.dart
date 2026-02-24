import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/timesheet_entry.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_reveal.dart';
import '../widgets/burst_hero_card.dart';

class PersonDetailScreen extends StatelessWidget {
  final String userId;

  const PersonDetailScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final dataService = context.watch<DataService>();
    final user = dataService.getUserById(userId);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dettaglio Persona')),
        body: const Center(child: Text('Utente non trovato.')),
      );
    }

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    final entries = dataService.getEntriesForUser(user.id, monthStart, monthEnd)
      ..sort((a, b) => b.date.compareTo(a.date));

    final totalHours = entries.fold<double>(0, (sum, entry) => sum + entry.hours);
    final workingDays = entries
        .map((entry) => DateUtils.dateOnly(entry.date))
        .toSet()
        .length;
    final perfectDays = dataService.getPerfectDaysCount(
      userId: user.id,
      startDate: monthStart,
      endDate: monthEnd,
    );
    final streak = dataService.getCurrentStreak(user.id);

    final byProject = dataService.getHoursByProjectForUser(
      user.id,
      startDate: monthStart,
      endDate: monthEnd,
    ).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: Text(user.fullName)),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF4F8FF), Color(0xFFEAF3FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
          children: [
            AnimatedReveal(
              delay: const Duration(milliseconds: 50),
              child: BurstHeroCard(
                title: 'Panoramica ${DateFormat('MMMM', 'it').format(now)}',
                value: totalHours.toStringAsFixed(1),
                unit: 'ore',
                subtitle:
                    '${user.role.displayName} • $workingDays giorni registrati • streak $streak',
              ),
            ),
            const SizedBox(height: 12),
            AnimatedReveal(
              delay: const Duration(milliseconds: 100),
              child: _StatsRow(
                items: [
                  _StatItem('Giorni perfetti', '$perfectDays', Icons.bolt),
                  _StatItem('Media giorno',
                      workingDays == 0 ? '0.0h' : '${(totalHours / workingDays).toStringAsFixed(1)}h', Icons.query_stats),
                  _StatItem('Consuntivi', '${entries.length}', Icons.assignment_outlined),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AnimatedReveal(
              delay: const Duration(milliseconds: 150),
              child: const Text('Ore per progetto', style: AppTheme.heading3),
            ),
            const SizedBox(height: 8),
            ...byProject.asMap().entries.map((indexed) {
              final idx = indexed.key;
              final item = indexed.value;
              final project = dataService.getProjectById(item.key);
              final color = _safeProjectColor(project?.color);
              final pct = totalHours == 0 ? 0.0 : (item.value / totalHours);

              return AnimatedReveal(
                delay: Duration(milliseconds: 180 + (idx * 45)),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFDCE8F9)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              project?.name ?? 'Progetto',
                              style: AppTheme.bodyLarge,
                            ),
                          ),
                          Text(
                            '${item.value.toStringAsFixed(1)}h',
                            style: AppTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 8,
                          backgroundColor: AppTheme.surfaceMutedColor,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
            AnimatedReveal(
              delay: const Duration(milliseconds: 260),
              child: const Text('Ultime attività', style: AppTheme.heading3),
            ),
            const SizedBox(height: 8),
            ...entries.take(12).toList().asMap().entries.map((indexed) {
              final idx = indexed.key;
              final entry = indexed.value;
              final project = dataService.getProjectById(entry.projectId);
              final color = _safeProjectColor(project?.color);

              return AnimatedReveal(
                delay: Duration(milliseconds: 300 + (idx * 35)),
                child: _EntryTile(entry: entry, projectName: project?.name ?? 'Progetto', color: color),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _safeProjectColor(String? raw) {
    if (raw == null) return AppTheme.primaryColor;
    try {
      return Color(int.parse(raw.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppTheme.primaryColor;
    }
  }
}

class _StatItem {
  final String title;
  final String value;
  final IconData icon;

  const _StatItem(this.title, this.value, this.icon);
}

class _StatsRow extends StatelessWidget {
  final List<_StatItem> items;

  const _StatsRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items
          .map(
            (item) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDCE8F9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item.icon, size: 18, color: AppTheme.primaryColor),
                    const SizedBox(height: 6),
                    Text(item.value, style: AppTheme.heading3),
                    Text(item.title, style: AppTheme.bodySmall),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final TimesheetEntry entry;
  final String projectName;
  final Color color;

  const _EntryTile({
    required this.entry,
    required this.projectName,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE8F9)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(projectName, style: AppTheme.bodyLarge),
                Text(
                  DateFormat('EEE d MMM', 'it').format(entry.date),
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            '${entry.hours.toStringAsFixed(1)}h',
            style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
