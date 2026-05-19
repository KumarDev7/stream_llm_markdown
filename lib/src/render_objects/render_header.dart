import 'package:flutter/rendering.dart';

import '../text/inline_span_builder.dart';
import '../theme/markdown_theme.dart';
import 'base/render_markdown_block.dart';
import 'mixins/selectable_text_mixin.dart';

/// Renders a header block (H1-H6).
class RenderMarkdownHeader extends RenderMarkdownBlock
    with SelectableTextMixin {
  /// Creates a new render header.
  RenderMarkdownHeader({
    required super.block,
    required super.theme,
    super.onLinkTapped,
    super.onCheckboxTapped,
    SelectionRegistrar? selectionRegistrar,
  }) {
    registrar = selectionRegistrar;
  }

  TextPainter? _textPainter;
  final _spanBuilder = InlineSpanBuilder();
  double? _lastWidth;
  String _lastContent = '';

  @override
  TextPainter? get selectableTextPainter => _textPainter;

  int get _level => (block.metadata['level'] as int?) ?? 1;

  @override
  void invalidateCache() {
    // Don't dispose painter here as it might still be referenced
    // by the selection system during updates. Let GC handle it.
    _textPainter = null;
    super.invalidateCache();
  }

  TextPainter _getTextPainter(double maxWidth) {
    if (_textPainter != null) return _textPainter!;

    final headerTheme = theme.headerTheme ?? const HeaderTheme();
    final baseStyle = headerTheme.getStyleForLevel(_level);

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

    _textPainter = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    return _textPainter!;
  }

  @override
  double computeIntrinsicHeight(double width) {
    final painter = _getTextPainter(width);
    return painter.height;
  }

  @override
  void performLayout() {
    // Only rebuild the painter if content, width, or level changed
    final effectiveContent = '${_level}:${block.content}';
    if (_textPainter == null ||
        _lastWidth != constraints.maxWidth ||
        _lastContent != effectiveContent) {
      _textPainter?.dispose();
      _textPainter = null;
      _lastWidth = constraints.maxWidth;
      _lastContent = effectiveContent;
    }

    final painter = _getTextPainter(constraints.maxWidth);
    size = Size(constraints.maxWidth, painter.height);

    // Initialize selectable after layout
    initSelectableIfNeeded();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    var canvas = context.canvas;

    // Paint selection highlight first
    paintSelection(context, offset);
    canvas = context.canvas;

    final painter = _getTextPainter(constraints.maxWidth);
    painter.paint(canvas, offset);
  }

  @override
  void dispose() {
    disposeSelectable();
    super.dispose();
  }

  @override
  Offset? getCursorOffset() {
    if (_textPainter == null) return null;

    // Get the position at the end of the text
    final endPosition = TextPosition(offset: _textPainter!.plainText.length);
    final endOffset = _textPainter!.getOffsetForCaret(endPosition, Rect.zero);

    return endOffset;
  }
}
