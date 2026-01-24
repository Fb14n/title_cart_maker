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
        
        return Container(
          color: Colors.grey[200],
          child: Center(
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  margin: const EdgeInsets.all(32),
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
                  child: _buildA4Preview(context, provider),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildA4Preview(BuildContext context, ProjectProvider provider) {
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
              itemCount: provider.cards.length,
              itemBuilder: (context, index) {
                return CardPreview(
                  index: index,
                  cardData: provider.cards[index],
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
