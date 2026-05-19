import 'package:flutter/rendering.dart';

import '../text/inline_span_builder.dart';
import 'base/render_markdown_block.dart';
import 'mixins/selectable_text_mixin.dart';

/// Renders a paragraph block.
class RenderMarkdownParagraph extends RenderMarkdownBlock
    with SelectableTextMixin {
  /// Creates a new render paragraph.
  RenderMarkdownParagraph({
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

  @override
  void invalidateCache() {
    // Don't dispose painter here as it might still be referenced
    // by the selection system during updates. Let GC handle it.
    _textPainter = null;
    super.invalidateCache();
  }

  TextPainter _getTextPainter(double maxWidth) {
    if (_textPainter != null) return _textPainter!;

    final baseStyle = theme.textStyle ?? const TextStyle(fontSize: 16);
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
    // Only rebuild the painter if content or width changed
    if (_textPainter == null ||
        _lastWidth != constraints.maxWidth ||
        block.content != _lastContent) {
      _textPainter?.dispose();
      _textPainter = null;
      _lastWidth = constraints.maxWidth;
      _lastContent = block.content;
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

    _textPainter?.paint(canvas, offset);
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

  @override
  String? getLinkAtPosition(Offset position) {
    if (_textPainter == null) return null;

    final textPosition = _textPainter!.getPositionForOffset(position);
    final span = _textPainter!.text;

    return _findLinkInSpan(span, textPosition.offset);
  }

  String? _findLinkInSpan(InlineSpan? span, int offset) {
    if (span == null) return null;

    if (span is TextSpan) {
      final text = span.text;
      final children = span.children;

      if (text != null) {
        if (offset < text.length) {
          // Check if this span has a recognizer (is a link)
          if (span.recognizer != null) {
            // Extract URL from the context - this is simplified
            return null; // Would need to store URL in recognizer
          }
          return null;
        }
        offset -= text.length;
      }

      if (children != null) {
        for (final child in children) {
          final result = _findLinkInSpan(child, offset);
          if (result != null) return result;

          if (child is TextSpan) {
            final childLength = _getSpanLength(child);
            if (offset < childLength) {
              if (child.recognizer != null) {
                return null; // Link found but URL not accessible
              }
            }
            offset -= childLength;
          }
        }
      }
    }

    return null;
  }

  int _getSpanLength(TextSpan span) {
    var length = span.text?.length ?? 0;
    if (span.children != null) {
      for (final child in span.children!) {
        if (child is TextSpan) {
          length += _getSpanLength(child);
        }
      }
    }
    return length;
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerDownEvent && _textPainter != null) {
      final position = event.localPosition;
      final textPosition = _textPainter!.getPositionForOffset(position);

      // Delegate to the text span's gesture recognizers
      final span = _textPainter!.text;
      if (span is TextSpan) {
        _handleTapOnSpan(span, textPosition.offset);
      }
    }
  }

  void _handleTapOnSpan(TextSpan span, int offset) {
    final text = span.text;

    if (text != null) {
      if (offset < text.length) {
        span.recognizer
            ?.addPointer(const PointerDownEvent(position: Offset.zero));
        return;
      }
      offset -= text.length;
    }

    if (span.children != null) {
      for (final child in span.children!) {
        if (child is TextSpan) {
          final childLength = _getSpanLength(child);
          if (offset < childLength) {
            _handleTapOnSpan(child, offset);
            return;
          }
          offset -= childLength;
        }
      }
    }
  }
}
