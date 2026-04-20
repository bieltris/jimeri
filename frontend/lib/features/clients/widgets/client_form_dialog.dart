import 'package:flutter/material.dart';

import '../../../dtos/client_with_balance_dto.dart';
import '../clients_provider.dart';

class ClientFormDialog extends StatefulWidget {
  const ClientFormDialog({
    this.client,
    super.key,
  });

  final ClientWithBalanceDto? client;

  @override
  State<ClientFormDialog> createState() => _ClientFormDialogState();
}

class _ClientFormDialogState extends State<ClientFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _responsibleNameController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _noteController = TextEditingController();

  bool _active = true;

  @override
  void initState() {
    super.initState();

    final client = widget.client?.client;
    if (client == null) {
      return;
    }

    _nameController.text = client.name;
    _responsibleNameController.text = client.responsibleName ?? '';
    _whatsappController.text = client.responsibleWhatsapp ?? '';
    _noteController.text = client.note ?? '';
    _active = client.active;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _responsibleNameController.dispose();
    _whatsappController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.client != null;

    return AlertDialog(
      title: Text(isEditing ? 'Editar cliente' : 'Novo cliente'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _responsibleNameController,
                decoration: const InputDecoration(
                  labelText: 'Responsavel',
                  prefixIcon: Icon(Icons.supervisor_account_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _whatsappController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'WhatsApp do responsavel',
                  prefixIcon: Icon(Icons.chat_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observacao',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              if (isEditing) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Cliente ativo no cadastro'),
                  value: _active,
                  onChanged: (value) {
                    setState(() {
                      _active = value;
                    });
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      ClientFormInput(
        name: _nameController.text.trim(),
        responsibleName: _nullable(_responsibleNameController.text),
        responsibleWhatsapp: _nullable(_whatsappController.text),
        note: _nullable(_noteController.text),
        active: _active,
      ),
    );
  }

  String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
