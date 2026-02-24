import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    final canViewTeamDashboard = authService.canViewTeamDashboard;

    final screens = <Widget>[
      const TimeSheetScreen(),
      const CalendarScreen(),
      if (canViewTeamDashboard) const AdminDashboardScreen(),
      const ProfileScreen(),
    ];

    final navItems = <_DockNavItemData>[
      const _DockNavItemData(icon: Icons.bolt_rounded, activeIcon: Icons.bolt),
      const _DockNavItemData(
        icon: Icons.calendar_month_outlined,
        activeIcon: Icons.calendar_month,
      ),
      if (canViewTeamDashboard)
        const _DockNavItemData(
          icon: Icons.insights_outlined,
          activeIcon: Icons.insights,
        ),
      const _DockNavItemData(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person,
      ),
    ];

    if (_selectedIndex >= screens.length) {
      _selectedIndex = screens.length - 1;
    }

    return Scaffold(
      body: AnimatedSwitcher(
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
          key: ValueKey<int>(_selectedIndex),
          child: screens[_selectedIndex],
        ),
      ),
      bottomNavigationBar: _AnimatedDockBar(
        items: navItems,
        selectedIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
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
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.14),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final isSelected = index == selectedIndex;
            final item = items[index];

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(index),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: isSelected ? 1 : 0),
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, _) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: lerpDouble(38, 56, t),
                          height: lerpDouble(38, 56, t),
                          decoration: BoxDecoration(
                            gradient: t > 0.01
                                ? AppTheme.primaryGradient
                                : null,
                            color: t < 0.01
                                ? Colors.transparent
                                : AppTheme.primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        Transform.scale(
                          scale: lerpDouble(1, 1.15, t),
                          child: Icon(
                            isSelected ? item.activeIcon : item.icon,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textSecondaryColor,
                            size: lerpDouble(22, 24, t),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  double lerpDouble(num a, num b, double t) {
    return a + (b - a) * t;
  }
}

class _DockNavItemData {
  final IconData icon;
  final IconData activeIcon;

  const _DockNavItemData({required this.icon, required this.activeIcon});
}
