import 'dart:convert';

import 'markdown_block.dart';
import 'markdown_pattern.dart';

/// A streaming-aware incremental Markdown parser.
///
/// Parses Markdown text and emits a list of complete blocks plus
/// one optional partial block for streaming content.
class IncrementalMarkdownParser {
  /// Creates a new incremental markdown parser.
  IncrementalMarkdownParser({this.customPatterns = const []});

  /// Custom patterns to recognize during parsing.
  final List<MarkdownPattern> customPatterns;

  int _parseDepth = 0;
  static const int _maxParseDepth = 10;

  /// Parses the given Markdown text into blocks.
  List<MarkdownBlock> parse(String markdown, {bool isNested = false}) {
    if (markdown.isEmpty) return [];

    _parseDepth++;
    if (_parseDepth > _maxParseDepth) {
      _parseDepth--;
      return [];
    }

    final lines = const LineSplitter().convert(markdown);
    final blocks = <MarkdownBlock>[];
    var i = 0;

    while (i < lines.length) {
      final result = _parseBlock(lines, i, blocks.length);
      if (result.block != null) {
        blocks.add(result.block!);
      }
      i = result.nextIndex;
    }

    // Mark the last block as partial if the text doesn't end with newlines
    if (blocks.isNotEmpty && !markdown.endsWith('\n\n') && !isNested) {
      final lastBlock = blocks.removeLast();
      blocks.add(lastBlock.copyWith(isPartial: true));
    }

    _parseDepth--;
    return blocks;
  }

  _ParseResult _parseBlock(List<String> lines, int index, int blockIndex) {
    if (index >= lines.length) {
      return _ParseResult(null, index + 1);
    }

    final line = lines[index];

    // Skip empty lines
    if (line.trim().isEmpty) {
      return _ParseResult(null, index + 1);
    }

    // Try to match block types in order of precedence

    // Custom patterns (Unicode Identifier)
    // Format: 󠄞content󠄞 (U+EB1E)
    const kCustomIdentifier = '\uEB1E';
    if (line.startsWith(kCustomIdentifier)) {
      // Check if the line ends with the identifier (ignoring trailing whitespace?)
      // Check if the line ends with the identifier (ignoring trailing whitespace?)
      // The user said "trigger custom widget and end should have same".
      // We assume the custom block content is usually on one line or spans until the closing identifier.

      var content = line.substring(kCustomIdentifier.length);
      var isClosed = false;

      if (content.contains(kCustomIdentifier)) {
        final endIndex = content.indexOf(kCustomIdentifier);
        content = content.substring(0, endIndex);
        isClosed = true;
      } else {
        // If it's not closed on this line, we might want to consume following lines until we find it.
        // But for now let's implement basic single line or consume until closing.
        // Let's implement multi-line consumption.
        var j = index + 1;
        final buffer = StringBuffer(content);

        while (j < lines.length) {
          final nextLine = lines[j];
          if (nextLine.contains(kCustomIdentifier)) {
            final endIdx = nextLine.indexOf(kCustomIdentifier);
            buffer.write('\n${nextLine.substring(0, endIdx)}');
            content = buffer.toString();
            isClosed = true;
            // index + 1 is next line, but here we advanced to j.
            // But wait, if we consume lines, we need to update index.
            index = j; // Update index to the line we finished on
            break;
          } else {
            buffer.write('\n$nextLine');
            j++;
          }
        }
        if (!isClosed) {
          content = buffer.toString();
          index = j; // We consumed until j, which is length, or break.
          // If j reached lines.length, we are at the end.
        }
      }

      // Now we have the content. Find a matching pattern.
      for (var i = 0; i < customPatterns.length; i++) {
        final pattern = customPatterns[i];
        final match = pattern.pattern.firstMatch(content);
        if (match != null) {
          final blockId =
              _generateId(MarkdownBlockType.custom, content, blockIndex);

          MarkdownBlock block;
          if (pattern.blockBuilder != null) {
            block = pattern.blockBuilder!(blockId, content, match);
          } else {
            block = MarkdownBlock(
              id: blockId,
              type: MarkdownBlockType.custom,
              content: content,
              metadata: {'patternIndex': i},
            );
          }
          return _ParseResult(block, index + 1);
        }
      }

      // If no pattern matches the content, what do we do?
      // We could return a paragraph with the raw content,
      // or a custom block that renders as error/fallback.
      // For now, let's return a custom block with index -1 (generic).
      // Or maybe just ignore it?
      // Let's return a custom block but with no specific pattern index.
      // The renderer will handle it (maybe show text?)
    }

    // Thematic break (---, ***, ___)
    if (_isThematicBreak(line)) {
      return _ParseResult(
        MarkdownBlock(
          id: _generateId(MarkdownBlockType.thematicBreak, line, blockIndex),
          type: MarkdownBlockType.thematicBreak,
          content: line,
        ),
        index + 1,
      );
    }

    // ATX Headers (# Header)
    final headerMatch = _headerPattern.firstMatch(line);
    if (headerMatch != null) {
      final level = headerMatch.group(1)!.length;
      final content = headerMatch.group(2)?.trim() ?? '';
      return _ParseResult(
        MarkdownBlock(
          id: _generateId(MarkdownBlockType.header, content, blockIndex),
          type: MarkdownBlockType.header,
          content: content,
          metadata: {'level': level},
        ),
        index + 1,
      );
    }

    // Fenced code block (``` or ~~~)
    final codeMatch = _fencedCodePattern.firstMatch(line);
    if (codeMatch != null) {
      final fence = codeMatch.group(1)!;
      final language = codeMatch.group(2)?.trim() ?? '';
      final codeLines = <String>[];
      var j = index + 1;

      while (j < lines.length) {
        if (lines[j].startsWith(fence[0] * fence.length)) {
          j++;
          break;
        }
        codeLines.add(lines[j]);
        j++;
      }

      return _ParseResult(
        MarkdownBlock(
          id: _generateId(
            MarkdownBlockType.codeBlock,
            codeLines.join('\n'),
            blockIndex,
          ),
          type: MarkdownBlockType.codeBlock,
          content: codeLines.join('\n'),
          metadata: <String, dynamic>{'language': language, 'fenced': true},
        ),
        j,
      );
    }

    // Indented code block (4 spaces or 1 tab)
    if (line.startsWith('    ') || line.startsWith('\t')) {
      final codeLines = <String>[];
      var j = index;

      while (j < lines.length) {
        final currentLine = lines[j];
        if (currentLine.startsWith('    ')) {
          codeLines.add(currentLine.substring(4));
          j++;
        } else if (currentLine.startsWith('\t')) {
          codeLines.add(currentLine.substring(1));
          j++;
        } else if (currentLine.trim().isEmpty) {
          codeLines.add('');
          j++;
        } else {
          break;
        }
      }

      // Remove trailing empty lines
      while (codeLines.isNotEmpty && codeLines.last.isEmpty) {
        codeLines.removeLast();
      }

      if (codeLines.isNotEmpty) {
        return _ParseResult(
          MarkdownBlock(
            id: _generateId(
              MarkdownBlockType.codeBlock,
              codeLines.join('\n'),
              blockIndex,
            ),
            type: MarkdownBlockType.codeBlock,
            content: codeLines.join('\n'),
            metadata: const <String, dynamic>{'language': '', 'fenced': false},
          ),
          j,
        );
      }
    }

    // Blockquote (> text)
    if (line.startsWith('>')) {
      final quoteLines = <String>[];
      var j = index;

      var loopCount = 0;
      const maxLoops = 1000;

      while (j < lines.length && loopCount < maxLoops) {
        loopCount++;
        final currentLine = lines[j];

        if (currentLine.startsWith('>')) {
          // Remove the > and optional space
          var content = currentLine.substring(1);
          if (content.startsWith(' ')) {
            content = content.substring(1);
          }
          quoteLines.add(content);
          j++;
        } else {
          // Any non-blockquote line (including empty lines) ends the blockquote
          break;
        }
      }

      // Join and clean up the content
      final quoteContent = quoteLines.join('\n').trim();

      // Don't create empty blockquotes
      if (quoteContent.isEmpty) {
        return _ParseResult(null, j);
      }

      // Recursively parse nested content within blockquote
      // But limit depth to prevent infinite recursion
      final nestedBlocks = parse(quoteContent, isNested: true);

      return _ParseResult(
        MarkdownBlock(
          id: _generateId(
            MarkdownBlockType.blockquote,
            quoteContent,
            blockIndex,
          ),
          type: MarkdownBlockType.blockquote,
          content: quoteContent,
          children: nestedBlocks,
        ),
        j,
      );
    }

    // Block LaTeX ($$...$$)
    if (line.trim().startsWith(r'$$')) {
      final latexLines = <String>[line];
      var j = index + 1;

      // Check if it's a single-line block latex
      if (line.trim().endsWith(r'$$') && line.trim().length > 4) {
        final content = line.trim().substring(2, line.trim().length - 2);
        return _ParseResult(
          MarkdownBlock(
            id: _generateId(MarkdownBlockType.latex, content, blockIndex),
            type: MarkdownBlockType.latex,
            content: content,
            metadata: const <String, dynamic>{'inline': false},
          ),
          index + 1,
        );
      }

      while (j < lines.length) {
        latexLines.add(lines[j]);
        if (lines[j].trim().endsWith(r'$$')) {
          j++;
          break;
        }
        j++;
      }

      final content = latexLines
          .join('\n')
          .trim()
          .replaceAll(RegExp(r'^\$\$'), '')
          .replaceAll(RegExp(r'\$\$$'), '')
          .trim();

      return _ParseResult(
        MarkdownBlock(
          id: _generateId(MarkdownBlockType.latex, content, blockIndex),
          type: MarkdownBlockType.latex,
          content: content,
          metadata: const <String, dynamic>{'inline': false},
        ),
        j,
      );
    }

    // Table
    if (_isTableRow(line) && index + 1 < lines.length) {
      final nextLine = lines[index + 1];
      if (_isTableDelimiter(nextLine)) {
        return _parseTable(lines, index, blockIndex);
      }
    }

    // Ordered list (1. item)
    final orderedMatch = _orderedListPattern.firstMatch(line);
    if (orderedMatch != null) {
      return _parseList(
        lines,
        index,
        blockIndex,
        isOrdered: true,
      );
    }

    // Unordered list (- item, * item, + item)
    final unorderedMatch = _unorderedListPattern.firstMatch(line);
    if (unorderedMatch != null) {
      return _parseList(
        lines,
        index,
        blockIndex,
        isOrdered: false,
      );
    }

    // HTML block
    if (_htmlBlockPattern.hasMatch(line)) {
      return _ParseResult(
        MarkdownBlock(
          id: _generateId(MarkdownBlockType.html, line, blockIndex),
          type: MarkdownBlockType.html,
          content: line,
        ),
        index + 1,
      );
    }

    // Default: paragraph
    final paragraphLines = <String>[];
    var j = index;

    while (j < lines.length) {
      final currentLine = lines[j];

      // Stop at block-level elements
      if (currentLine.trim().isEmpty ||
          _headerPattern.hasMatch(currentLine) ||
          _fencedCodePattern.hasMatch(currentLine) ||
          currentLine.startsWith('>') ||
          _orderedListPattern.hasMatch(currentLine) ||
          _unorderedListPattern.hasMatch(currentLine) ||
          _isThematicBreak(currentLine) ||
          _isTableRow(currentLine) ||
          currentLine.trim().startsWith(r'$$')) {
        break;
      }

      paragraphLines.add(currentLine);
      j++;
    }

    // If no lines were collected, still advance to prevent infinite loop
    if (paragraphLines.isEmpty) {
      return _ParseResult(null, index + 1);
    }

    final content = paragraphLines.join('\n');

    // Check for inline LaTeX in paragraph
    if (content.contains(r'$') && !content.contains(r'$$')) {
      // It's a paragraph with potential inline LaTeX, handle it as paragraph
    }

    return _ParseResult(
      MarkdownBlock(
        id: _generateId(MarkdownBlockType.paragraph, content, blockIndex),
        type: MarkdownBlockType.paragraph,
        content: content,
      ),
      j,
    );
  }

  _ParseResult _parseList(
    List<String> lines,
    int index,
    int blockIndex, {
    required bool isOrdered,
    int indentLevel = 0,
  }) {
    final items = <Map<String, dynamic>>[];
    var j = index;
    final pattern = isOrdered ? _orderedListPattern : _unorderedListPattern;
    int? startNumber;
    final indentPrefix = '  ' * indentLevel;
    String? extraIndent;

    while (j < lines.length) {
      var line = lines[j];

      // Check if line starts with expected indent
      if (indentLevel > 0) {
        if (!line.startsWith(indentPrefix)) {
          break;
        }
        line = line.substring(indentPrefix.length);
      }

      final match = pattern.firstMatch(line);

      if (match != null) {
        final currentIndent = match.group(1) ?? '';
        extraIndent ??= currentIndent;

        if (isOrdered && startNumber == null) {
          startNumber = int.tryParse(match.group(2) ?? '1') ?? 1;
        }

        var content = match.group(isOrdered ? 3 : 2)!;
        bool? isChecked;

        // Check for task list item
        final taskMatch = _taskListPattern.firstMatch(content);
        if (taskMatch != null) {
          isChecked = taskMatch.group(1) == 'x' || taskMatch.group(1) == 'X';
          content = taskMatch.group(2) ?? '';
        }

        items.add(<String, dynamic>{
          'content': content,
          'checked': isChecked,
          'children': <Map<String, dynamic>>[],
        });
        j++;

        // Check for nested lists (indented by 2 more spaces relative to current item)
        if (j < lines.length) {
          final nextLine = lines[j];
          final nestedIndent = '$indentPrefix$extraIndent  ';

          if (nextLine.startsWith(nestedIndent)) {
            final strippedLine = nextLine.substring(nestedIndent.length);
            final nestedOrdered = _orderedListPattern.hasMatch(strippedLine);
            final nestedUnordered =
                _unorderedListPattern.hasMatch(strippedLine);

            if (nestedOrdered || nestedUnordered) {
              // Parse nested list
              final nestedResult = _parseList(
                lines,
                j,
                blockIndex,
                isOrdered: nestedOrdered,
                indentLevel: indentLevel + 1 + (extraIndent!.length ~/ 2),
              );

              if (nestedResult.block != null) {
                final nestedItems =
                    nestedResult.block!.metadata['items'] as List<dynamic>?;
                if (nestedItems != null) {
                  items.last['children'] = nestedItems;
                }
              }
              j = nestedResult.nextIndex;
              continue;
            }
          }
        }

        // Handle continuation lines (indented content that's not a nested list)
        while (j < lines.length) {
          final nextLine = lines[j];
          final contIndent = '$indentPrefix$extraIndent  ';
          if (nextLine.startsWith(contIndent)) {
            final strippedLine = nextLine.substring(contIndent.length);
            // Make sure it's not a list item
            if (!_orderedListPattern.hasMatch(strippedLine) &&
                !_unorderedListPattern.hasMatch(strippedLine)) {
              final currentItem = items.last;
              currentItem['content'] =
                  '${currentItem['content']}\n$strippedLine';
              j++;
            } else {
              break;
            }
          } else {
            break;
          }
        }

        // Check for nested lists again (after continuation lines)
        if (j < lines.length) {
          final nextLine = lines[j];
          final nestedIndent = '$indentPrefix$extraIndent  ';

          if (nextLine.startsWith(nestedIndent)) {
            final strippedLine = nextLine.substring(nestedIndent.length);
            final nestedOrdered = _orderedListPattern.hasMatch(strippedLine);
            final nestedUnordered =
                _unorderedListPattern.hasMatch(strippedLine);

            if (nestedOrdered || nestedUnordered) {
              // Parse nested list
              final nestedResult = _parseList(
                lines,
                j,
                blockIndex,
                isOrdered: nestedOrdered,
                indentLevel: indentLevel + 1 + (extraIndent!.length ~/ 2),
              );

              if (nestedResult.block != null) {
                final nestedItems =
                    nestedResult.block!.metadata['items'] as List<dynamic>?;
                if (nestedItems != null) {
                  final existingChildren =
                      items.last['children'] as List<dynamic>;
                  existingChildren.addAll(nestedItems);
                }
              }
              j = nestedResult.nextIndex;
              continue;
            }
          }
        }
      } else if (line.trim().isEmpty) {
        j++;
        // Check if next line continues the list
        if (j < lines.length) {
          var nextLine = lines[j];
          if (indentLevel > 0 && nextLine.startsWith(indentPrefix)) {
            nextLine = nextLine.substring(indentPrefix.length);
          }
          if (pattern.hasMatch(nextLine)) {
            continue;
          }
        }
        break;
      } else {
        break;
      }
    }

    final type = isOrdered
        ? MarkdownBlockType.orderedList
        : MarkdownBlockType.unorderedList;
    final content = items.map((i) => i['content']).join('\n');

    return _ParseResult(
      MarkdownBlock(
        id: _generateId(type, content, blockIndex),
        type: type,
        content: content,
        metadata: <String, dynamic>{
          'items': items,
          if (isOrdered) 'start': startNumber ?? 1,
        },
      ),
      j,
    );
  }

  _ParseResult _parseTable(List<String> lines, int index, int blockIndex) {
    final rows = <List<String>>[];
    final alignments = <TableAlignment>[];

    // Parse header row
    rows.add(_parseTableRow(lines[index]));

    // Parse delimiter row and extract alignments
    final delimiterCells = _parseTableRow(lines[index + 1]);
    for (final cell in delimiterCells) {
      final trimmed = cell.trim();
      if (trimmed.startsWith(':') && trimmed.endsWith(':')) {
        alignments.add(TableAlignment.center);
      } else if (trimmed.endsWith(':')) {
        alignments.add(TableAlignment.right);
      } else {
        alignments.add(TableAlignment.left);
      }
    }

    var j = index + 2;

    // Parse data rows
    while (j < lines.length) {
      final line = lines[j];
      if (_isTableRow(line)) {
        rows.add(_parseTableRow(line));
        j++;
      } else {
        break;
      }
    }

    final content = rows.map((r) => r.join('|')).join('\n');

    // Use row count for stable ID so table only updates on complete rows
    final tableId = 'table_${blockIndex}_${rows.length}';

    return _ParseResult(
      MarkdownBlock(
        id: tableId,
        type: MarkdownBlockType.table,
        content: content,
        metadata: <String, dynamic>{
          'rows': rows,
          'alignments': alignments.map((a) => a.name).toList(),
        },
      ),
      j,
    );
  }

  List<String> _parseTableRow(String line) {
    var trimmed = line.trim();
    if (trimmed.startsWith('|')) trimmed = trimmed.substring(1);
    if (trimmed.endsWith('|')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed.split('|').map((c) => c.trim()).toList();
  }

  bool _isTableRow(String line) {
    final trimmed = line.trim();
    // Must contain | but not be just |
    // Also should have at least one cell (content before or after |)
    if (!trimmed.contains('|') || trimmed.startsWith('|--')) {
      return false;
    }
    // Require at least 2 pipe characters OR pipe with content on at least one side
    final pipeCount = '|'.allMatches(trimmed).length;
    if (pipeCount < 2 && trimmed == '|') {
      return false;
    }
    return true;
  }

  bool _isTableDelimiter(String line) {
    final trimmed = line.trim();
    return trimmed.contains('|') &&
        RegExp(r'^[\s|:\-]+$').hasMatch(trimmed) &&
        trimmed.contains('-');
  }

  bool _isThematicBreak(String line) {
    final trimmed = line.trim();
    if (trimmed.length < 3) return false;

    // Must be only -, *, or _ (optionally with spaces)
    final withoutSpaces = trimmed.replaceAll(' ', '');
    if (withoutSpaces.length < 3) return false;

    final char = withoutSpaces[0];
    if (char != '-' && char != '*' && char != '_') return false;

    return withoutSpaces.split('').every((c) => c == char);
  }

  String _generateId(MarkdownBlockType type, String content, int index) {
    // Generate a stable ID based on type and position (index).
    // content hash is deliberately excluded to ensure the ID remains stable
    // as content grows during streaming, allowing the renderer to update
    // existing RenderObjects instead of recreating them.
    return '${type.name}_$index';
  }

  // Patterns
  static final _headerPattern = RegExp(r'^(#{1,6})\s+(.*)$');
  static final _fencedCodePattern = RegExp(r'^(`{3,}|~{3,})(.*)$');
  static final _orderedListPattern = RegExp(r'^(\s*)(\d+)\.\s+(.*)$');
  static final _unorderedListPattern = RegExp(r'^(\s*)[-*+]\s+(.*)$');
  static final _taskListPattern = RegExp(r'^\[([xX ])\]\s+(.*)$');
  static final _htmlBlockPattern = RegExp('^<([a-zA-Z][a-zA-Z0-9]*)[^>]*>');
}

class _ParseResult {
  const _ParseResult(this.block, this.nextIndex);
  final MarkdownBlock? block;
  final int nextIndex;
}
