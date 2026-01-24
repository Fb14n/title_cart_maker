import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../providers/project_provider.dart';
import '../models/card_data.dart';
import '../models/text_mode.dart';

class CardPreview extends StatelessWidget {
  final int index;
  final CardData cardData;
  final double width;
  final double height;

  const CardPreview({
    super.key,
    required this.index,
    required this.cardData,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final isIndividualMode = provider.textMode == TextMode.individual;
    
    return GestureDetector(
      onTap: isIndividualMode ? () => _showEditDialog(context, provider) : null,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            // Image area
            Expanded(
              flex: 3,
              child: Container(
                color: Colors.grey[100],
                child: cardData.imagePath != null
                    ? Image.file(
                        File(cardData.imagePath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.broken_image, color: Colors.grey),
                          );
                        },
                      )
                    : Center(
                        child: Icon(
                          Icons.add_photo_alternate,
                          color: Colors.grey[400],
                          size: 32,
                        ),
                      ),
              ),
            ),
            
            // Text area
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(4),
                alignment: Alignment.center,
                child: Text(
                  cardData.text.isEmpty ? 'Text hier...' : cardData.text,
                  style: TextStyle(
                    fontSize: 10,
                    color: cardData.text.isEmpty ? Colors.grey : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, ProjectProvider provider) {
    final textController = TextEditingController(text: cardData.text);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Karte ${index + 1} bearbeiten'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                labelText: 'Text',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.image,
                );
                
                if (result != null && result.files.single.path != null) {
                  provider.updateCardImage(index, result.files.single.path!);
                }
              },
              icon: const Icon(Icons.image),
              label: const Text('Bild auswählen'),
            ),
            if (cardData.imagePath != null) ...[
              const SizedBox(height: 8),
              Text(
                'Aktuelles Bild: ${cardData.imagePath!.split(Platform.pathSeparator).last}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.updateCardText(index, textController.text);
              Navigator.pop(context);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }
}
