import 'package:flutter/foundation.dart';

/// The type of a Markdown block.
enum MarkdownBlockType {
  paragraph,
  header,
  codeBlock,
  blockquote,
  orderedList,
  unorderedList,
  table,
  thematicBreak,
  latex,
  html,
  custom,
}

/// Represents a single block in the Markdown AST.
@immutable
class MarkdownBlock {
  /// Creates a new Markdown block.
  const MarkdownBlock({
    required this.id,
    required this.type,
    required this.content,
    this.metadata = const {},
    this.children = const [],
    this.isPartial = false,
  });

  /// Stable identifier for this block (used for diffing).
  final String id;

  /// The type of this block.
  final MarkdownBlockType type;

  /// The raw content of this block.
  final String content;

  /// Additional metadata for this block.
  ///
  /// For headers: {'level': 1-6}
  /// For code blocks: {'language': 'dart', 'info': '...'}
  /// For lists: {'start': 1, 'items': [...]}
  /// For tables: {'alignments': [...], 'rows': [...]}
  final Map<String, dynamic> metadata;

  /// Child blocks (for nested structures like blockquotes).
  final List<MarkdownBlock> children;

  /// Whether this block is still being streamed.
  final bool isPartial;

  /// Creates a copy with modified fields.
  MarkdownBlock copyWith({
    String? id,
    MarkdownBlockType? type,
    String? content,
    Map<String, dynamic>? metadata,
    List<MarkdownBlock>? children,
    bool? isPartial,
  }) {
    return MarkdownBlock(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      metadata: metadata != null
          ? Map<String, dynamic>.from(metadata)
          : Map<String, dynamic>.from(this.metadata),
      children: children != null
          ? List<MarkdownBlock>.from(children)
          : List<MarkdownBlock>.from(this.children),
      isPartial: isPartial ?? this.isPartial,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MarkdownBlock) return false;
    // Fast path: if IDs differ, definitely not equal
    if (other.id != id) return false;
    if (other.isPartial != isPartial) return false;
    // Content comparison is the most expensive — check it early
    if (other.content != content) return false;
    if (other.type != type) return false;
    if (!mapEquals(other.metadata, metadata)) return false;
    if (!listEquals(other.children, children)) return false;
    return true;
  }

  @override
  int get hashCode => Object.hash(
        id,
        type,
        content,
        Object.hashAllUnordered(metadata.entries),
        Object.hashAll(children),
        isPartial,
      );

  @override
  String toString() =>
      'MarkdownBlock(id: $id, type: $type, content: ${content.length > 50 ? '${content.substring(0, 50)}...' : content})';
}

/// Represents a list item in ordered/unordered lists.
@immutable
class ListItem {
  /// Creates a new list item.
  const ListItem({
    required this.content,
    this.isChecked,
    this.children = const [],
  });

  /// The content of this list item.
  final String content;

  /// For task lists: whether the checkbox is checked.
  /// Null for regular list items.
  final bool? isChecked;

  /// Nested list items.
  final List<ListItem> children;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ListItem &&
        other.content == content &&
        other.isChecked == isChecked &&
        listEquals(other.children, children);
  }

  @override
  int get hashCode => Object.hash(content, isChecked, Object.hashAll(children));
}

/// Represents a table cell.
@immutable
class TableCell {
  /// Creates a new table cell.
  const TableCell({
    required this.content,
    this.alignment = TableAlignment.left,
  });

  /// The content of this cell.
  final String content;

  /// The alignment of this cell.
  final TableAlignment alignment;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TableCell &&
        other.content == content &&
        other.alignment == alignment;
  }

  @override
  int get hashCode => Object.hash(content, alignment);
}

/// Table column alignment.
enum TableAlignment {
  left,
  center,
  right,
}
