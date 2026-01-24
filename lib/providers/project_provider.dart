import 'package:flutter/foundation.dart';
import '../models/card_data.dart';
import '../models/layout_config.dart';
import '../models/text_mode.dart';
import '../models/layout_mode.dart';
import '../models/card_layout.dart';
import '../models/element_type.dart';

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
    
    for (int cardIndex = 0; cardIndex < _cards.length && cardIndex < numRows; cardIndex++) {
      final layout = _cards[cardIndex].getEffectiveLayout();
      final updatedElements = <CardElement>[];
      
      // Keep non-text elements (images, etc)
      updatedElements.addAll(
        layout.elements.where((e) => e.type != ElementType.text)
      );
      
      // Add text elements for each selected column
      for (int colIndex = 0; colIndex < numColumns; colIndex++) {
        final text = cardIndex < _tableData[colIndex].length 
            ? _tableData[colIndex][cardIndex] 
            : '';
        
        // Calculate position based on column index
        final yOffset = 0.1 + (colIndex * 0.25);
        
        updatedElements.add(CardElement(
          id: 'tbl_txt_${DateTime.now().millisecondsSinceEpoch}_$colIndex',
          type: ElementType.text,
          position: Offset(0.1, yOffset.clamp(0.0, 0.7)),
          size: const Size(0.8, 0.2),
          data: text,
          textStyle: const TextStyle(fontSize: 16, color: Colors.black),
          textAlign: TextAlign.center,
        ));
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
}
