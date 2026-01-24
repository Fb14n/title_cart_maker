class LayoutConfig {
  int columns;
  int rows;
  double cardWidth; // in mm
  double cardHeight; // in mm
  double horizontalSpacing; // in mm
  double verticalSpacing; // in mm
  double marginTop; // in mm
  double marginBottom; // in mm
  double marginLeft; // in mm
  double marginRight; // in mm
  
  LayoutConfig({
    this.columns = 2,
    this.rows = 3,
    this.cardWidth = 90.0,
    this.cardHeight = 50.0,
    this.horizontalSpacing = 5.0,
    this.verticalSpacing = 5.0,
    this.marginTop = 10.0,
    this.marginBottom = 10.0,
    this.marginLeft = 10.0,
    this.marginRight = 10.0,
  });
  
  int get totalCards => columns * rows;
  
  LayoutConfig copyWith({
    int? columns,
    int? rows,
    double? cardWidth,
    double? cardHeight,
    double? horizontalSpacing,
    double? verticalSpacing,
    double? marginTop,
    double? marginBottom,
    double? marginLeft,
    double? marginRight,
  }) {
    return LayoutConfig(
      columns: columns ?? this.columns,
      rows: rows ?? this.rows,
      cardWidth: cardWidth ?? this.cardWidth,
      cardHeight: cardHeight ?? this.cardHeight,
      horizontalSpacing: horizontalSpacing ?? this.horizontalSpacing,
      verticalSpacing: verticalSpacing ?? this.verticalSpacing,
      marginTop: marginTop ?? this.marginTop,
      marginBottom: marginBottom ?? this.marginBottom,
      marginLeft: marginLeft ?? this.marginLeft,
      marginRight: marginRight ?? this.marginRight,
    );
  }
}
