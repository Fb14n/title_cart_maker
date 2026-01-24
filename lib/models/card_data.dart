import 'card_layout.dart';

class CardData {
  // Legacy fields for backward compatibility
  String? imagePath;
  String text;
  
  // New layout system
  CardLayout? layout;
  
  CardData({
    this.imagePath,
    this.text = '',
    this.layout,
  });
  
  CardData copyWith({
    String? imagePath,
    String? text,
    CardLayout? layout,
  }) {
    return CardData(
      imagePath: imagePath ?? this.imagePath,
      text: text ?? this.text,
      layout: layout ?? this.layout,
    );
  }
  
  // Get effective layout (use layout if exists, otherwise create from legacy fields)
  CardLayout getEffectiveLayout() {
    if (layout != null) {
      return layout!;
    }
    // Fallback to legacy layout
    return CardLayout.fromLegacyCardData(
      imagePath: imagePath,
      text: text,
    );
  }
  
  // Migrate legacy data to new layout system
  void migrateToNewLayout() {
    if (layout == null) {
      layout = CardLayout.fromLegacyCardData(
        imagePath: imagePath,
        text: text,
      );
    }
  }
}
