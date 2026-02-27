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
  }) async {
    // Calculate dimensions based on options
    double pageWidthMm;
    double pageHeightMm;
    
    if (options.pageSize == PageSize.a4) {
      pageWidthMm = 210.0;
      pageHeightMm = 297.0;
    } else {
      pageWidthMm = options.customWidth!;
      pageHeightMm = options.customHeight!;
    }
    
    // Convert mm to pixels based on DPI
    final double mmToPixels = options.dpi / 25.4;
    final double pageWidth = pageWidthMm * mmToPixels;
    final double pageHeight = pageHeightMm * mmToPixels;
    
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
        
        // Create the widget to render
        final widget = _buildPageWidget(
          cardsOnPage: cardsOnPage,
          layoutConfig: layoutConfig,
          pageWidth: pageWidth,
          pageHeight: pageHeight,
          mmToPixels: mmToPixels,
        );
        
        // Render to image
        final image = await _widgetToImage(widget, pageWidth, pageHeight);
        
        // Save to file
        final extension = options.format == ImageFormat.png ? 'png' : 'jpg';
        final fileName = 'title_cards_page_${pageIndex + 1}.$extension';
        final filePath = '$outputDir${Platform.pathSeparator}$fileName';
        final file = File(filePath);
        
        // Convert to bytes
        if (options.format == ImageFormat.jpg) {
          // For JPG: convert to PNG first (Flutter doesn't support direct JPG encoding)
          // In production, use the 'image' package for proper JPG encoding
          final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          await file.writeAsBytes(byteData!.buffer.asUint8List());
        } else {
          final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          await file.writeAsBytes(byteData!.buffer.asUint8List());
        }
        
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
  
  static Widget _buildPageWidget({
    required List<CardData> cardsOnPage,
    required LayoutConfig layoutConfig,
    required double pageWidth,
    required double pageHeight,
    required double mmToPixels,
  }) {
    return SizedBox(
      width: pageWidth,
      height: pageHeight,
      child: Container(
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.only(
            left: layoutConfig.marginLeft * mmToPixels,
            right: layoutConfig.marginRight * mmToPixels,
            top: layoutConfig.marginTop * mmToPixels,
            bottom: layoutConfig.marginBottom * mmToPixels,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: layoutConfig.columns,
                  childAspectRatio: layoutConfig.cardWidth / layoutConfig.cardHeight,
                  crossAxisSpacing: layoutConfig.horizontalSpacing * mmToPixels,
                  mainAxisSpacing: layoutConfig.verticalSpacing * mmToPixels,
                ),
                itemCount: cardsOnPage.length,
                itemBuilder: (context, index) {
                  return _buildCard(
                    cardData: cardsOnPage[index],
                    width: layoutConfig.cardWidth * mmToPixels,
                    height: layoutConfig.cardHeight * mmToPixels,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
  
  static Widget _buildCard({
    required CardData cardData,
    required double width,
    required double height,
  }) {
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
          : _buildTextElement(element),
    );
  }
  
  static Widget _buildImageElement(CardElement element) {
    final imagePath = element.data as String?;
    
    if (imagePath == null || imagePath.isEmpty) {
      return Container(color: Colors.grey[100]);
    }
    
    return Image.file(
      File(imagePath),
      fit: element.imageFit ?? BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(color: Colors.grey[100]);
      },
    );
  }
  
  static Widget _buildTextElement(CardElement element) {
    final text = element.data as String? ?? '';
    if (text.isEmpty) return Container();
    
    // Map TextAlign to Container Alignment
    Alignment containerAlignment;
    final textAlign = element.textAlign ?? TextAlign.center;
    switch (textAlign) {
      case TextAlign.left:
      case TextAlign.start:
        containerAlignment = Alignment.centerLeft;
        break;
      case TextAlign.right:
      case TextAlign.end:
        containerAlignment = Alignment.centerRight;
        break;
      case TextAlign.center:
        containerAlignment = Alignment.center;
        break;
      case TextAlign.justify:
        containerAlignment = Alignment.centerLeft;
        break;
    }
    
    final style = element.textStyle ?? const TextStyle(fontSize: 16, color: Colors.black);

    return Container(
      padding: const EdgeInsets.only(left: 4, top: 4, right: 6, bottom: 4),
      alignment: containerAlignment,
      child: element.textVerticalAlign == 'bottom'
          ? LayoutBuilder(builder: (context, constraints) {
              final broken = CardPreview.breakBottomLonger(text, style, constraints.maxWidth - 10);
              return Text(broken, style: style, textAlign: textAlign, softWrap: true);
            })
          : Text(text, style: style, textAlign: textAlign, softWrap: true),
    );
  }
  
  static Future<ui.Image> _widgetToImage(Widget widget, double width, double height) async {
    final RenderRepaintBoundary repaintBoundary = RenderRepaintBoundary();

    // Versionssichere Offscreen-Render-Pipeline:
    // Statt ViewConfiguration manuell zu bauen (API driftet zwischen Flutter-Versionen),
    // verwenden wir die Configuration des aktuellen FlutterView und steuern die Zielgr f6 dfe  fcber pixelRatio.
    final ui.FlutterView flutterView = ui.PlatformDispatcher.instance.views.first;

    final RenderView renderView = RenderView(
      view: flutterView,
      configuration: const ViewConfiguration(devicePixelRatio: 1.0),
      child: RenderPositionedBox(
        alignment: Alignment.center,
        // Das Boundary lebt im RenderTree und wird danach mit einem Widget-Tree befüllt.
        child: repaintBoundary,
      ),
    );

    final PipelineOwner pipelineOwner = PipelineOwner();
    final BuildOwner buildOwner = BuildOwner(focusManager: FocusManager());

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final RenderObjectToWidgetElement<RenderBox> rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: SizedBox(
            width: width,
            height: height,
            child: widget,
          ),
        ),
      ),
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();

    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    // Skaliere das Ergebnis so, dass wir ungef e4r auf die gew fcnschte Pixelgr f6 dfe kommen.
    final double viewLogicalWidth = flutterView.physicalSize.width / flutterView.devicePixelRatio;
    final double viewLogicalHeight = flutterView.physicalSize.height / flutterView.devicePixelRatio;
    final double ratioX = viewLogicalWidth > 0 ? (width / viewLogicalWidth) : 1.0;
    final double ratioY = viewLogicalHeight > 0 ? (height / viewLogicalHeight) : 1.0;
    final double pixelRatio = (ratioX < ratioY ? ratioX : ratioY).clamp(0.01, 10.0);

    final ui.Image image = await repaintBoundary.toImage(pixelRatio: pixelRatio);
    return image;
  }
}
