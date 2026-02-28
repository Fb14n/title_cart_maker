import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:file_picker/file_picker.dart';
import 'package:title_card_maker/models/card_data.dart';
import 'package:title_card_maker/models/layout_config.dart';
import 'package:title_card_maker/models/card_element.dart';
import 'package:title_card_maker/models/element_type.dart';
import 'package:title_card_maker/models/image_export_options.dart';
import 'package:title_card_maker/widgets/card_preview.dart';

class ImageService {
  static Future<void> generateAndSaveImages({
    required List<CardData> cards,
    required LayoutConfig layoutConfig,
    required BuildContext context,
    required ImageExportOptions options,
    required Set<int> selectedIndices,
  }) async {
    // Page dimensions in mm
    double pageWidthMm;
    double pageHeightMm;
    
    if (options.pageSize == PageSize.a4) {
      pageWidthMm = 210.0;
      pageHeightMm = 297.0;
    } else {
      pageWidthMm = options.customWidth!;
      pageHeightMm = options.customHeight!;
    }
    
    // Pixel ratio: output pixels per mm (avoids oversized logical dimensions
    // that would exceed the off-screen RenderView's viewport and produce a
    // zero-size repaint boundary → "invalid image dimensions").
    final double pixelsPerMm = options.dpi / 25.4;
    
    // Calculate cards per page
    final cardsPerPage = layoutConfig.totalCards;
    final numberOfPages = (cards.length / cardsPerPage).ceil().clamp(1, 100);
    
    // Ask user for save location
    final outputDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Export Ordner wählen',
    );
    
    if (outputDir == null) return; // User cancelled
    
    // Show progress
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Exportiere Bilder...'),
            ],
          ),
        ),
      );
    }
    
    try {
      // Generate each page as image
      for (int pageIndex = 0; pageIndex < numberOfPages; pageIndex++) {
        final startIndex = pageIndex * cardsPerPage;
        final endIndex = (startIndex + cardsPerPage).clamp(0, cards.length);
        final cardsOnPage = cards.sublist(startIndex, endIndex);
        
        // Build widget at mm-scale (1 logical unit = 1 mm).
        // The repaint boundary stays well within any screen viewport,
        // and pixelsPerMm scales it to the desired DPI output.
        final widget = _buildPageWidget(
          cardsOnPage: cardsOnPage,
          layoutConfig: layoutConfig,
          pageWidth: pageWidthMm,
          pageHeight: pageHeightMm,
          mmToPixels: 1.0,
          startIndex: startIndex,
          selectedIndices: selectedIndices,
        );
        
        // Render to image at target DPI
        final image = await _widgetToImage(widget, pageWidthMm, pageHeightMm, pixelsPerMm);
        
        // Save to file
        final extension = options.format == ImageFormat.png ? 'png' : 'jpg';
        final fileName = 'title_cards_page_${pageIndex + 1}.$extension';
        final filePath = '$outputDir${Platform.pathSeparator}$fileName';
        final file = File(filePath);
        
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        await file.writeAsBytes(byteData!.buffer.asUint8List());
        
        image.dispose();
      }
      
      if (context.mounted) {
        Navigator.pop(context); // Close progress dialog
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close progress dialog
      }
      rethrow;
    }
  }
  
  static const double _mmToPoints = 2.83465; // 1 mm = 2.83465 PDF points

  static Widget _buildPageWidget({
    required List<CardData> cardsOnPage,
    required LayoutConfig layoutConfig,
    required double pageWidth,
    required double pageHeight,
    required double mmToPixels,
    int startIndex = 0,
    Set<int>? selectedIndices,
  }) {
    final cols = layoutConfig.columns;

    // Use config card dimensions directly – mirrors pdf_service which uses
    // layoutConfig.cardWidth * mmToPoints for both card container and element sizing.
    final cardW = layoutConfig.cardWidth * mmToPixels;
    final cardH = layoutConfig.cardHeight * mmToPixels;
    final hSpacing = layoutConfig.horizontalSpacing * mmToPixels;
    final vSpacing = layoutConfig.verticalSpacing * mmToPixels;
    final totalRows = (cardsOnPage.length / cols).ceil();

    final rows = <Widget>[];
    for (int r = 0; r < totalRows; r++) {
      final rowChildren = <Widget>[];
      for (int c = 0; c < cols; c++) {
        final idx = r * cols + c;
        if (c > 0) rowChildren.add(SizedBox(width: hSpacing));
        if (idx < cardsOnPage.length) {
          final globalIndex = startIndex + idx;
          final isSelected = selectedIndices == null || selectedIndices.contains(globalIndex);
          rowChildren.add(_buildCard(
            cardData: cardsOnPage[idx],
            width: cardW,
            height: cardH,
            isSelected: isSelected,
          ));
        } else {
          rowChildren.add(SizedBox(width: cardW, height: cardH));
        }
      }
      if (r > 0) rows.add(SizedBox(height: vSpacing));
      rows.add(Row(mainAxisSize: MainAxisSize.min, children: rowChildren));
    }

    return SizedBox(
      width: pageWidth * mmToPixels,
      height: pageHeight * mmToPixels,
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.only(
          left: layoutConfig.marginLeft * mmToPixels,
          right: layoutConfig.marginRight * mmToPixels,
          top: layoutConfig.marginTop * mmToPixels,
          bottom: layoutConfig.marginBottom * mmToPixels,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rows,
        ),
      ),
    );
  }
  
  static Widget _buildCard({
    required CardData cardData,
    required double width,
    required double height,
    bool isSelected = true,
  }) {
    if (!isSelected) {
      return SizedBox(width: width, height: height);
    }
    final layout = cardData.getEffectiveLayout();
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: layout.backgroundColor ?? Colors.white,
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        children: layout.elements.map((element) {
          return _buildElement(element, width, height);
        }).toList(),
      ),
    );
  }
  
  static Widget _buildElement(CardElement element, double cardWidth, double cardHeight) {
    final left = element.position.dx * cardWidth;
    final top = element.position.dy * cardHeight;
    final elementWidth = element.size.width * cardWidth;
    final elementHeight = element.size.height * cardHeight;
    
    return Positioned(
      left: left,
      top: top,
      width: elementWidth,
      height: elementHeight,
      child: element.type == ElementType.image
          ? _buildImageElement(element)
          : _buildTextElement(element, elementWidth),
    );
  }
  
  static Widget _buildImageElement(CardElement element) {
    final imagePath = element.data as String?;
    
    if (imagePath == null || imagePath.isEmpty) {
      return Container(color: Colors.grey[100]);
    }
    
    return ClipRect(
      child: Image.file(
        File(imagePath),
        fit: element.imageFit ?? BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(color: Colors.grey[100]);
        },
      ),
    );
  }
  
  static Widget _buildTextElement(CardElement element, double elementWidth) {
    final text = element.data as String? ?? '';
    if (text.isEmpty) return Container();
    
    final textAlign = element.textAlign ?? TextAlign.center;
    Alignment containerAlignment;
    switch (textAlign) {
      case TextAlign.left:
      case TextAlign.start:
      case TextAlign.justify:
        containerAlignment = Alignment.centerLeft;
        break;
      case TextAlign.right:
      case TextAlign.end:
        containerAlignment = Alignment.centerRight;
        break;
      case TextAlign.center:
        containerAlignment = Alignment.center;
    }

    // Convert font size from typographic points to mm.
    // 1pt = 1/_mmToPoints mm — identical conversion to what pdf_service uses in PDF space.
    final baseStyle = element.textStyle ?? const TextStyle(fontSize: 16, color: Colors.black);
    final style = baseStyle.copyWith(
      fontSize: (baseStyle.fontSize ?? 16) / _mmToPoints,
    );

    // Padding mirrors pdf_service: left 4pt, right 6pt, top/bottom 4pt.
    // breakBottomLonger gets container inner width = elementWidth - (4+6)pt in mm.
    final displayText = element.textVerticalAlign == 'bottom'
        ? CardPreview.breakBottomLonger(text, style, elementWidth - 10.0 / _mmToPoints)
        : text;

    return Container(
      padding: EdgeInsets.fromLTRB(
        4.0 / _mmToPoints, 4.0 / _mmToPoints,
        6.0 / _mmToPoints, 4.0 / _mmToPoints,
      ),
      alignment: containerAlignment,
      child: Text(displayText, style: style, textAlign: textAlign, softWrap: true),
    );
  }
  
  static Future<ui.Image> _widgetToImage(Widget widget, double width, double height, double pixelRatio) async {
    final repaintBoundary = RenderRepaintBoundary();
    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());

    // Attach as pipeline root WITHOUT a RenderView so that the logical size is
    // determined purely by our explicit layout constraints – completely
    // independent of the app window's physical dimensions (avoids the
    // "invalid image dimensions" crash when physicalSize == Size.zero or
    // when target pixel dimensions exceed the screen viewport).
    pipelineOwner.rootNode = repaintBoundary;

    final RenderObjectToWidgetElement<RenderBox> rootElement =
        RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: SizedBox(width: width, height: height, child: widget),
        ),
      ),
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();

    // Force the whole subtree to lay out at exactly (width × height).
    repaintBoundary.layout(
      BoxConstraints.tightFor(width: width, height: height),
      parentUsesSize: false,
    );

    // Attach an OffsetLayer so that flushPaint() can render into it.
    final rootLayer = OffsetLayer();
    rootLayer.attach(pipelineOwner);
    repaintBoundary.scheduleInitialPaint(rootLayer);

    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    return repaintBoundary.toImage(pixelRatio: pixelRatio);
  }
}