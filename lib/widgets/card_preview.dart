import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:title_card_maker/providers/project_provider.dart';
import 'package:title_card_maker/models/card_data.dart';
import 'package:title_card_maker/models/text_mode.dart';
import 'package:title_card_maker/models/card_element.dart';
import 'package:title_card_maker/models/element_type.dart';

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
    
    return Container(
      padding: const EdgeInsets.only(left: 4, top: 4, right: 6, bottom: 4),
      alignment: containerAlignment,
      decoration: isPlaceholder ? BoxDecoration(
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
        color: Colors.blue.withOpacity(0.05),
      ) : null,
      child: Text(
        displayText,
        style: element.textStyle?.copyWith(
          fontSize: (element.textStyle?.fontSize ?? 16) * 0.625, // Scale down for preview
          color: isPlaceholder 
              ? Colors.blue 
              : (text.isEmpty ? Colors.grey : element.textStyle?.color),
          fontStyle: isPlaceholder ? FontStyle.italic : element.textStyle?.fontStyle,
        ) ?? TextStyle(
          fontSize: 10,
          color: isPlaceholder ? Colors.blue : (text.isEmpty ? Colors.grey : Colors.black),
          fontStyle: isPlaceholder ? FontStyle.italic : null,
        ),
        textAlign: textAlign,
        softWrap: true,
      ),
    );
  }
}
