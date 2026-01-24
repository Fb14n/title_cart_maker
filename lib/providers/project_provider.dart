import 'package:flutter/foundation.dart';
import '../models/card_data.dart';
import '../models/layout_config.dart';
import '../models/text_mode.dart';

class ProjectProvider extends ChangeNotifier {
  LayoutConfig _layoutConfig = LayoutConfig();
  List<CardData> _cards = [];
  TextMode _textMode = TextMode.individual;
  String _globalText = '';
  String? _globalImagePath;

  LayoutConfig get layoutConfig => _layoutConfig;
  List<CardData> get cards => _cards;
  TextMode get textMode => _textMode;
  String get globalText => _globalText;
  String? get globalImagePath => _globalImagePath;

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
}
