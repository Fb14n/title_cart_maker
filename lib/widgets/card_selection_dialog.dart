import 'package:flutter/material.dart';
import 'package:title_card_maker/models/card_data.dart';

class CardSelectionDialog extends StatefulWidget {
  final List<CardData> cards;
  final int cardsPerPage;
  
  const CardSelectionDialog({
    super.key,
    required this.cards,
    required this.cardsPerPage,
  });

  @override
  State<CardSelectionDialog> createState() => _CardSelectionDialogState();
}

class _CardSelectionDialogState extends State<CardSelectionDialog> {
  late List<bool> _selectedCards;
  
  @override
  void initState() {
    super.initState();
    // Initially select all cards
    _selectedCards = List.filled(widget.cards.length, true);
  }
  
  void _toggleAll(bool value) {
    setState(() {
      _selectedCards = List.filled(widget.cards.length, value);
    });
  }
  
  void _togglePage(int pageIndex, bool value) {
    setState(() {
      final startIndex = pageIndex * widget.cardsPerPage;
      final endIndex = (startIndex + widget.cardsPerPage).clamp(0, widget.cards.length);
      
      for (int i = startIndex; i < endIndex; i++) {
        _selectedCards[i] = value;
      }
    });
  }
  
  int get _selectedCount => _selectedCards.where((selected) => selected).length;
  
  @override
  Widget build(BuildContext context) {
    final numberOfPages = (widget.cards.length / widget.cardsPerPage).ceil();
    
    return AlertDialog(
      title: const Text('Karten für Export auswählen'),
      content: SizedBox(
        width: 600,
        height: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary and controls
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$_selectedCount von ${widget.cards.length} Karten ausgewählt',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => _toggleAll(true),
                        icon: const Icon(Icons.check_box, size: 18),
                        label: const Text('Alle'),
                      ),
                      TextButton.icon(
                        onPressed: () => _toggleAll(false),
                        icon: const Icon(Icons.check_box_outline_blank, size: 18),
                        label: const Text('Keine'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Card grid by pages
            Expanded(
              child: ListView.builder(
                itemCount: numberOfPages,
                itemBuilder: (context, pageIndex) {
                  final startIndex = pageIndex * widget.cardsPerPage;
                  final endIndex = (startIndex + widget.cardsPerPage).clamp(0, widget.cards.length);
                  final cardsOnPage = endIndex - startIndex;
                  final allSelected = _selectedCards.sublist(startIndex, endIndex).every((s) => s);
                  final noneSelected = _selectedCards.sublist(startIndex, endIndex).every((s) => !s);
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      initiallyExpanded: pageIndex == 0,
                      title: Row(
                        children: [
                          Checkbox(
                            value: allSelected ? true : (noneSelected ? false : null),
                            tristate: true,
                            onChanged: (value) => _togglePage(pageIndex, value ?? true),
                          ),
                          Text(
                            'Seite ${pageIndex + 1} ($cardsOnPage Karten)',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(cardsOnPage, (index) {
                              final cardIndex = startIndex + index;
                              return _buildCardCheckbox(cardIndex);
                            }),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton.icon(
          onPressed: _selectedCount > 0
              ? () {
                  final selectedIndices = <int>[];
                  for (int i = 0; i < _selectedCards.length; i++) {
                    if (_selectedCards[i]) {
                      selectedIndices.add(i);
                    }
                  }
                  Navigator.pop(context, selectedIndices);
                }
              : null,
          icon: const Icon(Icons.picture_as_pdf),
          label: Text('PDF exportieren ($_selectedCount)'),
        ),
      ],
    );
  }
  
  Widget _buildCardCheckbox(int cardIndex) {
    final card = widget.cards[cardIndex];
    final layout = card.getEffectiveLayout();
    
    // Get preview text from first text element
    String previewText = 'Karte ${cardIndex + 1}';
    final textElements = layout.elements.where((e) => e.data is String);
    if (textElements.isNotEmpty) {
      final text = textElements.first.data as String;
      if (text.isNotEmpty) {
        previewText = text.length > 20 ? '${text.substring(0, 20)}...' : text;
      }
    }
    
    return Container(
      width: 150,
      decoration: BoxDecoration(
        border: Border.all(
          color: _selectedCards[cardIndex] ? Colors.blue : Colors.grey[300]!,
          width: _selectedCards[cardIndex] ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: _selectedCards[cardIndex] 
            ? Colors.blue.withOpacity(0.1) 
            : Colors.grey[50],
      ),
      child: CheckboxListTile(
        dense: true,
        value: _selectedCards[cardIndex],
        onChanged: (value) {
          setState(() {
            _selectedCards[cardIndex] = value ?? false;
          });
        },
        title: Text(
          previewText,
          style: const TextStyle(fontSize: 12),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
