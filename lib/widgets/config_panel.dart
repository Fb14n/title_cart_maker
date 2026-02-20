import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../models/layout_config.dart';

class ConfigPanel extends StatelessWidget {
  const ConfigPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        final config = provider.layoutConfig;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Layout-Konfiguration',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Columns
            _buildSlider(
              context,
              label: 'Spalten',
              value: config.columns.toDouble(),
              min: 1,
              max: 20,
              divisions: 19,
              onChanged: (value) {
                provider.updateLayoutConfig(
                  config.copyWith(columns: value.toInt()),
                );
              },
            ),
            
            // Rows
            _buildSlider(
              context,
              label: 'Reihen',
              value: config.rows.toDouble(),
              min: 1,
              max: 20,
              divisions: 19,
              onChanged: (value) {
                provider.updateLayoutConfig(
                  config.copyWith(rows: value.toInt()),
                );
              },
            ),
            
            const Divider(),
            const SizedBox(height: 8),
            
            // Card Width
            _buildSlider(
              context,
              label: 'Kartenbreite (mm)',
              value: config.cardWidth,
              min: 30,
              max: 150,
              divisions: 24,
              onChanged: (value) {
                provider.updateLayoutConfig(
                  config.copyWith(cardWidth: value),
                );
              },
            ),
            
            // Card Height
            _buildSlider(
              context,
              label: 'Kartenhöhe (mm)',
              value: config.cardHeight,
              min: 30,
              max: 150,
              divisions: 24,
              onChanged: (value) {
                provider.updateLayoutConfig(
                  config.copyWith(cardHeight: value),
                );
              },
            ),
            
            const Divider(),
            const SizedBox(height: 8),
            
            // Spacing
            _buildSlider(
              context,
              label: 'Horizontaler Abstand (mm)',
              value: config.horizontalSpacing,
              min: 0,
              max: 20,
              divisions: 20,
              onChanged: (value) {
                provider.updateLayoutConfig(
                  config.copyWith(horizontalSpacing: value),
                );
              },
            ),
            
            _buildSlider(
              context,
              label: 'Vertikaler Abstand (mm)',
              value: config.verticalSpacing,
              min: 0,
              max: 20,
              divisions: 20,
              onChanged: (value) {
                provider.updateLayoutConfig(
                  config.copyWith(verticalSpacing: value),
                );
              },
            ),
            
            const Divider(),
            const SizedBox(height: 8),
            
            // Total cards info and add button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gesamt: ${provider.cards.length} Karten',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${(provider.cards.length / config.totalCards).ceil()} Seiten',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      provider.addMoreCards(config.totalCards);
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Seite hinzufügen', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSlider(
    BuildContext context, {
    required String label,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
