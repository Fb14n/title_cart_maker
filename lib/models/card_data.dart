class CardData {
  String? imagePath;
  String text;
  
  CardData({
    this.imagePath,
    this.text = '',
  });
  
  CardData copyWith({
    String? imagePath,
    String? text,
  }) {
    return CardData(
      imagePath: imagePath ?? this.imagePath,
      text: text ?? this.text,
    );
  }
}
