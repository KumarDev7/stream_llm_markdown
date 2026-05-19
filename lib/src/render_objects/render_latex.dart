import 'package:flutter/rendering.dart';

import 'base/render_markdown_block.dart';

/// Renders a LaTeX block (placeholder rendering).
class RenderMarkdownLatex extends RenderMarkdownBlock {
  /// Creates a new render latex.
  RenderMarkdownLatex({
    required super.block,
    required super.theme,
    super.onLinkTapped,
    super.onCheckboxTapped,
  });

  TextPainter? _textPainter;
  double? _lastWidth;
  String _lastContent = '';

  bool get _isInline => (block.metadata['inline'] as bool?) ?? false;

  @override
  void invalidateCache() {
    _textPainter?.dispose();
    _textPainter = null;
    super.invalidateCache();
  }

  TextPainter _getTextPainter(double maxWidth) {
    if (_textPainter != null) return _textPainter!;

    final style = TextStyle(
      fontFamily: 'monospace',
      fontSize: _isInline ? 14 : 16,
      fontStyle: FontStyle.italic,
      color: const Color(0xFF6B7280),
      backgroundColor: const Color(0xFFF3F4F6),
    );

    final displayText =
        _isInline ? '\$${block.content}\$' : '\$\$\n${block.content}\n\$\$';

    _textPainter = TextPainter(
      text: TextSpan(text: displayText, style: style),
      textDirection: TextDirection.ltr,
      textAlign: _isInline ? TextAlign.left : TextAlign.center,
    )..layout(maxWidth: maxWidth);

    return _textPainter!;
  }

  @override
  double computeIntrinsicHeight(double width) {
    final painter = _getTextPainter(width);
    return painter.height + (_isInline ? 0 : 24);
  }

  @override
  void performLayout() {
    // Only rebuild the painter if content or width changed
    if (_textPainter == null ||
        _lastWidth != constraints.maxWidth ||
        block.content != _lastContent) {
      _textPainter?.dispose();
      _textPainter = null;
      _lastWidth = constraints.maxWidth;
      _lastContent = block.content;
    }

    final height = computeIntrinsicHeight(constraints.maxWidth);
    size = Size(constraints.maxWidth, height);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final painter = _getTextPainter(constraints.maxWidth);

    if (!_isInline) {
      final bgRect = Rect.fromLTWH(
        offset.dx,
        offset.dy,
        size.width,
        size.height,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bgRect, const Radius.circular(8)),
        Paint()..color = const Color(0xFFF9FAFB),
      );
    }

    final textOffset = _isInline
        ? offset
        : Offset(
            offset.dx + (size.width - painter.width) / 2,
            offset.dy + 12,
          );

    painter.paint(canvas, textOffset);
  }
}
