import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import '../models/card_data.dart';
import '../models/layout_config.dart';

class PdfService {
  static Future<void> generateAndSavePdf({
    required List<CardData> cards,
    required LayoutConfig layoutConfig,
  }) async {
    final pdf = pw.Document();

    // A4 size in points (1 mm = 2.83465 points)
    const double mmToPoints = 2.83465;
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.only(
          left: layoutConfig.marginLeft * mmToPoints,
          right: layoutConfig.marginRight * mmToPoints,
          top: layoutConfig.marginTop * mmToPoints,
          bottom: layoutConfig.marginBottom * mmToPoints,
        ),
        build: (context) {
          return pw.GridView(
            crossAxisCount: layoutConfig.columns,
            childAspectRatio: layoutConfig.cardWidth / layoutConfig.cardHeight,
            crossAxisSpacing: layoutConfig.horizontalSpacing * mmToPoints,
            mainAxisSpacing: layoutConfig.verticalSpacing * mmToPoints,
            children: cards.map((card) {
              return _buildPdfCard(
                card: card,
                width: layoutConfig.cardWidth * mmToPoints,
                height: layoutConfig.cardHeight * mmToPoints,
              );
            }).toList(),
          );
        },
      ),
    );

    // Save PDF
    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'PDF speichern',
      fileName: 'title_cards_${DateTime.now().millisecondsSinceEpoch}.pdf',
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (outputPath != null) {
      final file = File(outputPath);
      await file.writeAsBytes(await pdf.save());
    }
  }

  static pw.Widget _buildPdfCard({
    required CardData card,
    required double width,
    required double height,
  }) {
    return pw.Container(
      width: width,
      height: height,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        children: [
          // Image area
          pw.Expanded(
            flex: 3,
            child: card.imagePath != null
                ? pw.FutureBuilder<pw.ImageProvider>(
                    future: _loadImage(card.imagePath!),
                    builder: (context, imageData) {
                      if (imageData != null) {
                        return pw.Image(imageData, fit: pw.BoxFit.cover);
                      }
                      return pw.Container(color: PdfColors.grey100);
                    },
                  )
                : pw.Container(color: PdfColors.grey100),
          ),
          
          // Text area
          pw.Expanded(
            flex: 2,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(4),
              alignment: pw.Alignment.center,
              child: pw.Text(
                card.text,
                style: const pw.TextStyle(fontSize: 10),
                textAlign: pw.TextAlign.center,
                maxLines: 3,
                overflow: pw.TextOverflow.clip,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<pw.ImageProvider> _loadImage(String path) async {
    final file = File(path);
    final bytes = await file.readAsBytes();
    return pw.MemoryImage(bytes);
  }
}
