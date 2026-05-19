import 'package:flutter/material.dart';

@immutable
class MarkdownTheme {
  const MarkdownTheme({
    this.textStyle,
    @Deprecated('Use textStyle.fontFamily instead') this.fontFamily,
    this.linkStyle,
    @Deprecated('Use linkStyle.color instead') this.linkColor,
    this.inlineCodeStyle,
    this.boldStyle,
    this.italicStyle,
    this.strikethroughStyle,
    this.headerTheme,
    this.codeTheme,
    this.blockquoteTheme,
    this.tableTheme,
    this.listTheme,
    this.horizontalRuleTheme,
    this.blockSpacing,
    @Deprecated('Use textStyle.height instead') this.paragraphSpacing,
  });

  /// Creates a default light theme.
  factory MarkdownTheme.light() {
    return MarkdownTheme(
      textStyle: const TextStyle(
        fontSize: 16,
        color: Color(0xFF1F2937),
        height: 1.6,
      ),
      // ignore: deprecated_member_use_from_same_package
      fontFamily: null,
      linkStyle: const TextStyle(
        color: Color(0xFF2563EB),
        decoration: TextDecoration.underline,
      ),
      // ignore: deprecated_member_use_from_same_package
      linkColor: const Color(0xFF2563EB),
      inlineCodeStyle: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 14,
        color: Color(0xFFE11D48),
        backgroundColor: Color(0xFFF3F4F6),
      ),
      boldStyle: const TextStyle(fontWeight: FontWeight.bold),
      italicStyle: const TextStyle(fontStyle: FontStyle.italic),
      strikethroughStyle:
          const TextStyle(decoration: TextDecoration.lineThrough),
      headerTheme: const HeaderTheme(),
      codeTheme: CodeBlockTheme.light(),
      blockquoteTheme: const BlockquoteTheme(),
      tableTheme: const TableTheme(),
      listTheme: const ListTheme(),
      horizontalRuleTheme: const HorizontalRuleTheme(),
      blockSpacing: 16,
      // ignore: deprecated_member_use_from_same_package
      paragraphSpacing: null,
    );
  }

  /// Creates a default dark theme.
  factory MarkdownTheme.dark() {
    return MarkdownTheme(
      textStyle: const TextStyle(
        fontSize: 16,
        color: Color(0xFFF3F4F6),
        height: 1.6,
      ),
      // ignore: deprecated_member_use_from_same_package
      fontFamily: null,
      linkStyle: const TextStyle(
        color: Color(0xFF60A5FA),
        decoration: TextDecoration.underline,
      ),
      // ignore: deprecated_member_use_from_same_package
      linkColor: const Color(0xFF60A5FA),
      inlineCodeStyle: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 14,
        color: Color(0xFFF472B6),
        backgroundColor: Color(0xFF374151),
      ),
      boldStyle: const TextStyle(fontWeight: FontWeight.bold),
      italicStyle: const TextStyle(fontStyle: FontStyle.italic),
      strikethroughStyle:
          const TextStyle(decoration: TextDecoration.lineThrough),
      headerTheme: HeaderTheme.dark(),
      codeTheme: CodeBlockTheme.dark(),
      blockquoteTheme: BlockquoteTheme.dark(),
      tableTheme: TableTheme.dark(),
      listTheme: ListTheme.dark(),
      horizontalRuleTheme: HorizontalRuleTheme.dark(),
      blockSpacing: 16,
      // ignore: deprecated_member_use_from_same_package
      paragraphSpacing: null,
    );
  }

  /// Base text style for paragraphs.
  final TextStyle? textStyle;

  /// Default font family for all text (can be overridden per element).
  @Deprecated('Use textStyle.fontFamily instead')
  final String? fontFamily;

  /// Style for links (color, decoration, etc.).
  final TextStyle? linkStyle;

  /// Color for links (legacy, use linkStyle instead).
  @Deprecated('Use linkStyle.color instead')
  final Color? linkColor;

  /// Style for inline code.
  final TextStyle? inlineCodeStyle;

  /// Style for bold text.
  final TextStyle? boldStyle;

  /// Style for italic text.
  final TextStyle? italicStyle;

  /// Style for strikethrough text.
  final TextStyle? strikethroughStyle;

  /// Theme for headers.
  final HeaderTheme? headerTheme;

  /// Theme for code blocks.
  final CodeBlockTheme? codeTheme;

  /// Theme for blockquotes.
  final BlockquoteTheme? blockquoteTheme;

  /// Theme for tables.
  final TableTheme? tableTheme;

  /// Theme for lists.
  final ListTheme? listTheme;

  /// Theme for horizontal rules.
  final HorizontalRuleTheme? horizontalRuleTheme;

  /// Spacing between blocks.
  final double? blockSpacing;

  /// Line spacing within paragraphs.
  @Deprecated('Use textStyle.height instead')
  final double? paragraphSpacing;

  /// Returns this theme with defaults applied.
  MarkdownTheme withDefaults() {
    final defaultTheme = MarkdownTheme.light();
    return MarkdownTheme(
      textStyle: textStyle ?? defaultTheme.textStyle,
      // ignore: deprecated_member_use_from_same_package
      fontFamily: fontFamily ?? defaultTheme.fontFamily,
      linkStyle: linkStyle ?? defaultTheme.linkStyle,
      // ignore: deprecated_member_use_from_same_package
      linkColor: linkColor ?? defaultTheme.linkColor,
      inlineCodeStyle: inlineCodeStyle ?? defaultTheme.inlineCodeStyle,
      boldStyle: boldStyle ?? defaultTheme.boldStyle,
      italicStyle: italicStyle ?? defaultTheme.italicStyle,
      strikethroughStyle: strikethroughStyle ?? defaultTheme.strikethroughStyle,
      headerTheme: headerTheme ?? defaultTheme.headerTheme,
      codeTheme: codeTheme ?? defaultTheme.codeTheme,
      blockquoteTheme: blockquoteTheme ?? defaultTheme.blockquoteTheme,
      tableTheme: tableTheme ?? defaultTheme.tableTheme,
      listTheme: listTheme ?? defaultTheme.listTheme,
      horizontalRuleTheme:
          horizontalRuleTheme ?? defaultTheme.horizontalRuleTheme,
      blockSpacing: blockSpacing ?? defaultTheme.blockSpacing,
      // ignore: deprecated_member_use_from_same_package
      paragraphSpacing: paragraphSpacing ?? defaultTheme.paragraphSpacing,
    );
  }

  /// Creates a copy with modified fields.
  MarkdownTheme copyWith({
    TextStyle? textStyle,
    @Deprecated('Use textStyle.fontFamily instead') String? fontFamily,
    TextStyle? linkStyle,
    @Deprecated('Use linkStyle.color instead') Color? linkColor,
    TextStyle? inlineCodeStyle,
    TextStyle? boldStyle,
    TextStyle? italicStyle,
    TextStyle? strikethroughStyle,
    HeaderTheme? headerTheme,
    CodeBlockTheme? codeTheme,
    BlockquoteTheme? blockquoteTheme,
    TableTheme? tableTheme,
    ListTheme? listTheme,
    HorizontalRuleTheme? horizontalRuleTheme,
    double? blockSpacing,
    @Deprecated('Use textStyle.height instead') double? paragraphSpacing,
  }) {
    return MarkdownTheme(
      textStyle: textStyle ?? this.textStyle,
      // ignore: deprecated_member_use_from_same_package
      fontFamily: fontFamily ?? this.fontFamily,
      linkStyle: linkStyle ?? this.linkStyle,
      // ignore: deprecated_member_use_from_same_package
      linkColor: linkColor ?? this.linkColor,
      inlineCodeStyle: inlineCodeStyle ?? this.inlineCodeStyle,
      boldStyle: boldStyle ?? this.boldStyle,
      italicStyle: italicStyle ?? this.italicStyle,
      strikethroughStyle: strikethroughStyle ?? this.strikethroughStyle,
      headerTheme: headerTheme ?? this.headerTheme,
      codeTheme: codeTheme ?? this.codeTheme,
      blockquoteTheme: blockquoteTheme ?? this.blockquoteTheme,
      tableTheme: tableTheme ?? this.tableTheme,
      listTheme: listTheme ?? this.listTheme,
      horizontalRuleTheme: horizontalRuleTheme ?? this.horizontalRuleTheme,
      blockSpacing: blockSpacing ?? this.blockSpacing,
      // ignore: deprecated_member_use_from_same_package
      paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MarkdownTheme &&
        other.textStyle == textStyle &&
        // ignore: deprecated_member_use_from_same_package
        other.fontFamily == fontFamily &&
        other.linkStyle == linkStyle &&
        // ignore: deprecated_member_use_from_same_package
        other.linkColor == linkColor &&
        other.inlineCodeStyle == inlineCodeStyle &&
        other.boldStyle == boldStyle &&
        other.italicStyle == italicStyle &&
        other.strikethroughStyle == strikethroughStyle &&
        other.headerTheme == headerTheme &&
        other.codeTheme == codeTheme &&
        other.blockquoteTheme == blockquoteTheme &&
        other.tableTheme == tableTheme &&
        other.listTheme == listTheme &&
        other.horizontalRuleTheme == horizontalRuleTheme &&
        other.blockSpacing == blockSpacing &&
        // ignore: deprecated_member_use_from_same_package
        other.paragraphSpacing == paragraphSpacing;
  }

  @override
  int get hashCode => Object.hash(
        textStyle,
        // ignore: deprecated_member_use_from_same_package
        fontFamily,
        linkStyle,
        // ignore: deprecated_member_use_from_same_package
        linkColor,
        inlineCodeStyle,
        boldStyle,
        italicStyle,
        strikethroughStyle,
        headerTheme,
        codeTheme,
        blockquoteTheme,
        tableTheme,
        listTheme,
        horizontalRuleTheme,
        blockSpacing,
        // ignore: deprecated_member_use_from_same_package
        paragraphSpacing,
      );
}

/// Theme for headers (H1-H6).
@immutable
class HeaderTheme {
  /// Creates a new header theme.
  const HeaderTheme({
    this.h1Style,
    this.h2Style,
    this.h3Style,
    this.h4Style,
    this.h5Style,
    this.h6Style,
  });

  /// Creates a dark header theme.
  factory HeaderTheme.dark() {
    return const HeaderTheme(
      h1Style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Color(0xFFF9FAFB),
        height: 1.3,
      ),
      h2Style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Color(0xFFF9FAFB),
        height: 1.3,
      ),
      h3Style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Color(0xFFF3F4F6),
        height: 1.4,
      ),
      h4Style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFFF3F4F6),
        height: 1.4,
      ),
      h5Style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: Color(0xFFE5E7EB),
        height: 1.5,
      ),
      h6Style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFFD1D5DB),
        height: 1.5,
      ),
    );
  }

  /// Style for H1 headers.
  final TextStyle? h1Style;

  /// Style for H2 headers.
  final TextStyle? h2Style;

  /// Style for H3 headers.
  final TextStyle? h3Style;

  /// Style for H4 headers.
  final TextStyle? h4Style;

  /// Style for H5 headers.
  final TextStyle? h5Style;

  /// Style for H6 headers.
  final TextStyle? h6Style;

  /// Gets the style for a given header level.
  TextStyle getStyleForLevel(int level) {
    switch (level) {
      case 1:
        return h1Style ?? _defaultH1;
      case 2:
        return h2Style ?? _defaultH2;
      case 3:
        return h3Style ?? _defaultH3;
      case 4:
        return h4Style ?? _defaultH4;
      case 5:
        return h5Style ?? _defaultH5;
      case 6:
        return h6Style ?? _defaultH6;
      default:
        return h1Style ?? _defaultH1;
    }
  }

  static const _defaultH1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Color(0xFF111827),
    height: 1.3,
  );

  static const _defaultH2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Color(0xFF111827),
    height: 1.3,
  );

  static const _defaultH3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: Color(0xFF1F2937),
    height: 1.4,
  );

  static const _defaultH4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Color(0xFF1F2937),
    height: 1.4,
  );

  static const _defaultH5 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: Color(0xFF374151),
    height: 1.5,
  );

  static const _defaultH6 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Color(0xFF4B5563),
    height: 1.5,
  );

  /// Creates a copy with modified fields.
  HeaderTheme copyWith({
    TextStyle? h1Style,
    TextStyle? h2Style,
    TextStyle? h3Style,
    TextStyle? h4Style,
    TextStyle? h5Style,
    TextStyle? h6Style,
  }) {
    return HeaderTheme(
      h1Style: h1Style ?? this.h1Style,
      h2Style: h2Style ?? this.h2Style,
      h3Style: h3Style ?? this.h3Style,
      h4Style: h4Style ?? this.h4Style,
      h5Style: h5Style ?? this.h5Style,
      h6Style: h6Style ?? this.h6Style,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HeaderTheme &&
        other.h1Style == h1Style &&
        other.h2Style == h2Style &&
        other.h3Style == h3Style &&
        other.h4Style == h4Style &&
        other.h5Style == h5Style &&
        other.h6Style == h6Style;
  }

  @override
  int get hashCode => Object.hash(h1Style, h2Style, h3Style, h4Style, h5Style, h6Style);
}

/// Theme for code blocks.
@immutable
class CodeBlockTheme {
  /// Creates a new code block theme.
  const CodeBlockTheme({
    this.backgroundColor,
    this.textStyle,
    this.borderRadius,
    this.padding,
    this.labelStyle,
    this.copyButtonColor,
    this.syntaxTheme,
  });

  /// Creates a light code block theme.
  factory CodeBlockTheme.light() {
    return CodeBlockTheme(
      backgroundColor: const Color(0xFFF3F4F6),
      textStyle: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 14,
        color: Color(0xFF1F2937),
        height: 1.5,
      ),
      borderRadius: 8,
      padding: const EdgeInsets.all(16),
      labelStyle: const TextStyle(
        fontSize: 12,
        color: Color(0xFF6B7280),
        fontWeight: FontWeight.w500,
      ),
      copyButtonColor: const Color(0xFF6B7280),
      syntaxTheme: SyntaxTheme.light(),
    );
  }

  /// Creates a dark code block theme.
  factory CodeBlockTheme.dark() {
    return CodeBlockTheme(
      backgroundColor: const Color(0xFF1F2937),
      textStyle: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 14,
        color: Color(0xFFE5E7EB),
        height: 1.5,
      ),
      borderRadius: 8,
      padding: const EdgeInsets.all(16),
      labelStyle: const TextStyle(
        fontSize: 12,
        color: Color(0xFF9CA3AF),
        fontWeight: FontWeight.w500,
      ),
      copyButtonColor: const Color(0xFF9CA3AF),
      syntaxTheme: SyntaxTheme.dark(),
    );
  }

  /// Background color of the code block.
  final Color? backgroundColor;

  /// Text style for code.
  final TextStyle? textStyle;

  /// Border radius of the code block.
  final double? borderRadius;

  /// Padding inside the code block.
  final EdgeInsets? padding;

  /// Style for the language label.
  final TextStyle? labelStyle;

  /// Color for the copy button.
  final Color? copyButtonColor;

  /// Syntax highlighting theme.
  final SyntaxTheme? syntaxTheme;

  /// Creates a copy with modified fields.
  CodeBlockTheme copyWith({
    Color? backgroundColor,
    TextStyle? textStyle,
    double? borderRadius,
    EdgeInsets? padding,
    TextStyle? labelStyle,
    Color? copyButtonColor,
    SyntaxTheme? syntaxTheme,
  }) {
    return CodeBlockTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textStyle: textStyle ?? this.textStyle,
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
      labelStyle: labelStyle ?? this.labelStyle,
      copyButtonColor: copyButtonColor ?? this.copyButtonColor,
      syntaxTheme: syntaxTheme ?? this.syntaxTheme,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CodeBlockTheme &&
        other.backgroundColor == backgroundColor &&
        other.textStyle == textStyle &&
        other.borderRadius == borderRadius &&
        other.padding == padding &&
        other.labelStyle == labelStyle &&
        other.copyButtonColor == copyButtonColor &&
        other.syntaxTheme == syntaxTheme;
  }

  @override
  int get hashCode => Object.hash(
        backgroundColor,
        textStyle,
        borderRadius,
        padding,
        labelStyle,
        copyButtonColor,
        syntaxTheme,
      );
}

/// Syntax highlighting color theme.
@immutable
class SyntaxTheme {
  /// Creates a new syntax theme.
  const SyntaxTheme({
    required this.keyword,
    required this.string,
    required this.number,
    required this.comment,
    required this.className,
    required this.function,
    required this.variable,
    required this.operator,
    required this.punctuation,
    required this.annotation,
    required this.type,
    required this.plain,
  });

  /// Creates a light syntax theme.
  factory SyntaxTheme.light() {
    return const SyntaxTheme(
      keyword: Color(0xFFAF00DB),
      string: Color(0xFFA31515),
      number: Color(0xFF098658),
      comment: Color(0xFF008000),
      className: Color(0xFF267F99),
      function: Color(0xFF795E26),
      variable: Color(0xFF001080),
      operator: Color(0xFF000000),
      punctuation: Color(0xFF000000),
      annotation: Color(0xFF808000),
      type: Color(0xFF267F99),
      plain: Color(0xFF001080),
    );
  }

  /// Creates a dark syntax theme.
  factory SyntaxTheme.dark() {
    return const SyntaxTheme(
      keyword: Color(0xFFC586C0),
      string: Color(0xFFCE9178),
      number: Color(0xFFB5CEA8),
      comment: Color(0xFF6A9955),
      className: Color(0xFF4EC9B0),
      function: Color(0xFFDCDCAA),
      variable: Color(0xFF9CDCFE),
      operator: Color(0xFFD4D4D4),
      punctuation: Color(0xFFD4D4D4),
      annotation: Color(0xFFD7BA7D),
      type: Color(0xFF4EC9B0),
      plain: Color(0xFF9CDCFE),
    );
  }

  /// Color for keywords (if, else, return, etc.).
  final Color keyword;

  /// Color for strings.
  final Color string;

  /// Color for numbers.
  final Color number;

  /// Color for comments.
  final Color comment;

  /// Color for class names.
  final Color className;

  /// Color for function names.
  final Color function;

  /// Color for variables.
  final Color variable;

  /// Color for operators.
  final Color operator;

  /// Color for punctuation.
  final Color punctuation;

  /// Color for annotations/decorators.
  final Color annotation;

  /// Color for types.
  final Color type;

  /// Color for plain text.
  final Color plain;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyntaxTheme &&
        other.keyword == keyword &&
        other.string == string &&
        other.number == number &&
        other.comment == comment &&
        other.className == className &&
        other.function == function &&
        other.variable == variable &&
        other.operator == operator &&
        other.punctuation == punctuation &&
        other.annotation == annotation &&
        other.type == type &&
        other.plain == plain;
  }

  @override
  int get hashCode => Object.hash(
        keyword,
        string,
        number,
        comment,
        className,
        function,
        variable,
        operator,
        punctuation,
        annotation,
        type,
        plain,
      );
}

/// Theme for blockquotes.
@immutable
class BlockquoteTheme {
  /// Creates a new blockquote theme.
  const BlockquoteTheme({
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.textStyle,
    this.padding,
  });

  /// Creates a dark blockquote theme.
  factory BlockquoteTheme.dark() {
    return const BlockquoteTheme(
      backgroundColor: Color(0xFF374151),
      borderColor: Color(0xFF6B7280),
      borderWidth: 4,
      textStyle: TextStyle(
        fontSize: 16,
        color: Color(0xFFD1D5DB),
        fontStyle: FontStyle.italic,
        height: 1.6,
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 12, 12),
    );
  }

  /// Background color of the blockquote.
  final Color? backgroundColor;

  /// Color of the left border.
  final Color? borderColor;

  /// Width of the left border.
  final double? borderWidth;

  /// Text style for the blockquote.
  final TextStyle? textStyle;

  /// Padding inside the blockquote.
  final EdgeInsets? padding;

  /// Creates a copy with modified fields.
  BlockquoteTheme copyWith({
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    TextStyle? textStyle,
    EdgeInsets? padding,
  }) {
    return BlockquoteTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      textStyle: textStyle ?? this.textStyle,
      padding: padding ?? this.padding,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BlockquoteTheme &&
        other.backgroundColor == backgroundColor &&
        other.borderColor == borderColor &&
        other.borderWidth == borderWidth &&
        other.textStyle == textStyle &&
        other.padding == padding;
  }

  @override
  int get hashCode => Object.hash(
        backgroundColor,
        borderColor,
        borderWidth,
        textStyle,
        padding,
      );
}

/// Theme for tables.
@immutable
class TableTheme {
  /// Creates a new table theme.
  const TableTheme({
    this.headerBackgroundColor,
    this.headerTextStyle,
    this.cellBackgroundColor,
    this.cellTextStyle,
    this.borderColor,
    this.borderWidth,
    this.cellPadding,
  });

  /// Creates a dark table theme.
  factory TableTheme.dark() {
    return const TableTheme(
      headerBackgroundColor: Color(0xFF374151),
      headerTextStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFFF9FAFB),
      ),
      cellBackgroundColor: Color(0xFF1F2937),
      cellTextStyle: TextStyle(
        fontSize: 14,
        color: Color(0xFFE5E7EB),
      ),
      borderColor: Color(0xFF4B5563),
      borderWidth: 1,
      cellPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  /// Background color for header cells.
  final Color? headerBackgroundColor;

  /// Text style for header cells.
  final TextStyle? headerTextStyle;

  /// Background color for data cells.
  final Color? cellBackgroundColor;

  /// Text style for data cells.
  final TextStyle? cellTextStyle;

  /// Color of table borders.
  final Color? borderColor;

  /// Width of table borders.
  final double? borderWidth;

  /// Padding inside cells.
  final EdgeInsets? cellPadding;

  /// Creates a copy with modified fields.
  TableTheme copyWith({
    Color? headerBackgroundColor,
    TextStyle? headerTextStyle,
    Color? cellBackgroundColor,
    TextStyle? cellTextStyle,
    Color? borderColor,
    double? borderWidth,
    EdgeInsets? cellPadding,
  }) {
    return TableTheme(
      headerBackgroundColor: headerBackgroundColor ?? this.headerBackgroundColor,
      headerTextStyle: headerTextStyle ?? this.headerTextStyle,
      cellBackgroundColor: cellBackgroundColor ?? this.cellBackgroundColor,
      cellTextStyle: cellTextStyle ?? this.cellTextStyle,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      cellPadding: cellPadding ?? this.cellPadding,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TableTheme &&
        other.headerBackgroundColor == headerBackgroundColor &&
        other.headerTextStyle == headerTextStyle &&
        other.cellBackgroundColor == cellBackgroundColor &&
        other.cellTextStyle == cellTextStyle &&
        other.borderColor == borderColor &&
        other.borderWidth == borderWidth &&
        other.cellPadding == cellPadding;
  }

  @override
  int get hashCode => Object.hash(
        headerBackgroundColor,
        headerTextStyle,
        cellBackgroundColor,
        cellTextStyle,
        borderColor,
        borderWidth,
        cellPadding,
      );
}

/// Theme for lists.
@immutable
class ListTheme {
  /// Creates a new list theme.
  const ListTheme({
    this.bulletColor,
    this.bulletSize,
    this.numberStyle,
    this.checkboxCheckedColor,
    this.checkboxUncheckedColor,
    this.checkboxSize,
    this.indentWidth,
    this.itemSpacing,
    this.textStyle,
  });

  /// Creates a dark list theme.
  factory ListTheme.dark() {
    return const ListTheme(
      bulletColor: Color(0xFF9CA3AF),
      bulletSize: 6,
      checkboxCheckedColor: Color(0xFF60A5FA),
      checkboxUncheckedColor: Color(0xFF6B7280),
      checkboxSize: 16,
      indentWidth: 24,
      itemSpacing: 4,
    );
  }

  /// Color for bullet points.
  final Color? bulletColor;

  /// Size of bullet points.
  final double? bulletSize;

  /// Style for ordered list numbers.
  final TextStyle? numberStyle;

  /// Color for checked checkboxes.
  final Color? checkboxCheckedColor;

  /// Color for unchecked checkboxes.
  final Color? checkboxUncheckedColor;

  /// Size of checkboxes.
  final double? checkboxSize;

  /// Width of each indent level.
  final double? indentWidth;

  /// Spacing between list items.
  final double? itemSpacing;

  /// Text style for list items.
  final TextStyle? textStyle;

  /// Creates a copy with modified fields.
  ListTheme copyWith({
    Color? bulletColor,
    double? bulletSize,
    TextStyle? numberStyle,
    Color? checkboxCheckedColor,
    Color? checkboxUncheckedColor,
    double? checkboxSize,
    double? indentWidth,
    double? itemSpacing,
    TextStyle? textStyle,
  }) {
    return ListTheme(
      bulletColor: bulletColor ?? this.bulletColor,
      bulletSize: bulletSize ?? this.bulletSize,
      numberStyle: numberStyle ?? this.numberStyle,
      checkboxCheckedColor: checkboxCheckedColor ?? this.checkboxCheckedColor,
      checkboxUncheckedColor: checkboxUncheckedColor ?? this.checkboxUncheckedColor,
      checkboxSize: checkboxSize ?? this.checkboxSize,
      indentWidth: indentWidth ?? this.indentWidth,
      itemSpacing: itemSpacing ?? this.itemSpacing,
      textStyle: textStyle ?? this.textStyle,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ListTheme &&
        other.bulletColor == bulletColor &&
        other.bulletSize == bulletSize &&
        other.numberStyle == numberStyle &&
        other.checkboxCheckedColor == checkboxCheckedColor &&
        other.checkboxUncheckedColor == checkboxUncheckedColor &&
        other.checkboxSize == checkboxSize &&
        other.indentWidth == indentWidth &&
        other.itemSpacing == itemSpacing &&
        other.textStyle == textStyle;
  }

  @override
  int get hashCode => Object.hash(
        bulletColor,
        bulletSize,
        numberStyle,
        checkboxCheckedColor,
        checkboxUncheckedColor,
        checkboxSize,
        indentWidth,
        itemSpacing,
        textStyle,
      );
}

/// Theme for horizontal rules (thematic breaks).
@immutable
class HorizontalRuleTheme {
  /// Creates a new horizontal rule theme.
  const HorizontalRuleTheme({
    this.color,
    this.thickness,
    this.indent,
    this.endIndent,
    this.style,
  });

  /// Creates a dark horizontal rule theme.
  factory HorizontalRuleTheme.dark() {
    return const HorizontalRuleTheme(
      color: Color(0xFF4B5563),
      thickness: 1,
      indent: 0,
      endIndent: 0,
      style: HorizontalRuleStyle.solid,
    );
  }

  /// Color of the rule.
  final Color? color;

  /// Thickness of the rule.
  final double? thickness;

  /// Left indent.
  final double? indent;

  /// Right indent.
  final double? endIndent;

  /// Style of the rule (solid, dashed, dotted).
  final HorizontalRuleStyle? style;

  /// Creates a copy with modified fields.
  HorizontalRuleTheme copyWith({
    Color? color,
    double? thickness,
    double? indent,
    double? endIndent,
    HorizontalRuleStyle? style,
  }) {
    return HorizontalRuleTheme(
      color: color ?? this.color,
      thickness: thickness ?? this.thickness,
      indent: indent ?? this.indent,
      endIndent: endIndent ?? this.endIndent,
      style: style ?? this.style,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HorizontalRuleTheme &&
        other.color == color &&
        other.thickness == thickness &&
        other.indent == indent &&
        other.endIndent == endIndent &&
        other.style == style;
  }

  @override
  int get hashCode => Object.hash(
        color,
        thickness,
        indent,
        endIndent,
        style,
      );
}

/// Style for horizontal rules.
enum HorizontalRuleStyle {
  /// Solid line.
  solid,

  /// Dashed line.
  dashed,

  /// Dotted line.
  dotted,
}
