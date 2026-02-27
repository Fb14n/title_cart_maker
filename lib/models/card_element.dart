import 'package:flutter/material.dart';
import 'element_type.dart';

class CardElement {
  final String id;
  final ElementType type;
  final Offset position; // x, y in percent (0.0 - 1.0)
  final Size size; // width, height in percent (0.0 - 1.0)
  final dynamic data; // String: imagePath for image, text for text
  final TextStyle? textStyle;
  final TextAlign? textAlign;
  final String? placeholder; // Label for table mapping (e.g., "Spalte 1", "Spalte 2")
  final BoxFit? imageFit; // How image should fit in its box (contain or cover)
  final String? textVerticalAlign; // "top", "center", "bottom" – defaults to "center"
  
  CardElement({
    required this.id,
    required this.type,
    required this.position,
    required this.size,
    required this.data,
    this.textStyle,
    this.textAlign,
    this.placeholder,
    this.imageFit,
    this.textVerticalAlign,
  });
  
  CardElement copyWith({
    String? id,
    ElementType? type,
    Offset? position,
    Size? size,
    dynamic data,
    TextStyle? textStyle,
    TextAlign? textAlign,
    String? placeholder,
    BoxFit? imageFit,
    String? textVerticalAlign,
    bool clearTextVerticalAlign = false,
  }) {
    return CardElement(
      id: id ?? this.id,
      type: type ?? this.type,
      position: position ?? this.position,
      size: size ?? this.size,
      data: data ?? this.data,
      textStyle: textStyle ?? this.textStyle,
      textAlign: textAlign ?? this.textAlign,
      placeholder: placeholder ?? this.placeholder,
      imageFit: imageFit ?? this.imageFit,
      textVerticalAlign: clearTextVerticalAlign ? null : (textVerticalAlign ?? this.textVerticalAlign),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'position': {'dx': position.dx, 'dy': position.dy},
      'size': {'width': size.width, 'height': size.height},
      'data': data,
      'placeholder': placeholder,
      'imageFit': imageFit?.index,
      'textVerticalAlign': textVerticalAlign,
      'textStyle': textStyle != null ? {
        'fontSize': textStyle!.fontSize,
        'fontFamily': textStyle!.fontFamily,
        'color': textStyle!.color?.value,
        'fontWeight': textStyle!.fontWeight?.index,
        'fontStyle': textStyle!.fontStyle?.index,
        'decoration': textStyle!.decoration?.toString(),
      } : null,
      'textAlign': textAlign?.index,
    };
  }
  
  factory CardElement.fromJson(Map<String, dynamic> json) {
    return CardElement(
      id: json['id'],
      type: ElementType.values.firstWhere((e) => e.name == json['type']),
      position: Offset(json['position']['dx'], json['position']['dy']),
      size: Size(json['size']['width'], json['size']['height']),
      data: json['data'],
      placeholder: json['placeholder'],
      imageFit: json['imageFit'] != null ? BoxFit.values[json['imageFit']] : null,
      textVerticalAlign: json['textVerticalAlign'] as String?,
      textStyle: json['textStyle'] != null ? TextStyle(
        fontSize: json['textStyle']['fontSize'],
        fontFamily: json['textStyle']['fontFamily'],
        color: json['textStyle']['color'] != null 
            ? Color(json['textStyle']['color']) 
            : null,
        fontWeight: json['textStyle']['fontWeight'] != null
            ? FontWeight.values[json['textStyle']['fontWeight']]
            : null,
        fontStyle: json['textStyle']['fontStyle'] != null
            ? FontStyle.values[json['textStyle']['fontStyle']]
            : null,
        decoration: json['textStyle']['decoration']?.toString().contains('underline') == true
            ? TextDecoration.underline
            : null,
      ) : null,
      textAlign: json['textAlign'] != null 
          ? TextAlign.values[json['textAlign']] 
          : null,
    );
  }
}
