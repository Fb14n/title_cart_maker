import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/project_provider.dart';
import 'card_preview.dart';

class PreviewCanvas extends StatelessWidget {
  const PreviewCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        final config = provider.layoutConfig;
        final cardsPerPage = config.totalCards;
        final totalCards = provider.cards.length;
        final numberOfPages = (totalCards / cardsPerPage).ceil().clamp(1, 100);
        
        return Container(
          color: Colors.grey[200],
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: List.generate(numberOfPages, (pageIndex) {
                    final startIndex = pageIndex * cardsPerPage;
                    final endIndex = (startIndex + cardsPerPage).clamp(0, totalCards);
                    final cardsOnPage = provider.cards.sublist(startIndex, endIndex);
                    
                    return Column(
                      children: [
                        if (pageIndex > 0) const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _buildA4Preview(context, provider, cardsOnPage, startIndex),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Seite ${pageIndex + 1} von $numberOfPages',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildA4Preview(BuildContext context, ProjectProvider provider, List<dynamic> cardsOnPage, int startIndex) {
    final config = provider.layoutConfig;
    
    // A4 dimensions at 2x scale for better visibility
    const double a4WidthMm = 210.0;
    const double a4HeightMm = 297.0;
    const double mmToPixel = 2.0; // Scale factor for preview
    
    final double a4Width = a4WidthMm * mmToPixel;
    final double a4Height = a4HeightMm * mmToPixel;
    
    return SizedBox(
      width: a4Width,
      height: a4Height,
      child: Stack(
        children: [
          // A4 border
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
            ),
          ),
          
          // Cards grid
          Padding(
            padding: EdgeInsets.only(
              left: config.marginLeft * mmToPixel,
              right: config.marginRight * mmToPixel,
              top: config.marginTop * mmToPixel,
              bottom: config.marginBottom * mmToPixel,
            ),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: config.columns,
                childAspectRatio: config.cardWidth / config.cardHeight,
                crossAxisSpacing: config.horizontalSpacing * mmToPixel,
                mainAxisSpacing: config.verticalSpacing * mmToPixel,
              ),
              itemCount: cardsOnPage.length,
              itemBuilder: (context, index) {
                return CardPreview(
                  index: startIndex + index,
                  cardData: cardsOnPage[index],
                  width: config.cardWidth * mmToPixel,
                  height: config.cardHeight * mmToPixel,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
