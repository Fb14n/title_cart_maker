import 'package:flutter/material.dart';
import '../models/save_options.dart';

class SaveOptionsDialog extends StatefulWidget {
  const SaveOptionsDialog({super.key});

  @override
  State<SaveOptionsDialog> createState() => _SaveOptionsDialogState();
}

class _SaveOptionsDialogState extends State<SaveOptionsDialog> {
  SaveOptions _options = const SaveOptions();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Projekt speichern'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Was soll gespeichert werden?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Layout-Einstellungen'),
              subtitle: const Text('Spalten, Zeilen, Abstände, Ränder'),
              value: _options.saveLayout,
              onChanged: (value) {
                setState(() {
                  _options = _options.copyWith(saveLayout: value);
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Tabellendaten'),
              subtitle: const Text('Importierte Excel/CSV-Daten'),
              value: _options.saveTableData,
              onChanged: (value) {
                setState(() {
                  _options = _options.copyWith(saveTableData: value);
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Karteninhalte'),
              subtitle: const Text('Texte, Formatierungen, Platzhalter'),
              value: _options.saveCardContent,
              onChanged: (value) {
                setState(() {
                  _options = _options.copyWith(saveCardContent: value);
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Bilder'),
              subtitle: const Text('Eingebettete Bilder (kann groß werden)'),
              value: _options.saveImages,
              onChanged: (value) {
                setState(() {
                  _options = _options.copyWith(saveImages: value);
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Globale Einstellungen'),
              subtitle: const Text('Modi, globales Layout/Template'),
              value: _options.saveGlobalSettings,
              onChanged: (value) {
                setState(() {
                  _options = _options.copyWith(saveGlobalSettings: value);
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, _options),
          icon: const Icon(Icons.save),
          label: const Text('Speichern'),
        ),
      ],
    );
  }
}
