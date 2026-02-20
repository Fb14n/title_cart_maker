import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import '../models/card_data.dart';
import '../models/layout_config.dart';
import '../models/text_mode.dart';
import '../models/layout_mode.dart';
import '../models/card_layout.dart';
import '../models/element_type.dart';
import '../models/card_element.dart';
import '../models/project_data.dart';
import '../models/save_options.dart';

class ProjectProvider extends ChangeNotifier {
  LayoutConfig _layoutConfig = LayoutConfig();
  List<CardData> _cards = [];
  TextMode _textMode = TextMode.individual;
  String _globalText = '';
  String? _globalImagePath;
  
  // New layout system
  LayoutMode _layoutMode = LayoutMode.individual;
  CardLayout? _globalLayout;
  int _selectedCardIndex = 0; // Currently selected card in editor
  
  // Table data for text generation
  List<List<String>> _tableData = []; // Changed to support multiple columns

  LayoutConfig get layoutConfig => _layoutConfig;
  List<CardData> get cards => _cards;
  TextMode get textMode => _textMode;
  String get globalText => _globalText;
  String? get globalImagePath => _globalImagePath;
  
  // New getters
  LayoutMode get layoutMode => _layoutMode;
  CardLayout? get globalLayout => _globalLayout;
  int get selectedCardIndex => _selectedCardIndex;
  List<List<String>> get tableData => _tableData;

  ProjectProvider() {
    _initializeCards();
  }

  void _initializeCards() {
    _cards = List.generate(
      _layoutConfig.totalCards,
      (index) => CardData(),
    );
  }

  void updateLayoutConfig(LayoutConfig config) {
    final oldTotal = _layoutConfig.totalCards;
    _layoutConfig = config;
    
    if (config.totalCards != oldTotal) {
      if (config.totalCards > oldTotal) {
        // Add new cards
        _cards.addAll(
          List.generate(
            config.totalCards - oldTotal,
            (index) => CardData(
              text: _textMode == TextMode.global ? _globalText : '',
              imagePath: _textMode == TextMode.global ? _globalImagePath : null,
            ),
          ),
        );
      } else {
        // Remove excess cards
        _cards = _cards.sublist(0, config.totalCards);
      }
    }
    
    notifyListeners();
  }

  void updateCard(int index, CardData card) {
    if (index >= 0 && index < _cards.length) {
      _cards[index] = card;
      notifyListeners();
    }
  }

  void updateCardText(int index, String text) {
    if (index >= 0 && index < _cards.length) {
      _cards[index] = _cards[index].copyWith(text: text);
      notifyListeners();
    }
  }

  void updateCardImage(int index, String? imagePath) {
    if (index >= 0 && index < _cards.length) {
      _cards[index] = _cards[index].copyWith(imagePath: imagePath);
      notifyListeners();
    }
  }

  void setTextMode(TextMode mode) {
    _textMode = mode;
    
    if (mode == TextMode.global) {
      // Apply global text to all cards
      for (int i = 0; i < _cards.length; i++) {
        _cards[i] = _cards[i].copyWith(
          text: _globalText,
          imagePath: _globalImagePath,
        );
      }
    }
    
    notifyListeners();
  }

  void setGlobalText(String text) {
    _globalText = text;
    
    if (_textMode == TextMode.global) {
      for (int i = 0; i < _cards.length; i++) {
        _cards[i] = _cards[i].copyWith(text: text);
      }
    }
    
    notifyListeners();
  }

  void setGlobalImage(String? imagePath) {
    _globalImagePath = imagePath;
    
    if (_textMode == TextMode.global) {
      for (int i = 0; i < _cards.length; i++) {
        _cards[i] = _cards[i].copyWith(imagePath: imagePath);
      }
    }
    
    notifyListeners();
  }

  void importTextsFromList(List<String> texts) {
    _textMode = TextMode.imported;
    
    for (int i = 0; i < _cards.length && i < texts.length; i++) {
      _cards[i] = _cards[i].copyWith(text: texts[i]);
    }
    
    notifyListeners();
  }

  void clearAllCards() {
    for (int i = 0; i < _cards.length; i++) {
      _cards[i] = CardData();
    }
    notifyListeners();
  }
  
  // New layout mode methods
  void setLayoutMode(LayoutMode mode) {
    final oldMode = _layoutMode;
    _layoutMode = mode;
    
    if (mode == LayoutMode.global && oldMode == LayoutMode.individual) {
      // Switching to global: use first card's layout as template
      if (_cards.isNotEmpty) {
        _globalLayout = _cards[0].getEffectiveLayout();
        _applyGlobalLayout();
      }
    } else if (mode == LayoutMode.individual && oldMode == LayoutMode.global) {
      // Switching to individual: copy global layout to all cards
      if (_globalLayout != null) {
        for (int i = 0; i < _cards.length; i++) {
          _cards[i] = _cards[i].copyWith(layout: _globalLayout);
        }
      }
    }
    
    notifyListeners();
  }
  
  void setGlobalLayout(CardLayout layout) {
    _globalLayout = layout;
    
    if (_layoutMode == LayoutMode.global) {
      _applyGlobalLayout();
    }
    
    notifyListeners();
  }
  
  void _applyGlobalLayout() {
    if (_globalLayout != null) {
      for (int i = 0; i < _cards.length; i++) {
        _cards[i] = _cards[i].copyWith(layout: _globalLayout);
      }
    }
  }
  
  void updateCardLayout(int index, CardLayout layout) {
    if (index >= 0 && index < _cards.length) {
      _cards[index] = _cards[index].copyWith(layout: layout);
      notifyListeners();
    }
  }
  
  void setSelectedCardIndex(int index) {
    if (index >= 0 && index < _cards.length) {
      _selectedCardIndex = index;
      notifyListeners();
    }
  }
  
  CardLayout getCurrentEditingLayout() {
    if (_layoutMode == LayoutMode.global) {
      return _globalLayout ?? CardLayout();
    } else {
      return _cards[_selectedCardIndex].getEffectiveLayout();
    }
  }
  
  void updateCurrentEditingLayout(CardLayout layout) {
    if (_layoutMode == LayoutMode.global) {
      setGlobalLayout(layout);
    } else {
      updateCardLayout(_selectedCardIndex, layout);
    }
  }
  
  void setTableData(List<List<String>> data) {
    _tableData = data;
    notifyListeners();
  }
  
  void applyTableDataToCards() {
    if (_tableData.isEmpty) return;
    
    final numColumns = _tableData.length;
    final numRows = _tableData.first.length;
    
    // Calculate how many cards we need and add pages if necessary
    final cardsPerPage = _layoutConfig.totalCards;
    final pagesNeeded = (numRows / cardsPerPage).ceil();
    final currentPages = (_cards.length / cardsPerPage).ceil();
    
    // Get the global layout template BEFORE adding new cards
    final templateLayout = _layoutMode == LayoutMode.global && _globalLayout != null
        ? _globalLayout!
        : (_cards.isNotEmpty ? _cards[0].getEffectiveLayout() : CardLayout());
    
    // Add more pages if needed - initialize with template layout
    if (pagesNeeded > currentPages) {
      final additionalCards = (pagesNeeded * cardsPerPage) - _cards.length;
      for (int i = 0; i < additionalCards; i++) {
        // Create new card with template layout
        _cards.add(CardData(layout: templateLayout));
      }
    }
    
    // Find all text elements with placeholders
    final placeholderElements = templateLayout.elements
        .where((e) => e.type == ElementType.text && e.placeholder != null)
        .toList();
    
    // Apply to each card
    for (int cardIndex = 0; cardIndex < _cards.length && cardIndex < numRows; cardIndex++) {
      // Always start from template layout to ensure consistency
      final layout = templateLayout;
      final updatedElements = <CardElement>[];
      
      // Keep non-text elements and text elements without placeholders from template
      updatedElements.addAll(
        layout.elements.where((e) => 
          e.type != ElementType.text || e.placeholder == null)
      );
      
      // Update or create elements based on placeholders
      for (int colIndex = 0; colIndex < numColumns; colIndex++) {
        final text = cardIndex < _tableData[colIndex].length 
            ? _tableData[colIndex][cardIndex] 
            : '';
        
        // Find if there's already a placeholder element for this column
        CardElement? existingElement;
        for (var elem in placeholderElements) {
          // Check if placeholder matches column index (e.g., "Spalte 1" or just contains the number)
          final placeholder = elem.placeholder!.toLowerCase();
          if (placeholder.contains('spalte ${colIndex + 1}') || 
              placeholder == 'spalte ${colIndex + 1}' ||
              placeholder == '${colIndex + 1}') {
            existingElement = elem;
            break;
          }
        }
        
        if (existingElement != null) {
          // Use existing positioned element
          updatedElements.add(existingElement.copyWith(
            data: text,
            id: 'tbl_${existingElement.id}_$cardIndex',
          ));
        } else if (colIndex < placeholderElements.length) {
          // Use placeholder by index
          final placeholderElem = placeholderElements[colIndex];
          updatedElements.add(placeholderElem.copyWith(
            data: text,
            id: 'tbl_${placeholderElem.id}_$cardIndex',
          ));
        }
      }
      
      final newLayout = layout.copyWith(elements: updatedElements);
      _cards[cardIndex] = _cards[cardIndex].copyWith(layout: newLayout);
    }
    
    notifyListeners();
  }
  
  void addMoreCards(int count) {
    _cards.addAll(
      List.generate(
        count,
        (index) => CardData(
          text: _textMode == TextMode.global ? _globalText : '',
          imagePath: _textMode == TextMode.global ? _globalImagePath : null,
        ),
      ),
    );
    notifyListeners();
  }
  
  // Save and Load functionality
  Future<void> saveProject(String filePath, SaveOptions options) async {
    try {
      final projectData = ProjectData(
        version: '1.0',
        layoutConfig: options.saveLayout ? _layoutConfig : null,
        cards: options.saveCardContent ? _cards : null,
        textMode: options.saveGlobalSettings ? _textMode : null,
        layoutMode: options.saveGlobalSettings ? _layoutMode : null,
        globalText: options.saveGlobalSettings ? _globalText : null,
        globalImagePath: options.saveGlobalSettings ? _globalImagePath : null,
        globalLayout: options.saveGlobalSettings ? _globalLayout : null,
        tableData: options.saveTableData ? _tableData : null,
        embeddedImagePaths: options.saveImages ? await _collectImagePaths() : null,
      );
      
      final jsonString = projectData.toJsonString();
      final file = File(filePath);
      await file.writeAsString(jsonString, flush: true);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving project: $e');
      }
      rethrow;
    }
  }
  
  Future<void> loadProject(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final projectData = ProjectData.fromJsonString(jsonString);
      
      // Apply loaded data
      if (projectData.layoutConfig != null) {
        updateLayoutConfig(projectData.layoutConfig!);
      }
      
      if (projectData.cards != null) {
        _cards = projectData.cards!;
      }
      
      if (projectData.textMode != null) {
        _textMode = projectData.textMode!;
      }
      
      if (projectData.layoutMode != null) {
        _layoutMode = projectData.layoutMode!;
      }
      
      if (projectData.globalText != null) {
        _globalText = projectData.globalText!;
      }
      
      if (projectData.globalImagePath != null) {
        _globalImagePath = projectData.globalImagePath;
      }
      
      if (projectData.globalLayout != null) {
        _globalLayout = projectData.globalLayout;
      }
      
      if (projectData.tableData != null) {
        _tableData = projectData.tableData!;
      }
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading project: $e');
      }
      rethrow;
    }
  }
  
  Future<List<String>> _collectImagePaths() async {
    final imagePaths = <String>[];
    
    // Collect from global
    if (_globalImagePath != null && _globalImagePath!.isNotEmpty) {
      imagePaths.add(_globalImagePath!);
    }
    
    // Collect from cards
    for (final card in _cards) {
      final layout = card.getEffectiveLayout();
      for (final element in layout.elements) {
        if (element.type == ElementType.image && element.data is String) {
          final path = element.data as String;
          if (path.isNotEmpty && !imagePaths.contains(path)) {
            imagePaths.add(path);
          }
        }
      }
    }
    
    return imagePaths;
  }
}
