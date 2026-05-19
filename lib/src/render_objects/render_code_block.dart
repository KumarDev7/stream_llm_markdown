import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../text/syntax_highlighter.dart';
import '../theme/markdown_theme.dart';
import 'base/render_markdown_block.dart';
import 'mixins/selectable_text_mixin.dart';

/// Renders a code block with syntax highlighting.
class RenderMarkdownCodeBlock extends RenderMarkdownBlock
    with SelectableTextMixin {
  /// Creates a new render code block.
  RenderMarkdownCodeBlock({
    required super.block,
    required super.theme,
    super.onLinkTapped,
    super.onCheckboxTapped,
    SelectionRegistrar? selectionRegistrar,
  }) {
    registrar = selectionRegistrar;
  }

  TextPainter? _codePainter;
  TextPainter? _labelPainter;
  final _highlighter = const SyntaxHighlighter();

  bool _isHoveringCopy = false;
  Rect? _copyButtonRect;
  Offset _textOffset = Offset.zero;

  bool _isDisposed = false;
  double? _lastWidth;
  String _lastContent = '';

  @override
  TextPainter? get selectableTextPainter {
    if (_isDisposed) return null;
    return _codePainter;
  }

  @override
  Offset get textPaintOffset => _textOffset;

  String get _language => (block.metadata['language'] as String?) ?? '';

  CodeBlockTheme get _codeTheme => theme.codeTheme ?? CodeBlockTheme.light();

  @override
  void invalidateCache() {
    // Don't dispose painters here as they might still be referenced
    // by the selection system during updates. Let GC handle it.
    _codePainter = null;
    _labelPainter = null;
    super.invalidateCache();
  }

  TextPainter _getCodePainter(double maxWidth) {
    if (_isDisposed) {
      // Should not happen, but return a dummy painter if it does
      return TextPainter(textDirection: TextDirection.ltr)..layout();
    }

    final padding = _codeTheme.padding ?? const EdgeInsets.all(16);
    final contentWidth = maxWidth - padding.horizontal;

    if (_codePainter != null) {
      _codePainter!.layout(maxWidth: contentWidth);
      return _codePainter!;
    }

    final codeStyle = _codeTheme.textStyle ??
        const TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
        );

    final syntaxTheme = _codeTheme.syntaxTheme ?? SyntaxTheme.light();
    var content = block.content;
    if (content.isNotEmpty) {
      final lastCodeUnit = content.codeUnitAt(content.length - 1);
      if (lastCodeUnit >= 0xD800 && lastCodeUnit <= 0xDBFF) {
        content = content.substring(0, content.length - 1);
      }
    }

    final spans = _highlighter.highlight(
      content,
      _language,
      syntaxTheme,
      codeStyle,
    );

    _codePainter = TextPainter(
      text: TextSpan(children: spans),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: contentWidth);

    return _codePainter!;
  }

  TextPainter _getLabelPainter() {
    if (_isDisposed) {
      return TextPainter(textDirection: TextDirection.ltr)..layout();
    }

    if (_labelPainter != null) {
      _labelPainter!.layout();
      return _labelPainter!;
    }

    if (_language.isEmpty) {
      _labelPainter = TextPainter(
        text: const TextSpan(text: ''),
        textDirection: TextDirection.ltr,
      )..layout();
      return _labelPainter!;
    }

    final labelStyle = _codeTheme.labelStyle ??
        const TextStyle(
          fontSize: 12,
          color: Color(0xFF6B7280),
        );

    _labelPainter = TextPainter(
      text: TextSpan(text: _language, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    return _labelPainter!;
  }

  @override
  double computeIntrinsicHeight(double width) {
    if (_isDisposed) return 0;
    final padding = _codeTheme.padding ?? const EdgeInsets.all(16);
    final codePainter = _getCodePainter(width);
    final labelPainter = _getLabelPainter();

    var height = padding.vertical + codePainter.height;
    if (_language.isNotEmpty) {
      height += labelPainter.height + 8; // Label + spacing
    }

    return height;
  }

  @override
  void performLayout() {
    if (_isDisposed) return;

    // Invalidate painters if content or width changed
    if (_lastWidth != constraints.maxWidth || block.content != _lastContent) {
      _codePainter?.dispose();
      _codePainter = null;
      _labelPainter?.dispose();
      _labelPainter = null;
      _lastWidth = constraints.maxWidth;
      _lastContent = block.content;
    }

    final height = computeIntrinsicHeight(constraints.maxWidth);
    size = Size(constraints.maxWidth, height);

    // Calculate copy button rect
    const buttonSize = 32.0;
    _copyButtonRect = Rect.fromLTWH(
      size.width - buttonSize - 8,
      8,
      buttonSize,
      buttonSize,
    );

    // Calculate text offset for selection
    final padding = _codeTheme.padding ?? const EdgeInsets.all(16);
    var offsetY = padding.top;
    if (_language.isNotEmpty) {
      final labelPainter = _getLabelPainter();
      offsetY += labelPainter.height + 8;
    }
    _textOffset = Offset(padding.left, offsetY);

    // Initialize selectable after layout
    initSelectableIfNeeded();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_isDisposed) return;
    var canvas = context.canvas;
    final padding = _codeTheme.padding ?? const EdgeInsets.all(16);
    final borderRadius = _codeTheme.borderRadius ?? 8.0;
    final backgroundColor =
        _codeTheme.backgroundColor ?? const Color(0xFFF3F4F6);

    // Draw background
    final rect = offset & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    canvas.drawRRect(
      rrect,
      Paint()..color = backgroundColor,
    );

    // Paint selection highlight
    // This might push layers, so we must re-acquire the canvas afterwards
    paintSelection(context, offset);
    canvas = context.canvas;

    var contentOffset = offset + Offset(padding.left, padding.top);

    // Draw language label
    if (_language.isNotEmpty) {
      final labelPainter = _getLabelPainter()..paint(canvas, contentOffset);
      contentOffset = contentOffset.translate(0, labelPainter.height + 8);
    }

    // Draw code
    _getCodePainter(constraints.maxWidth).paint(canvas, contentOffset);

    // Draw copy button
    _drawCopyButton(canvas, offset);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _codePainter?.dispose();
    _codePainter = null;
    _labelPainter?.dispose();
    _labelPainter = null;
    disposeSelectable();
    super.dispose();
  }

  void _drawCopyButton(Canvas canvas, Offset offset) {
    if (_copyButtonRect == null) return;

    final buttonRect = _copyButtonRect!.shift(offset);
    final buttonColor = _isHoveringCopy
        ? (_codeTheme.copyButtonColor ?? const Color(0xFF6B7280))
            .withValues(alpha: 0.8)
        : (_codeTheme.copyButtonColor ?? const Color(0xFF6B7280))
            .withValues(alpha: 0.5);

    // Draw button background on hover
    if (_isHoveringCopy) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(buttonRect, const Radius.circular(4)),
        Paint()..color = const Color(0x1A000000),
      );
    }

    // Draw copy icon (simplified rectangle representation)
    final iconPaint = Paint()
      ..color = buttonColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const iconSize = 16.0;
    final iconOffset =
        buttonRect.center - const Offset(iconSize / 2, iconSize / 2);

    // Back rectangle
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            iconOffset.dx + 3,
            iconOffset.dy,
            iconSize - 3,
            iconSize - 3,
          ),
          const Radius.circular(2),
        ),
        iconPaint,
      )

      // Front rectangle
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            iconOffset.dx,
            iconOffset.dy + 3,
            iconSize - 3,
            iconSize - 3,
          ),
          const Radius.circular(2),
        ),
        iconPaint
          ..style = PaintingStyle.fill
          ..color = backgroundColor,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            iconOffset.dx,
            iconOffset.dy + 3,
            iconSize - 3,
            iconSize - 3,
          ),
          const Radius.circular(2),
        ),
        iconPaint
          ..style = PaintingStyle.stroke
          ..color = buttonColor,
      );
  }

  Color get backgroundColor =>
      _codeTheme.backgroundColor ?? const Color(0xFFF3F4F6);

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (_copyButtonRect == null) return;

    final isInButton = _copyButtonRect!.contains(event.localPosition);

    if (event is PointerHoverEvent) {
      if (isInButton != _isHoveringCopy) {
        _isHoveringCopy = isInButton;
        markNeedsPaint();
      }
    } else if (event is PointerDownEvent && isInButton) {
      _copyToClipboard();
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: block.content));
  }

  @override
  Offset? getCursorOffset() {
    if (_codePainter == null) return null;

    // Get the position at the end of the code text
    final endPosition = TextPosition(offset: _codePainter!.plainText.length);
    final endOffset = _codePainter!.getOffsetForCaret(endPosition, Rect.zero);

    // Add the text offset (padding + label)
    return endOffset + _textOffset;
  }
}
