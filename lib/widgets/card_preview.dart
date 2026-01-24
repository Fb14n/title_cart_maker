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
    
    return Image.file(
      File(imagePath),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[100],
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          ),
        );
      },
    );
  }
  
  Widget _buildTextElement(CardElement element) {
    final text = element.data as String? ?? '';
    
    return Container(
      padding: const EdgeInsets.all(4),
      alignment: Alignment.center,
      child: Text(
        text.isEmpty ? 'Text hier...' : text,
        style: element.textStyle?.copyWith(
          fontSize: (element.textStyle?.fontSize ?? 16) * 0.625, // Scale down for preview
          color: text.isEmpty ? Colors.grey : element.textStyle?.color,
        ) ?? TextStyle(
          fontSize: 10,
          color: text.isEmpty ? Colors.grey : Colors.black,
        ),
        textAlign: element.textAlign ?? TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
