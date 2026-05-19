// RenderBox is imported to allow custom patterns to return their own
// RenderObjects. This couples the parsing module to Flutter's rendering layer
// because MarkdownPattern.createRenderObject must return a RenderBox that
// integrates with the 100% RenderObject-based rendering pipeline.
import 'package:flutter/rendering.dart';
import '../theme/markdown_theme.dart';
import 'markdown_block.dart';

class MarkdownPattern {
  const MarkdownPattern({
    required this.pattern,
    required this.createRenderObject,
    this.updateRenderObject,
    this.blockBuilder,
  });

  /// The regex pattern to match against the content within the custom block delimiters.
  ///
  /// The parser looks for content enclosed in `U+EB1E` characters (e.g. `󠄞content󠄞`).
  /// This pattern is then matched against the extracted `content`.
  final RegExp pattern;

  final RenderBox Function(MarkdownBlock block, MarkdownTheme theme)
      createRenderObject;

  /// Optional function to update an existing RenderObject with new block data.
  ///
  /// If provided, this will be called when the block content changes (e.g. during streaming).
  /// If null, the RenderObject will be recreated when the block changes.
  final void Function(
          RenderBox renderObject, MarkdownBlock block, MarkdownTheme theme)?
      updateRenderObject;

  /// Optional function to customize the creation of the MarkdownBlock.

  ///
  /// If not provided, a default block of type [MarkdownBlockType.custom]
  /// will be created with the matched text as content.
  final MarkdownBlock Function(String id, String content, Match match)?
      blockBuilder;
}
