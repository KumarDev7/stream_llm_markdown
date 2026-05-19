import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import '../../parsing/markdown_block.dart';
import '../../theme/markdown_theme.dart';

/// Base class for all Markdown block RenderObjects.
abstract class RenderMarkdownBlock extends RenderBox {
  /// Creates a new render markdown block.
  RenderMarkdownBlock({
    required MarkdownBlock block,
    required MarkdownTheme theme,
    void Function(String url)? onLinkTapped,
    void Function(int index, bool checked)? onCheckboxTapped,
  })  : _block = block,
        _theme = theme,
        _onLinkTapped = onLinkTapped,
        _onCheckboxTapped = onCheckboxTapped;

  /// The markdown block data.
  MarkdownBlock get block => _block;
  MarkdownBlock _block;
  set block(MarkdownBlock value) {
    if (_block == value) return;
    final contentChanged = _block.content != value.content;
    _block = value;
    if (contentChanged) {
      invalidateCache();
    }
    markNeedsLayout();
  }

  /// The theme for rendering.
  MarkdownTheme get theme => _theme;
  MarkdownTheme _theme;
  set theme(MarkdownTheme value) {
    if (_theme == value) return;
    _theme = value;
    invalidateCache();
    markNeedsLayout();
  }

  /// Callback when a link is tapped.
  void Function(String url)? get onLinkTapped => _onLinkTapped;
  void Function(String url)? _onLinkTapped;
  set onLinkTapped(void Function(String url)? value) {
    if (_onLinkTapped == value) return;
    _onLinkTapped = value;
  }

  /// Callback when a checkbox is tapped.
  void Function(int index, bool checked)? get onCheckboxTapped =>
      _onCheckboxTapped;
  void Function(int index, bool checked)? _onCheckboxTapped;
  set onCheckboxTapped(void Function(int index, bool checked)? value) {
    if (_onCheckboxTapped == value) return;
    _onCheckboxTapped = value;
  }

  /// Cached text painter for performance.
  TextPainter? _cachedTextPainter;

  /// Cached paragraph for performance.
  ui.Paragraph? _cachedParagraph;

  /// Last constraints used for layout.
  BoxConstraints? _lastConstraints;

  /// Whether the cached layout is still valid.
  bool get isCacheValid => _cachedParagraph != null && _lastConstraints != null;

  /// Invalidates the cached layout.
  void invalidateCache() {
    _cachedTextPainter?.dispose();
    _cachedTextPainter = null;
    _cachedParagraph = null;
    _lastConstraints = null;
  }

  @override
  void dispose() {
    _cachedTextPainter?.dispose();
    _cachedTextPainter = null;
    _cachedParagraph = null;
    _lastConstraints = null;
    super.dispose();
  }

  @override
  void performLayout() {
    final newConstraints = constraints;

    // Check if we can reuse cached layout
    if (_lastConstraints != null &&
        _lastConstraints!.maxWidth == newConstraints.maxWidth &&
        isCacheValid) {
      size = Size(
        newConstraints.maxWidth,
        computeIntrinsicHeight(newConstraints.maxWidth),
      );
      return;
    }

    _lastConstraints = newConstraints;
    size = computeSize(newConstraints);
  }

  /// Computes the size for this block.
  Size computeSize(BoxConstraints constraints) {
    final height = computeIntrinsicHeight(constraints.maxWidth);
    return Size(constraints.maxWidth, height);
  }

  /// Computes the intrinsic height for this block.
  double computeIntrinsicHeight(double width);

  @override
  double computeMinIntrinsicWidth(double height) => 0;

  @override
  double computeMaxIntrinsicWidth(double height) => double.infinity;

  @override
  double computeMinIntrinsicHeight(double width) =>
      computeIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeIntrinsicHeight(width);

  @override
  bool hitTestSelf(Offset position) => true;

  /// Gets the link at the given position, if any.
  String? getLinkAtPosition(Offset position) => null;

  /// Gets the checkbox at the given position, if any.
  /// Returns the checkbox index or -1 if none.
  int getCheckboxAtPosition(Offset position) => -1;

  /// Gets the offset where the cursor should be positioned (end of text).
  /// Returns an Offset relative to this block's top-left corner.
  /// Override this in subclasses that have text content.
  Offset? getCursorOffset() => null;
}
