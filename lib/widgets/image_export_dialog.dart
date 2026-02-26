import 'package:flutter/material.dart';
import 'package:title_card_maker/models/image_export_options.dart';

class ImageExportDialog extends StatefulWidget {
  const ImageExportDialog({super.key});

  @override
  State<ImageExportDialog> createState() => _ImageExportDialogState();
}

class _ImageExportDialogState extends State<ImageExportDialog> {
  ImageFormat _format = ImageFormat.png;
  PageSize _pageSize = PageSize.a4;
  int _dpi = 300;
  
  final TextEditingController _widthController = TextEditingController(text: '210');
  final TextEditingController _heightController = TextEditingController(text: '297');
  
  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bild Export Einstellungen'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Format selection
            const Text('Format:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<ImageFormat>(
              segments: const [
                ButtonSegment(
                  value: ImageFormat.png,
                  label: Text('PNG'),
                  icon: Icon(Icons.image, size: 16),
                ),
                ButtonSegment(
                  value: ImageFormat.jpg,
                  label: Text('JPG'),
                  icon: Icon(Icons.image, size: 16),
                ),
              ],
              selected: {_format},
              onSelectionChanged: (Set<ImageFormat> newSelection) {
                setState(() {
                  _format = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Page size selection
            const Text('Seitengröße:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<PageSize>(
              segments: const [
                ButtonSegment(
                  value: PageSize.a4,
                  label: Text('A4'),
                ),
                ButtonSegment(
                  value: PageSize.custom,
                  label: Text('Benutzerdefiniert'),
                ),
              ],
              selected: {_pageSize},
              onSelectionChanged: (Set<PageSize> newSelection) {
                setState(() {
                  _pageSize = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Custom dimensions (only shown when custom is selected)
            if (_pageSize == PageSize.custom) ...[
              const Text('Abmessungen (mm):', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _widthController,
                      decoration: const InputDecoration(
                        labelText: 'Breite',
                        border: OutlineInputBorder(),
                        suffixText: 'mm',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _heightController,
                      decoration: const InputDecoration(
                        labelText: 'Höhe',
                        border: OutlineInputBorder(),
                        suffixText: 'mm',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            
            // DPI selection
            const Text('Auflösung:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _dpi,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 150, child: Text('150 DPI (niedrig)')),
                DropdownMenuItem(value: 300, child: Text('300 DPI (hoch)')),
                DropdownMenuItem(value: 600, child: Text('600 DPI (sehr hoch)')),
              ],
              onChanged: (value) {
                setState(() {
                  _dpi = value!;
                });
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Höhere Auflösung = bessere Qualität, aber größere Dateien',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () {
            double? customWidth;
            double? customHeight;
            
            if (_pageSize == PageSize.custom) {
              customWidth = double.tryParse(_widthController.text);
              customHeight = double.tryParse(_heightController.text);
              
              if (customWidth == null || customHeight == null || customWidth <= 0 || customHeight <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bitte gültige Abmessungen eingeben'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
            }
            
            final options = ImageExportOptions(
              format: _format,
              pageSize: _pageSize,
              customWidth: customWidth,
              customHeight: customHeight,
              dpi: _dpi,
            );
            
            Navigator.pop(context, options);
          },
          child: const Text('Exportieren'),
        ),
      ],
    );
  }
}
