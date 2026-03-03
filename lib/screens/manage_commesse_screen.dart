import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/commessa_model.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';

class ManageCommesseScreen extends StatefulWidget {
  const ManageCommesseScreen({super.key});

  @override
  State<ManageCommesseScreen> createState() => _ManageCommesseScreenState();
}

class _ManageCommesseScreenState extends State<ManageCommesseScreen> {
  Future<void> _openCommessaSheet({Commessa? commessa}) async {
    final formKey = GlobalKey<FormState>();
    final codiceController = TextEditingController(
      text: commessa?.codice ?? '',
    );
    final descrizioneController = TextEditingController(
      text: commessa?.descrizione ?? '',
    );
    final clienteController = TextEditingController(
      text: commessa?.cliente ?? '',
    );
    var selectedStatus = commessa?.status ?? CommessaStatus.active;
    var isActive = commessa?.isActive ?? true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setLocalState) {
          final media = MediaQuery.of(context);
          return AnimatedPadding(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          commessa == null
                              ? 'Nuova commessa'
                              : 'Modifica commessa',
                          style: AppTheme.heading3,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: codiceController,
                          decoration: const InputDecoration(
                            labelText: 'Codice commessa',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Codice obbligatorio';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: descrizioneController,
                          decoration: const InputDecoration(
                            labelText: 'Descrizione',
                            prefixIcon: Icon(Icons.description_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Descrizione obbligatoria';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: clienteController,
                          decoration: const InputDecoration(
                            labelText: 'Cliente',
                            prefixIcon: Icon(Icons.apartment_outlined),
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<CommessaStatus>(
                          initialValue: selectedStatus,
                          decoration: const InputDecoration(
                            labelText: 'Stato',
                            prefixIcon: Icon(Icons.tune_outlined),
                          ),
                          items: CommessaStatus.values
                              .map(
                                (status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status.displayName),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setLocalState(() {
                              selectedStatus = value;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Commessa attiva'),
                          value: isActive,
                          onChanged: (value) {
                            setLocalState(() {
                              isActive = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    Navigator.of(sheetContext).pop(),
                                child: const Text('Annulla'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (!formKey.currentState!.validate()) {
                                    return;
                                  }

                                  final dataService = context
                                      .read<DataService>();
                                  if (commessa == null) {
                                    await dataService.addCommessa(
                                      Commessa(
                                        id: 'comm_${DateTime.now().millisecondsSinceEpoch}',
                                        codice: codiceController.text.trim(),
                                        descrizione: descrizioneController.text
                                            .trim(),
                                        cliente: clienteController.text.trim(),
                                        status: selectedStatus,
                                        isActive: isActive,
                                        createdAt: DateTime.now(),
                                      ),
                                    );
                                  } else {
                                    await dataService.updateCommessa(
                                      commessa.copyWith(
                                        codice: codiceController.text.trim(),
                                        descrizione: descrizioneController.text
                                            .trim(),
                                        cliente: clienteController.text.trim(),
                                        status: selectedStatus,
                                        isActive: isActive,
                                      ),
                                    );
                                  }

                                  if (sheetContext.mounted) {
                                    Navigator.of(sheetContext).pop();
                                  }
                                },
                                child: Text(
                                  commessa == null ? 'Crea' : 'Salva',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 280));
    codiceController.dispose();
    descrizioneController.dispose();
    clienteController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataService = context.watch<DataService>();
    final commesse = dataService.commesse.toList()
      ..sort((a, b) => a.codice.compareTo(b.codice));

    return Scaffold(
      appBar: AppBar(title: const Text('Commesse GECO')),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: AppTheme.appBackgroundGradient,
        ),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 90),
          itemCount: commesse.length,
          itemBuilder: (context, index) {
            final commessa = commesse[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDCE8F9)),
              ),
              child: ListTile(
                title: Text('${commessa.codice} • ${commessa.descrizione}'),
                subtitle: Text(
                  '${commessa.cliente.isEmpty ? 'Cliente N/D' : commessa.cliente} • ${commessa.status.displayName}',
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      _openCommessaSheet(commessa: commessa);
                    } else if (value == 'delete') {
                      await dataService.deleteCommessa(commessa.id);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Modifica')),
                    PopupMenuItem(value: 'delete', child: Text('Elimina')),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCommessaSheet(),
        icon: const Icon(Icons.add),
        label: const Text('Nuova Commessa'),
      ),
    );
  }
}
