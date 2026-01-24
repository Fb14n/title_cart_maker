import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../widgets/config_panel.dart';
import '../widgets/preview_canvas.dart';
import '../widgets/text_mode_panel.dart';
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
          // Left sidebar - Configuration
          SizedBox(
            width: 300,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        ConfigPanel(),
                        SizedBox(height: 24),
                        TextModePanel(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // Main canvas - Preview
          const Expanded(
            child: PreviewCanvas(),
          ),
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
