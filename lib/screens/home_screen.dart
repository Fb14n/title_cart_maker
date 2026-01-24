import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../widgets/config_panel.dart';
import '../widgets/preview_canvas.dart';
import '../widgets/table_import_panel.dart';
import '../widgets/card_layout_editor.dart';
import '../services/pdf_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Title Card Maker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
            onPressed: () => _exportPdf(context),
          ),
        ],
      ),
      body: Row(
        children: [
          // Left sidebar - Configuration & Table Import
          SizedBox(
            width: 300,
            child: Column(
              children: const [
                SizedBox(
                  height: 200,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: ConfigPanel(),
                  ),
                ),
                Divider(height: 1),
                Expanded(
                  child: TableImportPanel(),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // Main canvas - Preview (Center)
          const Expanded(
            child: PreviewCanvas(),
          ),
          // Right sidebar - Layout Editor
          const CardLayoutEditor(),
        ],
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context) async {
    final provider = context.read<ProjectProvider>();
    
    try {
      await PdfService.generateAndSavePdf(
        cards: provider.cards,
        layoutConfig: provider.layoutConfig,
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF erfolgreich exportiert!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Export: $e')),
        );
      }
    }
  }
}
