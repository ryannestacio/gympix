import 'package:flutter/material.dart';

Future<bool> showSignOutConfirmationDialog(BuildContext context) async {
  final shouldSignOut = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Sair da conta'),
      content: const Text('Tem certeza que deseja sair agora?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Sair'),
        ),
      ],
    ),
  );

  return shouldSignOut ?? false;
}
