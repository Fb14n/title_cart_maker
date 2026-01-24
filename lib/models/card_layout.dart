import 'package:flutter/material.dart';
import 'card_element.dart';
import 'element_type.dart';

class CardLayout {
  final Color? backgroundColor;
  final List<CardElement> elements;
  
  CardLayout({
    this.backgroundColor,
    List<CardElement>? elements,
  }) : elements = elements ?? [];
  
  CardLayout copyWith({
    Color? backgroundColor,
    List<CardElement>? elements,
  }) {
    return CardLayout(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      elements: elements ?? this.elements,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'backgroundColor': backgroundColor?.value,
      'elements': elements.map((e) => e.toJson()).toList(),
    };
  }
  
  factory CardLayout.fromJson(Map<String, dynamic> json) {
    return CardLayout(
      backgroundColor: json['backgroundColor'] != null 
          ? Color(json['backgroundColor']) 
          : null,
      elements: (json['elements'] as List?)
          ?.map((e) => CardElement.fromJson(e))
          .toList() ?? [],
    );
  }
  
  // Create default layout from old CardData format
  factory CardLayout.fromLegacyCardData({
    String? imagePath,
    String? text,
  }) {
    final elements = <CardElement>[];
    
    // Add image element if exists (60% height at top)
    if (imagePath != null && imagePath.isNotEmpty) {
      elements.add(CardElement(
        id: 'legacy_image',
        type: ElementType.image,
        position: const Offset(0, 0),
        size: const Size(1.0, 0.6),
        data: imagePath,
      ));
    }
    
    // Add text element (40% height at bottom, or full height if no image)
    final textTop = imagePath != null && imagePath.isNotEmpty ? 0.6 : 0.0;
    final textHeight = imagePath != null && imagePath.isNotEmpty ? 0.4 : 1.0;
    
    elements.add(CardElement(
      id: 'legacy_text',
      type: ElementType.text,
      position: Offset(0, textTop),
      size: Size(1.0, textHeight),
      data: text ?? '',
      textStyle: const TextStyle(
        fontSize: 16,
        color: Colors.black,
      ),
      textAlign: TextAlign.center,
    ));
    
    return CardLayout(elements: elements);
  }
}
