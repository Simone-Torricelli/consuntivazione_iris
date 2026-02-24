import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/project_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_reveal.dart';
import '../widgets/project_card.dart';
import '../widgets/stat_card.dart';
import 'manage_projects_screen.dart';
import 'manage_users_screen.dart';
import 'person_detail_screen.dart';
import 'project_detail_screen.dart';
import 'team_overview_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final dataService = context.watch<DataService>();
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final users = switch (currentUser.role) {
      UserRole.admin => dataService.getUsersByRole(UserRole.employee),
      UserRole.manager => dataService.getDevelopersForManager(currentUser.id),
      UserRole.teamLead => dataService.getDevelopersForTeamLead(currentUser.id),
      UserRole.employee => <User>[],
    };
    final teamMembers = dataService.getTeamMembersForUser(currentUser);
    final projects = dataService.getProjectsVisibleForUser(currentUser);

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    final trackedEnd = now.isBefore(monthEnd) ? now : monthEnd;

    final elapsedWorkingDays = dataService.getWorkingDaysInRange(
      monthStart,
      trackedEnd,
    );
    final targetHoursPerUser = elapsedWorkingDays * 8.0;

    final userStats = users.map((user) {
      final entries = dataService.getEntriesForUser(
        user.id,
        monthStart,
        monthEnd,
      );
      final totalHours = entries.fold<double>(
        0,
        (sum, entry) => sum + entry.hours,
      );
      final perfectDays = dataService.getPerfectDaysCount(
        userId: user.id,
        startDate: monthStart,
        endDate: monthEnd,
      );
      final completionRate = targetHoursPerUser == 0
          ? 0.0
          : (totalHours / targetHoursPerUser).clamp(0.0, 1.5);

      return _UserMonthStat(
        user: user,
        totalHours: totalHours,
        perfectDays: perfectDays,
        completionRate: completionRate,
      );
    }).toList()..sort((a, b) => b.totalHours.compareTo(a.totalHours));

    final teamHours = userStats.fold<double>(
      0,
      (sum, stat) => sum + stat.totalHours,
    );
    final avgCompletion = userStats.isEmpty
        ? 0.0
        : userStats.fold<double>(0, (sum, stat) => sum + stat.completionRate) /
              userStats.length;
    final alertCount = userStats
        .where((stat) => stat.totalHours < (targetHoursPerUser * 0.75))
        .length;
    final topContributor = userStats.isEmpty ? null : userStats.first;

    final title = switch (currentUser.role) {
      UserRole.admin => 'Console Admin',
      UserRole.manager => 'Dashboard Manager',
      UserRole.teamLead => 'Dashboard Team Lead',
      UserRole.employee => 'Dashboard',
    };

    final visibleProjectIds = projects.map((project) => project.id).toSet();
    final projectHours = <String, double>{};
    final last7DaysDailyHours = <DateTime, double>{};
    final trendStart = DateUtils.dateOnly(
      now.subtract(const Duration(days: 6)),
    );

    for (final project in projects) {
      projectHours[project.id] = 0;
    }

    for (final entry in dataService.timesheetEntries) {
      if (!visibleProjectIds.contains(entry.projectId)) {
        continue;
      }

      if (!entry.date.isBefore(monthStart) && !entry.date.isAfter(monthEnd)) {
        projectHours[entry.projectId] =
            (projectHours[entry.projectId] ?? 0) + entry.hours;
      }

      final day = DateUtils.dateOnly(entry.date);
      if (!day.isBefore(trendStart) && !day.isAfter(DateUtils.dateOnly(now))) {
        last7DaysDailyHours[day] =
            (last7DaysDailyHours[day] ?? 0) + entry.hours;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: AppTheme.appBackgroundGradient,
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            final auth = context.read<AuthService>();
            final data = context.read<DataService>();
            await auth.refreshCurrentUserFromRemote();
            await data.refreshFromRemote();
          },
          child: StreamBuilder<int>(
            stream: dataService.realtimeTickStream,
            initialData: dataService.realtimeTick,
            builder: (context, _) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedReveal(
                    delay: const Duration(milliseconds: 60),
                    child: _HeroOverview(
                      now: now,
                      elapsedWorkingDays: elapsedWorkingDays,
                      targetHoursPerUser: targetHoursPerUser,
                      alertCount: alertCount,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedReveal(
                    delay: const Duration(milliseconds: 120),
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.32,
                      children: [
                        StatCard(
                          title: 'Membri Team',
                          value: teamMembers.length.toString(),
                          icon: Icons.people_alt_outlined,
                          color: AppTheme.primaryColor,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => authService.isAdmin
                                    ? const ManageUsersScreen()
                                    : const TeamOverviewScreen(),
                              ),
                            );
                          },
                        ),
                        StatCard(
                          title: 'Ore Team Mese',
                          value: teamHours.toStringAsFixed(1),
                          icon: Icons.timer_outlined,
                          color: AppTheme.secondaryColor,
                        ),
                        StatCard(
                          title: 'Completion Medio',
                          value: '${(avgCompletion * 100).round()}%',
                          icon: Icons.speed,
                          color: AppTheme.successColor,
                        ),
                        StatCard(
                          title: 'Progetti Attivi',
                          value: projects.length.toString(),
                          icon: Icons.folder_open,
                          color: AppTheme.accentColor,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ManageProjectsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  if (topContributor != null) ...[
                    const SizedBox(height: 20),
                    AnimatedReveal(
                      delay: const Duration(milliseconds: 170),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PersonDetailScreen(
                                userId: topContributor.user.id,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: AppTheme.emeraldGradient,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.emoji_events_outlined,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Top Contributor',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      topContributor.user.fullName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${topContributor.totalHours.toStringAsFixed(1)}h',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (currentUser.role == UserRole.teamLead &&
                      projects.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    AnimatedReveal(
                      delay: const Duration(milliseconds: 205),
                      child: _ProjectAnalyticsPanel(
                        projects: projects,
                        projectHours: projectHours,
                        last7DaysDailyHours: last7DaysDailyHours,
                        parseColor: _parseColor,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Text(
                    'Andamento per sviluppatore',
                    style: AppTheme.heading3,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFDCE8F9)),
                    ),
                    child: userStats.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              'Nessun membro team disponibile.',
                              style: AppTheme.bodyMedium,
                            ),
                          )
                        : Column(
                            children: userStats.asMap().entries.map((indexed) {
                              final idx = indexed.key;
                              final stat = indexed.value;
                              final isAlert =
                                  stat.totalHours < (targetHoursPerUser * 0.75);

                              return AnimatedReveal(
                                delay: Duration(milliseconds: 220 + (idx * 35)),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PersonDetailScreen(
                                          userId: stat.user.id,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                stat.user.fullName,
                                                style: AppTheme.bodyLarge,
                                              ),
                                            ),
                                            Text(
                                              '${stat.totalHours.toStringAsFixed(1)}h',
                                              style: AppTheme.bodyMedium
                                                  .copyWith(
                                                    color: isAlert
                                                        ? AppTheme.errorColor
                                                        : AppTheme
                                                              .textPrimaryColor,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Perfetti: ${stat.perfectDays}',
                                              style: AppTheme.caption,
                                            ),
                                            const SizedBox(width: 2),
                                            const Icon(
                                              Icons.chevron_right,
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: LinearProgressIndicator(
                                            value: stat.completionRate.clamp(
                                              0.0,
                                              1.0,
                                            ),
                                            minHeight: 8,
                                            backgroundColor:
                                                AppTheme.surfaceMutedColor,
                                            color: isAlert
                                                ? AppTheme.errorColor
                                                : AppTheme.primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Azioni rapide', style: AppTheme.heading3),
                  const SizedBox(height: 10),
                  if (authService.isAdmin) ...[
                    _QuickActionCard(
                      title: 'Console utenti',
                      subtitle: 'Assegna ruoli, TL e membri team',
                      icon: Icons.admin_panel_settings_outlined,
                      color: AppTheme.primaryColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ManageUsersScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                  _QuickActionCard(
                    title: 'Gestisci Progetti',
                    subtitle: 'Aggiorna backlog progetti e assegnazioni',
                    icon: Icons.folder_copy_outlined,
                    color: AppTheme.secondaryColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ManageProjectsScreen(),
                        ),
                      );
                    },
                  ),
                  if (currentUser.role == UserRole.manager ||
                      currentUser.role == UserRole.teamLead) ...[
                    const SizedBox(height: 10),
                    _QuickActionCard(
                      title: 'Il mio team',
                      subtitle: 'Vedi struttura e persone assegnate',
                      icon: Icons.groups_outlined,
                      color: AppTheme.successColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TeamOverviewScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                  if (projects.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Progetti in evidenza',
                          style: AppTheme.heading3,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ManageProjectsScreen(),
                              ),
                            );
                          },
                          child: const Text('Vedi tutti'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...projects.take(4).toList().asMap().entries.map((indexed) {
                      final idx = indexed.key;
                      final project = indexed.value;
                      return AnimatedReveal(
                        delay: Duration(milliseconds: 280 + (idx * 40)),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ProjectCard(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProjectDetailScreen(
                                    projectId: project.id,
                                  ),
                                ),
                              );
                            },
                            name: project.name,
                            description: project.description,
                            color: _parseColor(project.color),
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppTheme.primaryColor;
    }
  }
}

class _ProjectAnalyticsPanel extends StatelessWidget {
  final List<Project> projects;
  final Map<String, double> projectHours;
  final Map<DateTime, double> last7DaysDailyHours;
  final Color Function(String) parseColor;

  const _ProjectAnalyticsPanel({
    required this.projects,
    required this.projectHours,
    required this.last7DaysDailyHours,
    required this.parseColor,
  });

  @override
  Widget build(BuildContext context) {
    final totalHours = projectHours.values.fold<double>(0, (sum, h) => sum + h);
    final sortedProjectHours = projectHours.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final now = DateTime.now();
    final start = DateUtils.dateOnly(now.subtract(const Duration(days: 6)));
    final trendDays = List<DateTime>.generate(
      7,
      (index) => start.add(Duration(days: index)),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE8F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Analytics Progetti TL', style: AppTheme.heading3),
          const SizedBox(height: 4),
          Text(
            'Andamento ore ultimi 7 giorni + distribuzione ore per progetto.',
            style: AppTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 170,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 8.0 * (projects.isEmpty ? 1 : projects.length),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= trendDays.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat('E', 'it').format(trendDays[index]),
                            style: AppTheme.caption,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: trendDays.asMap().entries.map((indexed) {
                  final day = indexed.value;
                  final hours = last7DaysDailyHours[day] ?? 0;
                  return BarChartGroupData(
                    x: indexed.key,
                    barRods: [
                      BarChartRodData(
                        toY: hours,
                        width: 18,
                        borderRadius: BorderRadius.circular(6),
                        gradient: AppTheme.primaryGradient,
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (totalHours <= 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Nessuna ora registrata sui tuoi progetti nel mese corrente.',
                style: AppTheme.bodySmall,
              ),
            )
          else
            SizedBox(
              height: 190,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 34,
                  sections: sortedProjectHours
                      .where((entry) => entry.value > 0)
                      .take(5)
                      .map((entry) {
                        final project = projects.firstWhere(
                          (p) => p.id == entry.key,
                        );
                        final pct = (entry.value / totalHours) * 100;
                        return PieChartSectionData(
                          value: entry.value,
                          title: '${pct.toStringAsFixed(0)}%',
                          radius: 56,
                          color: parseColor(project.color),
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        );
                      })
                      .toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroOverview extends StatelessWidget {
  final DateTime now;
  final int elapsedWorkingDays;
  final double targetHoursPerUser;
  final int alertCount;

  const _HeroOverview({
    required this.now,
    required this.elapsedWorkingDays,
    required this.targetHoursPerUser,
    required this.alertCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Panoramica ${DateFormat('MMMM yyyy', 'it').format(now)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Monitora consuntivi, produttivita e segnali critici del team.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _HighlightChip(
                label: 'Giorni lavorativi',
                value: '$elapsedWorkingDays',
                icon: Icons.calendar_month,
              ),
              _HighlightChip(
                label: 'Target per persona',
                value: '${targetHoursPerUser.toStringAsFixed(0)}h',
                icon: Icons.flag_outlined,
              ),
              _HighlightChip(
                label: 'Alert',
                value: '$alertCount',
                icon: Icons.warning_amber_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HighlightChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _HighlightChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE8F9)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: AppTheme.bodyLarge),
        subtitle: Text(subtitle, style: AppTheme.bodySmall),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _UserMonthStat {
  final User user;
  final double totalHours;
  final int perfectDays;
  final double completionRate;

  const _UserMonthStat({
    required this.user,
    required this.totalHours,
    required this.perfectDays,
    required this.completionRate,
  });
}
