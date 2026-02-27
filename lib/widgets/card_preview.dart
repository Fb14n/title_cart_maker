import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../providers/project_provider.dart';
import '../models/card_data.dart';
import '../models/text_mode.dart';
import '../models/card_element.dart';
import '../models/element_type.dart';

class CardPreview extends StatelessWidget {
  final int index;
  final CardData cardData;
  final double width;
  final double height;

  const CardPreview({
    super.key,
    required this.index,
    required this.cardData,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final layout = cardData.getEffectiveLayout();
    
    return GestureDetector(
      onTap: () {
        // Select card for editing in right panel
        provider.setSelectedCardIndex(index);
      },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: layout.backgroundColor ?? Colors.white,
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Stack(
          children: layout.elements.map((element) {
            return _buildElement(element);
          }).toList(),
        ),
      ),
    );
  }
  
  Widget _buildElement(CardElement element) {
    final left = element.position.dx * width;
    final top = element.position.dy * height;
    final elementWidth = element.size.width * width;
    final elementHeight = element.size.height * height;
    
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
  
  Widget _buildImageElement(CardElement element) {
    final imagePath = element.data as String?;
    
    if (imagePath == null || imagePath.isEmpty) {
      return Container(
        color: Colors.grey[100],
        child: Center(
          child: Icon(
            Icons.add_photo_alternate,
            color: Colors.grey[400],
            size: 24,
          ),
        ),
      );
    }
    
    return ClipRect(
      child: Image.file(
        File(imagePath),
        fit: element.imageFit ?? BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[100],
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.grey),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildTextElement(CardElement element) {
    final text = element.data as String? ?? '';
    final displayText = text.isEmpty && element.placeholder != null 
        ? '[${element.placeholder}]' 
        : (text.isEmpty ? 'Text hier...' : text);
    final isPlaceholder = text.isEmpty && element.placeholder != null;
    
    // Map TextAlign to Container Alignment (horizontal only, vertical always centered)
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
      default:
        containerAlignment = Alignment.center;
    }

    final scaledStyle = element.textStyle?.copyWith(
      fontSize: (element.textStyle?.fontSize ?? 16) * 0.625,
      color: isPlaceholder
          ? Colors.blue
          : (text.isEmpty ? Colors.grey : element.textStyle?.color),
      fontStyle: isPlaceholder ? FontStyle.italic : element.textStyle?.fontStyle,
    ) ?? TextStyle(
      fontSize: 10,
      color: isPlaceholder ? Colors.blue : (text.isEmpty ? Colors.grey : Colors.black),
      fontStyle: isPlaceholder ? FontStyle.italic : null,
    );

    return Container(
      padding: const EdgeInsets.only(left: 4, top: 4, right: 6, bottom: 4),
      alignment: containerAlignment,
      decoration: isPlaceholder ? BoxDecoration(
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
        color: Colors.blue.withOpacity(0.05),
      ) : null,
      child: element.textVerticalAlign == 'bottom'
          ? LayoutBuilder(builder: (context, constraints) {
              final broken = CardPreview.breakBottomLonger(displayText, scaledStyle, constraints.maxWidth - 10);
              return Text(broken, style: scaledStyle, textAlign: textAlign, softWrap: true);
            })
          : Text(displayText, style: scaledStyle, textAlign: textAlign, softWrap: true),
    );
  }

  /// Finds a word-split point so the bottom line is wider than the top line.
  static String breakBottomLonger(String text, TextStyle style, double maxWidth) {
    if (text.contains('\n') || maxWidth <= 0) return text;
    final words = text.trim().split(RegExp(r' +'));
    if (words.length < 2) return text;

    // If the full text fits on one line, no split needed
    final tpFull = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '\u2026',
    )..layout(maxWidth: maxWidth);
    if (!tpFull.didExceedMaxLines) return text;

    String? best;
    double bestDiff = double.infinity;

    for (int i = 1; i < words.length; i++) {
      final top = words.sublist(0, i).join(' ');
      final bottom = words.sublist(i).join(' ');

      final tpBottom = TextPainter(
        text: TextSpan(text: bottom, style: style),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '\u2026',
      )..layout(maxWidth: maxWidth);

      if (tpBottom.didExceedMaxLines) break; // bottom no longer fits on one line

      final tpTop = TextPainter(
        text: TextSpan(text: top, style: style),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxWidth);

      final diff = tpBottom.width - tpTop.width;
      if (diff > 0 && diff < bestDiff) {
        bestDiff = diff;
        best = '$top\n$bottom';
      }
    }

    return best ?? text;
  }
}
