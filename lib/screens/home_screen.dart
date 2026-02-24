import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';

import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'admin_dashboard_screen.dart';
import 'calendar_screen.dart';
import 'profile_screen.dart';
import 'timesheet_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final dataService = context.watch<DataService>();
    final canViewTeamDashboard = authService.canViewTeamDashboard;
    final now = DateTime.now();
    final salaryDay = dataService.getLastWorkingDay(now);
    final isSalaryDay = DateUtils.isSameDay(DateUtils.dateOnly(now), salaryDay);

    final screens = <Widget>[
      const TimeSheetScreen(),
      const CalendarScreen(),
      if (canViewTeamDashboard) const AdminDashboardScreen(),
      const ProfileScreen(),
    ];

    final navItems = <_DockNavItemData>[
      const _DockNavItemData(
        icon: Icons.bolt_rounded,
        activeIcon: Icons.bolt,
        gradient: LinearGradient(
          colors: [Color(0xFF1757FF), Color(0xFF07C5C9)],
        ),
      ),
      const _DockNavItemData(
        icon: Icons.calendar_month_outlined,
        activeIcon: Icons.calendar_month,
        gradient: LinearGradient(
          colors: [Color(0xFF00A6FB), Color(0xFF05D5E8)],
        ),
      ),
      if (canViewTeamDashboard)
        const _DockNavItemData(
          icon: Icons.insights_outlined,
          activeIcon: Icons.insights,
          gradient: LinearGradient(
            colors: [Color(0xFFFF7A18), Color(0xFFFFB703)],
          ),
        ),
      const _DockNavItemData(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person,
        gradient: LinearGradient(
          colors: [Color(0xFF7B61FF), Color(0xFFB06CFF)],
        ),
      ),
    ];

    final effectiveIndex = _selectedIndex >= screens.length
        ? screens.length - 1
        : _selectedIndex;
    if (effectiveIndex != _selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _selectedIndex = effectiveIndex;
        });
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          StreamBuilder<int>(
            stream: dataService.realtimeTickStream,
            initialData: dataService.realtimeTick,
            builder: (context, snapshot) {
              return RefreshIndicator(
                onRefresh: () async {
                  final auth = context.read<AuthService>();
                  final data = context.read<DataService>();
                  await auth.refreshCurrentUserFromRemote();
                  await data.refreshFromRemote();
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final slide = Tween<Offset>(
                      begin: const Offset(0.06, 0),
                      end: Offset.zero,
                    ).animate(animation);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: slide, child: child),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<int>(effectiveIndex),
                    child: screens[effectiveIndex],
                  ),
                ),
              );
            },
          ),
          if (isSalaryDay)
            Align(
              alignment: Alignment.topCenter,
              child: SafeArea(
                minimum: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _SalaryCelebrationBanner(
                  onOpenCalendar: () {
                    setState(() {
                      _selectedIndex = 1;
                    });
                  },
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _AnimatedDockBar(
        items: navItems,
        selectedIndex: effectiveIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

class _SalaryCelebrationBanner extends StatefulWidget {
  final VoidCallback onOpenCalendar;

  const _SalaryCelebrationBanner({required this.onOpenCalendar});

  @override
  State<_SalaryCelebrationBanner> createState() =>
      _SalaryCelebrationBannerState();
}

class _SalaryCelebrationBannerState extends State<_SalaryCelebrationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final wave = math.sin(_controller.value * math.pi * 2);
        return Transform.scale(scale: 1 + (wave * 0.015), child: child);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF7A18), Color(0xFFFFB703), Color(0xFF05D5E8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentColor.withValues(alpha: 0.36),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            const _CelebrationIcons(),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Oggi e giorno stipendio! 🎉',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Ultimo giorno lavorativo del mese.',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: widget.onOpenCalendar,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.textPrimaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                minimumSize: const Size(0, 0),
              ),
              child: const Text(
                'Apri',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CelebrationIcons extends StatefulWidget {
  const _CelebrationIcons();

  @override
  State<_CelebrationIcons> createState() => _CelebrationIconsState();
}

class _CelebrationIconsState extends State<_CelebrationIcons>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 44,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final dyA = math.sin(t * math.pi * 2) * 2;
          final dyB = math.cos(t * math.pi * 2) * 2;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 6,
                top: 8 + dyA,
                child: const Icon(
                  Icons.payments_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              Positioned(
                right: -2,
                top: -2 + dyB,
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              Positioned(
                right: 2,
                bottom: 2 - dyA,
                child: const Icon(
                  Icons.celebration,
                  color: Colors.white,
                  size: 13,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AnimatedDockBar extends StatelessWidget {
  final List<_DockNavItemData> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _AnimatedDockBar({
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const barHeight = 66.0;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Container(
        height: barHeight,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF101216),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.32),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / items.length;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  left: selectedIndex * itemWidth,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: itemWidth,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: items[selectedIndex].gradient,
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: List.generate(items.length, (index) {
                    final isSelected = index == selectedIndex;
                    final item = items[index];

                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onTap(index),
                        child: Center(
                          child: AnimatedScale(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            scale: isSelected ? 1.12 : 1,
                            child: Icon(
                              isSelected ? item.activeIcon : item.icon,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.7),
                              size: isSelected ? 25 : 22,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DockNavItemData {
  final IconData icon;
  final IconData activeIcon;
  final Gradient gradient;

  const _DockNavItemData({
    required this.icon,
    required this.activeIcon,
    required this.gradient,
  });
}
