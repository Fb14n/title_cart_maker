import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../providers/project_provider.dart';
import '../models/text_mode.dart';
import '../services/import_service.dart';

class TextModePanel extends StatelessWidget {
  const TextModePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Text-Modus',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            SegmentedButton<TextMode>(
              segments: const [
                ButtonSegment(
                  value: TextMode.individual,
                  label: Text('Individuell'),
                  icon: Icon(Icons.edit),
                ),
                ButtonSegment(
                  value: TextMode.global,
                  label: Text('Global'),
                  icon: Icon(Icons.text_fields),
                ),
                ButtonSegment(
                  value: TextMode.imported,
                  label: Text('Import'),
                  icon: Icon(Icons.upload_file),
                ),
              ],
              selected: {provider.textMode},
              onSelectionChanged: (Set<TextMode> newSelection) {
                provider.setTextMode(newSelection.first);
              },
            ),
            
            const SizedBox(height: 16),
            
            if (provider.textMode == TextMode.global) ...[
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Text für alle Karten',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => provider.setGlobalText(value),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _pickGlobalImage(context, provider),
                icon: const Icon(Icons.image),
                label: const Text('Globales Bild auswählen'),
              ),
              if (provider.globalImagePath != null) ...[
                const SizedBox(height: 8),
                Text('Bild: ${provider.globalImagePath!.split(Platform.pathSeparator).last}'),
              ],
            ],
            
            if (provider.textMode == TextMode.imported) ...[
              ElevatedButton.icon(
                onPressed: () => _importTexts(context, provider),
                icon: const Icon(Icons.upload_file),
                label: const Text('CSV/Excel importieren'),
              ),
              const SizedBox(height: 8),
              Text(
                'Importieren Sie eine Datei mit einer Textspalte.\nJede Zeile wird einer Karte zugewiesen.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _pickGlobalImage(BuildContext context, ProjectProvider provider) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    
    if (result != null && result.files.single.path != null) {
      provider.setGlobalImage(result.files.single.path!);
    }
  }

  Future<void> _importTexts(BuildContext context, ProjectProvider provider) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
    );
    
    if (result != null && result.files.single.path != null) {
      try {
        final texts = await ImportService.importTexts(result.files.single.path!);
        provider.importTextsFromList(texts);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${texts.length} Texte erfolgreich importiert!')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler beim Import: $e')),
          );
        }
      }
    }
  }
}
