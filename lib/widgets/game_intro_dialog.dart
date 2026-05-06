import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class GameIntroDialogData {
  const GameIntroDialogData({
    required this.gameId,
    required this.title,
    required this.subtitle,
    required this.instructions,
  });

  final String gameId;
  final String title;
  final String subtitle;
  final List<String> instructions;
}

Future<void> showGameIntroDialogIfNeeded(
  BuildContext context,
  GameIntroDialogData data,
) async {
  final storageService = context.read<StorageService>();
  if (storageService.hasSeenGameIntro(data.gameId)) {
    return;
  }

  if (!context.mounted) return;

  var doNotShowAgain = false;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(data.title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.subtitle,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...data.instructions.map(
                    (instruction) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 3),
                            child: Icon(Icons.fiber_manual_record, size: 8),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(instruction)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: doNotShowAgain,
                    onChanged: (value) {
                      setState(() {
                        doNotShowAgain = value ?? false;
                      });
                    },
                    title: const Text('Não exibir isso novamente'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Entendi'),
              ),
            ],
          );
        },
      );
    },
  );

  if (doNotShowAgain) {
    await storageService.setGameIntroSeen(data.gameId, true);
  }
}
