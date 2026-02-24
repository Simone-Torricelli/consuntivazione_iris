import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/timesheet_entry.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_reveal.dart';
import '../widgets/burst_hero_card.dart';
import 'person_detail_screen.dart';

class ProjectDetailScreen extends StatelessWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    final dataService = context.watch<DataService>();
    final project = dataService.getProjectById(projectId);

    if (project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dettaglio Progetto')),
        body: const Center(child: Text('Progetto non trovato.')),
      );
    }

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    final entries = dataService.getEntriesForProject(
      project.id,
      startDate: monthStart,
      endDate: monthEnd,
    )..sort((a, b) => b.date.compareTo(a.date));

    final totalHours = entries.fold<double>(0, (sum, entry) => sum + entry.hours);
    final activeDays = entries
        .map((entry) => DateUtils.dateOnly(entry.date))
        .toSet()
        .length;

    final contributors = dataService.getHoursByUserForProject(
      project.id,
      startDate: monthStart,
      endDate: monthEnd,
    ).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: Text(project.name)),
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
              delay: const Duration(milliseconds: 60),
              child: BurstHeroCard(
                title: 'Project Pulse',
                value: totalHours.toStringAsFixed(1),
                unit: 'ore',
                subtitle:
                    '${DateFormat('MMMM', 'it').format(now)} • $activeDays giorni attivi • ${contributors.length} contributor',
              ),
            ),
            const SizedBox(height: 12),
            AnimatedReveal(
              delay: const Duration(milliseconds: 110),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFDCE8F9)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _safeProjectColor(project.color),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(project.description, style: AppTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            AnimatedReveal(
              delay: const Duration(milliseconds: 160),
              child: const Text('Contributors', style: AppTheme.heading3),
            ),
            const SizedBox(height: 8),
            ...contributors.asMap().entries.map((indexed) {
              final idx = indexed.key;
              final contributor = indexed.value;
              final user = dataService.getUserById(contributor.key);
              final pct = totalHours == 0 ? 0.0 : contributor.value / totalHours;

              if (user == null) {
                return const SizedBox.shrink();
              }

              return AnimatedReveal(
                delay: Duration(milliseconds: 190 + (idx * 45)),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PersonDetailScreen(userId: user.id),
                      ),
                    );
                  },
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
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppTheme.primaryColor.withValues(
                                alpha: 0.13,
                              ),
                              child: Text(
                                (user.name.isNotEmpty ? user.name[0].toUpperCase() : '?'),
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(user.fullName, style: AppTheme.bodyLarge),
                            ),
                            Text(
                              '${contributor.value.toStringAsFixed(1)}h',
                              style: AppTheme.bodyMedium.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.chevron_right, size: 18),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 8,
                            backgroundColor: AppTheme.surfaceMutedColor,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
            AnimatedReveal(
              delay: const Duration(milliseconds: 260),
              child: const Text('Timeline progetto', style: AppTheme.heading3),
            ),
            const SizedBox(height: 8),
            ...entries.take(14).toList().asMap().entries.map((indexed) {
              final idx = indexed.key;
              final entry = indexed.value;
              final user = dataService.getUserById(entry.userId);

              return AnimatedReveal(
                delay: Duration(milliseconds: 300 + (idx * 35)),
                child: _ProjectEntryTile(
                  entry: entry,
                  userName: user?.fullName ?? 'Utente',
                  color: _safeProjectColor(project.color),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _safeProjectColor(String raw) {
    try {
      return Color(int.parse(raw.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppTheme.primaryColor;
    }
  }
}

class _ProjectEntryTile extends StatelessWidget {
  final TimesheetEntry entry;
  final String userName;
  final Color color;

  const _ProjectEntryTile({
    required this.entry,
    required this.userName,
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
            height: 38,
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
                Text(userName, style: AppTheme.bodyLarge),
                Text(
                  DateFormat('EEE d MMM', 'it').format(entry.date),
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            '${entry.hours.toStringAsFixed(1)}h',
            style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
