import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_markdown_renderer/src/text/inline_span_builder.dart';
import 'package:stream_markdown_renderer/src/theme/markdown_theme.dart';

void main() {
  late InlineSpanBuilder builder;
  late TextStyle baseStyle;
  late MarkdownTheme theme;

  setUp(() {
    builder = InlineSpanBuilder();
    baseStyle = const TextStyle(fontSize: 16, color: Color(0xFF1F2937));
    theme = const MarkdownTheme();
  });

  tearDown(() {
    builder.dispose();
  });

  // ── Plain text ──────────────────────────────────────────────────

  group('plain text', () {
    test('renders simple text as a single TextSpan with base style', () {
      final span = builder.build('hello world', baseStyle, theme);
      expect(span.children, isNotNull);
      expect(span.children!.length, 1);
      final child = span.children!.first as TextSpan;
      expect(child.text, 'hello world');
      expect(child.style, baseStyle);
    });

    test('renders empty string without crashing', () {
      final span = builder.build('', baseStyle, theme);
      expect(span.children, isNotNull);
      expect(span.children!, isEmpty);
    });

    test('renders text with no special characters', () {
      final span = builder.build('just plain text here', baseStyle, theme);
      final child = span.children!.first as TextSpan;
      expect(child.text, 'just plain text here');
    });
  });

  // ── Bold ────────────────────────────────────────────────────────

  group('bold', () {
    test('**text** produces bold TextSpan', () {
      final span = builder.build('**bold text**', baseStyle, theme);
      expect(
        _anySpanHasProperty(span, (s) => s?.fontWeight == FontWeight.bold),
        isTrue,
        reason: 'Expected a span with fontWeight: FontWeight.bold',
      );
    });

    test('**text** with theme.boldStyle uses merged theme style', () {
      final themeWithBold = const MarkdownTheme(
        boldStyle: TextStyle(fontWeight: FontWeight.w900),
      );
      final span = builder.build('**bold**', baseStyle, themeWithBold);
      expect(
        _anySpanHasProperty(span, (s) => s?.fontWeight == FontWeight.w900),
        isTrue,
      );
    });
  });

  // ── Italic with asterisk ────────────────────────────────────────

  group('italic with asterisk', () {
    test('*text* produces italic TextSpan', () {
      final span = builder.build('*italic text*', baseStyle, theme);
      expect(
        _anySpanHasProperty(span, (s) => s?.fontStyle == FontStyle.italic),
        isTrue,
        reason: 'Expected a span with fontStyle: FontStyle.italic',
      );
    });

    test('*text* with theme.italicStyle uses merged theme style', () {
      final themeWithItalic = const MarkdownTheme(
        italicStyle: TextStyle(
          fontStyle: FontStyle.italic,
          color: Color(0xFF00FF00),
        ),
      );
      final span = builder.build('*italic*', baseStyle, themeWithItalic);
      expect(
        _anySpanHasProperty(span, (s) => s?.color == const Color(0xFF00FF00)),
        isTrue,
      );
    });
  });

  // ── Italic with underscore ──────────────────────────────────────

  group('italic with underscore', () {
    test('_text_ produces italic TextSpan', () {
      final span = builder.build('_italic text_', baseStyle, theme);
      expect(
        _anySpanHasProperty(span, (s) => s?.fontStyle == FontStyle.italic),
        isTrue,
        reason: 'Expected a span with fontStyle: FontStyle.italic',
      );
    });

    test('underscore italic NOT within words: foo_bar_baz is plain', () {
      final span = builder.build('foo_bar_baz', baseStyle, theme);
      expect(
        _anySpanHasProperty(span, (s) => s?.fontStyle == FontStyle.italic),
        isFalse,
        reason: 'Underscores within words should not trigger italic',
      );
    });

    test('word boundary _text_ is italic', () {
      final span = builder.build('hello _world_ end', baseStyle, theme);
      expect(
        _anySpanHasProperty(span, (s) => s?.fontStyle == FontStyle.italic),
        isTrue,
      );
    });
  });

  // ── Bold + Italic ───────────────────────────────────────────────

  group('bold+italic', () {
    test('***text*** produces bold and italic TextSpan', () {
      final span = builder.build('***bold italic***', baseStyle, theme);
      expect(
        _anySpanHasProperty(span, (s) => s?.fontWeight == FontWeight.bold),
        isTrue,
        reason: 'Expected bold in ***text***',
      );
      expect(
        _anySpanHasProperty(span, (s) => s?.fontStyle == FontStyle.italic),
        isTrue,
        reason: 'Expected italic in ***text***',
      );
    });

    test('***text*** with theme styles merges bold and italic', () {
      final themeWithStyles = const MarkdownTheme(
        boldStyle: TextStyle(fontWeight: FontWeight.w900),
        italicStyle: TextStyle(fontStyle: FontStyle.italic),
      );
      final span =
          builder.build('***bi***', baseStyle, themeWithStyles);
      expect(
        _anySpanHasProperty(span, (s) => s?.fontWeight == FontWeight.w900),
        isTrue,
      );
      expect(
        _anySpanHasProperty(span, (s) => s?.fontStyle == FontStyle.italic),
        isTrue,
      );
    });
  });

  // ── Strikethrough ───────────────────────────────────────────────

  group('strikethrough', () {
    test('~~text~~ produces lineThrough decoration', () {
      final span = builder.build('~~deleted~~', baseStyle, theme);
      expect(
        _anySpanHasDecoration(span, TextDecoration.lineThrough),
        isTrue,
        reason: 'Expected TextDecoration.lineThrough for ~~text~~',
      );
    });

    test('~~text~~ with theme.strikethroughStyle uses merged style', () {
      final themeWithStrike = const MarkdownTheme(
        strikethroughStyle: TextStyle(decoration: TextDecoration.lineThrough),
      );
      final span = builder.build('~~deleted~~', baseStyle, themeWithStrike);
      expect(
        _anySpanHasDecoration(span, TextDecoration.lineThrough),
        isTrue,
      );
    });
  });

  // ── Inline code ─────────────────────────────────────────────────

  group('inline code', () {
    test('`code` produces monospace font', () {
      final span = builder.build('`var x`', baseStyle, theme);
      expect(
        _anySpanHasProperty(span, (s) => s?.fontFamily == 'monospace'),
        isTrue,
        reason: 'Inline code should use monospace font',
      );
    });

    test('`code` content text is the code between backticks', () {
      final span = builder.build('`hello`', baseStyle, theme);
      final codeText = _collectTextWithFontFamily(span, 'monospace');
      expect(codeText, contains('hello'));
    });

    test('double backticks ``code`` produce monospace font', () {
      final span = builder.build('``var x``', baseStyle, theme);
      expect(
        _anySpanHasProperty(span, (s) => s?.fontFamily == 'monospace'),
        isTrue,
      );
      final codeText = _collectTextWithFontFamily(span, 'monospace');
      expect(codeText, contains('var x'));
    });

    test('inline code with theme.inlineCodeStyle uses merged style', () {
      final themeWithCode = const MarkdownTheme(
        inlineCodeStyle: TextStyle(fontFamily: 'Fira Code', fontSize: 12),
      );
      final span = builder.build('`x`', baseStyle, themeWithCode);
      expect(
        _anySpanHasProperty(span, (s) => s?.fontFamily == 'Fira Code'),
        isTrue,
      );
    });
  });

  // ── Links ───────────────────────────────────────────────────────

  group('links', () {
    test('[text](url) produces TextSpan with recognizer and underline', () {
      String? tappedUrl;
      final span = builder.build(
        '[click](https://example.com)',
        baseStyle,
        theme,
        onLinkTapped: (url) => tappedUrl = url,
      );
      expect(
        _anySpanHasDecoration(span, TextDecoration.underline),
        isTrue,
        reason: 'Link should have underline decoration',
      );
      final linkSpan = _findSpanWithRecognizer(span);
      expect(linkSpan, isNotNull);
      expect(linkSpan!.recognizer, isA<TapGestureRecognizer>());
      (linkSpan.recognizer as TapGestureRecognizer).onTap!();
      expect(tappedUrl, 'https://example.com');
    });

    test('[text](url) with theme.linkStyle uses merged style', () {
      final themeWithLink = const MarkdownTheme(
        linkStyle: TextStyle(color: Color(0xFFFF0000)),
      );
      final span = builder.build(
        '[click](https://example.com)',
        baseStyle,
        themeWithLink,
        onLinkTapped: (_) {},
      );
      expect(
        _anySpanHasProperty(span, (s) => s?.color == const Color(0xFFFF0000)),
        isTrue,
      );
    });
  });

  // ── Autolinks ───────────────────────────────────────────────────

  group('autolinks', () {
    test('<https://example.com> produces clickable link', () {
      String? tappedUrl;
      final span = builder.build(
        '<https://example.com>',
        baseStyle,
        theme,
        onLinkTapped: (url) => tappedUrl = url,
      );
      final linkSpan = _findSpanWithRecognizer(span);
      expect(linkSpan, isNotNull);
      (linkSpan!.recognizer as TapGestureRecognizer).onTap!();
      expect(tappedUrl, 'https://example.com');
    });

    test('autolink URL text is the content between angle brackets', () {
      final span = builder.build(
        '<https://example.com>',
        baseStyle,
        theme,
        onLinkTapped: (_) {},
      );
      final text = _collectAllText(span);
      expect(text, contains('https://example.com'));
    });
  });

  // ── Email autolinks ─────────────────────────────────────────────

  group('email autolinks', () {
    test('<user@example.com> produces mailto: prefix link', () {
      String? tappedUrl;
      final span = builder.build(
        '<user@example.com>',
        baseStyle,
        theme,
        onLinkTapped: (url) => tappedUrl = url,
      );
      final linkSpan = _findSpanWithRecognizer(span);
      expect(linkSpan, isNotNull);
      (linkSpan!.recognizer as TapGestureRecognizer).onTap!();
      expect(tappedUrl, 'mailto:user@example.com');
    });

    test('email autolink has underline decoration', () {
      final span = builder.build(
        '<user@example.com>',
        baseStyle,
        theme,
        onLinkTapped: (_) {},
      );
      expect(
        _anySpanHasDecoration(span, TextDecoration.underline),
        isTrue,
      );
    });
  });

  // ── Images ──────────────────────────────────────────────────────

  group('images', () {
    test('![alt](url) produces placeholder text [alt]', () {
      final span = builder.build('![logo](https://img.png)', baseStyle, theme);
      final text = _collectAllText(span);
      expect(text, contains('[logo]'));
    });

    test('image placeholder has italic style', () {
      final span = builder.build('![alt](url)', baseStyle, theme);
      expect(
        _anySpanHasProperty(span, (s) => s?.fontStyle == FontStyle.italic),
        isTrue,
        reason: 'Image placeholder should be italic',
      );
    });

    test('image placeholder has grey color', () {
      final span = builder.build('![alt](url)', baseStyle, theme);
      expect(
        _anySpanHasProperty(span, (s) => s?.color == const Color(0xFF6B7280)),
        isTrue,
        reason: 'Image placeholder should have grey color',
      );
    });
  });

  // ── Inline LaTeX ────────────────────────────────────────────────

  group('inline latex', () {
    test(r'$x^2$ produces monospace+italic span', () {
      final span = builder.build(r'$x^2$', baseStyle, theme);
      final hasMono =
          _anySpanHasProperty(span, (s) => s?.fontFamily == 'monospace');
      final hasItalic =
          _anySpanHasProperty(span, (s) => s?.fontStyle == FontStyle.italic);
      expect(hasMono, isTrue, reason: 'Inline LaTeX should use monospace');
      expect(hasItalic, isTrue, reason: 'Inline LaTeX should be italic');
    });

    test('inline latex preserves dollar signs in text', () {
      final span = builder.build(r'$x^2$', baseStyle, theme);
      final text = _collectAllText(span);
      expect(text, contains(r'$x^2$'));
    });
  });

  // ── Escaped characters ──────────────────────────────────────────

  group('escaped characters', () {
    test(r'\*not bold\* renders as literal asterisks', () {
      final span = builder.build(r'\*not bold\*', baseStyle, theme);
      expect(
        _anySpanHasProperty(span, (s) => s?.fontWeight == FontWeight.bold),
        isFalse,
        reason: 'Escaped asterisks should not produce bold',
      );
      final text = _collectAllText(span);
      expect(text, contains('*'));
    });

    test('escaped dollar sign is not treated as LaTeX', () {
      final span = builder.build(r'\$not latex$', baseStyle, theme);
      expect(
        _anySpanHasProperty(span, (s) => s?.fontFamily == 'monospace'),
        isFalse,
        reason: 'Escaped dollar sign should not trigger LaTeX parsing',
      );
    });

    test(r'other escapable characters: \` renders as backtick', () {
      final span = builder.build(r'\`not code\`', baseStyle, theme);
      expect(
        _anySpanHasProperty(span, (s) => s?.fontFamily == 'monospace'),
        isFalse,
        reason: 'Escaped backtick should not produce code span',
      );
    });
  });

  // ── HTML tags ───────────────────────────────────────────────────

  group('HTML tags', () {
    test('<br> produces newline', () {
      final span = builder.build('line1<br>line2', baseStyle, theme);
      final text = _collectAllText(span);
      expect(text, contains('\n'));
    });

    test('<br/> produces newline', () {
      final span = builder.build('line1<br/>line2', baseStyle, theme);
      final text = _collectAllText(span);
      expect(text, contains('\n'));
    });

    test('<br /> produces newline', () {
      final span = builder.build('line1<br />line2', baseStyle, theme);
      final text = _collectAllText(span);
      expect(text, contains('\n'));
    });

    test('<del>text</del> produces strikethrough', () {
      final span = builder.build('<del>deleted</del>', baseStyle, theme);
      expect(
        _anySpanHasDecoration(span, TextDecoration.lineThrough),
        isTrue,
        reason: '<del> should produce strikethrough',
      );
      final text = _collectAllText(span);
      expect(text, contains('deleted'));
    });

    test('<em>text</em> produces italic', () {
      final span = builder.build('<em>emphasis</em>', baseStyle, theme);
      expect(
        _anySpanHasProperty(span, (s) => s?.fontStyle == FontStyle.italic),
        isTrue,
        reason: '<em> should produce italic',
      );
      final text = _collectAllText(span);
      expect(text, contains('emphasis'));
    });

    test('<strong>text</strong> produces bold', () {
      final span = builder.build('<strong>bold</strong>', baseStyle, theme);
      expect(
        _anySpanHasProperty(span, (s) => s?.fontWeight == FontWeight.bold),
        isTrue,
        reason: '<strong> should produce bold',
      );
      final text = _collectAllText(span);
      expect(text, contains('bold'));
    });

    test('<code>text</code> produces monospace', () {
      final span = builder.build('<code>snippet</code>', baseStyle, theme);
      expect(
        _anySpanHasProperty(span, (s) => s?.fontFamily == 'monospace'),
        isTrue,
        reason: '<code> should produce monospace',
      );
      final text = _collectAllText(span);
      expect(text, contains('snippet'));
    });
  });

  // ── Line breaks ─────────────────────────────────────────────────

  group('line breaks', () {
    test('hard line break: two trailing spaces + newline', () {
      final span = builder.build('text  \nnext', baseStyle, theme);
      final text = _collectAllText(span);
      expect(text, contains('\n'));
    });

    test('soft line break: plain newline becomes space', () {
      final span = builder.build('text\nnext', baseStyle, theme);
      final text = _collectAllText(span);
      expect(text, contains(' '));
      expect(text.contains('\n'), isFalse);
    });
  });

  // ── Nested formatting ───────────────────────────────────────────

  group('nested formatting', () {
    test('**bold *italic* bold** produces nested spans', () {
      final span = builder.build('**bold *italic* bold**', baseStyle, theme);
      expect(
        _anySpanHasProperty(span, (s) => s?.fontWeight == FontWeight.bold),
        isTrue,
        reason: 'Should have bold',
      );
      expect(
        _anySpanHasProperty(span, (s) => s?.fontStyle == FontStyle.italic),
        isTrue,
        reason: 'Should have italic nested in bold',
      );
    });
  });

  // ── Unclosed markers ───────────────────────────────────────────

  group('unclosed markers', () {
    test('**no close renders as plain text', () {
      final span = builder.build('**no close', baseStyle, theme);
      expect(
        _anySpanHasProperty(span, (s) => s?.fontWeight == FontWeight.bold),
        isFalse,
        reason: 'Unclosed bold markers should be treated as plain text',
      );
    });

    test('*no close renders as plain text', () {
      final span = builder.build('*no close', baseStyle, theme);
      expect(
        _anySpanHasProperty(span, (s) => s?.fontStyle == FontStyle.italic),
        isFalse,
        reason: 'Unclosed italic markers should be treated as plain text',
      );
    });

    test('~~no close renders as plain text', () {
      final span = builder.build('~~no close', baseStyle, theme);
      expect(
        _anySpanHasDecoration(span, TextDecoration.lineThrough),
        isFalse,
        reason: 'Unclosed strikethrough should be treated as plain text',
      );
    });
  });

  // ── Empty content ───────────────────────────────────────────────

  group('empty content', () {
    test('**** does not crash', () {
      final span = builder.build('****', baseStyle, theme);
      expect(span, isNotNull);
    });

    test('**** does not produce bold span', () {
      final span = builder.build('****', baseStyle, theme);
      expect(
        _anySpanHasProperty(span, (s) => s?.fontWeight == FontWeight.bold),
        isFalse,
        reason: 'Empty bold content should not produce bold span',
      );
    });

    test('empty inline code `` does not crash', () {
      final span = builder.build('``', baseStyle, theme);
      expect(span, isNotNull);
    });

    test('empty italic ** does not crash', () {
      final span = builder.build('', baseStyle, theme);
      expect(span.children!, isEmpty);
    });
  });

  // ── dispose() ───────────────────────────────────────────────────

  group('dispose', () {
    test('dispose properly clears recognizers after building links', () {
      builder.build(
        '[link1](https://a.com) [link2](https://b.com)',
        baseStyle,
        theme,
        onLinkTapped: (_) {},
      );
      builder.dispose();
      final builder2 = InlineSpanBuilder();
      builder2.build(
        '[link](https://c.com)',
        baseStyle,
        theme,
        onLinkTapped: (_) {},
      );
      builder2.dispose();
    });

    test('TapGestureRecognizer memory: after dispose(), building fresh does not accumulate', () {
      for (var i = 0; i < 10; i++) {
        builder.build(
          '[link](https://example.com/$i)',
          baseStyle,
          theme,
          onLinkTapped: (_) {},
        );
        builder.dispose();
      }
    });

    test('dispose without any links does not crash', () {
      final emptyBuilder = InlineSpanBuilder();
      emptyBuilder.build('just text', baseStyle, theme);
      emptyBuilder.dispose();
    });

    test('multiple dispose calls do not crash', () {
      builder.build('[l](https://a.com)', baseStyle, theme, onLinkTapped: (_) {});
      builder.dispose();
      builder.dispose();
    });
  });

  // ── Mixed content ───────────────────────────────────────────────

  group('mixed content', () {
    test('bold, italic, and code in one line', () {
      final span = builder.build(
        '**bold** *italic* `code`',
        baseStyle,
        theme,
      );
      expect(
        _anySpanHasProperty(span, (s) => s?.fontWeight == FontWeight.bold),
        isTrue,
      );
      expect(
        _anySpanHasProperty(span, (s) => s?.fontStyle == FontStyle.italic),
        isTrue,
      );
      expect(
        _anySpanHasProperty(span, (s) => s?.fontFamily == 'monospace'),
        isTrue,
      );
    });

    test('text before and after formatting is preserved', () {
      final span = builder.build(
        'before **bold** after',
        baseStyle,
        theme,
      );
      final text = _collectAllText(span);
      expect(text, contains('before'));
      expect(text, contains('bold'));
      expect(text, contains('after'));
    });
  });
}

// ── Helper functions ──────────────────────────────────────────────

/// Recursively checks if any TextSpan in the tree satisfies [test].
bool _anySpanHasProperty(TextSpan span, bool Function(TextStyle? s) test) {
  if (test(span.style)) return true;
  if (span.children != null) {
    for (final child in span.children!) {
      if (child is TextSpan && _anySpanHasProperty(child, test)) return true;
    }
  }
  return false;
}

/// Recursively checks if any TextSpan has a specific [decoration].
bool _anySpanHasDecoration(TextSpan span, TextDecoration decoration) {
  if (span.style?.decoration == decoration) return true;
  if (span.style?.decoration != null &&
      span.style!.decoration!.contains(decoration)) {
    return true;
  }
  if (span.children != null) {
    for (final child in span.children!) {
      if (child is TextSpan && _anySpanHasDecoration(child, decoration)) {
        return true;
      }
    }
  }
  return false;
}

/// Finds the first TextSpan with a recognizer in the tree.
TextSpan? _findSpanWithRecognizer(TextSpan span) {
  if (span.recognizer != null) return span;
  if (span.children != null) {
    for (final child in span.children!) {
      if (child is TextSpan) {
        final found = _findSpanWithRecognizer(child);
        if (found != null) return found;
      }
    }
  }
  return null;
}

/// Collects all text content from a TextSpan tree.
String _collectAllText(TextSpan span) {
  final buffer = StringBuffer();
  void collect(TextSpan s) {
    if (s.text != null) buffer.write(s.text);
    if (s.children != null) {
      for (final child in s.children!) {
        if (child is TextSpan) collect(child);
      }
    }
  }
  collect(span);
  return buffer.toString();
}

/// Collects text content from spans that have a specific fontFamily.
String _collectTextWithFontFamily(TextSpan span, String fontFamily) {
  final buffer = StringBuffer();
  void collect(TextSpan s) {
    if (s.text != null && s.style?.fontFamily == fontFamily) {
      buffer.write(s.text);
    }
    if (s.children != null) {
      for (final child in s.children!) {
        if (child is TextSpan) collect(child);
      }
    }
  }
  collect(span);
  return buffer.toString();
}