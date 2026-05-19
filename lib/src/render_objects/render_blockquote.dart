import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

import '../parsing/markdown_block.dart';
import '../text/inline_span_builder.dart';
import '../theme/markdown_theme.dart';
import 'base/render_markdown_block.dart';
import 'mixins/selectable_text_mixin.dart';

/// Renders a blockquote.
class RenderMarkdownBlockquote extends RenderMarkdownBlock
    with SelectableTextMixin, RelayoutWhenSystemFontsChangeMixin {
  /// Creates a new render blockquote.
  RenderMarkdownBlockquote({
    required super.block,
    required super.theme,
    super.onLinkTapped,
    super.onCheckboxTapped,
    SelectionRegistrar? selectionRegistrar,
  }) {
    registrar = selectionRegistrar;
  }

  final List<TextPainter> _painters = [];
  final _spanBuilder = InlineSpanBuilder();

  // Selection support
  final List<_SelectableItem> _selectableItems = [];
  String _cachedPlainText = '';

  // Caching for performLayout
  double? _lastWidth;
  String _lastContent = '';

  BlockquoteTheme get _blockquoteTheme =>
      theme.blockquoteTheme ?? const BlockquoteTheme();

  @override
  TextPainter? get selectableTextPainter => null;

  @override
  void invalidateCache() {
    _spanBuilder.dispose();
    _disposePainters();
    _selectableItems.clear();
    _cachedPlainText = '';
    super.invalidateCache();
  }

  @override
  void systemFontsDidChange() {
    _spanBuilder.dispose();
    _disposePainters();
    _lastContent = '';
    super.systemFontsDidChange();
  }

  void _disposePainters() {
    for (final painter in _painters) {
      painter.dispose();
    }
    _painters.clear();
  }

  @override
  void dispose() {
    _disposePainters();
    super.dispose();
  }

  bool get _hasChildren => block.children.isNotEmpty;

  void _buildPainters(double maxWidth) {
    if (_painters.isNotEmpty) return;

    final padding =
        _blockquoteTheme.padding ?? const EdgeInsets.fromLTRB(16, 12, 12, 12);
    final borderWidth = _blockquoteTheme.borderWidth ?? 4;
    final availableWidth = maxWidth - padding.horizontal - borderWidth;

    if (_hasChildren) {
      // Render each child block
      for (final childBlock in block.children) {
        final painter = _createPainterForBlock(childBlock, availableWidth);
        _painters.add(painter);
      }
    } else {
      // Render content directly
      final baseStyle = _blockquoteTheme.textStyle ??
          TextStyle(
            fontSize: 16,
            fontStyle: FontStyle.italic,
            color: theme.textStyle?.color ?? const Color(0xFF4B5563),
          );

      var content = block.content;
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
      )..layout(maxWidth: availableWidth > 0 ? availableWidth : 0);

      _painters.add(painter);
    }
  }

  TextPainter _createPainterForBlock(
    MarkdownBlock childBlock,
    double availableWidth,
  ) {
    final baseStyle = _blockquoteTheme.textStyle ??
        TextStyle(
          fontSize: 16,
          color: theme.textStyle?.color ?? const Color(0xFF4B5563),
        );

    TextSpan span;

    switch (childBlock.type) {
      case MarkdownBlockType.paragraph:
        var content = childBlock.content;
        if (content.isNotEmpty) {
          final lastCodeUnit = content.codeUnitAt(content.length - 1);
          if (lastCodeUnit >= 0xD800 && lastCodeUnit <= 0xDBFF) {
            content = content.substring(0, content.length - 1);
          }
        }
        span = _spanBuilder.build(
          content,
          baseStyle.copyWith(fontStyle: FontStyle.italic),
          theme,
          onLinkTapped: onLinkTapped,
        );

      case MarkdownBlockType.unorderedList:
      case MarkdownBlockType.orderedList:
        // Render list items with bullets/numbers
        final items = (childBlock.metadata['items'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [];
        final isOrdered = childBlock.type == MarkdownBlockType.orderedList;
        final start = (childBlock.metadata['start'] as int?) ?? 1;

        final children = <InlineSpan>[];
        for (var i = 0; i < items.length; i++) {
          final item = items[i];
          var content = item['content'] as String? ?? '';
          if (content.isNotEmpty) {
            final lastCodeUnit = content.codeUnitAt(content.length - 1);
            if (lastCodeUnit >= 0xD800 && lastCodeUnit <= 0xDBFF) {
              content = content.substring(0, content.length - 1);
            }
          }
          final prefix = isOrdered ? '${start + i}. ' : '• ';

          if (i > 0) {
            children.add(const TextSpan(text: '\n'));
          }

          children.add(
            TextSpan(
              text: prefix,
              style: baseStyle.copyWith(fontStyle: FontStyle.normal),
            ),
          );

          // Parse inline content
          final contentSpan = _spanBuilder.build(
            content,
            baseStyle.copyWith(fontStyle: FontStyle.normal),
            theme,
            onLinkTapped: onLinkTapped,
          );
          children.add(contentSpan);
        }

        span = TextSpan(children: children);

      case MarkdownBlockType.header:
        final level = (childBlock.metadata['level'] as int?) ?? 1;
        final headerStyle =
            theme.headerTheme?.getStyleForLevel(level) ?? baseStyle;
        var content = childBlock.content;
        if (content.isNotEmpty) {
          final lastCodeUnit = content.codeUnitAt(content.length - 1);
          if (lastCodeUnit >= 0xD800 && lastCodeUnit <= 0xDBFF) {
            content = content.substring(0, content.length - 1);
          }
        }
        span = _spanBuilder.build(
          content,
          headerStyle,
          theme,
          onLinkTapped: onLinkTapped,
        );

      case MarkdownBlockType.codeBlock:
        final codeStyle = theme.codeTheme?.textStyle ??
            baseStyle.copyWith(fontFamily: 'monospace');
        var content = childBlock.content;
        if (content.isNotEmpty) {
          final lastCodeUnit = content.codeUnitAt(content.length - 1);
          if (lastCodeUnit >= 0xD800 && lastCodeUnit <= 0xDBFF) {
            content = content.substring(0, content.length - 1);
          }
        }
        span = TextSpan(text: content, style: codeStyle);

      default:
        var content = childBlock.content;
        if (content.isNotEmpty) {
          final lastCodeUnit = content.codeUnitAt(content.length - 1);
          if (lastCodeUnit >= 0xD800 && lastCodeUnit <= 0xDBFF) {
            content = content.substring(0, content.length - 1);
          }
        }
        span = _spanBuilder.build(
          content,
          baseStyle,
          theme,
          onLinkTapped: onLinkTapped,
        );
    }

    return TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: availableWidth > 0 ? availableWidth : 0);
  }

  void _updateSelectableItems(double maxWidth) {
    _selectableItems.clear();
    _cachedPlainText = '';

    final padding =
        _blockquoteTheme.padding ?? const EdgeInsets.fromLTRB(16, 12, 12, 12);
    final borderWidth = _blockquoteTheme.borderWidth ?? 4;
    final blockSpacing = theme.blockSpacing ?? 16.0;

    var currentY = padding.top;
    var currentTextOffset = 0;

    for (var i = 0; i < _painters.length; i++) {
      final painter = _painters[i];
      final offset = Offset(borderWidth + padding.left, currentY);

      final text = painter.plainText;
      final suffix = i < _painters.length - 1 ? '\n' : '';

      _selectableItems.add(_SelectableItem(
        painter: painter,
        offset: offset,
        startTextOffset: currentTextOffset,
        endTextOffset: currentTextOffset + text.length,
      ));

      _cachedPlainText += text + suffix;
      currentTextOffset += text.length + suffix.length;

      currentY += painter.height;
      if (i < _painters.length - 1) {
        currentY += blockSpacing;
      }
    }
  }

  @override
  double computeIntrinsicHeight(double width) {
    _buildPainters(width);

    final padding =
        _blockquoteTheme.padding ?? const EdgeInsets.fromLTRB(16, 12, 12, 12);
    final blockSpacing = theme.blockSpacing ?? 16.0;

    var height = padding.top;
    for (var i = 0; i < _painters.length; i++) {
      height += _painters[i].height;
      if (i < _painters.length - 1) {
        height += blockSpacing;
      }
    }
    height += padding.bottom;

    return height;
  }

  @override
  void performLayout() {
    // Only rebuild painters if content or width changed
    if (_lastWidth != constraints.maxWidth || block.content != _lastContent) {
      _disposePainters();
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
    final canvas = context.canvas;
    final padding =
        _blockquoteTheme.padding ?? const EdgeInsets.fromLTRB(16, 12, 12, 12);
    final borderWidth = _blockquoteTheme.borderWidth ?? 4;
    final borderColor = _blockquoteTheme.borderColor ?? const Color(0xFFD1D5DB);
    final backgroundColor = _blockquoteTheme.backgroundColor;
    final blockSpacing = theme.blockSpacing ?? 16.0;

    // Draw background if specified
    if (backgroundColor != null) {
      final rect = offset & size;
      canvas.drawRect(rect, Paint()..color = backgroundColor);
    }

    // Draw left border
    final borderRect = Rect.fromLTWH(
      offset.dx,
      offset.dy,
      borderWidth,
      size.height,
    );
    canvas.drawRect(borderRect, Paint()..color = borderColor);

    // Draw content
    _buildPainters(constraints.maxWidth);

    // Paint selection highlight
    paintSelection(context, offset);
    // Re-acquire canvas as paintSelection might have pushed layers
    final activeCanvas = context.canvas;

    var currentY = offset.dy + padding.top;
    for (var i = 0; i < _painters.length; i++) {
      final painter = _painters[i];
      final textOffset =
          Offset(offset.dx + borderWidth + padding.left, currentY);
      painter.paint(activeCanvas, textOffset);
      currentY += painter.height;
      if (i < _painters.length - 1) {
        currentY += blockSpacing;
      }
    }
  }

  @override
  Offset? getCursorOffset() {
    if (_painters.isEmpty) return null;

    // Get the last painter
    final lastPainter = _painters.last;

    // Get the position at the end of the last block's text
    final endPosition = TextPosition(offset: lastPainter.plainText.length);
    final endOffset = lastPainter.getOffsetForCaret(endPosition, Rect.zero);

    // Calculate Y position - sum of all previous painters
    final padding =
        _blockquoteTheme.padding ?? const EdgeInsets.fromLTRB(16, 12, 12, 12);
    final blockSpacing = theme.blockSpacing ?? 16.0;
    final borderWidth = _blockquoteTheme.borderWidth ?? 4;

    var yOffset = padding.top;
    for (var i = 0; i < _painters.length - 1; i++) {
      yOffset += _painters[i].height + blockSpacing;
    }

    // Add X offset (border + padding)
    final xOffset = borderWidth + padding.left + endOffset.dx;

    return Offset(xOffset, yOffset + endOffset.dy);
  }

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
      if (offset.dy >= itemRect.top && offset.dy < itemRect.bottom + 4) {
        final localOffset = offset - item.offset;
        final localPosition = item.painter.getPositionForOffset(localOffset);
        return TextPosition(
            offset: item.startTextOffset + localPosition.offset);
      }
    }

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
    if (_painters.isNotEmpty) {
      return _painters.first.preferredLineHeight;
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
