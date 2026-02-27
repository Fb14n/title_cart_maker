import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:title_card_maker/providers/project_provider.dart';

class TableImportPanel extends StatefulWidget {
  const TableImportPanel({super.key});

  @override
  State<TableImportPanel> createState() => _TableImportPanelState();
}

class _TableImportPanelState extends State<TableImportPanel> {
  List<List<String>> _tableData = [];
  List<int> _selectedColumnIndices = []; // Changed to support multiple columns
  List<List<String>> _selectedColumns = []; // Multiple columns data

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Tabellen-Import',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          
          // Import buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _importFromExcel,
                  icon: const Icon(Icons.file_upload, size: 16),
                  label: const Text('Excel/CSV', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pasteFromClipboard,
                  icon: const Icon(Icons.content_paste, size: 16),
                  label: const Text('Einfügen', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Table preview
          Expanded(
            child: _tableData.isNotEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Divider(height: 8),
                      const Text(
                        'Vorschau:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: DataTable(
                              columnSpacing: 15,
                              headingRowHeight: 32,
                              dataRowMinHeight: 24,
                              dataRowMaxHeight: 32,
                              columns: List.generate(
                                _tableData.first.length,
                                (index) => DataColumn(
                                  label: InkWell(
                                    onTap: () => _selectColumn(index),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _selectedColumnIndices.contains(index)
                                            ? Colors.blue.withOpacity(0.2)
                                            : null,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Sp${index + 1}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: _selectedColumnIndices.contains(index)
                                                  ? Colors.blue
                                                  : Colors.black,
                                            ),
                                          ),
                                          if (_selectedColumnIndices.contains(index))
                                            Text(
                                              '${_selectedColumnIndices.indexOf(index) + 1}',
                                              style: const TextStyle(
                                                fontSize: 9,
                                                color: Colors.blue,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              rows: _tableData.map((row) {
                                return DataRow(
                                  cells: row.asMap().entries.map((cellEntry) {
                                    final colIndex = cellEntry.key;
                                    final cell = cellEntry.value;
                                    return DataCell(
                                      Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: _selectedColumnIndices.contains(colIndex)
                                              ? Colors.blue.withOpacity(0.1)
                                              : null,
                                        ),
                                        child: Text(
                                          cell,
                                          style: const TextStyle(fontSize: 10),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Info text
                      if (_selectedColumnIndices.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${_selectedColumnIndices.length} Spalte(n) ausgewählt',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                    ],
                  )
                : const Center(
                    child: Text(
                      'Keine Daten\n\nImportiere oder füge Daten ein',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _selectColumn(int index) {
    setState(() {
      if (_selectedColumnIndices.contains(index)) {
        // Deselect
        _selectedColumnIndices.remove(index);
      } else {
        // Select
        _selectedColumnIndices.add(index);
      }
      
      _selectedColumnIndices.sort(); // Keep order
      
      // Extract selected columns data
      _selectedColumns = _selectedColumnIndices.map((colIndex) {
        return _tableData.map((row) {
          return colIndex < row.length ? row[colIndex] : '';
        }).toList();
      }).toList();
    });
    
    // Update provider with selected columns data
    final provider = context.read<ProjectProvider>();
    provider.setTableData(_selectedColumns);
  }

  Future<void> _importFromExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final extension = path.split('.').last.toLowerCase();

      try {
        if (extension == 'csv') {
          await _loadCsv(path);
        } else {
          await _loadExcel(path);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler beim Laden: $e')),
          );
        }
      }
    }
  }

  Future<void> _loadExcel(String path) async {
    final bytes = await File(path).readAsBytes();
    final excel = Excel.decodeBytes(bytes);

    final sheet = excel.tables[excel.tables.keys.first];
    if (sheet != null) {
      setState(() {
        _tableData = sheet.rows.map((row) {
          return row.map((cell) => cell?.value?.toString() ?? '').toList();
        }).toList();
        _selectedColumnIndices = [];
        _selectedColumns = [];
      });
    }
  }

  Future<void> _loadCsv(String path) async {
    final content = await File(path).readAsString();
    final rows = const CsvToListConverter().convert(content);

    setState(() {
      _tableData = rows.map((row) {
        return row.map((cell) => cell.toString()).toList();
      }).toList();
      _selectedColumnIndices = [];
      _selectedColumns = [];
    });
  }

  Future<void> _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null) {
      final text = clipboardData!.text!;
      
      // Parse tab-separated or comma-separated data
      final rows = text.split('\n').where((line) => line.trim().isNotEmpty).toList();
      
      setState(() {
        _tableData = rows.map((row) {
          // Try tab first, then comma
          if (row.contains('\t')) {
            return row.split('\t');
          } else {
            return row.split(',');
          }
        }).toList();
        _selectedColumnIndices = [];
        _selectedColumns = [];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daten eingefügt!')),
        );
      }
    }
  }

  // Returns the selected column data as a list of strings.
  // If multiple columns are selected, their values are concatenated per row with ' | ' as separator.
  List<String> getSelectedColumnData() {
    if (_selectedColumns.isEmpty) return [];

    // If exactly one column selected, return it directly
    if (_selectedColumns.length == 1) {
      return _selectedColumns.first;
    }

    // Multiple columns: combine values row-wise
    final maxRows = _selectedColumns.map((col) => col.length).reduce((a, b) => a > b ? a : b);
    final combined = <String>[];

    for (int row = 0; row < maxRows; row++) {
      final parts = <String>[];
      for (final col in _selectedColumns) {
        parts.add(row < col.length ? col[row] : '');
      }
      combined.add(parts.join(' | '));
    }

    return combined;
  }
}
