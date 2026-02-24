import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/timesheet_entry.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_reveal.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final dataService = context.watch<DataService>();
    final user = authService.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    final allEntries =
        dataService.timesheetEntries
            .where((entry) => entry.userId == user.id)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    final monthEntries = dataService.getEntriesForUser(
      user.id,
      monthStart,
      monthEnd,
    )..sort((a, b) => b.date.compareTo(a.date));

    final totalHours = allEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.hours,
    );
    final totalDays = allEntries
        .map((entry) => DateUtils.dateOnly(entry.date))
        .toSet()
        .length;
    final avgHoursPerDay = totalDays == 0 ? 0.0 : totalHours / totalDays;

    final monthHours = monthEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.hours,
    );
    final monthlyXp = dataService.getMonthlyExperience(user.id, now);
    final streak = dataService.getCurrentStreak(user.id);
    final perfectDays = dataService.getPerfectDaysCount(
      userId: user.id,
      startDate: monthStart,
      endDate: monthEnd,
    );

    final workingDaysInMonth = dataService.getWorkingDaysInMonth(now);
    final monthCompletion = workingDaysInMonth == 0
        ? 0.0
        : (monthHours / (workingDaysInMonth * 8.0)).clamp(0.0, 1.0);

    final totalXp =
        (totalHours * 10).round() + (streak * 40) + (perfectDays * 25);
    final level = _levelForXp(totalXp);
    final levelProgress =
        (totalXp - level.startXp) / (level.endXp - level.startXp);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFFF2F3F5)),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
            children: [
              AnimatedReveal(
                delay: const Duration(milliseconds: 40),
                beginOffset: const Offset(0, -0.04),
                child: Row(
                  children: [
                    const Spacer(),
                    _CircleActionButton(
                      icon: Icons.settings_outlined,
                      onTap: () => _openSettingsSheet(authService),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              AnimatedReveal(
                delay: const Duration(milliseconds: 80),
                child: Text(
                  'IL MIO PROFILO',
                  style: GoogleFonts.archivoBlack(
                    fontSize: 48,
                    height: 0.95,
                    color: Colors.black,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              AnimatedReveal(
                delay: const Duration(milliseconds: 100),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD4DBE6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user.email,
                        style: const TextStyle(
                          color: Color(0xFF5E6778),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              AnimatedReveal(
                delay: const Duration(milliseconds: 120),
                child: _ProfileTabs(
                  index: _tabIndex,
                  onChanged: (index) {
                    setState(() {
                      _tabIndex = index;
                    });
                  },
                ),
              ),
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _tabIndex == 0
                    ? _ProfileHighlightsView(
                        key: const ValueKey('highlights'),
                        user: user,
                        totalHours: totalHours,
                        monthHours: monthHours,
                        totalEntries: allEntries.length,
                        avgHoursPerDay: avgHoursPerDay,
                        monthlyXp: monthlyXp,
                        streak: streak,
                        level: level,
                        levelProgress: levelProgress,
                        totalXp: totalXp,
                        monthCompletion: monthCompletion,
                        onLevelInfoTap: () => _openInfoSheet(
                          title: 'Livello',
                          message:
                              'Il livello cresce con XP totali: ore registrate, streak e giorni perfetti.',
                        ),
                        onActivityInfoTap: () => _openInfoSheet(
                          title: 'Livello di attivita',
                          message:
                              'La classifica dipende da completamento target mensile, streak e ore del mese.',
                        ),
                      )
                    : _ProfileTimelineView(
                        key: const ValueKey('timeline'),
                        entries: allEntries,
                        getProjectName: (projectId) =>
                            dataService.getProjectById(projectId)?.name ??
                            'Progetto',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSettingsSheet(AuthService authService) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppTheme.textLightColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Impostazioni profilo', style: AppTheme.heading3),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.notifications_active_outlined),
                title: const Text('Attiva promemoria'),
                onTap: () async {
                  await NotificationService().scheduleDailyReminder();
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Promemoria giornalieri aggiornati'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout, color: AppTheme.errorColor),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: AppTheme.errorColor),
                ),
                onTap: () async {
                  await authService.logout();
                  if (!mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openInfoSheet({
    required String title,
    required String message,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppTheme.textLightColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(title, style: AppTheme.heading3),
              const SizedBox(height: 6),
              Text(message, style: AppTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }

  _LevelInfo _levelForXp(int xp) {
    const tiers = <_LevelInfo>[
      _LevelInfo(name: 'Bronze', startXp: 0, endXp: 3000),
      _LevelInfo(name: 'Silver', startXp: 3000, endXp: 7000),
      _LevelInfo(name: 'Gold', startXp: 7000, endXp: 14000),
      _LevelInfo(name: 'Legend', startXp: 14000, endXp: 25000),
    ];

    for (final tier in tiers) {
      if (xp < tier.endXp) {
        return tier;
      }
    }

    return const _LevelInfo(name: 'Master', startXp: 25000, endXp: 40000);
  }
}

class _ProfileHighlightsView extends StatelessWidget {
  final User user;
  final double totalHours;
  final double monthHours;
  final int totalEntries;
  final double avgHoursPerDay;
  final int monthlyXp;
  final int streak;
  final _LevelInfo level;
  final double levelProgress;
  final int totalXp;
  final double monthCompletion;
  final VoidCallback onLevelInfoTap;
  final VoidCallback onActivityInfoTap;

  const _ProfileHighlightsView({
    super.key,
    required this.user,
    required this.totalHours,
    required this.monthHours,
    required this.totalEntries,
    required this.avgHoursPerDay,
    required this.monthlyXp,
    required this.streak,
    required this.level,
    required this.levelProgress,
    required this.totalXp,
    required this.monthCompletion,
    required this.onLevelInfoTap,
    required this.onActivityInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Punti salienti', style: AppTheme.heading3),
        const SizedBox(height: 10),
        AnimatedReveal(
          delay: const Duration(milliseconds: 160),
          child: _MainStatCard(
            title: 'In totale, ${user.name} ha consuntivato',
            mainValue: _hoursLabel(totalHours),
            subtitle: '$totalEntries registrazioni complessive',
            color: const Color(0xFFF3EAF0),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 7,
              child: AnimatedReveal(
                delay: const Duration(milliseconds: 200),
                child: _SmallStatCard(
                  color: const Color(0xFFDDECF8),
                  title: 'In media, ${user.name} registra',
                  value: _hoursLabel(avgHoursPerDay),
                  subtitle: 'ore al giorno',
                  trailingEmoji: '⚡',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 4,
              child: AnimatedReveal(
                delay: const Duration(milliseconds: 240),
                child: _SmallStatCard(
                  color: const Color(0xFFF3F2DA),
                  title: 'XP mese',
                  value: NumberFormat.decimalPattern('it').format(monthlyXp),
                  subtitle: 'punti',
                  trailingEmoji: '🏆',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Text('Livello', style: AppTheme.heading3),
            const SizedBox(width: 8),
            _SectionInfoButton(
              tooltip: 'Come funziona il livello',
              onTap: onLevelInfoTap,
            ),
          ],
        ),
        const SizedBox(height: 10),
        AnimatedReveal(
          delay: const Duration(milliseconds: 280),
          child: _LevelCard(
            level: level,
            progress: levelProgress.clamp(0.0, 1.0),
            currentXp: totalXp,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Text('Livello di attivita', style: AppTheme.heading3),
            const SizedBox(width: 8),
            _SectionInfoButton(
              tooltip: 'Come funziona la classifica',
              onTap: onActivityInfoTap,
            ),
          ],
        ),
        const SizedBox(height: 10),
        AnimatedReveal(
          delay: const Duration(milliseconds: 320),
          child: _ActivityRankCard(
            streak: streak,
            monthHours: monthHours,
            completion: monthCompletion,
          ),
        ),
      ],
    );
  }

  String _hoursLabel(double hours) {
    return '${hours.toStringAsFixed(hours == hours.roundToDouble() ? 0 : 1)}h';
  }
}

class _ProfileTimelineView extends StatelessWidget {
  final List<TimesheetEntry> entries;
  final String Function(String projectId) getProjectName;

  const _ProfileTimelineView({
    super.key,
    required this.entries,
    required this.getProjectName,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 36),
        child: Text('Nessuna attivita registrata.', style: AppTheme.bodyMedium),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cronologia attivita', style: AppTheme.heading3),
        const SizedBox(height: 10),
        ...entries.take(20).toList().asMap().entries.map((indexed) {
          final index = indexed.key;
          final entry = indexed.value;

          return AnimatedReveal(
            delay: Duration(milliseconds: 120 + (index * 35)),
            child: Container(
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
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.folder_open,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          getProjectName(entry.projectId),
                          style: AppTheme.bodyLarge,
                        ),
                        Text(
                          DateFormat('EEE d MMM yyyy', 'it').format(entry.date),
                          style: AppTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${entry.hours.toStringAsFixed(1)}h',
                    style: GoogleFonts.archivoBlack(
                      fontSize: 20,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F2F5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFCFD8E4)),
        ),
        child: Icon(icon, color: Colors.black, size: 28),
      ),
    );
  }
}

class _SectionInfoButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback onTap;

  const _SectionInfoButton({required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      triggerMode: TooltipTriggerMode.tap,
      child: IconButton(
        onPressed: onTap,
        splashRadius: 18,
        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
        icon: Icon(
          Icons.info_outline,
          size: 19,
          color: Colors.black.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

class _ProfileTabs extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _ProfileTabs({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _TabLabel(
                text: 'Profilo',
                active: index == 0,
                onTap: () => onChanged(0),
              ),
            ),
            Expanded(
              child: _TabLabel(
                text: 'Cronologia',
                active: index == 1,
                onTap: () => onChanged(1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Stack(
          children: [
            Container(height: 2, color: const Color(0xFFCFD8E4)),
            AnimatedAlign(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              alignment: index == 0
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TabLabel extends StatelessWidget {
  final String text;
  final bool active;
  final VoidCallback onTap;

  const _TabLabel({
    required this.text,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? Colors.black : const Color(0xFF8A96AB),
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            fontSize: 38 / 2,
          ),
        ),
      ),
    );
  }
}

class _MainStatCard extends StatelessWidget {
  final String title;
  final String mainValue;
  final String subtitle;
  final Color color;

  const _MainStatCard({
    required this.title,
    required this.mainValue,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, color: Color(0xFF5E6778)),
          ),
          const SizedBox(height: 10),
          Text(
            mainValue,
            style: GoogleFonts.archivoBlack(
              fontSize: 78,
              height: 0.9,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 18, color: Colors.black),
          ),
        ],
      ),
    );
  }
}

class _SmallStatCard extends StatelessWidget {
  final Color color;
  final String title;
  final String value;
  final String subtitle;
  final String trailingEmoji;

  const _SmallStatCard({
    required this.color,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.trailingEmoji,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, color: Color(0xFF5E6778)),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.archivoBlack(
              fontSize: 48,
              height: 0.9,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  subtitle,
                  style: const TextStyle(fontSize: 18, color: Colors.black),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(trailingEmoji, style: const TextStyle(fontSize: 22)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final _LevelInfo level;
  final double progress;
  final int currentXp;

  const _LevelCard({
    required this.level,
    required this.progress,
    required this.currentXp,
  });

  @override
  Widget build(BuildContext context) {
    final nextLevelName = _nextLevelName(level.name);
    final xpFormatter = NumberFormat.decimalPattern('it');
    final clampedProgress = progress.clamp(0.0, 1.0);
    final remainingXp = (level.endXp - currentXp).clamp(0, level.endXp);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7EDDF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFC57A35), width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '👑 ${xpFormatter.format(currentXp)} / ${xpFormatter.format(level.endXp)}',
            style: GoogleFonts.archivoBlack(fontSize: 30, color: Colors.black),
          ),
          const SizedBox(height: 10),
          Text(
            'Mancano ${xpFormatter.format(remainingXp)} XP al prossimo livello',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF626E7F),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const _LevelNode(icon: Icons.check_rounded, active: true),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 12,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFD8DEE6),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: clampedProgress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFC57A35),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const _LevelNode(icon: Icons.lock_rounded, active: false),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _LevelLabel(
                title: level.name,
                subtitle: 'Attuale',
                alignEnd: false,
              ),
              const Spacer(),
              _LevelLabel(
                title: nextLevelName,
                subtitle: '${xpFormatter.format(level.endXp)} XP',
                alignEnd: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _nextLevelName(String current) {
    switch (current) {
      case 'Bronze':
        return 'Silver';
      case 'Silver':
        return 'Gold';
      case 'Gold':
        return 'Legend';
      case 'Legend':
        return 'Master';
      default:
        return 'Master';
    }
  }
}

class _LevelNode extends StatelessWidget {
  final IconData icon;
  final bool active;

  const _LevelNode({required this.icon, required this.active});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: active ? const Color(0xFFECC79D) : const Color(0xFFD0D6DE),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF161616), width: 1.2),
        ),
        child: Icon(icon, color: Colors.black, size: 22),
      ),
    );
  }
}

class _LevelLabel extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool alignEnd;

  const _LevelLabel({
    required this.title,
    required this.subtitle,
    required this.alignEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF606A7A),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _ActivityRankCard extends StatelessWidget {
  final int streak;
  final double monthHours;
  final double completion;

  const _ActivityRankCard({
    required this.streak,
    required this.monthHours,
    required this.completion,
  });

  @override
  Widget build(BuildContext context) {
    final rank = _rankName();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'La classifica attuale e',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            rank,
            style: GoogleFonts.archivoBlack(
              fontSize: 58,
              height: 0.9,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Streak $streak giorni • ${monthHours.toStringAsFixed(1)}h mese • ${(completion * 100).round()}% target',
            style: const TextStyle(color: Color(0xFFBFC7D6), fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _rankName() {
    if (completion >= 1.0 && streak >= 5) {
      return 'Legend';
    }
    if (completion >= 0.8) {
      return 'Explorer';
    }
    if (completion >= 0.55) {
      return 'Runner';
    }
    return 'Starter';
  }
}

class _LevelInfo {
  final String name;
  final int startXp;
  final int endXp;

  const _LevelInfo({
    required this.name,
    required this.startXp,
    required this.endXp,
  });
}
