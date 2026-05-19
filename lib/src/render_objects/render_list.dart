import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

import '../parsing/markdown_block.dart';
import '../text/inline_span_builder.dart';
import '../theme/markdown_theme.dart';
import 'base/render_markdown_block.dart';
import 'mixins/selectable_text_mixin.dart';

class RenderMarkdownList extends RenderMarkdownBlock
    with SelectableTextMixin, RelayoutWhenSystemFontsChangeMixin {
  RenderMarkdownList({
    required super.block,
    required super.theme,
    super.onLinkTapped,
    super.onCheckboxTapped,
    SelectionRegistrar? selectionRegistrar,
  }) {
    registrar = selectionRegistrar;
  }

  final List<TextPainter> _itemPainters = [];
  final _spanBuilder = InlineSpanBuilder();
  final List<Rect> _checkboxRects = [];
  final List<_NestedListInfo> _nestedLists = [];

  double? _lastWidth;
  String _lastContent = '';

  final List<_SelectableItem> _selectableItems = [];
  String _cachedPlainText = '';

  ListTheme get _listTheme => theme.listTheme ?? const ListTheme();

  bool get _isOrdered => block.type == MarkdownBlockType.orderedList;

  List<Map<String, dynamic>> get _items =>
      (block.metadata['items'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>() ??
      [];

  int get _start => (block.metadata['start'] as int?) ?? 1;

  @override
  TextPainter? get selectableTextPainter => null;

  @override
  void invalidateCache() {
    _spanBuilder.dispose();
    for (final painter in _itemPainters) {
      painter.dispose();
    }
    _itemPainters.clear();
    _checkboxRects.clear();
    _disposeNestedLists();
    _selectableItems.clear();
    _cachedPlainText = '';
    super.invalidateCache();
  }

  @override
  void systemFontsDidChange() {
    _spanBuilder.dispose();
    for (final painter in _itemPainters) {
      painter.dispose();
    }
    _itemPainters.clear();
    _checkboxRects.clear();
    _lastContent = '';
    super.systemFontsDidChange();
  }

  void _disposeNestedLists() {
    for (final nested in _nestedLists) {
      for (final painter in nested.painters) {
        painter.dispose();
      }
    }
    _nestedLists.clear();
  }

  void _buildItemPainters(double maxWidth) {
    if (_itemPainters.isNotEmpty) return;

    final indentWidth = _listTheme.indentWidth ?? 24;
    final availableWidth = maxWidth - indentWidth;
    final baseStyle = theme.textStyle ?? const TextStyle(fontSize: 16);

    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      var content = item['content'] as String? ?? '';
      if (content.isNotEmpty) {
        final lastCodeUnit = content.codeUnitAt(content.length - 1);
        if (lastCodeUnit >= 0xD800 && lastCodeUnit <= 0xDBFF) {
          content = content.substring(0, content.length - 1);
        }
      }

      final span = _spanBuilder.build(
        content,
        baseStyle,
        theme,
        onLinkTapped: onLinkTapped,
      );

      final painter = TextPainter(
        text: span,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: availableWidth);

      _itemPainters.add(painter);

      // Build nested list painters if children exist
      final children = item['children'] as List<dynamic>?;
      if (children != null && children.isNotEmpty) {
        final nestedItems = children.cast<Map<String, dynamic>>();
        final nestedPainters = <TextPainter>[];
        final nestedAvailableWidth = availableWidth - indentWidth;

        for (final nestedItem in nestedItems) {
          var nestedContent = nestedItem['content'] as String? ?? '';
          if (nestedContent.isNotEmpty) {
            final lastCodeUnit =
                nestedContent.codeUnitAt(nestedContent.length - 1);
            if (lastCodeUnit >= 0xD800 && lastCodeUnit <= 0xDBFF) {
              nestedContent =
                  nestedContent.substring(0, nestedContent.length - 1);
            }
          }

          final nestedSpan = _spanBuilder.build(
            nestedContent,
            baseStyle,
            theme,
            onLinkTapped: onLinkTapped,
          );

          final nestedPainter = TextPainter(
            text: nestedSpan,
            textDirection: TextDirection.ltr,
          )..layout(
              maxWidth: nestedAvailableWidth > 0 ? nestedAvailableWidth : 0,
            );

          nestedPainters.add(nestedPainter);
        }

        // Determine if nested list is ordered by checking if any item looks ordered
        const isNestedOrdered =
            false; // Nested lists inherit unordered by default

        _nestedLists.add(
          _NestedListInfo(
            itemIndex: i,
            items: nestedItems,
            isOrdered: isNestedOrdered,
            painters: nestedPainters,
          ),
        );
      }
    }
  }

  void _updateSelectableItems(double maxWidth) {
    _selectableItems.clear();
    _cachedPlainText = '';

    final indentWidth = _listTheme.indentWidth ?? 24;
    final itemSpacing = _listTheme.itemSpacing ?? 4;

    var currentY = 0.0;
    var currentTextOffset = 0;

    for (var i = 0; i < _itemPainters.length; i++) {
      final painter = _itemPainters[i];
      final offset = Offset(indentWidth, currentY);

      final text = painter.plainText;
      // Add newline only if not the last item or if there are nested items
      final suffix = '\n';

      _selectableItems.add(_SelectableItem(
        painter: painter,
        offset: offset,
        startTextOffset: currentTextOffset,
        endTextOffset: currentTextOffset + text.length,
      ));

      _cachedPlainText += text + suffix;
      currentTextOffset += text.length + suffix.length;

      currentY += painter.height;

      // Nested lists
      final nestedList =
          _nestedLists.where((n) => n.itemIndex == i).firstOrNull;
      if (nestedList != null) {
        final nestedIndentWidth = indentWidth * 2;

        for (var j = 0; j < nestedList.painters.length; j++) {
          currentY += itemSpacing;
          final nestedPainter = nestedList.painters[j];
          final nestedOffset = Offset(nestedIndentWidth, currentY);

          final nestedText = nestedPainter.plainText;
          final nestedSuffix = '\n';

          _selectableItems.add(_SelectableItem(
            painter: nestedPainter,
            offset: nestedOffset,
            startTextOffset: currentTextOffset,
            endTextOffset: currentTextOffset + nestedText.length,
          ));

          _cachedPlainText += nestedText + nestedSuffix;
          currentTextOffset += nestedText.length + nestedSuffix.length;

          currentY += nestedPainter.height;
        }
      }

      currentY += itemSpacing;
    }

    // Remove last newline if exists
    if (_cachedPlainText.isNotEmpty && _cachedPlainText.endsWith('\n')) {
      _cachedPlainText =
          _cachedPlainText.substring(0, _cachedPlainText.length - 1);
    }
  }

  @override
  double computeIntrinsicHeight(double width) {
    _buildItemPainters(width);

    final itemSpacing = _listTheme.itemSpacing ?? 4;
    var height = 0.0;

    for (var i = 0; i < _itemPainters.length; i++) {
      height += _itemPainters[i].height;

      // Add height for nested list if present
      final nestedList =
          _nestedLists.where((n) => n.itemIndex == i).firstOrNull;
      if (nestedList != null) {
        for (var j = 0; j < nestedList.painters.length; j++) {
          height += itemSpacing;
          height += nestedList.painters[j].height;
        }
      }

      if (i < _itemPainters.length - 1) {
        height += itemSpacing;
      }
    }

    return height;
  }

  @override
  void performLayout() {
    // Only rebuild painters if content or width changed
    if (_lastWidth != constraints.maxWidth || block.content != _lastContent) {
      for (final painter in _itemPainters) {
        painter.dispose();
      }
      _itemPainters.clear();
      _checkboxRects.clear();
      _disposeNestedLists();
      _selectableItems.clear();
      _cachedPlainText = '';
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
    final indentWidth = _listTheme.indentWidth ?? 24;
    final itemSpacing = _listTheme.itemSpacing ?? 4;
    final bulletColor = _listTheme.bulletColor ?? const Color(0xFF6B7280);

    _buildItemPainters(constraints.maxWidth);
    _checkboxRects.clear();

    // Paint selection highlight
    paintSelection(context, offset);
    // Re-acquire canvas as paintSelection might have pushed layers
    final activeCanvas = context.canvas;

    var currentY = offset.dy;

    for (var i = 0; i < _itemPainters.length; i++) {
      final item = _items[i];
      final painter = _itemPainters[i];
      final isChecked = item['checked'] as bool?;

      // Calculate vertical center for bullet/number
      final bulletY = currentY + painter.height / 2;

      if (isChecked != null) {
        // Task list item - draw checkbox
        const checkboxSize = 16.0;
        final checkboxX = offset.dx + (indentWidth - checkboxSize) / 2;
        final checkboxY = bulletY - checkboxSize / 2;
        final checkboxRect =
            Rect.fromLTWH(checkboxX, checkboxY, checkboxSize, checkboxSize);
        _checkboxRects.add(checkboxRect);

        final checkboxColor = isChecked
            ? (_listTheme.checkboxCheckedColor ?? const Color(0xFF2563EB))
            : (_listTheme.checkboxUncheckedColor ?? const Color(0xFF6B7280));

        // Draw checkbox
        activeCanvas.drawRRect(
          RRect.fromRectAndRadius(checkboxRect, const Radius.circular(3)),
          Paint()
            ..color = checkboxColor
            ..style = isChecked ? PaintingStyle.fill : PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );

        // Draw checkmark if checked
        if (isChecked) {
          final path = Path()
            ..moveTo(checkboxX + 3, bulletY)
            ..lineTo(checkboxX + 6, bulletY + 3)
            ..lineTo(checkboxX + 12, bulletY - 4);

          activeCanvas.drawPath(
            path,
            Paint()
              ..color = const Color(0xFFFFFFFF)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round,
          );
        }
      } else if (_isOrdered) {
        // Ordered list - draw number
        final number = '${_start + i}.';
        final numberPainter = TextPainter(
          text: TextSpan(
            text: number,
            style: TextStyle(
              fontSize: 16,
              color: bulletColor,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        numberPainter.paint(
          activeCanvas,
          Offset(
            offset.dx + indentWidth - numberPainter.width - 8,
            bulletY - numberPainter.height / 2,
          ),
        );
        numberPainter.dispose();
      } else {
        // Unordered list - draw bullet
        activeCanvas.drawCircle(
          Offset(offset.dx + indentWidth / 2, bulletY),
          3,
          Paint()..color = bulletColor,
        );
      }

      // Draw item text
      painter.paint(activeCanvas, Offset(offset.dx + indentWidth, currentY));

      currentY += painter.height;

      // Draw nested list if present
      final nestedList =
          _nestedLists.where((n) => n.itemIndex == i).firstOrNull;
      if (nestedList != null) {
        final nestedIndentWidth = indentWidth * 2;

        for (var j = 0; j < nestedList.painters.length; j++) {
          currentY += itemSpacing;

          final nestedItem = nestedList.items[j];
          final nestedPainter = nestedList.painters[j];
          final nestedBulletY = currentY + nestedPainter.height / 2;
          final nestedIsChecked = nestedItem['checked'] as bool?;

          if (nestedIsChecked != null) {
            // Nested task list item - draw checkbox
            const checkboxSize = 16.0;
            final checkboxX = offset.dx +
                nestedIndentWidth -
                indentWidth +
                (indentWidth - checkboxSize) / 2;
            final checkboxY = nestedBulletY - checkboxSize / 2;
            final checkboxRect =
                Rect.fromLTWH(checkboxX, checkboxY, checkboxSize, checkboxSize);

            final checkboxColor = nestedIsChecked
                ? (_listTheme.checkboxCheckedColor ?? const Color(0xFF2563EB))
                : (_listTheme.checkboxUncheckedColor ??
                    const Color(0xFF6B7280));

            activeCanvas.drawRRect(
              RRect.fromRectAndRadius(checkboxRect, const Radius.circular(3)),
              Paint()
                ..color = checkboxColor
                ..style =
                    nestedIsChecked ? PaintingStyle.fill : PaintingStyle.stroke
                ..strokeWidth = 1.5,
            );

            if (nestedIsChecked) {
              final path = Path()
                ..moveTo(checkboxX + 3, nestedBulletY)
                ..lineTo(checkboxX + 6, nestedBulletY + 3)
                ..lineTo(checkboxX + 12, nestedBulletY - 4);

              activeCanvas.drawPath(
                path,
                Paint()
                  ..color = const Color(0xFFFFFFFF)
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 2
                  ..strokeCap = StrokeCap.round
                  ..strokeJoin = StrokeJoin.round,
              );
            }
          } else if (nestedList.isOrdered) {
            // Nested ordered list - draw number
            final number = '${j + 1}.';
            final numberPainter = TextPainter(
              text: TextSpan(
                text: number,
                style: TextStyle(
                  fontSize: 16,
                  color: bulletColor,
                ),
              ),
              textDirection: TextDirection.ltr,
            )..layout();

            numberPainter.paint(
              activeCanvas,
              Offset(
                offset.dx + nestedIndentWidth - numberPainter.width - 8,
                nestedBulletY - numberPainter.height / 2,
              ),
            );
            numberPainter.dispose();
          } else {
            // Nested unordered list - draw smaller bullet
            activeCanvas.drawCircle(
              Offset(
                offset.dx + nestedIndentWidth - indentWidth / 2,
                nestedBulletY,
              ),
              2.5,
              Paint()..color = bulletColor,
            );
          }

          // Draw nested item text
          nestedPainter.paint(
            activeCanvas,
            Offset(offset.dx + nestedIndentWidth, currentY),
          );
          currentY += nestedPainter.height;
        }
      }

      currentY += itemSpacing;
    }
  }

  @override
  int getCheckboxAtPosition(Offset position) {
    for (var i = 0; i < _checkboxRects.length; i++) {
      if (_checkboxRects[i].contains(position)) {
        return i;
      }
    }
    return -1;
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerDownEvent) {
      final checkboxIndex = getCheckboxAtPosition(event.localPosition);
      if (checkboxIndex >= 0 && onCheckboxTapped != null) {
        final item = _items[checkboxIndex];
        final isChecked = item['checked'] as bool? ?? false;
        onCheckboxTapped!(checkboxIndex, !isChecked);
      }
    }
  }

  @override
  Offset? getCursorOffset() {
    if (_itemPainters.isEmpty) return null;

    // Get the last item painter
    final lastPainter = _itemPainters.last;

    // Get the position at the end of the last item's text
    final endPosition = TextPosition(offset: lastPainter.plainText.length);
    final endOffset = lastPainter.getOffsetForCaret(endPosition, Rect.zero);

    // Calculate Y position - sum of all previous items
    var yOffset = 0.0;
    final itemSpacing = _listTheme.itemSpacing ?? 8;
    for (var i = 0; i < _itemPainters.length - 1; i++) {
      yOffset += _itemPainters[i].height + itemSpacing;
    }

    // Add left indent and bullet/number width
    final leftIndent = _listTheme.indentWidth ?? 16.0;
    final bulletWidth = _listTheme.bulletSize ?? 6.0;
    final xOffset = leftIndent + bulletWidth + 8 + endOffset.dx;

    return Offset(xOffset, yOffset + endOffset.dy);
  }

  @override
  String get plainText => _cachedPlainText;

  @override
  List<TextBox> getBoxesForSelection(TextSelection selection) {
    final boxes = <TextBox>[];

    for (final item in _selectableItems) {
      // Check if this item overlaps with selection
      // Item range: [item.startTextOffset, item.endTextOffset]
      // Selection range: [selection.start, selection.end]

      final itemStart = item.startTextOffset;
      final itemEnd = item.endTextOffset;

      if (selection.start < itemEnd && selection.end > itemStart) {
        // Calculate intersection
        final localStart = (selection.start - itemStart)
            .clamp(0, item.painter.plainText.length);
        final localEnd =
            (selection.end - itemStart).clamp(0, item.painter.plainText.length);

        if (localStart < localEnd) {
          final itemBoxes = item.painter.getBoxesForSelection(
            TextSelection(baseOffset: localStart, extentOffset: localEnd),
          );

          // Shift boxes by item offset
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
    // Find which item contains the offset (vertically)
    for (final item in _selectableItems) {
      final itemRect = item.offset & item.painter.size;
      // We check vertical bounds loosely to capture clicks between items
      if (offset.dy >= itemRect.top && offset.dy < itemRect.bottom + 4) {
        // +4 for spacing
        // Map to local coordinates
        final localOffset = offset - item.offset;
        final localPosition = item.painter.getPositionForOffset(localOffset);
        return TextPosition(
            offset: item.startTextOffset + localPosition.offset);
      }
    }

    // If above first item
    if (_selectableItems.isNotEmpty &&
        offset.dy < _selectableItems.first.offset.dy) {
      return const TextPosition(offset: 0);
    }

    // If below last item
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
        // Clamp localOffset to painter length
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
    if (_itemPainters.isNotEmpty) {
      return _itemPainters.first.preferredLineHeight;
    }
    return 14.0;
  }

  @override
  List<ui.LineMetrics> computeLineMetrics() {
    // Return empty for now as it's complex to aggregate and mostly used for keyboard nav
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

/// Information about a nested list for rendering.
class _NestedListInfo {
  _NestedListInfo({
    required this.itemIndex,
    required this.items,
    required this.isOrdered,
    required this.painters,
  });

  final int itemIndex;
  final List<Map<String, dynamic>> items;
  final bool isOrdered;
  final List<TextPainter> painters;
}
