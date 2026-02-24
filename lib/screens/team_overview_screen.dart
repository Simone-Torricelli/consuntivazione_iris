import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_reveal.dart';
import 'person_detail_screen.dart';

class TeamOverviewScreen extends StatelessWidget {
  const TeamOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final dataService = context.watch<DataService>();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Il mio team')),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: AppTheme.appBackgroundGradient,
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          children: [
            AnimatedReveal(
              delay: const Duration(milliseconds: 60),
              child: _TeamHeaderCard(
                user: currentUser,
                dataService: dataService,
              ),
            ),
            const SizedBox(height: 14),
            if (currentUser.role == UserRole.manager)
              _ManagerTeamSection(currentUser: currentUser)
            else if (currentUser.role == UserRole.teamLead)
              _TeamLeadSection(currentUser: currentUser)
            else
              const _NoTeamSection(),
          ],
        ),
      ),
    );
  }
}

class _TeamHeaderCard extends StatelessWidget {
  final User user;
  final DataService dataService;

  const _TeamHeaderCard({required this.user, required this.dataService});

  @override
  Widget build(BuildContext context) {
    final teamMembers = dataService.getTeamMembersForUser(user);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user.role == UserRole.manager
                ? 'Panoramica team manager'
                : user.role == UserRole.teamLead
                ? 'Panoramica team TL'
                : 'Panoramica personale',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${teamMembers.length} persone nel tuo perimetro',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagerTeamSection extends StatelessWidget {
  final User currentUser;

  const _ManagerTeamSection({required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final dataService = context.watch<DataService>();
    final teamLeads = dataService.getTeamLeadsForManager(currentUser.id)
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    if (teamLeads.isEmpty) {
      return const _NoTeamSection();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Team Lead assegnati', style: AppTheme.heading3),
        const SizedBox(height: 10),
        ...teamLeads.asMap().entries.map((indexed) {
          final index = indexed.key;
          final tl = indexed.value;
          final developers = dataService.getDevelopersForTeamLead(tl.id)
            ..sort((a, b) => a.fullName.compareTo(b.fullName));

          return AnimatedReveal(
            delay: Duration(milliseconds: 120 + (index * 45)),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFDCE8F9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(tl.fullName, style: AppTheme.bodyLarge),
                      ),
                      Text(
                        '${developers.length} dev',
                        style: AppTheme.bodySmall,
                      ),
                    ],
                  ),
                  if (developers.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: developers.map((dev) {
                        final monthHours = dataService
                            .getEntriesForUser(dev.id, monthStart, monthEnd)
                            .fold<double>(0, (sum, entry) => sum + entry.hours);
                        return InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PersonDetailScreen(userId: dev.id),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.08,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${dev.fullName} • ${monthHours.toStringAsFixed(1)}h',
                              style: AppTheme.bodySmall,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _TeamLeadSection extends StatelessWidget {
  final User currentUser;

  const _TeamLeadSection({required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final dataService = context.watch<DataService>();
    final developers = dataService.getDevelopersForTeamLead(currentUser.id)
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    if (developers.isEmpty) {
      return const _NoTeamSection();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Sviluppatori del tuo team', style: AppTheme.heading3),
        const SizedBox(height: 10),
        ...developers.asMap().entries.map((indexed) {
          final index = indexed.key;
          final dev = indexed.value;
          final monthHours = dataService
              .getEntriesForUser(dev.id, monthStart, monthEnd)
              .fold<double>(0, (sum, entry) => sum + entry.hours);
          return AnimatedReveal(
            delay: Duration(milliseconds: 110 + (index * 35)),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDCE8F9)),
              ),
              child: ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PersonDetailScreen(userId: dev.id),
                    ),
                  );
                },
                title: Text(dev.fullName, style: AppTheme.bodyLarge),
                subtitle: Text(
                  '${dev.email}\n${monthHours.toStringAsFixed(1)}h nel mese',
                  style: AppTheme.bodySmall,
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _NoTeamSection extends StatelessWidget {
  const _NoTeamSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE8F9)),
      ),
      child: const Text(
        'Nessun team assegnato al momento.',
        style: AppTheme.bodyMedium,
      ),
    );
  }
}
