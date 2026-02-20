import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../providers/project_provider.dart';
import '../widgets/config_panel.dart';
import '../widgets/preview_canvas.dart';
import '../widgets/table_import_panel.dart';
import '../widgets/card_layout_editor.dart';
import '../widgets/save_options_dialog.dart';
import '../widgets/card_selection_dialog.dart';
import '../widgets/image_export_dialog.dart';
import '../services/pdf_service.dart';
import '../services/image_service.dart';
import '../models/save_options.dart';

class HomeScreen extends StatefulWidget {
  final String? fileToOpen;
  
  const HomeScreen({super.key, this.fileToOpen});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    
    // Load file if passed as argument
    if (widget.fileToOpen != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadProjectFile(widget.fileToOpen!);
      });
    }
  }
  
  Future<void> _loadProjectFile(String filePath) async {
    final provider = context.read<ProjectProvider>();
    
    try {
      await provider.loadProject(filePath);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Projekt geladen: ${filePath.split(Platform.pathSeparator).last}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Laden: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Title Card Maker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'Projekt laden',
            onPressed: () => _loadProject(context),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Projekt speichern',
            onPressed: () => _saveProject(context),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
            onPressed: () => _exportPdf(context),
          ),
          IconButton(
            icon: const Icon(Icons.image),
            tooltip: 'Export PNG',
            onPressed: () => _exportPng(context),
          ),
          const SizedBox(width: 8),
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

  Future<void> _exportPng(BuildContext context) async {
    final provider = context.read<ProjectProvider>();
    
    if (provider.cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keine Karten zum Exportieren vorhanden')),
      );
      return;
    }
    
    // Show export options dialog
    final exportOptions = await showDialog(
      context: context,
      builder: (context) => const ImageExportDialog(),
    );
    
    if (exportOptions == null) return; // User cancelled
    
    // Show card selection dialog
    final selectedIndices = await showDialog<List<int>>(
      context: context,
      builder: (context) => CardSelectionDialog(
        cards: provider.cards,
        cardsPerPage: provider.layoutConfig.totalCards,
      ),
    );
    
    if (selectedIndices == null || selectedIndices.isEmpty) return; // User cancelled or no cards selected
    
    // Get only selected cards
    final selectedCards = selectedIndices.map((index) => provider.cards[index]).toList();
    
    try {
      await ImageService.generateAndSaveImages(
        cards: selectedCards,
        layoutConfig: provider.layoutConfig,
        context: context,
        options: exportOptions,
      );
      
      if (context.mounted) {
        final numberOfPages = (selectedCards.length / provider.layoutConfig.totalCards).ceil();
        final formatName = exportOptions.format.name.toUpperCase();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$numberOfPages $formatName-Seite(n) mit ${selectedCards.length} Karten erfolgreich exportiert!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Bild-Export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportPdf(BuildContext context) async {
    final provider = context.read<ProjectProvider>();
    
    if (provider.cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keine Karten zum Exportieren vorhanden')),
      );
      return;
    }
    
    // Show card selection dialog
    final selectedIndices = await showDialog<List<int>>(
      context: context,
      builder: (context) => CardSelectionDialog(
        cards: provider.cards,
        cardsPerPage: provider.layoutConfig.totalCards,
      ),
    );
    
    if (selectedIndices == null || selectedIndices.isEmpty) return; // User cancelled or no cards selected
    
    // Get only selected cards
    final selectedCards = selectedIndices.map((index) => provider.cards[index]).toList();
    
    try {
      await PdfService.generateAndSavePdf(
        cards: selectedCards,
        layoutConfig: provider.layoutConfig,
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF mit ${selectedCards.length} Karten erfolgreich exportiert!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _saveProject(BuildContext context) async {
    final provider = context.read<ProjectProvider>();
    
    // Show options dialog
    final options = await showDialog<SaveOptions>(
      context: context,
      builder: (context) => const SaveOptionsDialog(),
    );
    
    if (options == null) return; // User cancelled
    
    // Pick save location
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Projekt speichern',
      fileName: 'projekt.tcmaker',
      type: FileType.custom,
      allowedExtensions: ['tcmaker'],
    );
    
    if (result == null) return; // User cancelled
    
    try {
      await provider.saveProject(result, options);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Projekt erfolgreich gespeichert!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _loadProject(BuildContext context) async {
    final provider = context.read<ProjectProvider>();
    
    // Pick file to load
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Projekt laden',
      type: FileType.custom,
      allowedExtensions: ['tcmaker'],
    );
    
    if (result == null || result.files.isEmpty) return; // User cancelled
    
    final filePath = result.files.first.path;
    if (filePath == null) return;
    
    try {
      await provider.loadProject(filePath);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Projekt erfolgreich geladen!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Laden: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
