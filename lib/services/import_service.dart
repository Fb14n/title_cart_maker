import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as excel_pkg;

class ImportService {
  static Future<List<String>> importFromCsv(String filePath) async {
    final file = File(filePath);
    final contents = await file.readAsString();
    
    final List<List<dynamic>> rows = const CsvToListConverter().convert(contents);
    
    if (rows.isEmpty) {
      return [];
    }
    
    // Extract first column
    return rows.map((row) => row.isNotEmpty ? row[0].toString() : '').toList();
  }

  static Future<List<String>> importFromExcel(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final excelFile = excel_pkg.Excel.decodeBytes(bytes);
    
    final List<String> texts = [];
    
    // Get first sheet
    if (excelFile.tables.isNotEmpty) {
      final sheetName = excelFile.tables.keys.first;
      final sheet = excelFile.tables[sheetName];
      
      if (sheet != null) {
        for (var row in sheet.rows) {
          if (row.isNotEmpty && row[0] != null) {
            texts.add(row[0]!.value.toString());
          }
        }
      }
    }
    
    return texts;
  }

  static Future<List<String>> importTexts(String filePath) async {
    final extension = filePath.split('.').last.toLowerCase();
    
    if (extension == 'csv') {
      return importFromCsv(filePath);
    } else if (extension == 'xlsx' || extension == 'xls') {
      return importFromExcel(filePath);
    }
    
    throw Exception('Unsupported file format: $extension');
  }
}
