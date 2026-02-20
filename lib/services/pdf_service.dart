import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_picker/file_picker.dart';
import '../models/card_data.dart';
import '../models/layout_config.dart';
import '../models/card_element.dart';
import '../models/element_type.dart';

class PdfService {
  static Future<void> generateAndSavePdf({
    required List<CardData> cards,
    required LayoutConfig layoutConfig,
  }) async {
    final pdf = pw.Document();

    // A4 size in points (1 mm = 2.83465 points)
    const double mmToPoints = 2.83465;
    
    // Calculate cards per page
    final cardsPerPage = layoutConfig.totalCards;
    final numberOfPages = (cards.length / cardsPerPage).ceil().clamp(1, 100);

    // Process all cards and preload images
    final processedCards = await _preprocessCards(cards);

    // Create pages
    for (int pageIndex = 0; pageIndex < numberOfPages; pageIndex++) {
      final startIndex = pageIndex * cardsPerPage;
      final endIndex = (startIndex + cardsPerPage).clamp(0, cards.length);
      final cardsOnPage = processedCards.sublist(startIndex, endIndex);
      
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
              children: cardsOnPage.map((processedCard) {
                return _buildPdfCard(
                  processedCard: processedCard,
                  width: layoutConfig.cardWidth * mmToPoints,
                  height: layoutConfig.cardHeight * mmToPoints,
                );
              }).toList(),
            );
          },
        ),
      );
    }

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

  static Future<List<_ProcessedCard>> _preprocessCards(List<CardData> cards) async {
    final processed = <_ProcessedCard>[];
    
    for (final card in cards) {
      final layout = card.getEffectiveLayout();
      final elements = <_ProcessedElement>[];
      
      for (final element in layout.elements) {
        if (element.type == ElementType.image) {
          // Preload image
          final imagePath = element.data as String?;
          pw.ImageProvider? imageProvider;
          
          if (imagePath != null && imagePath.isNotEmpty) {
            try {
              final bytes = await File(imagePath).readAsBytes();
              imageProvider = pw.MemoryImage(bytes);
            } catch (e) {
              imageProvider = null;
            }
          }
          
          elements.add(_ProcessedElement(
            element: element,
            imageProvider: imageProvider,
          ));
        } else {
          elements.add(_ProcessedElement(element: element));
        }
      }
      
      processed.add(_ProcessedCard(
        backgroundColor: layout.backgroundColor,
        elements: elements,
      ));
    }
    
    return processed;
  }

  static pw.Widget _buildPdfCard({
    required _ProcessedCard processedCard,
    required double width,
    required double height,
  }) {
    return pw.Container(
      width: width,
      height: height,
      decoration: pw.BoxDecoration(
        color: processedCard.backgroundColor != null
            ? PdfColor.fromInt(processedCard.backgroundColor!.value)
            : PdfColors.white,
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Stack(
        children: processedCard.elements.map((processedElement) {
          return _buildPdfElement(
            processedElement: processedElement,
            cardWidth: width,
            cardHeight: height,
          );
        }).toList(),
      ),
    );
  }

  static pw.Widget _buildPdfElement({
    required _ProcessedElement processedElement,
    required double cardWidth,
    required double cardHeight,
  }) {
    final element = processedElement.element;
    final left = element.position.dx * cardWidth;
    final top = element.position.dy * cardHeight;
    final width = element.size.width * cardWidth;
    final height = element.size.height * cardHeight;

    return pw.Positioned(
      left: left,
      top: top,
      child: pw.Container(
        width: width,
        height: height,
        child: element.type == ElementType.image
            ? _buildPdfImage(processedElement, width, height)
            : _buildPdfText(element, width, height),
      ),
    );
  }

  static pw.Widget _buildPdfImage(_ProcessedElement processedElement, double width, double height) {
    if (processedElement.imageProvider != null) {
      // Convert Flutter BoxFit to PDF BoxFit
      final imageFit = processedElement.element.imageFit ?? BoxFit.contain;
      pw.BoxFit pdfBoxFit = pw.BoxFit.contain;
      
      if (imageFit == BoxFit.cover) {
        pdfBoxFit = pw.BoxFit.cover;
      } else if (imageFit == BoxFit.contain) {
        pdfBoxFit = pw.BoxFit.contain;
      } else if (imageFit == BoxFit.fill) {
        pdfBoxFit = pw.BoxFit.fill;
      }
      
      return pw.Image(
        processedElement.imageProvider!,
        fit: pdfBoxFit,
      );
    }
    return pw.Container(
      color: PdfColors.grey200,
    );
  }

  static pw.Widget _buildPdfText(CardElement element, double width, double height) {
    final text = element.data as String? ?? '';
    final textStyle = element.textStyle;
    
    // Convert Flutter TextAlign to PDF TextAlign and Alignment
    pw.TextAlign pdfTextAlign = pw.TextAlign.center;
    pw.Alignment containerAlignment = pw.Alignment.center;
    
    if (element.textAlign != null) {
      switch (element.textAlign!.index) {
        case 0: // left
          pdfTextAlign = pw.TextAlign.left;
          containerAlignment = pw.Alignment.centerLeft;
          break;
        case 1: // right
          pdfTextAlign = pw.TextAlign.right;
          containerAlignment = pw.Alignment.centerRight;
          break;
        case 2: // center
          pdfTextAlign = pw.TextAlign.center;
          containerAlignment = pw.Alignment.center;
          break;
        case 3: // justify
          pdfTextAlign = pw.TextAlign.justify;
          containerAlignment = pw.Alignment.centerLeft;
          break;
      }
    }
    
    // Check decoration
    bool isUnderlined = false;
    if (textStyle?.decoration != null) {
      isUnderlined = textStyle!.decoration == TextDecoration.underline;
    }
    
    // Determine the correct PDF font based on family, weight, and style
    pw.Font? pdfFont;
    final isBold = textStyle?.fontWeight == FontWeight.bold;
    final isItalic = textStyle?.fontStyle == FontStyle.italic;
    
    if (textStyle?.fontFamily != null) {
      final family = textStyle!.fontFamily!.toLowerCase();
      
      if (family.contains('times') || family.contains('georgia')) {
        // Times font family (Times New Roman, Georgia)
        if (isBold && isItalic) {
          pdfFont = pw.Font.timesBoldItalic();
        } else if (isBold) {
          pdfFont = pw.Font.timesBold();
        } else if (isItalic) {
          pdfFont = pw.Font.timesItalic();
        } else {
          pdfFont = pw.Font.times();
        }
      } else if (family.contains('courier')) {
        // Courier font family (Courier New)
        if (isBold && isItalic) {
          pdfFont = pw.Font.courierBoldOblique();
        } else if (isBold) {
          pdfFont = pw.Font.courierBold();
        } else if (isItalic) {
          pdfFont = pw.Font.courierOblique();
        } else {
          pdfFont = pw.Font.courier();
        }
      } else {
        // Helvetica (default for Arial, Verdana, Roboto, Comic Sans MS, Impact, Trebuchet MS)
        if (isBold && isItalic) {
          pdfFont = pw.Font.helveticaBoldOblique();
        } else if (isBold) {
          pdfFont = pw.Font.helveticaBold();
        } else if (isItalic) {
          pdfFont = pw.Font.helveticaOblique();
        } else {
          pdfFont = pw.Font.helvetica();
        }
      }
    } else {
      // No font family specified, use Helvetica as default
      if (isBold && isItalic) {
        pdfFont = pw.Font.helveticaBoldOblique();
      } else if (isBold) {
        pdfFont = pw.Font.helveticaBold();
      } else if (isItalic) {
        pdfFont = pw.Font.helveticaOblique();
      } else {
        pdfFont = pw.Font.helvetica();
      }
    }
    
    return pw.Container(
      width: width,
      height: height,
      padding: const pw.EdgeInsets.only(left: 4, top: 4, right: 6, bottom: 4),
      alignment: containerAlignment,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: pdfFont,
          fontSize: textStyle?.fontSize ?? 12,
          color: textStyle?.color != null
              ? PdfColor.fromInt(textStyle!.color!.value)
              : PdfColors.black,
          decoration: isUnderlined
              ? pw.TextDecoration.underline
              : null,
        ),
        textAlign: pdfTextAlign,
        maxLines: 100,
        softWrap: true,
      ),
    );
  }
}

class _ProcessedCard {
  final Color? backgroundColor;
  final List<_ProcessedElement> elements;

  _ProcessedCard({
    this.backgroundColor,
    required this.elements,
  });
}

class _ProcessedElement {
  final CardElement element;
  final pw.ImageProvider? imageProvider;

  _ProcessedElement({
    required this.element,
    this.imageProvider,
  });
}
