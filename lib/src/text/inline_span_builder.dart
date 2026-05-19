import 'package:flutter/gestures.dart';
import 'package:flutter/painting.dart';

import '../theme/markdown_theme.dart';

/// Builds TextSpans from inline Markdown content.
class InlineSpanBuilder {
  /// Creates a new inline span builder.
  InlineSpanBuilder();

  final List<TapGestureRecognizer> _recognizers = [];

  /// Disposes all gesture recognizers created by this builder.
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  /// Builds a TextSpan tree from inline Markdown.
  TextSpan build(
    String text,
    TextStyle baseStyle,
    MarkdownTheme theme, {
    void Function(String url)? onLinkTapped,
  }) {
    final spans = _parseInline(text, baseStyle, theme, onLinkTapped);
    return TextSpan(children: spans);
  }

  List<InlineSpan> _parseInline(
    String text,
    TextStyle baseStyle,
    MarkdownTheme theme,
    void Function(String url)? onLinkTapped,
  ) {
    final spans = <InlineSpan>[];
    var i = 0;

    while (i < text.length) {
      // Escape character
      if (text[i] == r'\' && i + 1 < text.length) {
        final nextChar = text[i + 1];
        if (_isEscapable(nextChar)) {
          spans.add(TextSpan(text: nextChar, style: baseStyle));
          i += 2;
          continue;
        }
      }

      // Inline code
      if (text[i] == '`') {
        final result = _parseInlineCode(text, i, baseStyle, theme);
        if (result != null) {
          spans.add(result.span);
          i = result.endIndex;
          continue;
        }
      }

      // Inline LaTeX $...$
      if (text[i] == r'$' && !_isDollarEscaped(text, i)) {
        final result = _parseInlineLatex(text, i, baseStyle);
        if (result != null) {
          spans.add(result.span);
          i = result.endIndex;
          continue;
        }
      }

      // Images ![alt](url)
      if (text[i] == '!' && i + 1 < text.length && text[i + 1] == '[') {
        final result = _parseImage(text, i, baseStyle);
        if (result != null) {
          spans.add(result.span);
          i = result.endIndex;
          continue;
        }
      }

      // Links [text](url)
      if (text[i] == '[') {
        final result = _parseLink(text, i, baseStyle, theme, onLinkTapped);
        if (result != null) {
          spans.add(result.span);
          i = result.endIndex;
          continue;
        }
      }

      // Autolinks <url>
      if (text[i] == '<') {
        final result = _parseAutolink(text, i, baseStyle, theme, onLinkTapped);
        if (result != null) {
          spans.add(result.span);
          i = result.endIndex;
          continue;
        }
      }

      // Bold and italic (*** or ___)
      if ((text[i] == '*' || text[i] == '_') &&
          i + 2 < text.length &&
          text[i + 1] == text[i] &&
          text[i + 2] == text[i]) {
        final result =
            _parseBoldItalic(text, i, baseStyle, theme, onLinkTapped);
        if (result != null) {
          spans.add(result.span);
          i = result.endIndex;
          continue;
        }
      }

      // Bold (** or __)
      if ((text[i] == '*' || text[i] == '_') &&
          i + 1 < text.length &&
          text[i + 1] == text[i]) {
        final result = _parseBold(text, i, baseStyle, theme, onLinkTapped);
        if (result != null) {
          spans.add(result.span);
          i = result.endIndex;
          continue;
        }
      }

      // Italic (* or _)
      if (text[i] == '*' || text[i] == '_') {
        final result = _parseItalic(text, i, baseStyle, theme, onLinkTapped);
        if (result != null) {
          spans.add(result.span);
          i = result.endIndex;
          continue;
        }
      }

      // Strikethrough (~~)
      if (text[i] == '~' && i + 1 < text.length && text[i + 1] == '~') {
        final result =
            _parseStrikethrough(text, i, baseStyle, theme, onLinkTapped);
        if (result != null) {
          spans.add(result.span);
          i = result.endIndex;
          continue;
        }
      }

      // HTML entities and tags
      if (text[i] == '<') {
        final result = _parseHtmlTag(text, i, baseStyle);
        if (result != null) {
          spans.add(result.span);
          i = result.endIndex;
          continue;
        }
      }

      // Line break (<br> or double space + newline)
      if (text[i] == '\n') {
        // Character-by-character check for trailing double spaces before newline
        var hasHardBreak = false;
        if (i >= 2) {
          hasHardBreak = text[i - 1] == ' ' && text[i - 2] == ' ';
        }
        if (hasHardBreak) {
          spans.add(const TextSpan(text: '\n'));
          i++;
          continue;
        }
        spans.add(TextSpan(text: ' ', style: baseStyle));
        i++;
        continue;
      }

      // Plain text - collect until next special character
      final start = i;
      while (i < text.length && !_isSpecialChar(text[i])) {
        i++;
      }
      if (i > start) {
        spans.add(TextSpan(text: text.substring(start, i), style: baseStyle));
      } else {
        // Single special character that wasn't matched
        spans.add(TextSpan(text: text[i], style: baseStyle));
        i++;
      }
    }

    return spans;
  }

  _ParseResult? _parseInlineCode(
    String text,
    int start,
    TextStyle baseStyle,
    MarkdownTheme theme,
  ) {
    // Find the closing backtick(s)
    var backticks = 1;
    var i = start + 1;
    while (i < text.length && text[i] == '`') {
      backticks++;
      i++;
    }

    final openingEnd = i;

    // Find matching closing backticks
    while (i < text.length) {
      if (text[i] == '`') {
        var closeCount = 0;
        final closeStart = i;
        while (i < text.length && text[i] == '`') {
          closeCount++;
          i++;
        }
        if (closeCount == backticks) {
          var code = text.substring(openingEnd, closeStart);
          // Strip single leading/trailing space if present
          if (code.startsWith(' ') && code.endsWith(' ') && code.length > 2) {
            code = code.substring(1, code.length - 1);
          }

          // Use theme's inline code style if available
          final themeCodeStyle = theme.inlineCodeStyle;
          final codeStyle = themeCodeStyle != null
              ? baseStyle.merge(themeCodeStyle)
              : baseStyle.copyWith(
                  fontFamily: 'monospace',
                  backgroundColor:
                      theme.codeTheme?.backgroundColor?.withValues(alpha: 0.3),
                );

          return _ParseResult(
            TextSpan(text: code, style: codeStyle),
            i,
          );
        }
      } else {
        i++;
      }
    }

    return null;
  }

  _ParseResult? _parseInlineLatex(String text, int start, TextStyle baseStyle) {
    if (start + 1 >= text.length) return null;

    // Don't match $$ (block latex)
    if (text[start + 1] == r'$') return null;

    var i = start + 1;
    while (i < text.length && text[i] != r'$') {
      i++;
    }

    if (i >= text.length) return null;

    final latex = text.substring(start + 1, i);
    final latexStyle = baseStyle.copyWith(
      fontFamily: 'monospace',
      fontStyle: FontStyle.italic,
    );

    return _ParseResult(
      TextSpan(text: '\$$latex\$', style: latexStyle),
      i + 1,
    );
  }

  _ParseResult? _parseImage(String text, int start, TextStyle baseStyle) {
    // ![alt](url)
    if (start + 4 >= text.length) return null;

    var i = start + 2;
    final altStart = i;

    // Find ]
    while (i < text.length && text[i] != ']') {
      i++;
    }
    if (i >= text.length || i + 1 >= text.length || text[i + 1] != '(') {
      return null;
    }

    final alt = text.substring(altStart, i);
    i += 2; // Skip ](

    while (i < text.length && text[i] != ')') {
      i++;
    }
    if (i >= text.length) return null;

    // Show alt text as placeholder
    return _ParseResult(
      TextSpan(
        text: '[$alt]',
        style: baseStyle.copyWith(
          color: const Color(0xFF6B7280),
          fontStyle: FontStyle.italic,
        ),
      ),
      i + 1,
    );
  }

  _ParseResult? _parseLink(
    String text,
    int start,
    TextStyle baseStyle,
    MarkdownTheme theme,
    void Function(String url)? onLinkTapped,
  ) {
    // [text](url)
    var i = start + 1;
    final textStart = i;
    var bracketDepth = 1;

    // Find matching ]
    while (i < text.length && bracketDepth > 0) {
      if (text[i] == '[') {
        bracketDepth++;
      } else if (text[i] == ']') {
        bracketDepth--;
      }
      if (bracketDepth > 0) i++;
    }

    if (i >= text.length || i + 1 >= text.length || text[i + 1] != '(') {
      return null;
    }

    final linkText = text.substring(textStart, i);
    i += 2; // Skip ](

    final urlStart = i;
    var parenDepth = 1;
    while (i < text.length && parenDepth > 0) {
      if (text[i] == '(') {
        parenDepth++;
      } else if (text[i] == ')') {
        parenDepth--;
      }
      if (parenDepth > 0) i++;
    }

    if (i > text.length) return null;

    final url = text.substring(urlStart, i);

    // Use theme's link style if available
    final themeLinkStyle = theme.linkStyle;
    final linkStyle = themeLinkStyle != null
        ? baseStyle.merge(themeLinkStyle)
        : baseStyle.copyWith(
            color: theme.linkColor ?? const Color(0xFF2563EB),
            decoration: TextDecoration.underline,
          );

    TapGestureRecognizer? recognizer;
    if (onLinkTapped != null) {
      recognizer = TapGestureRecognizer()..onTap = () => onLinkTapped(url);
      _recognizers.add(recognizer);
    }

    // Parse nested inline elements in link text
    final nestedSpans = _parseInline(linkText, linkStyle, theme, onLinkTapped);

    return _ParseResult(
      TextSpan(
        children: nestedSpans,
        recognizer: recognizer,
      ),
      i + 1,
    );
  }

  _ParseResult? _parseAutolink(
    String text,
    int start,
    TextStyle baseStyle,
    MarkdownTheme theme,
    void Function(String url)? onLinkTapped,
  ) {
    // <url> or <email>
    var i = start + 1;
    final contentStart = i;

    while (i < text.length && text[i] != '>') {
      i++;
    }

    if (i >= text.length) return null;

    final content = text.substring(contentStart, i);

    // Check if it's a valid URL or email
    if (!content.contains('://') && !content.contains('@')) {
      return null;
    }

    final url = content.contains('@') && !content.contains('://')
        ? 'mailto:$content'
        : content;

    // Use theme's link style if available
    final themeLinkStyle = theme.linkStyle;
    final linkStyle = themeLinkStyle != null
        ? baseStyle.merge(themeLinkStyle)
        : baseStyle.copyWith(
            color: theme.linkColor ?? const Color(0xFF2563EB),
            decoration: TextDecoration.underline,
          );

    TapGestureRecognizer? recognizer;
    if (onLinkTapped != null) {
      recognizer = TapGestureRecognizer()..onTap = () => onLinkTapped(url);
      _recognizers.add(recognizer);
    }

    return _ParseResult(
      TextSpan(
        text: content,
        style: linkStyle,
        recognizer: recognizer,
      ),
      i + 1,
    );
  }

  _ParseResult? _parseBoldItalic(
    String text,
    int start,
    TextStyle baseStyle,
    MarkdownTheme theme,
    void Function(String url)? onLinkTapped,
  ) {
    final marker = text[start];
    var i = start + 3;

    // Find closing ***
    while (i + 2 < text.length) {
      if (text[i] == marker && text[i + 1] == marker && text[i + 2] == marker) {
        final content = text.substring(start + 3, i);
        // Merge both bold and italic styles from theme
        var boldItalicStyle = baseStyle;
        if (theme.boldStyle != null) {
          boldItalicStyle = boldItalicStyle.merge(theme.boldStyle);
        } else {
          boldItalicStyle =
              boldItalicStyle.copyWith(fontWeight: FontWeight.bold);
        }
        if (theme.italicStyle != null) {
          boldItalicStyle = boldItalicStyle.merge(theme.italicStyle);
        } else {
          boldItalicStyle =
              boldItalicStyle.copyWith(fontStyle: FontStyle.italic);
        }

        final nestedSpans =
            _parseInline(content, boldItalicStyle, theme, onLinkTapped);

        return _ParseResult(
          TextSpan(children: nestedSpans),
          i + 3,
        );
      }
      i++;
    }

    return null;
  }

  _ParseResult? _parseBold(
    String text,
    int start,
    TextStyle baseStyle,
    MarkdownTheme theme,
    void Function(String url)? onLinkTapped,
  ) {
    final marker = text[start];
    var i = start + 2;

    // Find closing **
    while (i + 1 < text.length) {
      if (text[i] == marker && text[i + 1] == marker) {
        // Make sure it's not *** (bold italic)
        if (i + 2 < text.length && text[i + 2] == marker) {
          // Skip the entire *** sequence
          i += 3;
          continue;
        }

        final content = text.substring(start + 2, i);
        // Use theme's bold style if available
        final boldStyle = theme.boldStyle != null
            ? baseStyle.merge(theme.boldStyle)
            : baseStyle.copyWith(fontWeight: FontWeight.bold);

        final nestedSpans =
            _parseInline(content, boldStyle, theme, onLinkTapped);

        return _ParseResult(
          TextSpan(children: nestedSpans),
          i + 2,
        );
      }
      i++;
    }

    return null;
  }

  _ParseResult? _parseItalic(
    String text,
    int start,
    TextStyle baseStyle,
    MarkdownTheme theme,
    void Function(String url)? onLinkTapped,
  ) {
    final marker = text[start];
    var i = start + 1;

    // Don't match if followed by space
    if (i < text.length && text[i] == ' ') return null;

    // For underscores, check word boundary at opening
    if (marker == '_' && start > 0 && _isWordChar(text[start - 1])) {
      return null;
    }

    // Find closing *
    while (i < text.length) {
      if (text[i] == marker) {
        // Make sure it's not ** or ***
        if (i + 1 < text.length && text[i + 1] == marker) {
          i++;
          continue;
        }

        final content = text.substring(start + 1, i);
        if (content.isEmpty) return null;

        // For underscores, check word boundary at closing
        if (marker == '_' &&
            i + 1 < text.length &&
            _isWordChar(text[i + 1])) {
          i++;
          continue;
        }

        // Use theme's italic style if available
        final italicStyle = theme.italicStyle != null
            ? baseStyle.merge(theme.italicStyle)
            : baseStyle.copyWith(fontStyle: FontStyle.italic);

        final nestedSpans =
            _parseInline(content, italicStyle, theme, onLinkTapped);

        return _ParseResult(
          TextSpan(children: nestedSpans),
          i + 1,
        );
      }
      i++;
    }

    return null;
  }

  _ParseResult? _parseStrikethrough(
    String text,
    int start,
    TextStyle baseStyle,
    MarkdownTheme theme,
    void Function(String url)? onLinkTapped,
  ) {
    var i = start + 2;

    // Find closing ~~
    while (i + 1 < text.length) {
      if (text[i] == '~' && text[i + 1] == '~') {
        final content = text.substring(start + 2, i);
        // Use theme's strikethrough style if available
        final strikeStyle = theme.strikethroughStyle != null
            ? baseStyle.merge(theme.strikethroughStyle)
            : baseStyle.copyWith(decoration: TextDecoration.lineThrough);

        final nestedSpans =
            _parseInline(content, strikeStyle, theme, onLinkTapped);

        return _ParseResult(
          TextSpan(children: nestedSpans),
          i + 2,
        );
      }
      i++;
    }

    return null;
  }

  _ParseResult? _parseHtmlTag(String text, int start, TextStyle baseStyle) {
    // Handle common HTML tags
    if (text.substring(start).startsWith('<br>') ||
        text.substring(start).startsWith('<br/>') ||
        text.substring(start).startsWith('<br />')) {
      final tagEnd = text.indexOf('>', start) + 1;
      return _ParseResult(
        const TextSpan(text: '\n'),
        tagEnd,
      );
    }

    // <del>text</del>
    if (text.substring(start).startsWith('<del>')) {
      final closeTag = text.indexOf('</del>', start);
      if (closeTag != -1) {
        final content = text.substring(start + 5, closeTag);
        return _ParseResult(
          TextSpan(
            text: content,
            style: baseStyle.copyWith(decoration: TextDecoration.lineThrough),
          ),
          closeTag + 6,
        );
      }
    }

    // <em>text</em>
    if (text.substring(start).startsWith('<em>')) {
      final closeTag = text.indexOf('</em>', start);
      if (closeTag != -1) {
        final content = text.substring(start + 4, closeTag);
        return _ParseResult(
          TextSpan(
            text: content,
            style: baseStyle.copyWith(fontStyle: FontStyle.italic),
          ),
          closeTag + 5,
        );
      }
    }

    // <strong>text</strong>
    if (text.substring(start).startsWith('<strong>')) {
      final closeTag = text.indexOf('</strong>', start);
      if (closeTag != -1) {
        final content = text.substring(start + 8, closeTag);
        return _ParseResult(
          TextSpan(
            text: content,
            style: baseStyle.copyWith(fontWeight: FontWeight.bold),
          ),
          closeTag + 9,
        );
      }
    }

    // <code>text</code>
    if (text.substring(start).startsWith('<code>')) {
      final closeTag = text.indexOf('</code>', start);
      if (closeTag != -1) {
        final content = text.substring(start + 6, closeTag);
        return _ParseResult(
          TextSpan(
            text: content,
            style: baseStyle.copyWith(fontFamily: 'monospace'),
          ),
          closeTag + 7,
        );
      }
    }

    return null;
  }

  bool _isSpecialChar(String char) {
    return char == '*' ||
        char == '_' ||
        char == '`' ||
        char == '[' ||
        char == '!' ||
        char == '<' ||
        char == '~' ||
        char == r'\' ||
        char == r'$' ||
        char == '\n';
  }

  bool _isEscapable(String char) {
    return r'\`*_{}[]()#+-.!~$'.contains(char);
  }

  /// Checks whether a `$` at [index] is escaped by an odd number of
  /// preceding backslashes.
  bool _isDollarEscaped(String text, int index) {
    var backslashCount = 0;
    var j = index - 1;
    while (j >= 0 && text[j] == r'\') {
      backslashCount++;
      j--;
    }
    // Odd number of backslashes means the $ is escaped
    return backslashCount.isOdd;
  }

  /// Checks if a character is a word character (letter, digit, or underscore).
  bool _isWordChar(String char) {
    return RegExp(r'[\w]').hasMatch(char);
  }
}

class _ParseResult {
  const _ParseResult(this.span, this.endIndex);
  final InlineSpan span;
  final int endIndex;
}
