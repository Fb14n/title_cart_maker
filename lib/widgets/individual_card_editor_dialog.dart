import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import 'card_layout_editor.dart';

class IndividualCardEditorDialog extends StatelessWidget {
  final int cardIndex;

  const IndividualCardEditorDialog({super.key, required this.cardIndex});

  static Future<void> show(BuildContext context, int cardIndex) async {
    final provider = context.read<ProjectProvider>();
    provider.startIndividualEdit(cardIndex);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => IndividualCardEditorDialog(cardIndex: cardIndex),
    );

    // Ensure cleanup even if dialog is dismissed unexpectedly
    if (context.mounted) {
      context.read<ProjectProvider>().stopIndividualEdit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 820),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit_note, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Karte ${cardIndex + 1} individuell bearbeiten',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Individuelle Änderungen werden durch globale Änderungen überschrieben.',
                    child: Icon(Icons.info_outline,
                        size: 18, color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                ],
              ),
            ),

            // Editor – Expanded so CardLayoutEditor gets a bounded height
            const Expanded(
              child: CardLayoutEditor(inDialog: true),
            ),

            // Footer
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      context.read<ProjectProvider>().stopIndividualEdit();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Fertig'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
