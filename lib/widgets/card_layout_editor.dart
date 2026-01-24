import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../models/card_layout.dart';
import '../models/card_element.dart';
import '../models/element_type.dart';
import '../models/layout_mode.dart';
import 'dart:math' as math;
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class CardLayoutEditor extends StatefulWidget {
  const CardLayoutEditor({super.key});

  @override
  State<CardLayoutEditor> createState() => _CardLayoutEditorState();
}

class _CardLayoutEditorState extends State<CardLayoutEditor> {
  String? _selectedElementId;
  final double _cardPreviewWidth = 300;
  final double _cardPreviewHeight = 400;
  bool _isDragging = false;
  bool _isResizing = false;
  String? _resizeHandle;
  
  // For smoother dragging - accumulate deltas
  Offset _dragAccumulator = Offset.zero;
  static const double _dragThreshold = 3.0; // Only update every 3 pixels

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        final layout = provider.getCurrentEditingLayout();
        
        return Container(
          width: 400,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: const Border(
              left: BorderSide(color: Colors.grey, width: 1),
            ),
          ),
          child: Column(
            children: [
              _buildHeader(provider),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildCardPreview(layout, provider),
                      const SizedBox(height: 16),
                      _buildToolbar(provider),
                      const SizedBox(height: 16),
                      _buildBackgroundColorPicker(layout, provider),
                      const SizedBox(height: 16),
                      _buildTableDataSection(provider),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(ProjectProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Karten-Layout-Editor',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Modus: '),
              const SizedBox(width: 8),
              SegmentedButton<LayoutMode>(
                segments: const [
                  ButtonSegment(
                    value: LayoutMode.global,
                    label: Text('Global'),
                    icon: Icon(Icons.public, size: 16),
                  ),
                  ButtonSegment(
                    value: LayoutMode.individual,
                    label: Text('Individual'),
                    icon: Icon(Icons.person, size: 16),
                  ),
                ],
                selected: {provider.layoutMode},
                onSelectionChanged: (Set<LayoutMode> newSelection) {
                  provider.setLayoutMode(newSelection.first);
                },
              ),
            ],
          ),
          if (provider.layoutMode == LayoutMode.individual) ...[
            const SizedBox(height: 8),
            Text(
              'Karte ${provider.selectedCardIndex + 1} von ${provider.cards.length}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardPreview(CardLayout layout, ProjectProvider provider) {
    return Container(
      width: _cardPreviewWidth,
      height: _cardPreviewHeight,
      decoration: BoxDecoration(
        color: layout.backgroundColor ?? Colors.white,
        border: Border.all(color: Colors.grey[400]!),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Render all elements
            ...layout.elements.map((element) {
              return _buildDraggableElement(element, layout, provider);
            }),
            // Helper text when empty
            if (layout.elements.isEmpty)
              const Center(
                child: Text(
                  'Füge Elemente hinzu',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraggableElement(
    CardElement element,
    CardLayout layout,
    ProjectProvider provider,
  ) {
    final isSelected = _selectedElementId == element.id;
    final left = element.position.dx * _cardPreviewWidth;
    final top = element.position.dy * _cardPreviewHeight;
    final width = element.size.width * _cardPreviewWidth;
    final height = element.size.height * _cardPreviewHeight;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onPanStart: (details) {
          setState(() {
            _selectedElementId = element.id;
            _isDragging = true;
            _dragAccumulator = Offset.zero;
          });
        },
        onPanUpdate: (details) {
          if (_isDragging && !_isResizing) {
            _dragAccumulator += details.delta;
            
            // Only update when accumulated movement exceeds threshold
            if (_dragAccumulator.dx.abs() >= _dragThreshold || 
                _dragAccumulator.dy.abs() >= _dragThreshold) {
              final newLayout = _updateElementPosition(
                layout,
                element.id,
                _dragAccumulator,
              );
              provider.updateCurrentEditingLayout(newLayout);
              _dragAccumulator = Offset.zero;
            }
          }
        },
        onPanEnd: (details) {
          // Apply any remaining accumulated delta
          if (_dragAccumulator != Offset.zero) {
            final newLayout = _updateElementPosition(
              layout,
              element.id,
              _dragAccumulator,
            );
            provider.updateCurrentEditingLayout(newLayout);
          }
          setState(() {
            _isDragging = false;
            _dragAccumulator = Offset.zero;
          });
        },
        onDoubleTap: () {
          if (element.type == ElementType.text) {
            _editTextElement(element, provider);
          }
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                border: isSelected
                    ? Border.all(color: Colors.blue, width: 2)
                    : Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
              ),
              child: _buildElementContent(element),
            ),
            // Resize handles when selected
            if (isSelected) ..._buildResizeHandles(element, layout, provider, width, height),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildResizeHandles(
    CardElement element,
    CardLayout layout,
    ProjectProvider provider,
    double width,
    double height,
  ) {
    const handleSize = 12.0;
    const halfHandle = handleSize / 2;

    return [
      // Top-left
      _buildResizeHandle(-halfHandle, -halfHandle, handleSize, element, layout, provider, 'tl'),
      // Top-right
      _buildResizeHandle(width - halfHandle, -halfHandle, handleSize, element, layout, provider, 'tr'),
      // Bottom-left
      _buildResizeHandle(-halfHandle, height - halfHandle, handleSize, element, layout, provider, 'bl'),
      // Bottom-right
      _buildResizeHandle(width - halfHandle, height - halfHandle, handleSize, element, layout, provider, 'br'),
      // Top
      _buildResizeHandle(width / 2 - halfHandle, -halfHandle, handleSize, element, layout, provider, 't'),
      // Bottom
      _buildResizeHandle(width / 2 - halfHandle, height - halfHandle, handleSize, element, layout, provider, 'b'),
      // Left
      _buildResizeHandle(-halfHandle, height / 2 - halfHandle, handleSize, element, layout, provider, 'l'),
      // Right
      _buildResizeHandle(width - halfHandle, height / 2 - halfHandle, handleSize, element, layout, provider, 'r'),
    ];
  }

  Widget _buildResizeHandle(
    double left,
    double top,
    double size,
    CardElement element,
    CardLayout layout,
    ProjectProvider provider,
    String handle,
  ) {
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onPanStart: (details) {
          setState(() {
            _isResizing = true;
            _resizeHandle = handle;
          });
        },
        onPanUpdate: (details) {
          if (_isResizing) {
            final newLayout = _resizeElement(
              layout,
              element.id,
              details.delta,
              handle,
            );
            provider.updateCurrentEditingLayout(newLayout);
          }
        },
        onPanEnd: (details) {
          setState(() {
            _isResizing = false;
            _resizeHandle = null;
          });
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.blue,
            border: Border.all(color: Colors.white, width: 1),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  CardLayout _resizeElement(
    CardLayout layout,
    String elementId,
    Offset delta,
    String handle,
  ) {
    final updatedElements = layout.elements.map((element) {
      if (element.id == elementId) {
        var newPosition = element.position;
        var newSize = element.size;

        final deltaX = delta.dx / _cardPreviewWidth;
        final deltaY = delta.dy / _cardPreviewHeight;

        switch (handle) {
          case 'tl':
            newPosition = Offset(
              (element.position.dx + deltaX).clamp(0.0, element.position.dx + element.size.width - 0.05),
              (element.position.dy + deltaY).clamp(0.0, element.position.dy + element.size.height - 0.05),
            );
            newSize = Size(
              (element.size.width - deltaX).clamp(0.05, 1.0),
              (element.size.height - deltaY).clamp(0.05, 1.0),
            );
            break;
          case 'tr':
            newPosition = Offset(
              element.position.dx,
              (element.position.dy + deltaY).clamp(0.0, element.position.dy + element.size.height - 0.05),
            );
            newSize = Size(
              (element.size.width + deltaX).clamp(0.05, 1.0 - element.position.dx),
              (element.size.height - deltaY).clamp(0.05, 1.0),
            );
            break;
          case 'bl':
            newPosition = Offset(
              (element.position.dx + deltaX).clamp(0.0, element.position.dx + element.size.width - 0.05),
              element.position.dy,
            );
            newSize = Size(
              (element.size.width - deltaX).clamp(0.05, 1.0),
              (element.size.height + deltaY).clamp(0.05, 1.0 - element.position.dy),
            );
            break;
          case 'br':
            newSize = Size(
              (element.size.width + deltaX).clamp(0.05, 1.0 - element.position.dx),
              (element.size.height + deltaY).clamp(0.05, 1.0 - element.position.dy),
            );
            break;
          case 't':
            newPosition = Offset(
              element.position.dx,
              (element.position.dy + deltaY).clamp(0.0, element.position.dy + element.size.height - 0.05),
            );
            newSize = Size(
              element.size.width,
              (element.size.height - deltaY).clamp(0.05, 1.0),
            );
            break;
          case 'b':
            newSize = Size(
              element.size.width,
              (element.size.height + deltaY).clamp(0.05, 1.0 - element.position.dy),
            );
            break;
          case 'l':
            newPosition = Offset(
              (element.position.dx + deltaX).clamp(0.0, element.position.dx + element.size.width - 0.05),
              element.position.dy,
            );
            newSize = Size(
              (element.size.width - deltaX).clamp(0.05, 1.0),
              element.size.height,
            );
            break;
          case 'r':
            newSize = Size(
              (element.size.width + deltaX).clamp(0.05, 1.0 - element.position.dx),
              element.size.height,
            );
            break;
        }

        return element.copyWith(position: newPosition, size: newSize);
      }
      return element;
    }).toList();

    return layout.copyWith(elements: updatedElements);
  }

  Widget _buildElementContent(CardElement element) {
    if (element.type == ElementType.image) {
      final imagePath = element.data as String?;
      if (imagePath != null && imagePath.isNotEmpty) {
        return Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Icon(Icons.image, color: Colors.grey),
            );
          },
        );
      }
      return Container(
        color: Colors.grey[300],
        child: const Icon(Icons.add_photo_alternate, color: Colors.grey),
      );
    } else {
      // Text element
      return Container(
        padding: const EdgeInsets.all(4),
        child: Text(
          element.data as String? ?? '',
          style: element.textStyle ?? const TextStyle(fontSize: 16),
          textAlign: element.textAlign ?? TextAlign.center,
          maxLines: 10,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
  }

  CardLayout _updateElementPosition(
    CardLayout layout,
    String elementId,
    Offset delta,
  ) {
    final updatedElements = layout.elements.map((element) {
      if (element.id == elementId) {
        final newPosition = Offset(
          (element.position.dx + delta.dx / _cardPreviewWidth).clamp(0.0, 1.0 - element.size.width),
          (element.position.dy + delta.dy / _cardPreviewHeight).clamp(0.0, 1.0 - element.size.height),
        );
        return element.copyWith(position: newPosition);
      }
      return element;
    }).toList();

    return layout.copyWith(elements: updatedElements);
  }

  Widget _buildToolbar(ProjectProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () => _addImageElement(provider),
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Bild hinzufügen'),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => _addTextElement(provider),
          icon: const Icon(Icons.text_fields),
          label: const Text('Text hinzufügen'),
        ),
        const SizedBox(height: 8),
        if (_selectedElementId != null)
          ElevatedButton.icon(
            onPressed: () => _deleteSelectedElement(provider),
            icon: const Icon(Icons.delete),
            label: const Text('Element löschen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[100],
              foregroundColor: Colors.red[900],
            ),
          ),
      ],
    );
  }

  Widget _buildBackgroundColorPicker(CardLayout layout, ProjectProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hintergrundfarbe',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _colorButton(null, provider, layout), // White/No color
            _colorButton(Colors.grey[200], provider, layout),
            _colorButton(Colors.blue[100], provider, layout),
            _colorButton(Colors.green[100], provider, layout),
            _colorButton(Colors.yellow[100], provider, layout),
            _colorButton(Colors.red[100], provider, layout),
            _colorButton(Colors.purple[100], provider, layout),
            _colorButton(Colors.orange[100], provider, layout),
          ],
        ),
      ],
    );
  }

  Widget _colorButton(Color? color, ProjectProvider provider, CardLayout layout) {
    final isSelected = layout.backgroundColor == color;
    return GestureDetector(
      onTap: () {
        final newLayout = layout.copyWith(backgroundColor: color);
        provider.updateCurrentEditingLayout(newLayout);
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: color == null
            ? const Icon(Icons.close, size: 16, color: Colors.grey)
            : null,
      ),
    );
  }

  void _addImageElement(ProjectProvider provider) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null && result.files.single.path != null) {
      final layout = provider.getCurrentEditingLayout();
      final newElement = CardElement(
        id: 'img_${DateTime.now().millisecondsSinceEpoch}',
        type: ElementType.image,
        position: const Offset(0.1, 0.1),
        size: const Size(0.8, 0.5),
        data: result.files.single.path!,
      );

      final newLayout = layout.copyWith(
        elements: [...layout.elements, newElement],
      );
      provider.updateCurrentEditingLayout(newLayout);
    }
  }

  void _addTextElement(ProjectProvider provider) {
    final textController = TextEditingController(text: 'Neuer Text');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Text hinzufügen'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Text',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              final layout = provider.getCurrentEditingLayout();
              final newElement = CardElement(
                id: 'txt_${DateTime.now().millisecondsSinceEpoch}',
                type: ElementType.text,
                position: const Offset(0.1, 0.1),
                size: const Size(0.8, 0.3),
                data: textController.text,
                textStyle: const TextStyle(fontSize: 16, color: Colors.black),
                textAlign: TextAlign.center,
              );

              final newLayout = layout.copyWith(
                elements: [...layout.elements, newElement],
              );
              provider.updateCurrentEditingLayout(newLayout);
              Navigator.pop(context);
            },
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );
  }

  void _deleteSelectedElement(ProjectProvider provider) {
    if (_selectedElementId != null) {
      final layout = provider.getCurrentEditingLayout();
      final newElements = layout.elements
          .where((element) => element.id != _selectedElementId)
          .toList();
      
      final newLayout = layout.copyWith(elements: newElements);
      provider.updateCurrentEditingLayout(newLayout);
      
      setState(() {
        _selectedElementId = null;
      });
    }
  }

  void _editTextElement(CardElement element, ProjectProvider provider) {
    final textController = TextEditingController(text: element.data as String? ?? '');
    Color textColor = element.textStyle?.color ?? Colors.black;
    double fontSize = element.textStyle?.fontSize ?? 16.0;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Text bearbeiten'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: textController,
                  decoration: const InputDecoration(
                    labelText: 'Text',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                
                // Font size slider
                const Text('Schriftgröße:', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: fontSize,
                        min: 8,
                        max: 72,
                        divisions: 64,
                        label: fontSize.round().toString(),
                        onChanged: (value) {
                          setDialogState(() {
                            fontSize = value;
                          });
                        },
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        fontSize.round().toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Color picker
                const Text('Textfarbe:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _colorPickerButton(Colors.black, textColor, (color) {
                      setDialogState(() => textColor = color);
                    }),
                    _colorPickerButton(Colors.white, textColor, (color) {
                      setDialogState(() => textColor = color);
                    }),
                    _colorPickerButton(Colors.red, textColor, (color) {
                      setDialogState(() => textColor = color);
                    }),
                    _colorPickerButton(Colors.blue, textColor, (color) {
                      setDialogState(() => textColor = color);
                    }),
                    _colorPickerButton(Colors.green, textColor, (color) {
                      setDialogState(() => textColor = color);
                    }),
                    _colorPickerButton(Colors.orange, textColor, (color) {
                      setDialogState(() => textColor = color);
                    }),
                    _colorPickerButton(Colors.purple, textColor, (color) {
                      setDialogState(() => textColor = color);
                    }),
                    _colorPickerButton(Colors.yellow[700]!, textColor, (color) {
                      setDialogState(() => textColor = color);
                    }),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Preview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.grey[50],
                  ),
                  child: Text(
                    textController.text.isEmpty ? 'Vorschau' : textController.text,
                    style: TextStyle(
                      fontSize: fontSize,
                      color: textColor,
                    ),
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
            TextButton(
              onPressed: () {
                final layout = provider.getCurrentEditingLayout();
                final updatedElements = layout.elements.map((e) {
                  if (e.id == element.id) {
                    return e.copyWith(
                      data: textController.text,
                      textStyle: TextStyle(
                        fontSize: fontSize,
                        color: textColor,
                      ),
                    );
                  }
                  return e;
                }).toList();
                
                final newLayout = layout.copyWith(elements: updatedElements);
                provider.updateCurrentEditingLayout(newLayout);
                Navigator.pop(context);
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorPickerButton(Color color, Color currentColor, Function(Color) onTap) {
    final isSelected = color == currentColor;
    return GestureDetector(
      onTap: () => onTap(color),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
          boxShadow: color == Colors.white ? [
            BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 2)
          ] : null,
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : null,
      ),
    );
  }
  
  Widget _buildTableDataSection(ProjectProvider provider) {
    final hasTableData = provider.tableData.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tabellendaten',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (hasTableData) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Text(
              '${provider.tableData.length} Spalte(n) mit ${provider.tableData.first.length} Zeilen',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () {
              provider.applyTableDataToCards();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tabellendaten auf Karten angewendet!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Auf Karten anwenden'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[100],
              foregroundColor: Colors.green[900],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Erstellt ${provider.tableData.length} Text-Element(e) pro Karte',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: const Text(
              'Keine Tabellendaten.\nWähle Spalte(n) im linken Panel.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}
