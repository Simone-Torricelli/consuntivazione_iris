import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_reveal.dart';
import 'person_detail_screen.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  String _searchQuery = '';

  Future<void> _openUserSheet() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final surnameController = TextEditingController();
    final emailController = TextEditingController();

    UserRole selectedRole = UserRole.employee;
    DeveloperType? selectedType;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final media = MediaQuery.of(context);

          return AnimatedPadding(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
            child: Container(
              constraints: BoxConstraints(maxHeight: media.size.height * 0.92),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppTheme.textLightColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nuova persona',
                                style: AppTheme.heading2.copyWith(fontSize: 26),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Crea un nuovo utente e assegna ruolo/team.',
                                style: AppTheme.bodyMedium,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Nome',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Nome richiesto';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: surnameController,
                                decoration: const InputDecoration(
                                  labelText: 'Cognome',
                                  prefixIcon: Icon(Icons.badge_outlined),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Cognome richiesto';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Email richiesta';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Email non valida';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<UserRole>(
                                initialValue: selectedRole,
                                decoration: const InputDecoration(
                                  labelText: 'Ruolo',
                                  prefixIcon: Icon(
                                    Icons.workspace_premium_outlined,
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: UserRole.employee,
                                    child: Text('Developer'),
                                  ),
                                  DropdownMenuItem(
                                    value: UserRole.teamLead,
                                    child: Text('Team Lead'),
                                  ),
                                  DropdownMenuItem(
                                    value: UserRole.manager,
                                    child: Text('Manager'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value == null) return;
                                  setSheetState(() {
                                    selectedRole = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<DeveloperType>(
                                initialValue: selectedType,
                                decoration: const InputDecoration(
                                  labelText: 'Specializzazione (opzionale)',
                                  prefixIcon: Icon(Icons.code),
                                ),
                                items: DeveloperType.values
                                    .map(
                                      (type) => DropdownMenuItem(
                                        value: type,
                                        child: Text(type.displayName),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setSheetState(() {
                                    selectedType = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(
                            color: AppTheme.surfaceMutedColor,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              child: const Text('Annulla'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) {
                                  return;
                                }

                                final user = User(
                                  id: 'user_${DateTime.now().millisecondsSinceEpoch}',
                                  email: emailController.text.trim(),
                                  name: nameController.text.trim(),
                                  surname: surnameController.text.trim(),
                                  role: selectedRole,
                                  developerType: selectedType,
                                  createdAt: DateTime.now(),
                                );

                                await context.read<DataService>().addUser(user);
                                if (sheetContext.mounted) {
                                  Navigator.of(sheetContext).pop();
                                }
                              },
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Crea'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 400));
    nameController.dispose();
    surnameController.dispose();
    emailController.dispose();
  }

  Future<void> _openDeleteUserSheet(User user) async {
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
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppTheme.textLightColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Eliminare utente?', style: AppTheme.heading3),
              const SizedBox(height: 6),
              Text(
                'Rimuovere ${user.fullName} dal team?',
                style: AppTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: const Text('Annulla'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await context.read<DataService>().deleteUser(user.id);
                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                      ),
                      child: const Text('Elimina'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataService = context.watch<DataService>();
    final users = dataService.users
        .where((u) => u.role != UserRole.admin)
        .toList();
    final managerCount = users.where((u) => u.role == UserRole.manager).length;
    final teamLeadCount = users
        .where((u) => u.role == UserRole.teamLead)
        .length;
    final developerCount = users
        .where((u) => u.role == UserRole.employee)
        .length;

    final query = _searchQuery.trim().toLowerCase();
    final filteredUsers = query.isEmpty
        ? users
        : users.where((user) {
            final fullName = user.fullName.toLowerCase();
            final email = user.email.toLowerCase();
            final role = user.role.displayName.toLowerCase();
            return fullName.contains(query) ||
                email.contains(query) ||
                role.contains(query);
          }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('People Studio')),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: AppTheme.appBackgroundGradient,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: AnimatedReveal(
                delay: const Duration(milliseconds: 60),
                child: _PeopleHeroCard(
                  totalPeople: users.length,
                  managers: managerCount,
                  teamLeads: teamLeadCount,
                  developers: developerCount,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: AnimatedReveal(
                delay: const Duration(milliseconds: 110),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: 'Cerca persona, ruolo o email',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
            ),
            Expanded(
              child: users.isEmpty
                  ? const _UsersEmptyState()
                  : filteredUsers.isEmpty
                  ? const _UsersNoResultState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        return AnimatedReveal(
                          delay: Duration(milliseconds: 140 + (index * 35)),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFDCE8F9),
                              ),
                            ),
                            child: ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PersonDetailScreen(userId: user.id),
                                  ),
                                );
                              },
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primaryColor
                                    .withValues(alpha: 0.1),
                                child: Text(
                                  user.name.isNotEmpty
                                      ? user.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(user.fullName),
                              subtitle: Text(
                                '${user.role.displayName}${user.developerType != null ? ' • ${user.developerType!.displayName}' : ''}\n${user.email}',
                              ),
                              isThreeLine: true,
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    _openDeleteUserSheet(user);
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete,
                                          color: AppTheme.errorColor,
                                        ),
                                        SizedBox(width: 8),
                                        Text('Elimina'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openUserSheet,
        icon: const Icon(Icons.add),
        label: const Text('Aggiungi Utente'),
      ),
    );
  }
}

class _PeopleHeroCard extends StatelessWidget {
  final int totalPeople;
  final int managers;
  final int teamLeads;
  final int developers;

  const _PeopleHeroCard({
    required this.totalPeople,
    required this.managers,
    required this.teamLeads,
    required this.developers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'People Pulse',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$totalPeople persone attive',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _RoleMetric(
                  label: 'Manager',
                  value: managers.toString(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RoleMetric(
                  label: 'Team Lead',
                  value: teamLeads.toString(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RoleMetric(
                  label: 'Developer',
                  value: developers.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleMetric extends StatelessWidget {
  final String label;
  final String value;

  const _RoleMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
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
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _UsersEmptyState extends StatelessWidget {
  const _UsersEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.group_outlined,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 14),
          const Text('Nessun utente', style: AppTheme.heading3),
          const SizedBox(height: 6),
          const Text(
            'Aggiungi il primo membro del team.',
            style: AppTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _UsersNoResultState extends StatelessWidget {
  const _UsersNoResultState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Nessun risultato per questa ricerca.',
        style: AppTheme.bodyMedium,
      ),
    );
  }
}
