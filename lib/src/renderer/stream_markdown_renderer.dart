import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart' show SelectionArea;
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../parsing/incremental_markdown_parser.dart';
import '../parsing/markdown_block.dart';
import '../parsing/markdown_pattern.dart';
import '../render_objects/base/render_markdown_block.dart';
import '../render_objects/mixins/selectable_text_mixin.dart';
import '../theme/markdown_theme.dart';

import 'block_registry.dart';

/// A widget that renders streaming Markdown content using custom RenderObjects.
///
/// This widget provides maximum performance by using a flat list of custom
/// RenderObjects instead of building a widget tree.
class StreamMarkdownRenderer extends LeafRenderObjectWidget {
  const StreamMarkdownRenderer({
    required this.markdownStream,
    this.theme,
    this.onLinkTapped,
    this.onCheckboxTapped,
    this.showCursor = true,
    this.cursorColor,
    this.cursorWidth = 2.0,
    this.cursorHeight,
    this.cursorBlinkDuration = const Duration(milliseconds: 500),
    this.scrollController,
    this.autoScrollToBottom = true,
    this.selectionEnabled =
        false, // Disabled for now - selection implementation in progress
    this.characterDelay,
    this.customPatterns = const [],
    super.key,
  });

  final List<MarkdownPattern> customPatterns;

  /// Whether text selection is enabled.
  ///
  /// When true, users can select text with gestures like:
  /// - Double-tap to select a word
  /// - Triple-tap to select a paragraph
  /// - Long press and drag to select text
  ///
  /// This widget should be wrapped in a [SelectionArea] for full
  /// selection support with handles and context menu.
  final bool selectionEnabled;

  /// The stream of Markdown content to render.
  ///
  /// Each emission should be the complete Markdown text so far
  /// (not just the new chunk).
  final Stream<String> markdownStream;

  final MarkdownTheme? theme;

  final void Function(String url)? onLinkTapped;

  final void Function(int index, bool checked)? onCheckboxTapped;

  /// Whether to show a blinking cursor while streaming.
  final bool showCursor;

  /// Color of the cursor. Defaults to theme text color.
  final Color? cursorColor;

  /// Width of the cursor.
  final double cursorWidth;

  /// Height of the cursor. Defaults to text height.
  final double? cursorHeight;

  /// Duration for cursor blink animation.
  final Duration cursorBlinkDuration;

  /// ScrollController for auto-scrolling to bottom.
  ///
  /// If provided, the widget will automatically scroll to the bottom
  /// when new content is added during streaming.
  final ScrollController? scrollController;

  /// Whether to automatically scroll to bottom when new content arrives.
  ///
  /// Defaults to true. Requires [scrollController] to be provided.
  final bool autoScrollToBottom;

  /// Delay between character emissions for typewriter effect.
  ///
  /// When set, incoming text chunks are buffered and emitted character-by-character
  /// with this delay, creating a typewriter effect.
  ///
  /// If null or [Duration.zero], text is displayed immediately as it arrives from the stream.
  ///
  /// Example: `Duration(milliseconds: 50)` for smooth typing effect.
  final Duration? characterDelay;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderStreamMarkdown(
      markdownStream: markdownStream,
      customPatterns: customPatterns,
      characterDelay: characterDelay,
      theme: (theme ?? MarkdownTheme.light()).withDefaults(),
      onLinkTapped: onLinkTapped,
      onCheckboxTapped: onCheckboxTapped,
      showCursor: showCursor,
      cursorColor: cursorColor,
      cursorWidth: cursorWidth,
      cursorHeight: cursorHeight,
      cursorBlinkDuration: cursorBlinkDuration,
      scrollController: scrollController,
      autoScrollToBottom: autoScrollToBottom,
      selectionRegistrar:
          selectionEnabled ? SelectionContainer.maybeOf(context) : null,
      selectionEnabled: selectionEnabled,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderStreamMarkdown renderObject,
  ) {
    renderObject
      ..markdownStream = markdownStream
      ..characterDelay = characterDelay
      ..theme = (theme ?? MarkdownTheme.light()).withDefaults()
      ..onLinkTapped = onLinkTapped
      ..onCheckboxTapped = onCheckboxTapped
      ..showCursor = showCursor
      ..cursorColor = cursorColor
      ..cursorWidth = cursorWidth
      ..cursorHeight = cursorHeight
      ..cursorBlinkDuration = cursorBlinkDuration
      ..scrollController = scrollController
      ..autoScrollToBottom = autoScrollToBottom
      ..selectionRegistrar =
          selectionEnabled ? SelectionContainer.maybeOf(context) : null
      ..selectionEnabled = selectionEnabled;
  }
}

/// RenderObject for streaming Markdown content.
class RenderStreamMarkdown extends RenderBox {
  RenderStreamMarkdown({
    required Stream<String> markdownStream,
    required MarkdownTheme theme,
    List<MarkdownPattern> customPatterns = const [],
    void Function(String url)? onLinkTapped,
    void Function(int index, bool checked)? onCheckboxTapped,
    bool showCursor = true,
    Color? cursorColor,
    double cursorWidth = 2.0,
    double? cursorHeight,
    Duration cursorBlinkDuration = const Duration(milliseconds: 500),
    ScrollController? scrollController,
    bool autoScrollToBottom = true,
    SelectionRegistrar? selectionRegistrar,
    bool selectionEnabled = true,
    Duration? characterDelay,
  })  : _theme = theme,
        _onLinkTapped = onLinkTapped,
        _onCheckboxTapped = onCheckboxTapped,
        _showCursor = showCursor,
        _cursorColor = cursorColor,
        _cursorWidth = cursorWidth,
        _cursorHeight = cursorHeight,
        _cursorBlinkDuration = cursorBlinkDuration,
        _scrollController = scrollController,
        _autoScrollToBottom = autoScrollToBottom,
        _selectionRegistrar = selectionRegistrar,
        _selectionEnabled = selectionEnabled,
        _characterDelay = characterDelay,
        _customPatterns = customPatterns,
        _parser = IncrementalMarkdownParser(customPatterns: customPatterns) {
    _subscribeToStream(markdownStream);
  }

  IncrementalMarkdownParser _parser;
  StreamSubscription<String>? _subscription;

  List<MarkdownPattern> get customPatterns => _customPatterns;
  List<MarkdownPattern> _customPatterns;
  set customPatterns(List<MarkdownPattern> value) {
    if (_customPatterns == value) return;
    _customPatterns = value;
    _parser = IncrementalMarkdownParser(customPatterns: value);
    _currentBlocks = _parser.parse(_currentMarkdown);
    _updateChildren();
  }

  String _currentMarkdown = '';
  String _pendingMarkdown = '';
  List<MarkdownBlock> _currentBlocks = [];
  bool _updateScheduled = false;
  bool _isStreaming = true;
  bool _cursorVisible = true;
  Timer? _cursorTimer;

  // Character emission state (frame-aligned batching)
  String _accumulatedSourceText = '';
  int _emittedLength = 0;
  int _lastEmitTimestamp = 0;
  bool _frameCallbackScheduled = false;
  int _emitFrameCallbackId = 0;

  /// Delay between character emissions.
  Duration? get characterDelay => _characterDelay;
  Duration? _characterDelay;
  set characterDelay(Duration? value) {
    if (_characterDelay == value) return;
    _characterDelay = value;

    // Cancel any pending frame callback
    if (_frameCallbackScheduled) {
      _frameCallbackScheduled = false;
      SchedulerBinding.instance.cancelFrameCallbackWithId(_emitFrameCallbackId);
    }

    if (_accumulatedSourceText.isNotEmpty) {
      if (value != null && value != Duration.zero) {
        // Restart emission with new delay
        _lastEmitTimestamp = 0;
        _scheduleNextEmit();
      } else {
        // Flush all characters immediately
        _emittedLength = _accumulatedSourceText.length;
        _scheduleUpdate(_accumulatedSourceText);
      }
    }
  }

  final List<RenderMarkdownBlock> _children = [];
  final Map<String, RenderMarkdownBlock> _childMap = {};

  // Scroll controller for auto-scroll
  ScrollController? get scrollController => _scrollController;
  ScrollController? _scrollController;
  set scrollController(ScrollController? value) {
    if (_scrollController == value) return;
    _scrollController = value;
  }

  bool get autoScrollToBottom => _autoScrollToBottom;
  bool _autoScrollToBottom;
  set autoScrollToBottom(bool value) {
    if (_autoScrollToBottom == value) return;
    _autoScrollToBottom = value;
  }

  // Selection properties
  SelectionRegistrar? get selectionRegistrar => _selectionRegistrar;
  SelectionRegistrar? _selectionRegistrar;
  set selectionRegistrar(SelectionRegistrar? value) {
    if (_selectionRegistrar == value) return;
    _selectionRegistrar = value;
    // Update all children with new registrar
    for (final child in _children) {
      _updateChildSelectionRegistrar(child);
    }
  }

  bool get selectionEnabled => _selectionEnabled;
  bool _selectionEnabled;
  set selectionEnabled(bool value) {
    if (_selectionEnabled == value) return;
    _selectionEnabled = value;
    // Update all children
    for (final child in _children) {
      _updateChildSelectionRegistrar(child);
    }
  }

  void _updateChildSelectionRegistrar(RenderMarkdownBlock child) {
    if (child is SelectableTextMixin) {
      (child as SelectableTextMixin).registrar =
          _selectionEnabled ? _selectionRegistrar : null;
    }
  }

  // Cursor properties
  bool get showCursor => _showCursor;
  bool _showCursor;
  set showCursor(bool value) {
    if (_showCursor == value) return;
    _showCursor = value;
    _updateCursorTimer();
    markNeedsPaint();
  }

  Color? get cursorColor => _cursorColor;
  Color? _cursorColor;
  set cursorColor(Color? value) {
    if (_cursorColor == value) return;
    _cursorColor = value;
    markNeedsPaint();
  }

  double get cursorWidth => _cursorWidth;
  double _cursorWidth;
  set cursorWidth(double value) {
    if (_cursorWidth == value) return;
    _cursorWidth = value;
    markNeedsPaint();
  }

  double? get cursorHeight => _cursorHeight;
  double? _cursorHeight;
  set cursorHeight(double? value) {
    if (_cursorHeight == value) return;
    _cursorHeight = value;
    markNeedsPaint();
  }

  Duration get cursorBlinkDuration => _cursorBlinkDuration;
  Duration _cursorBlinkDuration;
  set cursorBlinkDuration(Duration value) {
    if (_cursorBlinkDuration == value) return;
    _cursorBlinkDuration = value;
    _updateCursorTimer();
  }

  void _updateCursorTimer() {
    _cursorTimer?.cancel();
    if (_showCursor && _isStreaming) {
      _cursorTimer = Timer.periodic(_cursorBlinkDuration, (_) {
        _cursorVisible = !_cursorVisible;
        markNeedsPaint();
      });
    }
  }

  Stream<String>? _markdownStream;
  Stream<String>? get markdownStream => _markdownStream;
  set markdownStream(Stream<String>? value) {
    if (_markdownStream == value) return;
    if (value != null) {
      _subscribeToStream(value);
    }
  }

  /// The theme for rendering.
  MarkdownTheme get theme => _theme;
  MarkdownTheme _theme;
  set theme(MarkdownTheme value) {
    if (_theme == value) return;
    _theme = value;
    for (final child in _children) {
      child.theme = value;
    }
    markNeedsLayout();
    markNeedsPaint();
  }

  /// Callback when a link is tapped.
  void Function(String url)? get onLinkTapped => _onLinkTapped;
  void Function(String url)? _onLinkTapped;
  set onLinkTapped(void Function(String url)? value) {
    if (_onLinkTapped == value) return;
    _onLinkTapped = value;
    for (final child in _children) {
      child.onLinkTapped = value;
    }
  }

  /// Callback when a checkbox is tapped.
  void Function(int index, bool checked)? get onCheckboxTapped =>
      _onCheckboxTapped;
  void Function(int index, bool checked)? _onCheckboxTapped;
  set onCheckboxTapped(void Function(int index, bool checked)? value) {
    if (_onCheckboxTapped == value) return;
    _onCheckboxTapped = value;
    for (final child in _children) {
      child.onCheckboxTapped = value;
    }
  }

  void _subscribeToStream(Stream<String> stream) {
    _subscription?.cancel();
    _cursorTimer?.cancel();

    // Cancel any pending frame callback
    if (_frameCallbackScheduled) {
      _frameCallbackScheduled = false;
      SchedulerBinding.instance.cancelFrameCallbackWithId(_emitFrameCallbackId);
    }

    _markdownStream = stream;
    _currentMarkdown = '';
    _pendingMarkdown = '';
    _currentBlocks = [];
    _updateScheduled = false;
    _isStreaming = true;
    _cursorVisible = true;

    _accumulatedSourceText = '';
    _emittedLength = 0;
    _lastEmitTimestamp = 0;
    _frameCallbackScheduled = false;

    // Clear existing children
    _clearChildren();

    _subscription = stream.listen(
      (data) {
        _onMarkdownReceived(data);
      },
      onError: _onError,
      onDone: () {
        _onDone();
      },
    );

    // Start cursor blinking
    _updateCursorTimer();
  }

  void _clearChildren() {
    for (final child in _children) {
      dropChild(child);
      child.dispose();
    }
    _children.clear();
    _childMap.clear();
  }

  void _onMarkdownReceived(String rawMarkdown) {
    if (rawMarkdown == _accumulatedSourceText) return;

    // Handle reset or non-incremental updates
    if (rawMarkdown.length < _accumulatedSourceText.length) {
      _accumulatedSourceText = rawMarkdown;
      _emittedLength = rawMarkdown.length;
      _lastEmitTimestamp = 0;
      if (_frameCallbackScheduled) {
        _frameCallbackScheduled = false;
        SchedulerBinding.instance.cancelFrameCallbackWithId(_emitFrameCallbackId);
      }
      _scheduleUpdate(rawMarkdown);
      return;
    }

    _accumulatedSourceText = rawMarkdown;

    if (_characterDelay != null && _characterDelay != Duration.zero) {
      _scheduleNextEmit();
    } else {
      _emittedLength = rawMarkdown.length;
      _scheduleUpdate(rawMarkdown);
    }
  }

  void _scheduleNextEmit() {
    if (_frameCallbackScheduled) return;
    if (_characterDelay == null || _characterDelay == Duration.zero) {
      // No delay — emit everything immediately
      _emittedLength = _accumulatedSourceText.length;
      _scheduleUpdate(_accumulatedSourceText);
      return;
    }
    _frameCallbackScheduled = true;
    _emitFrameCallbackId = SchedulerBinding.instance.scheduleFrameCallback(_emitFrame);
  }

  void _emitFrame(Duration timestamp) {
    _frameCallbackScheduled = false;
    if (!attached || _emittedLength >= _accumulatedSourceText.length) return;

    // Calculate how many characters to emit based on elapsed time
    final nowUs = timestamp.inMicroseconds;
    final remaining = _accumulatedSourceText.length - _emittedLength;

    int charsToEmit;
    if (_lastEmitTimestamp == 0) {
      // First frame — emit initial batch (reasonable chunk for first visual update)
      charsToEmit = remaining.clamp(1, 20);
    } else {
      final elapsed = nowUs - _lastEmitTimestamp;
      charsToEmit = (elapsed / _characterDelay!.inMicroseconds).ceil().clamp(1, remaining);
    }

    _emittedLength += charsToEmit;
    _lastEmitTimestamp = nowUs;

    final text = _accumulatedSourceText.substring(0, _emittedLength);
    _scheduleUpdate(text);

    // Schedule next frame if there's more to emit
    if (_emittedLength < _accumulatedSourceText.length) {
      _scheduleNextEmit();
    }
  }

  void _scheduleUpdate(String markdown) {
    _pendingMarkdown = markdown;

    // Throttle updates to once per frame
    if (!_updateScheduled) {
      _updateScheduled = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _updateScheduled = false;
        if (!attached) return;
        if (_pendingMarkdown != _currentMarkdown) {
          _currentMarkdown = _pendingMarkdown;
          _currentBlocks = _parser.parse(_currentMarkdown);
          _updateChildren();
        }
      });
    }
  }

  void _updateChildren() {
    final newChildren = <RenderMarkdownBlock>[];
    final newChildMap = <String, RenderMarkdownBlock>{};

    final registrar = _selectionEnabled ? _selectionRegistrar : null;

    var needsRelayout = false;

    for (final block in _currentBlocks) {
      final existingChild = _childMap[block.id];

      // Check if the existing render object type matches what the block needs.
      // During streaming, a block can transition (e.g., a partial custom block
      // rendered as paragraph needs to become a custom render object once matched).
      final needsRecreation = existingChild != null &&
          BlockRegistry.renderObjectTypeMismatch(
            existingRenderObject: existingChild,
            newBlock: block,
            customPatterns: customPatterns,
          );

      if (existingChild != null && !needsRecreation) {
        // Update existing child
        BlockRegistry.updateRenderObject(
          renderObject: existingChild,
          block: block,
          theme: _theme,
          onLinkTapped: _onLinkTapped,
          onCheckboxTapped: _onCheckboxTapped,
          selectionRegistrar: registrar,
          customPatterns: customPatterns,
        );
        newChildren.add(existingChild);
        newChildMap[block.id] = existingChild;
      } else if (existingChild != null && needsRecreation) {
        // Type mismatch — dispose old child and create new one
        dropChild(existingChild);
        existingChild.dispose();
        final child = BlockRegistry.createRenderObject(
          block: block,
          theme: _theme,
          onLinkTapped: _onLinkTapped,
          onCheckboxTapped: _onCheckboxTapped,
          selectionRegistrar: registrar,
          customPatterns: customPatterns,
        );
        adoptChild(child);
        newChildren.add(child);
        newChildMap[block.id] = child;
        needsRelayout = true;
      } else {
        // Create new child
        final child = BlockRegistry.createRenderObject(
          block: block,
          theme: _theme,
          onLinkTapped: _onLinkTapped,
          onCheckboxTapped: _onCheckboxTapped,
          selectionRegistrar: registrar,
          customPatterns: customPatterns,
        );
        adoptChild(child);
        newChildren.add(child);
        newChildMap[block.id] = child;
        needsRelayout = true;
      }
    }

    // Dispose removed children
    for (final entry in _childMap.entries) {
      if (!newChildMap.containsKey(entry.key)) {
        dropChild(entry.value);
        entry.value.dispose();
        needsRelayout = true;
      }
    }

    // Check if child ordering/reference changed (different block IDs in same positions)
    if (!needsRelayout && _children.length == newChildren.length) {
      for (var i = 0; i < _children.length; i++) {
        if (_children[i] != newChildren[i]) {
          needsRelayout = true;
          break;
        }
      }
    } else if (_children.length != newChildren.length) {
      needsRelayout = true;
    }

    _children
      ..clear()
      ..addAll(newChildren);

    _childMap
      ..clear()
      ..addAll(newChildMap);

    if (needsRelayout) {
      markNeedsLayout();
    } else {
      // Children may have updated their content and marked themselves dirty,
      // but the parent structure hasn't changed. Still need to mark paint
      // in case children changed visual appearance.
      markNeedsPaint();
    }

    // Auto-scroll to bottom after layout
    if (_autoScrollToBottom && _scrollController != null && _isStreaming) {
      if (_scrollController!.hasClients) {
        final pos = _scrollController!.position;
        // Only auto-scroll if we are already near the bottom (within 50px)
        // or if the content is smaller than the viewport (can't scroll yet)
        if (pos.maxScrollExtent - pos.pixels < 50 || pos.maxScrollExtent == 0) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (!attached) return;
            _scrollToBottom();
          });
        }
      }
    }
  }

  void _scrollToBottom() {
    final controller = _scrollController;
    if (controller == null || !controller.hasClients) return;

    final maxScroll = controller.position.maxScrollExtent;
    if (controller.offset < maxScroll) {
      controller.animateTo(
        maxScroll,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  void _onError(Object error, StackTrace stackTrace) {
    log('[StreamMarkdownRenderer] Error: $error\n$stackTrace');
    // Handle error gracefully - keep showing current content
  }

  void _onDone() {
    // Stream completed - stop cursor and ensure last block is not marked as partial
    _isStreaming = false;
    _cursorTimer?.cancel();
    _cursorTimer = null;

    // Cancel any pending frame callback
    if (_frameCallbackScheduled) {
      _frameCallbackScheduled = false;
      SchedulerBinding.instance.cancelFrameCallbackWithId(_emitFrameCallbackId);
    }

    // Flush any remaining un-emitted text
    if (_emittedLength < _accumulatedSourceText.length) {
      _emittedLength = _accumulatedSourceText.length;
      _scheduleUpdate(_accumulatedSourceText);
    }

    if (_currentBlocks.isNotEmpty && _currentBlocks.last.isPartial) {
      _currentBlocks = List.of(_currentBlocks)..[_currentBlocks.length - 1] =
          _currentBlocks.last.copyWith(isPartial: false);
      _updateChildren();
    }

    markNeedsPaint();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _cursorTimer?.cancel();
    if (_frameCallbackScheduled) {
      _frameCallbackScheduled = false;
      SchedulerBinding.instance.cancelFrameCallbackWithId(_emitFrameCallbackId);
    }
    _clearChildren();
    super.dispose();
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! BoxParentData) {
      child.parentData = BoxParentData();
    }
  }

  @override
  void performLayout() {
    final blockSpacing = _theme.blockSpacing ?? 16;

    var currentY = 0.0;

    for (var i = 0; i < _children.length; i++) {
      final child = _children[i];

      // Layout each block with the full width
      child.layout(
        BoxConstraints(
          minWidth: 0,
          maxWidth: constraints.maxWidth,
        ),
        parentUsesSize: true,
      );

      final childParentData = child.parentData as BoxParentData;
      childParentData.offset = Offset(0, currentY);

      currentY += child.size.height;

      if (i < _children.length - 1) {
        currentY += blockSpacing;
      }
    }

    final desiredHeight = currentY > 0 ? currentY : 0.0;
    size = constraints.constrain(Size(constraints.maxWidth, desiredHeight));
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    final childParentData = child.parentData as BoxParentData;
    transform.translate(childParentData.offset.dx, childParentData.offset.dy);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    for (var i = 0; i < _children.length; i++) {
      final child = _children[i];

      // Skip children that haven't been laid out yet
      if (!child.hasSize) continue;

      final childParentData = child.parentData as BoxParentData;
      context.paintChild(child, childParentData.offset + offset);
    }

    // Draw blinking cursor if streaming
    if (_showCursor && _isStreaming && _cursorVisible && _children.isNotEmpty) {
      final canvas = context.canvas;
      final color =
          _cursorColor ?? _theme.textStyle?.color ?? const Color(0xFF000000);
      final height = _cursorHeight ?? (_theme.textStyle?.fontSize ?? 16) * 1.2;

      // Get the last child and calculate cursor position
      final lastChild = _children.last;
      final lastChildParentData = lastChild.parentData as BoxParentData;
      final lastChildY = offset.dy + lastChildParentData.offset.dy;

      // Get the cursor offset from the last child
      final cursorOffset = lastChild.getCursorOffset();

      if (cursorOffset != null) {
        // Position cursor at the end of last block's text
        // The cursor should extend downward from the baseline
        final cursorX = offset.dx + cursorOffset.dx;
        final cursorY = lastChildY + cursorOffset.dy;

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cursorX, cursorY, _cursorWidth, height),
            const Radius.circular(1),
          ),
          Paint()..color = color,
        );
      } else {
        // Fallback: position at start of block if no cursor offset available
        final cursorX = offset.dx + 4;
        final cursorY = lastChildY + (lastChild.size.height - height) / 2;

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cursorX, cursorY, _cursorWidth, height),
            const Radius.circular(1),
          ),
          Paint()..color = color,
        );
      }
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    // Safety check: don't hit test if we haven't been laid out yet
    if (!hasSize) return false;

    for (var i = _children.length - 1; i >= 0; i--) {
      final child = _children[i];

      // Skip children that haven't been laid out yet
      if (!child.hasSize) continue;

      final childParentData = child.parentData as BoxParentData;
      final childOffset = childParentData.offset;

      final bool isHit = result.addWithPaintOffset(
        offset: childOffset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          return child.hitTest(result, position: transformed);
        },
      );

      if (isHit) return true;
    }

    return false;
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    // Events are handled by child render objects
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    for (final child in _children) {
      child.attach(owner);
    }
  }

  @override
  void detach() {
    super.detach();
    for (final child in _children) {
      child.detach();
    }
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    for (final child in _children) {
      visitor(child);
    }
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return _children.map((child) {
      return child.toDiagnosticsNode(name: 'child');
    }).toList();
  }
}
