import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import '../providers/project_provider.dart';
import '../models/card_layout.dart';
import '../models/card_element.dart';
import '../models/element_type.dart';
import '../models/layout_mode.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class CardLayoutEditor extends StatefulWidget {
  const CardLayoutEditor({super.key});

  @override
  State<CardLayoutEditor> createState() => _CardLayoutEditorState();
}

class _CardLayoutEditorState extends State<CardLayoutEditor> {
  String? _selectedElementId;
  bool _isDragging = false;
  bool _isResizing = false;
  String? _resizeHandle;
  
  // Zoom and pan controls
  double _zoomLevel = 1.0;
  bool _snapToGrid = true;
  static const double _gridStep = 0.05; // 5% grid

  // Focus node for keyboard shortcuts
  final FocusNode _focusNode = FocusNode();

  // For smoother dragging - no threshold needed, direct updates
  static const double mmToPixel = 2.0; // Same scale as PreviewCanvas
  
  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // Dynamic card size calculation - matches actual A4 preview size
  double _getCardPreviewWidth(ProjectProvider provider) {
    return provider.layoutConfig.cardWidth * mmToPixel * _zoomLevel;
  }
  
  double _getCardPreviewHeight(ProjectProvider provider) {
    return provider.layoutConfig.cardHeight * mmToPixel * _zoomLevel;
  }

  // Snap position to grid if enabled
  double _snapToGridValue(double value) {
    if (!_snapToGrid) return value;
    return (value / _gridStep).round() * _gridStep;
  }

  // Handle keyboard shortcuts for precise movement
  void _handleKeyEvent(KeyEvent event, ProjectProvider provider) {
    if (_selectedElementId == null) return;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;

    final layout = provider.getCurrentEditingLayout();
    final element = layout.elements.firstWhere(
      (e) => e.id == _selectedElementId,
      orElse: () => layout.elements.first,
    );

    const moveStep = 0.01; // 1% movement
    const largeStep = 0.05; // 5% with Shift

    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
    final step = isShiftPressed ? largeStep : moveStep;

    Offset delta = Offset.zero;

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      delta = Offset(0, -step);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      delta = Offset(0, step);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      delta = Offset(-step, 0);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      delta = Offset(step, 0);
    } else if (event.logicalKey == LogicalKeyboardKey.delete ||
               event.logicalKey == LogicalKeyboardKey.backspace) {
      _deleteSelectedElement(provider);
      return;
    } else {
      return;
    }

    final newPosition = Offset(
      (element.position.dx + delta.dx).clamp(-0.5, 1.5),
      (element.position.dy + delta.dy).clamp(-0.5, 1.5),
    );

    final updatedElements = layout.elements.map((e) {
      if (e.id == _selectedElementId) {
        return e.copyWith(position: newPosition);
      }
      return e;
    }).toList();

    provider.updateCurrentEditingLayout(layout.copyWith(elements: updatedElements));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        final layout = provider.getCurrentEditingLayout();
        
        return KeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: (event) => _handleKeyEvent(event, provider),
          child: Container(
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
                _buildZoomAndGridControls(),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildCardPreview(layout, provider),
                        const SizedBox(height: 16),
                        if (_selectedElementId != null)
                          _buildElementPropertiesPanel(layout, provider),
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
          ),
        );
      },
    );
  }

  Widget _buildZoomAndGridControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[200],
      child: Row(
        children: [
          // Zoom controls
          const Icon(Icons.zoom_out, size: 16),
          Expanded(
            child: Slider(
              value: _zoomLevel,
              min: 0.5,
              max: 2.0,
              divisions: 6,
              label: '${(_zoomLevel * 100).round()}%',
              onChanged: (value) {
                setState(() {
                  _zoomLevel = value;
                });
              },
            ),
          ),
          const Icon(Icons.zoom_in, size: 16),
          const SizedBox(width: 8),
          Text('${(_zoomLevel * 100).round()}%', style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 16),
          // Grid snap toggle
          Tooltip(
            message: 'Am Raster ausrichten',
            child: FilterChip(
              label: const Text('Raster', style: TextStyle(fontSize: 11)),
              avatar: Icon(_snapToGrid ? Icons.grid_on : Icons.grid_off, size: 14),
              selected: _snapToGrid,
              onSelected: (value) {
                setState(() {
                  _snapToGrid = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElementPropertiesPanel(CardLayout layout, ProjectProvider provider) {
    final element = layout.elements.firstWhere(
      (e) => e.id == _selectedElementId,
      orElse: () => layout.elements.first,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withAlpha(75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                element.type == ElementType.image ? 'Bild-Element' : 'Text-Element',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  // Move to back
                  IconButton(
                    icon: const Icon(Icons.flip_to_back, size: 18),
                    tooltip: 'Nach hinten',
                    onPressed: () => _moveElementLayer(layout, provider, element, false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  // Move to front
                  IconButton(
                    icon: const Icon(Icons.flip_to_front, size: 18),
                    tooltip: 'Nach vorne',
                    onPressed: () => _moveElementLayer(layout, provider, element, true),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Position inputs
          Row(
            children: [
              const Text('Position: ', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 8),
              _buildPositionInput('X', element.position.dx, (value) {
                _updateElementPropertyPosition(layout, provider, element, dx: value);
              }),
              const SizedBox(width: 8),
              _buildPositionInput('Y', element.position.dy, (value) {
                _updateElementPropertyPosition(layout, provider, element, dy: value);
              }),
            ],
          ),
          const SizedBox(height: 8),
          // Size inputs
          Row(
            children: [
              const Text('Größe:    ', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 8),
              _buildPositionInput('W', element.size.width, (value) {
                _updateElementPropertySize(layout, provider, element, width: value);
              }),
              const SizedBox(width: 8),
              _buildPositionInput('H', element.size.height, (value) {
                _updateElementPropertySize(layout, provider, element, height: value);
              }),
            ],
          ),
          const SizedBox(height: 8),
          // Quick actions
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              _buildQuickPositionButton('Oben Links', layout, provider, element, 0.0, 0.0),
              _buildQuickPositionButton('Oben Mitte', layout, provider, element, 0.5 - element.size.width / 2, 0.0),
              _buildQuickPositionButton('Oben Rechts', layout, provider, element, 1.0 - element.size.width, 0.0),
              _buildQuickPositionButton('Mitte', layout, provider, element, 0.5 - element.size.width / 2, 0.5 - element.size.height / 2),
              _buildQuickPositionButton('Unten Links', layout, provider, element, 0.0, 1.0 - element.size.height),
              _buildQuickPositionButton('Unten Mitte', layout, provider, element, 0.5 - element.size.width / 2, 1.0 - element.size.height),
              _buildQuickPositionButton('Unten Rechts', layout, provider, element, 1.0 - element.size.width, 1.0 - element.size.height),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tipp: Pfeiltasten zum Verschieben, Shift für größere Schritte',
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionInput(String label, double value, Function(double) onChanged) {
    return SizedBox(
      width: 70,
      height: 30,
      child: TextFormField(
        initialValue: (value * 100).toStringAsFixed(0),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 10),
          suffixText: '%',
          suffixStyle: const TextStyle(fontSize: 10),
          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        style: const TextStyle(fontSize: 11),
        keyboardType: TextInputType.number,
        onFieldSubmitted: (text) {
          final parsed = double.tryParse(text);
          if (parsed != null) {
            onChanged(parsed / 100);
          }
        },
      ),
    );
  }

  Widget _buildQuickPositionButton(
    String label,
    CardLayout layout,
    ProjectProvider provider,
    CardElement element,
    double x,
    double y,
  ) {
    return SizedBox(
      height: 24,
      child: TextButton(
        onPressed: () {
          _updateElementPropertyPosition(layout, provider, element, dx: x, dy: y);
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          minimumSize: Size.zero,
        ),
        child: Text(label, style: const TextStyle(fontSize: 10)),
      ),
    );
  }

  void _updateElementPropertyPosition(
    CardLayout layout,
    ProjectProvider provider,
    CardElement element, {
    double? dx,
    double? dy,
  }) {
    final newPosition = Offset(
      dx ?? element.position.dx,
      dy ?? element.position.dy,
    );

    final updatedElements = layout.elements.map((e) {
      if (e.id == element.id) {
        return e.copyWith(position: newPosition);
      }
      return e;
    }).toList();

    provider.updateCurrentEditingLayout(layout.copyWith(elements: updatedElements));
  }

  void _updateElementPropertySize(
    CardLayout layout,
    ProjectProvider provider,
    CardElement element, {
    double? width,
    double? height,
  }) {
    final newSize = Size(
      (width ?? element.size.width).clamp(0.05, 2.0),
      (height ?? element.size.height).clamp(0.05, 2.0),
    );

    final updatedElements = layout.elements.map((e) {
      if (e.id == element.id) {
        return e.copyWith(size: newSize);
      }
      return e;
    }).toList();

    provider.updateCurrentEditingLayout(layout.copyWith(elements: updatedElements));
  }

  void _moveElementLayer(CardLayout layout, ProjectProvider provider, CardElement element, bool toFront) {
    final elements = List<CardElement>.from(layout.elements);
    final index = elements.indexWhere((e) => e.id == element.id);
    if (index == -1) return;

    elements.removeAt(index);
    if (toFront) {
      elements.add(element);
    } else {
      elements.insert(0, element);
    }

    provider.updateCurrentEditingLayout(layout.copyWith(elements: elements));
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
    final cardWidth = _getCardPreviewWidth(provider);
    final cardHeight = _getCardPreviewHeight(provider);
    
    return GestureDetector(
      onTap: () {
        // Deselect when clicking on empty area
        setState(() {
          _selectedElementId = null;
        });
        _focusNode.requestFocus();
      },
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          color: layout.backgroundColor ?? Colors.white,
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Grid overlay when snap is enabled
            if (_snapToGrid)
              CustomPaint(
                size: Size(cardWidth, cardHeight),
                painter: _GridPainter(gridStep: _gridStep),
              ),
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
    ),
    );
  }

  Widget _buildDraggableElement(
    CardElement element,
    CardLayout layout,
    ProjectProvider provider,
  ) {
    final cardWidth = _getCardPreviewWidth(provider);
    final cardHeight = _getCardPreviewHeight(provider);
    final isSelected = _selectedElementId == element.id;
    final left = element.position.dx * cardWidth;
    final top = element.position.dy * cardHeight;
    final width = element.size.width * cardWidth;
    final height = element.size.height * cardHeight;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onPanStart: (details) {
          setState(() {
            _selectedElementId = element.id;
            _isDragging = true;
          });
        },
        onPanUpdate: (details) {
          if (_isDragging && !_isResizing) {
            final newLayout = _updateElementPosition(
              layout,
              element.id,
              details.delta,
              provider,
            );
            provider.updateCurrentEditingLayout(newLayout);
          }
        },
        onPanEnd: (details) {
          setState(() {
            _isDragging = false;
          });
        },
        onDoubleTap: () {
          if (element.type == ElementType.text) {
            _editTextElement(element, provider);
          } else if (element.type == ElementType.image) {
            _editImageElement(element, provider);
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
    const handleSize = 16.0; // Größere Handles für einfacheres Greifen
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
              provider,
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
    ProjectProvider provider,
  ) {
    final cardWidth = _getCardPreviewWidth(provider);
    final cardHeight = _getCardPreviewHeight(provider);
    
    final updatedElements = layout.elements.map((element) {
      if (element.id == elementId) {
        var newPosition = element.position;
        var newSize = element.size;

        final deltaX = delta.dx / cardWidth;
        final deltaY = delta.dy / cardHeight;

        switch (handle) {
          case 'tl':
            newPosition = Offset(
              element.position.dx + deltaX,
              element.position.dy + deltaY,
            );
            newSize = Size(
              (element.size.width - deltaX).clamp(0.05, 2.0),
              (element.size.height - deltaY).clamp(0.05, 2.0),
            );
            break;
          case 'tr':
            newPosition = Offset(
              element.position.dx,
              element.position.dy + deltaY,
            );
            newSize = Size(
              (element.size.width + deltaX).clamp(0.05, 2.0),
              (element.size.height - deltaY).clamp(0.05, 2.0),
            );
            break;
          case 'bl':
            newPosition = Offset(
              element.position.dx + deltaX,
              element.position.dy,
            );
            newSize = Size(
              (element.size.width - deltaX).clamp(0.05, 2.0),
              (element.size.height + deltaY).clamp(0.05, 2.0),
            );
            break;
          case 'br':
            newSize = Size(
              (element.size.width + deltaX).clamp(0.05, 2.0),
              (element.size.height + deltaY).clamp(0.05, 2.0),
            );
            break;
          case 't':
            newPosition = Offset(
              element.position.dx,
              element.position.dy + deltaY,
            );
            newSize = Size(
              element.size.width,
              (element.size.height - deltaY).clamp(0.05, 2.0),
            );
            break;
          case 'b':
            newSize = Size(
              element.size.width,
              (element.size.height + deltaY).clamp(0.05, 2.0),
            );
            break;
          case 'l':
            newPosition = Offset(
              element.position.dx + deltaX,
              element.position.dy,
            );
            newSize = Size(
              (element.size.width - deltaX).clamp(0.05, 2.0),
              element.size.height,
            );
            break;
          case 'r':
            newSize = Size(
              (element.size.width + deltaX).clamp(0.05, 2.0),
              element.size.height,
            );
            break;
        }

        // Apply grid snapping if enabled
        if (_snapToGrid) {
          newPosition = Offset(
            _snapToGridValue(newPosition.dx),
            _snapToGridValue(newPosition.dy),
          );
          newSize = Size(
            _snapToGridValue(newSize.width),
            _snapToGridValue(newSize.height),
          );
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
        return ClipRect(
          child: Image.file(
            File(imagePath),
            fit: element.imageFit ?? BoxFit.contain, // Use element's fit or default to contain
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Icon(Icons.image, color: Colors.grey),
              );
            },
          ),
        );
      }
      return Container(
        color: Colors.grey[300],
        child: const Icon(Icons.add_photo_alternate, color: Colors.grey),
      );
    } else {
      // Text element
      final text = element.data as String? ?? '';
      final displayText = text.isEmpty && element.placeholder != null 
          ? '[${element.placeholder}]' 
          : (text.isEmpty ? 'Text hier...' : text);
      final isPlaceholder = text.isEmpty && element.placeholder != null;
      
      // Map TextAlign to Container Alignment
      Alignment containerAlignment;
      final textAlign = element.textAlign ?? TextAlign.center;
      switch (textAlign) {
        case TextAlign.left:
        case TextAlign.start:
          containerAlignment = Alignment.centerLeft;
          break;
        case TextAlign.right:
        case TextAlign.end:
          containerAlignment = Alignment.centerRight;
          break;
        case TextAlign.center:
          containerAlignment = Alignment.center;
          break;
        case TextAlign.justify:
          containerAlignment = Alignment.centerLeft;
          break;
      }
      
      return Container(
        padding: const EdgeInsets.only(left: 4, top: 4, right: 6, bottom: 4),
        alignment: containerAlignment,
        decoration: isPlaceholder ? BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          border: Border.all(color: Colors.blue.withOpacity(0.5), width: 1),
        ) : null,
        child: Text(
          displayText,
          style: (element.textStyle ?? const TextStyle(fontSize: 16)).copyWith(
            color: isPlaceholder ? Colors.blue : element.textStyle?.color,
            fontStyle: isPlaceholder ? FontStyle.italic : element.textStyle?.fontStyle,
          ),
          textAlign: textAlign,
          softWrap: true,
        ),
      );
    }
  }

  CardLayout _updateElementPosition(
    CardLayout layout,
    String elementId,
    Offset delta,
    ProjectProvider provider,
  ) {
    final cardWidth = _getCardPreviewWidth(provider);
    final cardHeight = _getCardPreviewHeight(provider);
    
    final updatedElements = layout.elements.map((element) {
      if (element.id == elementId) {
        var newX = (element.position.dx + delta.dx / cardWidth).clamp(-0.5, 1.5);
        var newY = (element.position.dy + delta.dy / cardHeight).clamp(-0.5, 1.5);

        // Apply grid snapping if enabled
        if (_snapToGrid) {
          newX = _snapToGridValue(newX);
          newY = _snapToGridValue(newY);
        }

        final newPosition = Offset(newX, newY);
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Hintergrundfarbe',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            OutlinedButton.icon(
              onPressed: () => _showAdvancedColorPicker(
                context,
                layout.backgroundColor ?? Colors.white,
                (color) {
                  final newLayout = layout.copyWith(backgroundColor: color);
                  provider.updateCurrentEditingLayout(newLayout);
                },
              ),
              icon: const Icon(Icons.colorize, size: 16),
              label: const Text('Erweitert'),
            ),
          ],
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
        size: const Size(0.3, 0.3), // Smaller initial size: 30% x 30%
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
  
  void _editImageElement(CardElement element, ProjectProvider provider) {
    BoxFit imageFit = element.imageFit ?? BoxFit.contain;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Bild-Einstellungen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Wie soll das Bild angezeigt werden?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              RadioListTile<BoxFit>(
                title: const Text('Ganzes Bild anzeigen'),
                subtitle: const Text('Bild wird vollständig dargestellt'),
                value: BoxFit.contain,
                groupValue: imageFit,
                onChanged: (value) {
                  setDialogState(() {
                    imageFit = value!;
                  });
                },
              ),
              RadioListTile<BoxFit>(
                title: const Text('Box ausfüllen'),
                subtitle: const Text('Bild füllt gesamten Bereich, kann beschnitten werden'),
                value: BoxFit.cover,
                groupValue: imageFit,
                onChanged: (value) {
                  setDialogState(() {
                    imageFit = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Tipp: Ändere die Größe des Elements mit den Resize-Handles, um den Bildausschnitt anzupassen.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
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
                    return e.copyWith(imageFit: imageFit);
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

  void _editTextElement(CardElement element, ProjectProvider provider) {
    final textController = TextEditingController(text: element.data as String? ?? '');
    final placeholderController = TextEditingController(text: element.placeholder ?? '');
    Color textColor = element.textStyle?.color ?? Colors.black;
    double fontSize = element.textStyle?.fontSize ?? 16.0;
    bool isBold = element.textStyle?.fontWeight == FontWeight.bold;
    bool isItalic = element.textStyle?.fontStyle == FontStyle.italic;
    bool isUnderline = element.textStyle?.decoration == TextDecoration.underline;
    TextAlign textAlign = element.textAlign ?? TextAlign.center;
    String fontFamily = element.textStyle?.fontFamily ?? 'Arial';
    
    // Available fonts - mapped to PDF standard fonts
    // Helvetica group: Arial, Verdana, Roboto, Impact
    // Times group: Times New Roman, Georgia
    // Courier group: Courier New
    final List<String> availableFonts = [
      'Arial',
      'Verdana',
      'Roboto',
      'Impact',
      'Times New Roman',
      'Georgia',
      'Courier New',
    ];
    
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
                
                // Placeholder/Label field
                TextField(
                  controller: placeholderController,
                  decoration: const InputDecoration(
                    labelText: 'Platzhalter (z.B. "Spalte 1", "Name")',
                    border: OutlineInputBorder(),
                    helperText: 'Wird durch Tabellendaten ersetzt',
                  ),
                ),
                const SizedBox(height: 16),
                
                // Text formatting buttons
                const Text('Formatierung:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Bold
                    IconButton.filledTonal(
                      onPressed: () {
                        setDialogState(() {
                          isBold = !isBold;
                        });
                      },
                      icon: const Icon(Icons.format_bold),
                      isSelected: isBold,
                      tooltip: 'Fett',
                    ),
                    const SizedBox(width: 8),
                    // Italic
                    IconButton.filledTonal(
                      onPressed: () {
                        setDialogState(() {
                          isItalic = !isItalic;
                        });
                      },
                      icon: const Icon(Icons.format_italic),
                      isSelected: isItalic,
                      tooltip: 'Kursiv',
                    ),
                    const SizedBox(width: 8),
                    // Underline
                    IconButton.filledTonal(
                      onPressed: () {
                        setDialogState(() {
                          isUnderline = !isUnderline;
                        });
                      },
                      icon: const Icon(Icons.format_underline),
                      isSelected: isUnderline,
                      tooltip: 'Unterstrichen',
                    ),
                    const SizedBox(width: 16),
                    const Text('|'),
                    const SizedBox(width: 16),
                    // Align Left
                    IconButton.filledTonal(
                      onPressed: () {
                        setDialogState(() {
                          textAlign = TextAlign.left;
                        });
                      },
                      icon: const Icon(Icons.format_align_left),
                      isSelected: textAlign == TextAlign.left,
                      tooltip: 'Linksbündig',
                    ),
                    const SizedBox(width: 8),
                    // Align Center
                    IconButton.filledTonal(
                      onPressed: () {
                        setDialogState(() {
                          textAlign = TextAlign.center;
                        });
                      },
                      icon: const Icon(Icons.format_align_center),
                      isSelected: textAlign == TextAlign.center,
                      tooltip: 'Zentriert',
                    ),
                    const SizedBox(width: 8),
                    // Align Right
                    IconButton.filledTonal(
                      onPressed: () {
                        setDialogState(() {
                          textAlign = TextAlign.right;
                        });
                      },
                      icon: const Icon(Icons.format_align_right),
                      isSelected: textAlign == TextAlign.right,
                      tooltip: 'Rechtsbündig',
                    ),
                  ],
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
                
                // Font family dropdown
                const Text('Schriftart:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: fontFamily,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: availableFonts.map((font) {
                    return DropdownMenuItem(
                      value: font,
                      child: Text(font, style: TextStyle(fontFamily: font)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        fontFamily = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Color picker
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Textfarbe:', style: TextStyle(fontWeight: FontWeight.bold)),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final newColor = await _showAdvancedColorPicker(
                          context,
                          textColor,
                          (color) {
                            setDialogState(() => textColor = color);
                          },
                        );
                      },
                      icon: const Icon(Icons.colorize, size: 16),
                      label: const Text('Erweitert'),
                    ),
                  ],
                ),
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
                      fontFamily: fontFamily,
                      fontSize: fontSize,
                      color: textColor,
                      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                      fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                      decoration: isUnderline ? TextDecoration.underline : TextDecoration.none,
                    ),
                    textAlign: textAlign,
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
                      placeholder: placeholderController.text.isEmpty ? null : placeholderController.text,
                      textStyle: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: fontSize,
                        color: textColor,
                        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                        fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                        decoration: isUnderline ? TextDecoration.underline : TextDecoration.none,
                      ),
                      textAlign: textAlign,
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
  
  Future<void> _showAdvancedColorPicker(
    BuildContext context,
    Color initialColor,
    Function(Color) onColorChanged,
  ) async {
    Color selectedColor = initialColor;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Farbe wählen'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 300,
            child: ColorPicker(
              color: selectedColor,
              onColorChanged: (color) {
                selectedColor = color;
              },
              width: 40,
              height: 40,
              borderRadius: 8,
              spacing: 5,
              runSpacing: 5,
              wheelDiameter: 200,
              heading: Text(
                'Farbe auswählen',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subheading: Text(
                'Farbton',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              wheelSubheading: Text(
                'Farbrad',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              showMaterialName: false,
              showColorName: false,
              showColorCode: true,
              copyPasteBehavior: const ColorPickerCopyPasteBehavior(
                longPressMenu: true,
              ),
              materialNameTextStyle: Theme.of(context).textTheme.bodySmall,
              colorNameTextStyle: Theme.of(context).textTheme.bodySmall,
              colorCodeTextStyle: Theme.of(context).textTheme.bodySmall,
              pickersEnabled: const <ColorPickerType, bool>{
                ColorPickerType.both: false,
                ColorPickerType.primary: true,
                ColorPickerType.accent: false,
                ColorPickerType.bw: false,
                ColorPickerType.custom: false,
                ColorPickerType.wheel: true,
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              onColorChanged(selectedColor);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// Custom painter for grid overlay
class _GridPainter extends CustomPainter {
  final double gridStep;

  _GridPainter({required this.gridStep});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withAlpha(50)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Vertical lines
    for (double x = 0; x <= 1.0; x += gridStep) {
      final xPos = x * size.width;
      canvas.drawLine(Offset(xPos, 0), Offset(xPos, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y <= 1.0; y += gridStep) {
      final yPos = y * size.height;
      canvas.drawLine(Offset(0, yPos), Offset(size.width, yPos), paint);
    }

    // Draw center lines with slightly stronger color
    final centerPaint = Paint()
      ..color = Colors.grey.withAlpha(100)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Vertical center
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      centerPaint,
    );

    // Horizontal center
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

