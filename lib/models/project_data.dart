import 'dart:convert';
import 'package:flutter/material.dart';
import 'card_data.dart';
import 'layout_config.dart';
import 'text_mode.dart';
import 'layout_mode.dart';
import 'card_layout.dart';

class ProjectData {
  final String version;
  final LayoutConfig? layoutConfig;
  final List<CardData>? cards;
  final TextMode? textMode;
  final LayoutMode? layoutMode;
  final String? globalText;
  final String? globalImagePath;
  final CardLayout? globalLayout;
  final List<List<String>>? tableData;
  final List<String>? embeddedImagePaths; // Base64 encoded images
  
  ProjectData({
    this.version = '1.0',
    this.layoutConfig,
    this.cards,
    this.textMode,
    this.layoutMode,
    this.globalText,
    this.globalImagePath,
    this.globalLayout,
    this.tableData,
    this.embeddedImagePaths,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'layoutConfig': layoutConfig?.toJson(),
      'cards': cards?.map((c) => c.toJson()).toList(),
      'textMode': textMode?.toString(),
      'layoutMode': layoutMode?.toString(),
      'globalText': globalText,
      'globalImagePath': globalImagePath,
      'globalLayout': globalLayout?.toJson(),
      'tableData': tableData,
      'embeddedImagePaths': embeddedImagePaths,
    };
  }
  
  factory ProjectData.fromJson(Map<String, dynamic> json) {
    return ProjectData(
      version: json['version'] ?? '1.0',
      layoutConfig: json['layoutConfig'] != null 
          ? LayoutConfig.fromJson(json['layoutConfig'])
          : null,
      cards: json['cards'] != null
          ? (json['cards'] as List).map((c) => CardData.fromJson(c)).toList()
          : null,
      textMode: json['textMode'] != null
          ? TextMode.values.firstWhere(
              (e) => e.toString() == json['textMode'],
              orElse: () => TextMode.individual,
            )
          : null,
      layoutMode: json['layoutMode'] != null
          ? LayoutMode.values.firstWhere(
              (e) => e.toString() == json['layoutMode'],
              orElse: () => LayoutMode.individual,
            )
          : null,
      globalText: json['globalText'],
      globalImagePath: json['globalImagePath'],
      globalLayout: json['globalLayout'] != null
          ? CardLayout.fromJson(json['globalLayout'])
          : null,
      tableData: json['tableData'] != null
          ? (json['tableData'] as List).map((row) => List<String>.from(row)).toList()
          : null,
      embeddedImagePaths: json['embeddedImagePaths'] != null
          ? List<String>.from(json['embeddedImagePaths'])
          : null,
    );
  }
  
  String toJsonString() {
    return jsonEncode(toJson());
  }
  
  factory ProjectData.fromJsonString(String jsonString) {
    return ProjectData.fromJson(jsonDecode(jsonString));
  }
}
