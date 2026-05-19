import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

import '../parsing/markdown_block.dart';
import '../text/inline_span_builder.dart';
import '../theme/markdown_theme.dart';
import 'base/render_markdown_block.dart';
import 'mixins/selectable_text_mixin.dart';

/// Renders a table.
class RenderMarkdownTable extends RenderMarkdownBlock with SelectableTextMixin {
  /// Creates a new render table.
  RenderMarkdownTable({
    required super.block,
    required super.theme,
    super.onLinkTapped,
    super.onCheckboxTapped,
    SelectionRegistrar? selectionRegistrar,
  }) {
    registrar = selectionRegistrar;
  }

  final List<List<TextPainter>> _cellPainters = [];
  final _spanBuilder = InlineSpanBuilder();
  List<double> _columnWidths = [];
  List<double> _rowHeights = [];

  // Caching for performLayout
  double? _lastWidth;
  String _lastContent = '';

  // Selection support
  final List<_SelectableItem> _selectableItems = [];
  String _cachedPlainText = '';

  TableTheme get _tableTheme => theme.tableTheme ?? const TableTheme();

  List<List<String>> get _rows {
    final rows = block.metadata['rows'] as List<dynamic>?;
    if (rows == null) return [];
    return rows.map((r) => (r as List<dynamic>).cast<String>()).toList();
  }

  List<TableAlignment> get _alignments {
    final alignments = block.metadata['alignments'] as List<dynamic>?;
    if (alignments == null) return [];
    return alignments.map((a) {
      switch (a as String) {
        case 'center':
          return TableAlignment.center;
        case 'right':
          return TableAlignment.right;
        default:
          return TableAlignment.left;
      }
    }).toList();
  }

  @override
  TextPainter? get selectableTextPainter => null;

  @override
  void invalidateCache() {
    for (final row in _cellPainters) {
      for (final painter in row) {
        painter.dispose();
      }
    }
    _cellPainters.clear();
    _columnWidths = [];
    _rowHeights = [];
    _selectableItems.clear();
    _cachedPlainText = '';
    super.invalidateCache();
  }

  @override
  void dispose() {
    for (final row in _cellPainters) {
      for (final painter in row) {
        painter.dispose();
      }
    }
    super.dispose();
  }

  void _buildCellPainters(double maxWidth) {
    if (_cellPainters.isNotEmpty) return;

    final rows = _rows;
    if (rows.isEmpty) return;

    final cellPadding = _tableTheme.cellPadding ??
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8);

    // First, create all painters to measure
    final numColumns = rows.isNotEmpty ? rows[0].length : 0;
    _columnWidths = List.filled(numColumns, 0);
    _rowHeights = [];

    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      final rowPainters = <TextPainter>[];
      var rowHeight = 0.0;

      for (var colIndex = 0; colIndex < row.length; colIndex++) {
        final isHeader = rowIndex == 0;

        // Get base text color from theme
        final baseTextColor = theme.textStyle?.color ?? const Color(0xFF1F2937);

        final cellStyle = isHeader
            ? (_tableTheme.headerTextStyle ??
                TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: baseTextColor,
                ))
            : (_tableTheme.cellTextStyle ??
                TextStyle(
                  fontSize: 14,
                  color: baseTextColor,
                ));

        // Ensure color is set if not specified in theme style
        final styleWithColor = cellStyle.color == null
            ? cellStyle.copyWith(color: baseTextColor)
            : cellStyle;

        var content = row[colIndex];
        if (content.isNotEmpty) {
          final lastCodeUnit = content.codeUnitAt(content.length - 1);
          if (lastCodeUnit >= 0xD800 && lastCodeUnit <= 0xDBFF) {
            content = content.substring(0, content.length - 1);
          }
        }

        final span = _spanBuilder.build(
          content,
          styleWithColor,
          theme,
          onLinkTapped: onLinkTapped,
        );

        final painter = TextPainter(
          text: span,
          textDirection: TextDirection.ltr,
          textAlign: _getTextAlign(colIndex),
        )..layout();

        rowPainters.add(painter);

        // Update column width
        final cellWidth = painter.width + cellPadding.horizontal;
        if (cellWidth > _columnWidths[colIndex]) {
          _columnWidths[colIndex] = cellWidth;
        }

        // Update row height
        final cellHeight = painter.height + cellPadding.vertical;
        if (cellHeight > rowHeight) {
          rowHeight = cellHeight;
        }
      }

      _cellPainters.add(rowPainters);
      _rowHeights.add(rowHeight);
    }

    // Adjust column widths to fit available space
    final totalWidth = _columnWidths.fold<double>(0, (sum, w) => sum + w);
    if (totalWidth > maxWidth && numColumns > 0) {
      final scale = maxWidth / totalWidth;
      _columnWidths = _columnWidths.map((w) => w * scale).toList();
    }

    // Re-layout painters with final widths
    for (var rowIndex = 0; rowIndex < _cellPainters.length; rowIndex++) {
      for (var colIndex = 0;
          colIndex < _cellPainters[rowIndex].length;
          colIndex++) {
        final painter = _cellPainters[rowIndex][colIndex];
        final cellPaddingHorizontal = cellPadding.horizontal;
        painter.layout(
          maxWidth: _columnWidths[colIndex] - cellPaddingHorizontal,
        );
      }
    }
  }

  TextAlign _getTextAlign(int columnIndex) {
    if (columnIndex >= _alignments.length) return TextAlign.left;
    switch (_alignments[columnIndex]) {
      case TableAlignment.center:
        return TextAlign.center;
      case TableAlignment.right:
        return TextAlign.right;
      case TableAlignment.left:
        return TextAlign.left;
    }
  }

  void _updateSelectableItems(double maxWidth) {
    _selectableItems.clear();
    _cachedPlainText = '';

    final cellPadding = _tableTheme.cellPadding ??
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8);

    var currentY = 0.0;
    var currentTextOffset = 0;

    for (var rowIndex = 0; rowIndex < _cellPainters.length; rowIndex++) {
      final rowHeight = _rowHeights[rowIndex];
      var currentX = 0.0;

      for (var colIndex = 0;
          colIndex < _cellPainters[rowIndex].length;
          colIndex++) {
        final painter = _cellPainters[rowIndex][colIndex];
        final cellWidth = _columnWidths[colIndex];

        // Calculate text position
        double textX;
        switch (_getTextAlign(colIndex)) {
          case TextAlign.center:
            textX = currentX + (cellWidth - painter.width) / 2;
          case TextAlign.right:
            textX = currentX + cellWidth - painter.width - cellPadding.right;
          default:
            textX = currentX + cellPadding.left;
        }

        final textY = currentY + (rowHeight - painter.height) / 2;
        final offset = Offset(textX, textY);

        final text = painter.plainText;
        // Use tab between cells, newline between rows
        final isLastCol = colIndex == _cellPainters[rowIndex].length - 1;
        final suffix = isLastCol ? '\n' : '\t';

        _selectableItems.add(_SelectableItem(
          painter: painter,
          offset: offset,
          startTextOffset: currentTextOffset,
          endTextOffset: currentTextOffset + text.length,
        ));

        _cachedPlainText += text + suffix;
        currentTextOffset += text.length + suffix.length;

        currentX += cellWidth;
      }

      currentY += rowHeight;
    }

    // Remove last newline if exists
    if (_cachedPlainText.isNotEmpty && _cachedPlainText.endsWith('\n')) {
      _cachedPlainText =
          _cachedPlainText.substring(0, _cachedPlainText.length - 1);
    }
  }

  @override
  double computeIntrinsicHeight(double width) {
    _buildCellPainters(width);

    final borderWidth = _tableTheme.borderWidth ?? 1;
    return _rowHeights.fold<double>(0, (sum, h) => sum + h) +
        borderWidth * (_rowHeights.length + 1);
  }

  @override
  void performLayout() {
    // Only rebuild cell painters if content or width changed
    if (_lastWidth != constraints.maxWidth || block.content != _lastContent) {
      for (final row in _cellPainters) {
        for (final painter in row) {
          painter.dispose();
        }
      }
      _cellPainters.clear();
      _columnWidths = [];
      _rowHeights = [];
      _selectableItems.clear();
      _lastWidth = constraints.maxWidth;
      _lastContent = block.content;
    }

    final height = computeIntrinsicHeight(constraints.maxWidth);
    size = Size(constraints.maxWidth, height);

    // Build selectable items after layout
    _updateSelectableItems(constraints.maxWidth);
    initSelectableIfNeeded();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    _buildCellPainters(constraints.maxWidth);

    final borderWidth = _tableTheme.borderWidth ?? 1;
    final borderColor = _tableTheme.borderColor ?? const Color(0xFFE5E7EB);
    final headerBgColor =
        _tableTheme.headerBackgroundColor ?? const Color(0xFFF9FAFB);
    final cellBgColor = _tableTheme.cellBackgroundColor;
    final cellPadding = _tableTheme.cellPadding ??
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8);

    var currentY = offset.dy;

    // First pass: Draw backgrounds and borders
    for (var rowIndex = 0; rowIndex < _cellPainters.length; rowIndex++) {
      final isHeader = rowIndex == 0;
      final rowHeight = _rowHeights[rowIndex];
      var currentX = offset.dx;

      // Draw row background
      final rowRect = Rect.fromLTWH(
        offset.dx,
        currentY,
        _columnWidths.fold<double>(0, (sum, w) => sum + w),
        rowHeight,
      );

      if (isHeader) {
        canvas.drawRect(rowRect, Paint()..color = headerBgColor);
      } else if (cellBgColor != null) {
        canvas.drawRect(rowRect, Paint()..color = cellBgColor);
      }

      // Draw cells
      for (var colIndex = 0;
          colIndex < _cellPainters[rowIndex].length;
          colIndex++) {
        final cellWidth = _columnWidths[colIndex];

        // Draw cell border
        final cellRect =
            Rect.fromLTWH(currentX, currentY, cellWidth, rowHeight);
        canvas.drawRect(
          cellRect,
          Paint()
            ..color = borderColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = borderWidth,
        );

        currentX += cellWidth;
      }

      currentY += rowHeight;
    }

    // Paint selection highlight
    paintSelection(context, offset);
    // Re-acquire canvas as paintSelection might have pushed layers
    final activeCanvas = context.canvas;

    // Second pass: Paint text
    currentY = offset.dy;
    for (var rowIndex = 0; rowIndex < _cellPainters.length; rowIndex++) {
      final rowHeight = _rowHeights[rowIndex];
      var currentX = offset.dx;

      for (var colIndex = 0;
          colIndex < _cellPainters[rowIndex].length;
          colIndex++) {
        final painter = _cellPainters[rowIndex][colIndex];
        final cellWidth = _columnWidths[colIndex];

        // Calculate text position based on alignment
        double textX;
        switch (_getTextAlign(colIndex)) {
          case TextAlign.center:
            textX = currentX + (cellWidth - painter.width) / 2;
          case TextAlign.right:
            textX = currentX + cellWidth - painter.width - cellPadding.right;
          default:
            textX = currentX + cellPadding.left;
        }

        final textY = currentY + (rowHeight - painter.height) / 2;
        painter.paint(activeCanvas, Offset(textX, textY));

        currentX += cellWidth;
      }
      currentY += rowHeight;
    }
  }

  @override
  Offset? getCursorOffset() {
    if (_cellPainters.isEmpty) return null;

    // Get the last row and last cell
    final lastRow = _cellPainters.last;
    if (lastRow.isEmpty) return null;

    final lastCellPainter = lastRow.last;

    // Calculate position at end of last cell
    final endPosition = TextPosition(offset: lastCellPainter.plainText.length);
    final endOffset = lastCellPainter.getOffsetForCaret(endPosition, Rect.zero);

    // Calculate X position - sum of column widths up to last column
    var xOffset = 0.0;
    for (var i = 0; i < _columnWidths.length; i++) {
      if (i < _columnWidths.length - 1) {
        xOffset += _columnWidths[i];
      } else {
        // For last column, add partial width based on text position
        final cellPadding = _tableTheme.cellPadding ??
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
        xOffset += cellPadding.left + endOffset.dx;
      }
    }

    // Calculate Y position - sum of row heights
    var yOffset = 0.0;
    final borderWidth = _tableTheme.borderWidth ?? 1;
    for (var i = 0; i < _rowHeights.length - 1; i++) {
      yOffset += _rowHeights[i] + borderWidth;
    }

    // Add position within last cell
    yOffset += (_rowHeights.last - lastCellPainter.height) / 2 + endOffset.dy;

    return Offset(xOffset, yOffset);
  }

  // --- SelectableTextMixin Overrides ---

  @override
  String get plainText => _cachedPlainText;

  @override
  List<TextBox> getBoxesForSelection(TextSelection selection) {
    final boxes = <TextBox>[];

    for (final item in _selectableItems) {
      final itemStart = item.startTextOffset;
      final itemEnd = item.endTextOffset;

      if (selection.start < itemEnd && selection.end > itemStart) {
        final localStart = (selection.start - itemStart)
            .clamp(0, item.painter.plainText.length);
        final localEnd =
            (selection.end - itemStart).clamp(0, item.painter.plainText.length);

        if (localStart < localEnd) {
          final itemBoxes = item.painter.getBoxesForSelection(
            TextSelection(baseOffset: localStart, extentOffset: localEnd),
          );

          for (final box in itemBoxes) {
            boxes.add(TextBox.fromLTRBD(
              box.left + item.offset.dx,
              box.top + item.offset.dy,
              box.right + item.offset.dx,
              box.bottom + item.offset.dy,
              box.direction,
            ));
          }
        }
      }
    }

    return boxes;
  }

  @override
  TextPosition getPositionForOffset(Offset offset) {
    for (final item in _selectableItems) {
      final itemRect = item.offset & item.painter.size;
      // Check if offset is within item bounds (with some tolerance)
      if (offset.dy >= itemRect.top - 2 &&
          offset.dy < itemRect.bottom + 2 &&
          offset.dx >= itemRect.left - 2 &&
          offset.dx < itemRect.right + 2) {
        final localOffset = offset - item.offset;
        final localPosition = item.painter.getPositionForOffset(localOffset);
        return TextPosition(
            offset: item.startTextOffset + localPosition.offset);
      }
    }

    // Fallback: find closest item vertically
    // This is a simple approximation. For tables, it's more complex.
    // If not found, return 0 or length.

    if (_selectableItems.isNotEmpty &&
        offset.dy < _selectableItems.first.offset.dy) {
      return const TextPosition(offset: 0);
    }

    if (_selectableItems.isNotEmpty &&
        offset.dy >= _selectableItems.last.offset.dy) {
      return TextPosition(offset: _cachedPlainText.length);
    }

    return const TextPosition(offset: 0);
  }

  @override
  TextRange getWordBoundary(TextPosition position) {
    for (final item in _selectableItems) {
      if (position.offset >= item.startTextOffset &&
          position.offset <= item.endTextOffset) {
        final localOffset = position.offset - item.startTextOffset;
        final range =
            item.painter.getWordBoundary(TextPosition(offset: localOffset));
        return TextRange(
          start: item.startTextOffset + range.start,
          end: item.startTextOffset + range.end,
        );
      }
    }
    return TextRange.empty;
  }

  @override
  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype) {
    for (final item in _selectableItems) {
      if (position.offset >= item.startTextOffset &&
          position.offset <= item.endTextOffset) {
        final localOffset = position.offset - item.startTextOffset;
        final clampedLocalOffset =
            localOffset.clamp(0, item.painter.plainText.length);

        final offset = item.painter.getOffsetForCaret(
            TextPosition(offset: clampedLocalOffset), caretPrototype);
        return offset + item.offset;
      }
    }
    return Offset.zero;
  }

  @override
  double get preferredLineHeight {
    if (_cellPainters.isNotEmpty && _cellPainters.first.isNotEmpty) {
      return _cellPainters.first.first.preferredLineHeight;
    }
    return 14.0;
  }

  @override
  List<ui.LineMetrics> computeLineMetrics() {
    return [];
  }
}

class _SelectableItem {
  _SelectableItem({
    required this.painter,
    required this.offset,
    required this.startTextOffset,
    required this.endTextOffset,
  });

  final TextPainter painter;
  final Offset offset;
  final int startTextOffset;
  final int endTextOffset;
}
