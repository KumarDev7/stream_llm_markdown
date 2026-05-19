import 'package:flutter/rendering.dart';

import '../parsing/markdown_block.dart';
import '../parsing/markdown_pattern.dart';
import '../render_objects/base/render_markdown_block.dart';
import '../render_objects/render_custom_block.dart';
import '../render_objects/mixins/selectable_text_mixin.dart';
import '../render_objects/render_blockquote.dart';
import '../render_objects/render_code_block.dart';
import '../render_objects/render_header.dart';
import '../render_objects/render_latex.dart';
import '../render_objects/render_list.dart';
import '../render_objects/render_paragraph.dart';
import '../render_objects/render_table.dart';
import '../render_objects/render_thematic_break.dart';
import '../theme/markdown_theme.dart';

/// Factory for creating RenderObjects from MarkdownBlocks.
class BlockRegistry {
  /// Creates a RenderObject for the given block.
  static RenderMarkdownBlock createRenderObject({
    required MarkdownBlock block,
    required MarkdownTheme theme,
    void Function(String url)? onLinkTapped,
    void Function(int index, bool checked)? onCheckboxTapped,
    SelectionRegistrar? selectionRegistrar,
    List<MarkdownPattern>? customPatterns,
  }) {
    switch (block.type) {
      case MarkdownBlockType.custom:
        if (customPatterns != null) {
          final index = block.metadata['patternIndex'] as int?;
          if (index != null && index >= 0 && index < customPatterns.length) {
            final renderBox =
                customPatterns[index].createRenderObject(block, theme);
            if (renderBox is RenderMarkdownBlock) {
              return renderBox;
            }
            return RenderCustomMarkdownBlock(
              child: renderBox,
              block: block,
              theme: theme,
            );
          }
        }
        // No matching pattern — render as an empty/hidden block during streaming.
        // Custom block content is not markdown; showing it as raw text is wrong.
        // Once a pattern match is found, the block will be recreated with the
        // proper render object (handled by renderObjectTypeMismatch in _updateChildren).
        return RenderMarkdownParagraph(
          block: block.copyWith(content: ''),
          theme: theme,
          onLinkTapped: onLinkTapped,
          onCheckboxTapped: onCheckboxTapped,
          selectionRegistrar: selectionRegistrar,
        );
      case MarkdownBlockType.paragraph:
        return RenderMarkdownParagraph(
          block: block,
          theme: theme,
          onLinkTapped: onLinkTapped,
          onCheckboxTapped: onCheckboxTapped,
          selectionRegistrar: selectionRegistrar,
        );
      case MarkdownBlockType.header:
        return RenderMarkdownHeader(
          block: block,
          theme: theme,
          onLinkTapped: onLinkTapped,
          onCheckboxTapped: onCheckboxTapped,
          selectionRegistrar: selectionRegistrar,
        );
      case MarkdownBlockType.codeBlock:
        return RenderMarkdownCodeBlock(
          block: block,
          theme: theme,
          onLinkTapped: onLinkTapped,
          onCheckboxTapped: onCheckboxTapped,
          selectionRegistrar: selectionRegistrar,
        );
      case MarkdownBlockType.blockquote:
        return RenderMarkdownBlockquote(
          block: block,
          theme: theme,
          onLinkTapped: onLinkTapped,
          onCheckboxTapped: onCheckboxTapped,
          selectionRegistrar: selectionRegistrar,
        );
      case MarkdownBlockType.orderedList:
      case MarkdownBlockType.unorderedList:
        return RenderMarkdownList(
          block: block,
          theme: theme,
          onLinkTapped: onLinkTapped,
          onCheckboxTapped: onCheckboxTapped,
          selectionRegistrar: selectionRegistrar,
        );
      case MarkdownBlockType.table:
        return RenderMarkdownTable(
          block: block,
          theme: theme,
          onLinkTapped: onLinkTapped,
          onCheckboxTapped: onCheckboxTapped,
          selectionRegistrar: selectionRegistrar,
        );
      case MarkdownBlockType.thematicBreak:
        return RenderMarkdownThematicBreak(
          block: block,
          theme: theme,
          onLinkTapped: onLinkTapped,
          onCheckboxTapped: onCheckboxTapped,
        );
      case MarkdownBlockType.latex:
        return RenderMarkdownLatex(
          block: block,
          theme: theme,
          onLinkTapped: onLinkTapped,
          onCheckboxTapped: onCheckboxTapped,
        );
      case MarkdownBlockType.html:
        // Render HTML as paragraph for now
        return RenderMarkdownParagraph(
          block: block,
          theme: theme,
          onLinkTapped: onLinkTapped,
          onCheckboxTapped: onCheckboxTapped,
          selectionRegistrar: selectionRegistrar,
        );
    }
  }

  /// Determines whether an existing render object needs to be recreated
  /// because its type doesn't match what the new block requires.
  ///
  /// This handles the streaming case where a custom block starts as a partial
  /// (rendered as paragraph) and then transitions to a fully matched custom
  /// block that needs a different render object type.
  static bool renderObjectTypeMismatch({
    required RenderMarkdownBlock existingRenderObject,
    required MarkdownBlock newBlock,
    List<MarkdownPattern>? customPatterns,
  }) {
    final currentBlock = existingRenderObject.block;

    // If block type changed entirely, definitely needs recreation
    if (currentBlock.type != newBlock.type) {
      return true;
    }

    // For custom blocks, check if the pattern assignment changed.
    // A partial custom block has no patternIndex (rendered as paragraph),
    // while a fully matched one has a patternIndex (rendered with custom RO).
    if (newBlock.type == MarkdownBlockType.custom) {
      final oldPatternIndex = currentBlock.metadata['patternIndex'] as int?;
      final newPatternIndex = newBlock.metadata['patternIndex'] as int?;

      // If patternIndex changed (including null→non-null or vice versa),
      // the render object type changes.
      if (oldPatternIndex != newPatternIndex) {
        return true;
      }

      // If patternIndex went from null to a value, the render object
      // was created as RenderMarkdownParagraph but now needs to be
      // a RenderCustomMarkdownBlock (or pattern-provided RenderMarkdownBlock).
      if (newPatternIndex != null &&
          existingRenderObject is RenderParagraph) {
        return true;
      }
    }

    return false;
  }

  /// Updates an existing RenderObject with new block data.
  static void updateRenderObject({
    required RenderMarkdownBlock renderObject,
    required MarkdownBlock block,
    required MarkdownTheme theme,
    void Function(String url)? onLinkTapped,
    void Function(int index, bool checked)? onCheckboxTapped,
    SelectionRegistrar? selectionRegistrar,
    List<MarkdownPattern>? customPatterns,
  }) {
    // First allow the pattern to update its custom render object
    if (block.type == MarkdownBlockType.custom && customPatterns != null) {
      final index = block.metadata['patternIndex'] as int?;
      if (index != null && index >= 0 && index < customPatterns.length) {
        final pattern = customPatterns[index];
        if (pattern.updateRenderObject != null) {
          if (renderObject is RenderCustomMarkdownBlock &&
              renderObject.child != null) {
            pattern.updateRenderObject!(renderObject.child!, block, theme);
          } else {
            pattern.updateRenderObject!(renderObject, block, theme);
          }
        }
      }
    }

    renderObject
      ..block = block
      ..theme = theme
      ..onLinkTapped = onLinkTapped
      ..onCheckboxTapped = onCheckboxTapped;

    // Update selection registrar for selectable render objects
    if (renderObject is SelectableTextMixin) {
      (renderObject as SelectableTextMixin).registrar = selectionRegistrar;
    }
  }
}
