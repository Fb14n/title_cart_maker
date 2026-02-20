class SaveOptions {
  final bool saveLayout;
  final bool saveTableData;
  final bool saveCardContent;
  final bool saveImages;
  final bool saveGlobalSettings;
  
  const SaveOptions({
    this.saveLayout = true,
    this.saveTableData = true,
    this.saveCardContent = true,
    this.saveImages = true,
    this.saveGlobalSettings = true,
  });
  
  SaveOptions copyWith({
    bool? saveLayout,
    bool? saveTableData,
    bool? saveCardContent,
    bool? saveImages,
    bool? saveGlobalSettings,
  }) {
    return SaveOptions(
      saveLayout: saveLayout ?? this.saveLayout,
      saveTableData: saveTableData ?? this.saveTableData,
      saveCardContent: saveCardContent ?? this.saveCardContent,
      saveImages: saveImages ?? this.saveImages,
      saveGlobalSettings: saveGlobalSettings ?? this.saveGlobalSettings,
    );
  }
}
