import 'dart:convert';

import 'markdown_block.dart';
import 'markdown_pattern.dart';

class IncrementalMarkdownParser {
  IncrementalMarkdownParser({this.customPatterns = const []});

  final List<MarkdownPattern> customPatterns;

  int _parseDepth = 0;
  static const int _maxParseDepth = 10;

  List<MarkdownBlock> parse(String markdown, {bool isNested = false}) {
    if (markdown.isEmpty) return [];

    _parseDepth++;
    try {
      if (_parseDepth > _maxParseDepth) {
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

      return blocks;
    } finally {
      _parseDepth--;
    }
  }

  _ParseResult _parseBlock(List<String> lines, int index, int blockIndex) {
    if (index >= lines.length) {
      return _ParseResult(null, index + 1);
    }

    final line = lines[index];

    if (line.trim().isEmpty) {
      return _ParseResult(null, index + 1);
    }

    // Custom patterns
    // Format: 󠄞content󠄞 (U+EB1E)
    const kCustomIdentifier = '\uEB1E';
    if (line.startsWith(kCustomIdentifier)) {
      // Check if the line ends with the identifier (ignoring trailing whitespace?)
      // Check if the line ends with the identifier (ignoring trailing whitespace?)
      // The user said "trigger custom widget and end should have same".
      // We assume the custom block content is usually on one line or spans until the closing identifier.

      var content = line.substring(kCustomIdentifier.length);

      if (content.contains(kCustomIdentifier)) {
        final endIndex = content.indexOf(kCustomIdentifier);
        content = content.substring(0, endIndex);
      } else {
        // Multi-line consumption — look for closing delimiter
        var j = index + 1;
        final buffer = StringBuffer(content);
        var closed = false;

        while (j < lines.length) {
          final nextLine = lines[j];
          if (nextLine.contains(kCustomIdentifier)) {
            final endIdx = nextLine.indexOf(kCustomIdentifier);
            buffer.write('\n${nextLine.substring(0, endIdx)}');
            content = buffer.toString();
            closed = true;
            index = j;
            break;
          } else {
            buffer.write('\n$nextLine');
            j++;
          }
        }

        if (!closed) {
          // No closing delimiter found — treat as partial block (like unclosed code blocks)
          // Only consume the opening line, don't gobble the rest of the document
          // Strip the opening delimiter from content so it's clean
          final partialContent = content;
          // Try to match patterns on the partial content (may match for simple patterns)
          for (var pi = 0; pi < customPatterns.length; pi++) {
            final p = customPatterns[pi];
            final m = p.pattern.firstMatch(partialContent);
            if (m != null) {
              final partialBlockId = p.blockBuilder != null
                  ? p.blockBuilder!(
                      _generateId(MarkdownBlockType.custom, partialContent, blockIndex),
                      partialContent,
                      m,
                    )
                  : MarkdownBlock(
                      id: _generateId(MarkdownBlockType.custom, partialContent, blockIndex),
                      type: MarkdownBlockType.custom,
                      content: partialContent,
                      metadata: {'patternIndex': pi},
                      isPartial: true,
                    );
              return _ParseResult(partialBlockId, index + 1);
            }
          }
          // No pattern matched the partial content — return as custom block without patternIndex
          return _ParseResult(
            MarkdownBlock(
              id: _generateId(MarkdownBlockType.custom, partialContent, blockIndex),
              type: MarkdownBlockType.custom,
              content: partialContent,
              metadata: const <String, dynamic>{},
              isPartial: true,
            ),
            index + 1,
          );
        }
      }

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

      return _ParseResult(
        MarkdownBlock(
          id: _generateId(MarkdownBlockType.paragraph, line, blockIndex),
          type: MarkdownBlockType.paragraph,
          content: line,
        ),
        index + 1,
      );
    }

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

    final codeMatch = _fencedCodePattern.firstMatch(line);
    if (codeMatch != null) {
      final fence = codeMatch.group(1)!;
      final language = codeMatch.group(2)?.trim() ?? '';
      final codeLines = <String>[];
      var j = index + 1;
      final closingPattern = RegExp(
        '^${RegExp.escape(fence[0])}{${fence.length},}\\s*\$',
      );

      while (j < lines.length) {
        final closingMatch = closingPattern.firstMatch(lines[j]);
        if (closingMatch != null) {
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

    if (line.startsWith('>')) {
      final quoteLines = <String>[];
      var j = index;

      while (j < lines.length) {
        final currentLine = lines[j];

        if (currentLine.startsWith('>')) {
          // Remove the > and optional space
          var content = currentLine.substring(1);
          if (content.startsWith(' ')) {
            content = content.substring(1);
          }
          quoteLines.add(content);
          j++;
        } else if (currentLine.trim().isEmpty) {
          // Blank line: include it but check if next line continues blockquote
          quoteLines.add('');
          j++;
          if (j < lines.length && !lines[j].startsWith('>')) {
            // Blank line followed by non-blockquote line ends the blockquote
            // Remove the blank line we just added
            quoteLines.removeLast();
            break;
          }
        } else {
          break;
        }
      }

      // Join and clean up the content (trimRight preserves leading whitespace)
      final quoteContent = quoteLines.join('\n').trimRight();

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
        final nextTrimmed = lines[j].trim();
        // Closing $$ must be at start of line or preceded only by whitespace
        if (nextTrimmed.startsWith(r'$$') &&
            nextTrimmed.indexOf(r'$$', 2) == -1) {
          // This line starts with $$ and has no more $$ after the opening pair
          // (i.e. it's a closing fence, not an inline $$ pair)
          latexLines.add(lines[j]);
          j++;
          break;
        }
        latexLines.add(lines[j]);
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
      final htmlLines = <String>[line];
      var j = index + 1;

      // Continue until blank line (CommonMark HTML block type 6/7 end condition)
      while (j < lines.length) {
        if (lines[j].trim().isEmpty) break;
        htmlLines.add(lines[j]);
        j++;
      }

      return _ParseResult(
        MarkdownBlock(
          id: _generateId(MarkdownBlockType.html, htmlLines.join('\n'), blockIndex),
          type: MarkdownBlockType.html,
          content: htmlLines.join('\n'),
        ),
        j,
      );
    }

    // Default: paragraph
    final paragraphLines = <String>[];
    var j = index;

    while (j < lines.length) {
      final currentLine = lines[j];

      // Stop at block-level elements
      if (currentLine.trim().isEmpty ||
          currentLine.startsWith(kCustomIdentifier) ||
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

        var content = match.group(isOrdered ? 4 : 2)!;
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
                indentLevel: indentLevel + 1 + (extraIndent.length ~/ 2),
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
                indentLevel: indentLevel + 1 + (extraIndent.length ~/ 2),
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
    if (!trimmed.contains('|')) {
      return false;
    }
    // Don't confuse delimiter rows with data rows - check if it looks like a delimiter
    if (_isTableDelimiter(trimmed)) {
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
    if (!trimmed.contains('|')) return false;
    if (!RegExp(r'^[\s|:\-]+$').hasMatch(trimmed)) return false;
    // Each cell must contain at least one dash
    final cells = trimmed.split('|');
    for (final cell in cells) {
      if (cell.trim().contains('-')) {
        return true; // At least one cell has a dash
      }
    }
    return false;
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
  static final _headerPattern = RegExp(r'^(#{1,6})\s+(.*?)(?:\s+#+\s*)?$');
  static final _fencedCodePattern = RegExp(r'^(`{3,}|~{3,})(.*)$');
  static final _orderedListPattern = RegExp(r'^(\s*)(\d+)([.)])\s+(.*)$');
  static final _unorderedListPattern = RegExp(r'^(\s*)[-*+]\s+(.*)$');
  static final _taskListPattern = RegExp(r'^\[([xX ])\]\s+(.*)$');
  static final _htmlBlockPattern = RegExp(r'^(<!--|<!|<([a-zA-Z][a-zA-Z0-9]*)[^>]*>)');
}

class _ParseResult {
  const _ParseResult(this.block, this.nextIndex);
  final MarkdownBlock? block;
  final int nextIndex;
}
