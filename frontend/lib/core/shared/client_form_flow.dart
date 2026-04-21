import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jimeri_frontend/core/shared/adaptive_form_sheet.dart';
import 'package:jimeri_frontend/core/shared/app_snackbar.dart';
import 'package:jimeri_frontend/dtos/client_with_balance_dto.dart';
import 'package:jimeri_frontend/features/clients/clients_provider.dart';
import 'package:jimeri_frontend/features/clients/widgets/client_form_dialog.dart';

class ClientFormFlow {
  static Future<void> open(
    BuildContext context,
    WidgetRef ref, [
    ClientWithBalanceDto? client,
  ]) async {
    final input = await showAdaptiveFormSheet<ClientFormInput>(
      context: context,
      builder: (context) => ClientFormDialog(client: client),
    );

    if (input == null || !context.mounted) {
      return;
    }

    final error = client == null
        ? await ref.read(clientsProvider.notifier).createClient(input)
        : await ref.read(clientsProvider.notifier).updateClient(client, input);

    if (!context.mounted) {
      return;
    }

    if (error != null) {
      AppSnackBar.showError(error, context: context);
      return;
    }

    AppSnackBar.showSuccess(
      client == null ? 'Cliente criado.' : 'Cliente atualizado.',
      context: context,
    );
  }
}
