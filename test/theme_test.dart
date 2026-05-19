import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_markdown_renderer/stream_markdown_renderer.dart';

void main() {
  // ── MarkdownTheme ──────────────────────────────────────────────────────

  group('MarkdownTheme', () {
    test('light() creates theme with defaults', () {
      final theme = MarkdownTheme.light();

      expect(theme.textStyle, isNotNull);
      expect(theme.textStyle!.fontSize, 16);
      expect(theme.textStyle!.color, const Color(0xFF1F2937));
      expect(theme.textStyle!.height, 1.6);

      expect(theme.linkStyle, isNotNull);
      expect(theme.linkStyle!.color, const Color(0xFF2563EB));
      expect(theme.linkStyle!.decoration, TextDecoration.underline);

      // ignore: deprecated_member_use_from_same_package
      expect(theme.linkColor, const Color(0xFF2563EB));

      expect(theme.inlineCodeStyle, isNotNull);
      expect(theme.inlineCodeStyle!.fontFamily, 'monospace');
      expect(theme.inlineCodeStyle!.fontSize, 14);
      expect(theme.inlineCodeStyle!.color, const Color(0xFFE11D48));

      expect(theme.boldStyle, isNotNull);
      expect(theme.boldStyle!.fontWeight, FontWeight.bold);

      expect(theme.italicStyle, isNotNull);
      expect(theme.italicStyle!.fontStyle, FontStyle.italic);

      expect(theme.strikethroughStyle, isNotNull);
      expect(theme.strikethroughStyle!.decoration, TextDecoration.lineThrough);

      expect(theme.headerTheme, isNotNull);
      expect(theme.codeTheme, isNotNull);
      expect(theme.blockquoteTheme, isNotNull);
      expect(theme.tableTheme, isNotNull);
      expect(theme.listTheme, isNotNull);
      expect(theme.horizontalRuleTheme, isNotNull);

      expect(theme.blockSpacing, 16);
    });

    test('dark() creates theme with dark colors', () {
      final theme = MarkdownTheme.dark();

      expect(theme.textStyle, isNotNull);
      expect(theme.textStyle!.fontSize, 16);
      expect(theme.textStyle!.color, const Color(0xFFF3F4F6));

      expect(theme.linkStyle, isNotNull);
      expect(theme.linkStyle!.color, const Color(0xFF60A5FA));

      // ignore: deprecated_member_use_from_same_package
      expect(theme.linkColor, const Color(0xFF60A5FA));

      expect(theme.inlineCodeStyle!.color, const Color(0xFFF472B6));
      expect(theme.inlineCodeStyle!.backgroundColor, const Color(0xFF374151));

      expect(theme.headerTheme, isNotNull);
      expect(theme.codeTheme, isNotNull);
    });

    test('withDefaults() fills in missing values from light theme', () {
      const partialTheme = MarkdownTheme(
        textStyle: TextStyle(fontSize: 20),
        boldStyle: TextStyle(fontWeight: FontWeight.w900),
      );

      final filled = partialTheme.withDefaults();

      // Provided values should be preserved.
      expect(filled.textStyle!.fontSize, 20);
      expect(filled.boldStyle!.fontWeight, FontWeight.w900);

      // Missing values should be filled from the default light theme.
      expect(filled.linkStyle, isNotNull);
      expect(filled.linkStyle!.color, const Color(0xFF2563EB));
      expect(filled.inlineCodeStyle, isNotNull);
      expect(filled.headerTheme, isNotNull);
      expect(filled.codeTheme, isNotNull);
      expect(filled.blockquoteTheme, isNotNull);
      expect(filled.tableTheme, isNotNull);
      expect(filled.listTheme, isNotNull);
      expect(filled.horizontalRuleTheme, isNotNull);
      expect(filled.blockSpacing, 16);
    });

    test('copyWith creates modified copy', () {
      final base = MarkdownTheme.light();
      final modified = base.copyWith(
        blockSpacing: 24,
        textStyle: const TextStyle(fontSize: 18),
      );

      expect(modified.blockSpacing, 24);
      expect(modified.textStyle!.fontSize, 18);
    });

    test('copyWith preserves unspecified fields', () {
      final base = MarkdownTheme.light();
      final modified = base.copyWith(blockSpacing: 32);

      expect(modified.textStyle, base.textStyle);
      expect(modified.linkStyle, base.linkStyle);
      expect(modified.inlineCodeStyle, base.inlineCodeStyle);
      expect(modified.boldStyle, base.boldStyle);
      expect(modified.italicStyle, base.italicStyle);
      expect(modified.strikethroughStyle, base.strikethroughStyle);
      expect(modified.headerTheme, base.headerTheme);
      expect(modified.codeTheme, base.codeTheme);
      expect(modified.blockSpacing, 32); // only changed field
    });

    test('operator == returns true for identical themes', () {
      final a = MarkdownTheme.light();
      final b = MarkdownTheme.light();
      expect(a == b, isTrue);
    });

    test('operator == returns false for different themes', () {
      final a = MarkdownTheme.light();
      final b = MarkdownTheme.dark();
      expect(a == b, isFalse);
    });

    test('hashCode consistency (same theme same hash)', () {
      final a = MarkdownTheme.light();
      final b = MarkdownTheme.light();
      expect(a.hashCode, b.hashCode);

      final c = MarkdownTheme.dark();
      // Different themes should (very likely) have different hash codes.
      // We can't guarantee non-collision but for these distinct objects it holds.
      expect(a.hashCode == c.hashCode, isFalse);
    });
  });

  // ── HeaderTheme ───────────────────────────────────────────────────────

  group('HeaderTheme', () {
    test('getStyleForLevel(1) returns appropriate style', () {
      const theme = HeaderTheme();
      final style = theme.getStyleForLevel(1);
      expect(style.fontSize, 32);
      expect(style.fontWeight, FontWeight.bold);
      expect(style.color, const Color(0xFF111827));
    });

    test('getStyleForLevel(2) returns appropriate style', () {
      const theme = HeaderTheme();
      final style = theme.getStyleForLevel(2);
      expect(style.fontSize, 28);
      expect(style.fontWeight, FontWeight.bold);
    });

    test('getStyleForLevel(3) returns appropriate style', () {
      const theme = HeaderTheme();
      final style = theme.getStyleForLevel(3);
      expect(style.fontSize, 24);
      expect(style.fontWeight, FontWeight.w600);
    });

    test('getStyleForLevel(4) returns appropriate style', () {
      const theme = HeaderTheme();
      final style = theme.getStyleForLevel(4);
      expect(style.fontSize, 20);
      expect(style.fontWeight, FontWeight.w600);
    });

    test('getStyleForLevel(5) returns appropriate style', () {
      const theme = HeaderTheme();
      final style = theme.getStyleForLevel(5);
      expect(style.fontSize, 18);
      expect(style.fontWeight, FontWeight.w500);
    });

    test('getStyleForLevel(6) returns appropriate style', () {
      const theme = HeaderTheme();
      final style = theme.getStyleForLevel(6);
      expect(style.fontSize, 16);
      expect(style.fontWeight, FontWeight.w500);
    });

    test('getStyleForLevel falls back to H1 for out-of-range levels', () {
      const theme = HeaderTheme();
      final h1Style = theme.getStyleForLevel(1);
      final outOfRangeStyle = theme.getStyleForLevel(0);
      expect(outOfRangeStyle.fontSize, h1Style.fontSize);
      expect(outOfRangeStyle.fontWeight, h1Style.fontWeight);
      expect(outOfRangeStyle.color, h1Style.color);
    });

    test('getStyleForLevel uses custom styles when provided', () {
      const theme = HeaderTheme(
        h1Style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900),
      );
      final style = theme.getStyleForLevel(1);
      expect(style.fontSize, 40);
      expect(style.fontWeight, FontWeight.w900);
    });

    test('dark() factory creates dark colors', () {
      final dark = HeaderTheme.dark();
      dark.getStyleForLevel(1);
      // Verify dark theme produces light-text colors.
      final h1Style = dark.getStyleForLevel(1);
      expect(h1Style.color, const Color(0xFFF9FAFB));

      final h6Style = dark.getStyleForLevel(6);
      expect(h6Style.color, const Color(0xFFD1D5DB));
    });

    test('Default styles exist for all levels', () {
      const theme = HeaderTheme();
      // All 6 levels should produce non-null TextStyle
      for (var level = 1; level <= 6; level++) {
        final style = theme.getStyleForLevel(level);
        expect(style, isNotNull);
        expect(style.fontSize, greaterThan(0));
      }
    });

    test('copyWith works', () {
      const theme = HeaderTheme();
      final modified = theme.copyWith(
        h1Style: const TextStyle(fontSize: 100),
      );
      expect(modified.h1Style!.fontSize, 100);
      // Other levels unchanged
      expect(modified.h2Style, theme.h2Style);
    });

    test('operator == and hashCode', () {
      const a = HeaderTheme();
      const b = HeaderTheme();
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);

      const c = HeaderTheme(h1Style: TextStyle(fontSize: 99));
      expect(a == c, isFalse);
    });
  });

  // ── CodeBlockTheme ─────────────────────────────────────────────────────

  group('CodeBlockTheme', () {
    test('light() factory creates expected defaults', () {
      final light = CodeBlockTheme.light();
      expect(light.backgroundColor, const Color(0xFFF3F4F6));
      expect(light.textStyle, isNotNull);
      expect(light.textStyle!.fontFamily, 'monospace');
      expect(light.textStyle!.fontSize, 14);
      expect(light.borderRadius, 8);
      expect(light.padding, const EdgeInsets.all(16));
      expect(light.syntaxTheme, isNotNull);
      expect(light.copyButtonColor, const Color(0xFF6B7280));
    });

    test('dark() factory creates expected defaults', () {
      final dark = CodeBlockTheme.dark();
      expect(dark.backgroundColor, const Color(0xFF1F2937));
      expect(dark.textStyle, isNotNull);
      expect(dark.textStyle!.color, const Color(0xFFE5E7EB));
      expect(dark.borderRadius, 8);
      expect(dark.syntaxTheme, isNotNull);
      expect(dark.copyButtonColor, const Color(0xFF9CA3AF));
    });

    test('copyWith method works', () {
      final base = CodeBlockTheme.light();
      final modified = base.copyWith(
        backgroundColor: Colors.red,
        borderRadius: 12,
      );
      expect(modified.backgroundColor, Colors.red);
      expect(modified.borderRadius, 12);
      // Unchanged fields preserved
      expect(modified.textStyle, base.textStyle);
      expect(modified.padding, base.padding);
      expect(modified.syntaxTheme, base.syntaxTheme);
    });

    test('operator == and hashCode', () {
      final a = CodeBlockTheme.light();
      final b = CodeBlockTheme.light();
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);

      final c = CodeBlockTheme.dark();
      expect(a == c, isFalse);
    });
  });

  // ── SyntaxTheme ────────────────────────────────────────────────────────

  group('SyntaxTheme', () {
    test('light() factory produces correct colors', () {
      final light = SyntaxTheme.light();

      expect(light.keyword, const Color(0xFFAF00DB));
      expect(light.string, const Color(0xFFA31515));
      expect(light.number, const Color(0xFF098658));
      expect(light.comment, const Color(0xFF008000));
      expect(light.className, const Color(0xFF267F99));
      expect(light.function, const Color(0xFF795E26));
      expect(light.variable, const Color(0xFF001080));
      expect(light.operator, const Color(0xFF000000));
      expect(light.punctuation, const Color(0xFF000000));
      expect(light.annotation, const Color(0xFF808000));
      expect(light.type, const Color(0xFF267F99));
      expect(light.plain, const Color(0xFF001080));
    });

    test('dark() factory produces correct colors', () {
      final dark = SyntaxTheme.dark();

      expect(dark.keyword, const Color(0xFFC586C0));
      expect(dark.string, const Color(0xFFCE9178));
      expect(dark.number, const Color(0xFFB5CEA8));
      expect(dark.comment, const Color(0xFF6A9955));
      expect(dark.className, const Color(0xFF4EC9B0));
      expect(dark.function, const Color(0xFFDCDCAA));
      expect(dark.variable, const Color(0xFF9CDCFE));
      expect(dark.operator, const Color(0xFFD4D4D4));
      expect(dark.punctuation, const Color(0xFFD4D4D4));
      expect(dark.annotation, const Color(0xFFD7BA7D));
      expect(dark.type, const Color(0xFF4EC9B0));
      expect(dark.plain, const Color(0xFF9CDCFE));
    });

    test('Has all required color fields', () {
      final theme = SyntaxTheme.light();
      // Simply confirm that all fields are Color instances (not null).
      expect(theme.keyword, isA<Color>());
      expect(theme.string, isA<Color>());
      expect(theme.number, isA<Color>());
      expect(theme.comment, isA<Color>());
      expect(theme.className, isA<Color>());
      expect(theme.function, isA<Color>());
      expect(theme.variable, isA<Color>());
      expect(theme.operator, isA<Color>());
      expect(theme.punctuation, isA<Color>());
      expect(theme.annotation, isA<Color>());
      expect(theme.type, isA<Color>());
      expect(theme.plain, isA<Color>());
    });

    test('plain field defaults to appropriate colors', () {
      // In light theme, plain should be a dark-ish color for readability.
      expect(SyntaxTheme.light().plain, const Color(0xFF001080));
      // In dark theme, plain should be a light-ish color for readability.
      expect(SyntaxTheme.dark().plain, const Color(0xFF9CDCFE));
    });

    test('operator == and hashCode', () {
      final a = SyntaxTheme.light();
      final b = SyntaxTheme.light();
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);

      final c = SyntaxTheme.dark();
      expect(a == c, isFalse);
    });
  });

  // ── BlockquoteTheme ────────────────────────────────────────────────────

  group('BlockquoteTheme', () {
    test('Default values', () {
      const theme = BlockquoteTheme();
      expect(theme.backgroundColor, isNull);
      expect(theme.borderColor, isNull);
      expect(theme.borderWidth, isNull);
      expect(theme.textStyle, isNull);
      expect(theme.padding, isNull);
    });

    test('dark() factory', () {
      final dark = BlockquoteTheme.dark();
      expect(dark.backgroundColor, const Color(0xFF374151));
      expect(dark.borderColor, const Color(0xFF6B7280));
      expect(dark.borderWidth, 4);
      expect(dark.textStyle, isNotNull);
      expect(dark.textStyle!.fontStyle, FontStyle.italic);
      expect(dark.padding, const EdgeInsets.fromLTRB(16, 12, 12, 12));
    });

    test('copyWith method', () {
      const base = BlockquoteTheme();
      final modified = base.copyWith(
        backgroundColor: Colors.blue,
        borderWidth: 2,
      );
      expect(modified.backgroundColor, Colors.blue);
      expect(modified.borderWidth, 2);
      expect(modified.borderColor, isNull); // unchanged
    });

    test('operator == and hashCode', () {
      const a = BlockquoteTheme();
      const b = BlockquoteTheme();
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);

      final c = BlockquoteTheme.dark();
      expect(a == c, isFalse);
    });
  });

  // ── TableTheme ─────────────────────────────────────────────────────────

  group('TableTheme', () {
    test('Default values', () {
      const theme = TableTheme();
      expect(theme.headerBackgroundColor, isNull);
      expect(theme.headerTextStyle, isNull);
      expect(theme.cellBackgroundColor, isNull);
      expect(theme.cellTextStyle, isNull);
      expect(theme.borderColor, isNull);
      expect(theme.borderWidth, isNull);
      expect(theme.cellPadding, isNull);
    });

    test('dark() factory', () {
      final dark = TableTheme.dark();
      expect(dark.headerBackgroundColor, const Color(0xFF374151));
      expect(dark.headerTextStyle, isNotNull);
      expect(dark.headerTextStyle!.fontWeight, FontWeight.w600);
      expect(dark.headerTextStyle!.color, const Color(0xFFF9FAFB));
      expect(dark.cellBackgroundColor, const Color(0xFF1F2937));
      expect(dark.cellTextStyle, isNotNull);
      expect(dark.borderColor, const Color(0xFF4B5563));
      expect(dark.borderWidth, 1);
      expect(
        dark.cellPadding,
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      );
    });

    test('copyWith method', () {
      const base = TableTheme();
      final modified = base.copyWith(
        headerBackgroundColor: Colors.purple,
        borderWidth: 2,
      );
      expect(modified.headerBackgroundColor, Colors.purple);
      expect(modified.borderWidth, 2);
      expect(modified.cellBackgroundColor, isNull); // unchanged
    });

    test('operator == and hashCode', () {
      const a = TableTheme();
      const b = TableTheme();
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);

      final c = TableTheme.dark();
      expect(a == c, isFalse);
    });
  });

  // ── ListTheme ──────────────────────────────────────────────────────────

  group('ListTheme', () {
    test('Default values', () {
      const theme = ListTheme();
      expect(theme.bulletColor, isNull);
      expect(theme.bulletSize, isNull);
      expect(theme.numberStyle, isNull);
      expect(theme.checkboxCheckedColor, isNull);
      expect(theme.checkboxUncheckedColor, isNull);
      expect(theme.checkboxSize, isNull);
      expect(theme.indentWidth, isNull);
      expect(theme.itemSpacing, isNull);
      expect(theme.textStyle, isNull);
    });

    test('dark() factory', () {
      final dark = ListTheme.dark();
      expect(dark.bulletColor, const Color(0xFF9CA3AF));
      expect(dark.bulletSize, 6);
      expect(dark.checkboxCheckedColor, const Color(0xFF60A5FA));
      expect(dark.checkboxUncheckedColor, const Color(0xFF6B7280));
      expect(dark.checkboxSize, 16);
      expect(dark.indentWidth, 24);
      expect(dark.itemSpacing, 4);
    });

    test('copyWith method', () {
      const base = ListTheme();
      final modified = base.copyWith(
        bulletColor: Colors.orange,
        indentWidth: 32,
      );
      expect(modified.bulletColor, Colors.orange);
      expect(modified.indentWidth, 32);
      expect(modified.bulletSize, isNull); // unchanged
    });

    test('operator == and hashCode', () {
      const a = ListTheme();
      const b = ListTheme();
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);

      final c = ListTheme.dark();
      expect(a == c, isFalse);
    });
  });

  // ── HorizontalRuleTheme ────────────────────────────────────────────────

  group('HorizontalRuleTheme', () {
    test('Default values', () {
      const theme = HorizontalRuleTheme();
      expect(theme.color, isNull);
      expect(theme.thickness, isNull);
      expect(theme.indent, isNull);
      expect(theme.endIndent, isNull);
      expect(theme.style, isNull);
    });

    test('dark() factory', () {
      final dark = HorizontalRuleTheme.dark();
      expect(dark.color, const Color(0xFF4B5563));
      expect(dark.thickness, 1);
      expect(dark.indent, 0);
      expect(dark.endIndent, 0);
      expect(dark.style, HorizontalRuleStyle.solid);
    });

    test('copyWith method', () {
      const base = HorizontalRuleTheme();
      final modified = base.copyWith(
        color: Colors.grey,
        thickness: 2,
        style: HorizontalRuleStyle.dashed,
      );
      expect(modified.color, Colors.grey);
      expect(modified.thickness, 2);
      expect(modified.style, HorizontalRuleStyle.dashed);
      expect(modified.indent, isNull); // unchanged
    });

    test('operator == and hashCode', () {
      const a = HorizontalRuleTheme();
      const b = HorizontalRuleTheme();
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);

      final c = HorizontalRuleTheme.dark();
      expect(a == c, isFalse);
    });

    test('HorizontalRuleStyle enum values', () {
      expect(HorizontalRuleStyle.solid.index, 0);
      expect(HorizontalRuleStyle.dashed.index, 1);
      expect(HorizontalRuleStyle.dotted.index, 2);
    });
  });
}