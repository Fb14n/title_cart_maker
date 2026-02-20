enum ImageFormat {
  png,
  jpg,
}

enum PageSize {
  a4,
  custom,
}

class ImageExportOptions {
  final ImageFormat format;
  final PageSize pageSize;
  final double? customWidth;  // in mm
  final double? customHeight; // in mm
  final int dpi;
  
  ImageExportOptions({
    this.format = ImageFormat.png,
    this.pageSize = PageSize.a4,
    this.customWidth,
    this.customHeight,
    this.dpi = 300,
  });
}
