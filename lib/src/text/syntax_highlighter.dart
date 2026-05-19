import 'package:flutter/painting.dart';

import '../theme/markdown_theme.dart';

/// A token in syntax-highlighted code.
class SyntaxToken {
  /// Creates a new syntax token.
  const SyntaxToken(this.text, this.type);

  /// The text content of this token.
  final String text;

  /// The type of this token.
  final SyntaxTokenType type;
}

/// Types of syntax tokens.
enum SyntaxTokenType {
  plain,
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
}

/// A syntax highlighter for code blocks.
class SyntaxHighlighter {
  /// Creates a new syntax highlighter.
  const SyntaxHighlighter();

  /// Highlights the given code and returns TextSpans.
  List<TextSpan> highlight(
    String code,
    String language,
    SyntaxTheme theme,
    TextStyle baseStyle,
  ) {
    final tokens = tokenize(code, language);
    return tokens.map((token) {
      final color = _getColorForType(token.type, theme);
      return TextSpan(
        text: token.text,
        style: baseStyle.copyWith(color: color),
      );
    }).toList();
  }

  /// Tokenizes code into syntax tokens.
  List<SyntaxToken> tokenize(String code, String language) {
    final normalizedLanguage = language.toLowerCase();

    switch (normalizedLanguage) {
      case 'dart':
        return _tokenize(
          code,
          _dartKeywords,
          _dartTypes,
          '//',
          '/*',
          '*/',
          true,
        );
      case 'javascript':
      case 'js':
        return _tokenize(code, _jsKeywords, _jsTypes, '//', '/*', '*/');
      case 'typescript':
      case 'ts':
        return _tokenize(
          code,
          {..._jsKeywords, ..._tsKeywords},
          {..._jsTypes, ..._tsTypes},
          '//',
          '/*',
          '*/',
          true,
        );
      case 'python':
      case 'py':
        return _tokenize(
          code,
          _pythonKeywords,
          _pythonTypes,
          '#',
          null,
          null,
          true,
        );
      case 'java':
        return _tokenize(
          code,
          _javaKeywords,
          _javaTypes,
          '//',
          '/*',
          '*/',
          true,
        );
      case 'c':
        return _tokenize(code, _cKeywords, _cTypes, '//', '/*', '*/');
      case 'cpp':
      case 'c++':
        return _tokenize(
          code,
          {..._cKeywords, ..._cppKeywords},
          {..._cTypes, ..._cppTypes},
          '//',
          '/*',
          '*/',
        );
      case 'rust':
      case 'rs':
        return _tokenize(
          code,
          _rustKeywords,
          _rustTypes,
          '//',
          '/*',
          '*/',
          true,
          '#',
        );
      case 'go':
        return _tokenize(code, _goKeywords, _goTypes, '//', '/*', '*/');
      case 'swift':
        return _tokenize(
          code,
          _swiftKeywords,
          _swiftTypes,
          '//',
          '/*',
          '*/',
          true,
        );
      case 'kotlin':
      case 'kt':
        return _tokenize(
          code,
          _kotlinKeywords,
          _kotlinTypes,
          '//',
          '/*',
          '*/',
          true,
        );
      case 'ruby':
      case 'rb':
        return _tokenize(code, _rubyKeywords, <String>{}, '#');
      case 'php':
        return _tokenize(code, _phpKeywords, _phpTypes, '//', '/*', '*/');
      case 'sql':
        return _tokenize(code, _sqlKeywords, _sqlTypes, '--', '/*', '*/');
      case 'json':
        return _tokenizeJson(code);
      case 'yaml':
      case 'yml':
        return _tokenizeYaml(code);
      case 'bash':
      case 'sh':
      case 'shell':
        return _tokenize(code, _bashKeywords, <String>{}, '#');
      case 'html':
      case 'xml':
        return _tokenizeHtml(code);
      case 'css':
        return _tokenizeCss(code);
      default:
        return [SyntaxToken(code, SyntaxTokenType.plain)];
    }
  }

  Color _getColorForType(SyntaxTokenType type, SyntaxTheme theme) {
    switch (type) {
      case SyntaxTokenType.plain:
        return theme.plain;
      case SyntaxTokenType.keyword:
        return theme.keyword;
      case SyntaxTokenType.string:
        return theme.string;
      case SyntaxTokenType.number:
        return theme.number;
      case SyntaxTokenType.comment:
        return theme.comment;
      case SyntaxTokenType.className:
        return theme.className;
      case SyntaxTokenType.function:
        return theme.function;
      case SyntaxTokenType.variable:
        return theme.variable;
      case SyntaxTokenType.operator:
        return theme.operator;
      case SyntaxTokenType.punctuation:
        return theme.punctuation;
      case SyntaxTokenType.annotation:
        return theme.annotation;
      case SyntaxTokenType.type:
        return theme.type;
    }
  }

  List<SyntaxToken> _tokenize(
    String code,
    Set<String> keywords,
    Set<String> types, [
    String? singleLineComment,
    String? multiLineCommentStart,
    String? multiLineCommentEnd,
    bool hasAnnotations = false,
    String annotationPrefix = '@',
  ]) {
    final tokens = <SyntaxToken>[];
    var i = 0;

    while (i < code.length) {
      // Whitespace
      if (_isWhitespace(code[i])) {
        final start = i;
        while (i < code.length && _isWhitespace(code[i])) {
          i++;
        }
        tokens
            .add(SyntaxToken(code.substring(start, i), SyntaxTokenType.plain));
        continue;
      }

      // Single-line comment
      if (singleLineComment != null &&
          code.startsWith(singleLineComment, i)) {
        final start = i;
        while (i < code.length && code[i] != '\n') {
          i++;
        }
        tokens.add(
          SyntaxToken(code.substring(start, i), SyntaxTokenType.comment),
        );
        continue;
      }

      // Multi-line comment
      if (multiLineCommentStart != null &&
          code.startsWith(multiLineCommentStart, i)) {
        final start = i;
        i += multiLineCommentStart.length;
        while (i < code.length &&
            !(multiLineCommentEnd != null && code.startsWith(multiLineCommentEnd, i))) {
          i++;
        }
        if (multiLineCommentEnd != null && i < code.length) {
          i += multiLineCommentEnd.length;
        }
        tokens.add(
          SyntaxToken(code.substring(start, i), SyntaxTokenType.comment),
        );
        continue;
      }

      // Annotation
      if (hasAnnotations && code[i] == annotationPrefix) {
        final start = i;
        i++;
        while (i < code.length && _isWordChar(code[i])) {
          i++;
        }
        tokens.add(
          SyntaxToken(code.substring(start, i), SyntaxTokenType.annotation),
        );
        continue;
      }

      // String (double quote)
      if (code[i] == '"') {
        final start = i;
        i++;
        while (i < code.length && code[i] != '"') {
          if (code[i] == r'\' && i + 1 < code.length) {
            i += 2;
          } else {
            i++;
          }
        }
        if (i < code.length) i++;
        tokens
            .add(SyntaxToken(code.substring(start, i), SyntaxTokenType.string));
        continue;
      }

      // String (single quote)
      if (code[i] == "'") {
        final start = i;
        i++;
        while (i < code.length && code[i] != "'") {
          if (code[i] == r'\' && i + 1 < code.length) {
            i += 2;
          } else {
            i++;
          }
        }
        if (i < code.length) i++;
        tokens
            .add(SyntaxToken(code.substring(start, i), SyntaxTokenType.string));
        continue;
      }

      // Number
      if (_isDigit(code[i]) ||
          (code[i] == '.' && i + 1 < code.length && _isDigit(code[i + 1]))) {
        final start = i;
        while (i < code.length && _isNumberChar(code[i])) {
          i++;
        }
        tokens
            .add(SyntaxToken(code.substring(start, i), SyntaxTokenType.number));
        continue;
      }

      // Identifier
      if (_isIdentifierStart(code[i])) {
        final start = i;
        while (i < code.length && _isIdentifierChar(code[i])) {
          i++;
        }
        final word = code.substring(start, i);

        SyntaxTokenType type;
        if (keywords.contains(word)) {
          type = SyntaxTokenType.keyword;
        } else if (types.contains(word)) {
          type = SyntaxTokenType.type;
        } else if (i < code.length && code[i] == '(') {
          type = SyntaxTokenType.function;
        } else if (_isClassName(word)) {
          type = SyntaxTokenType.className;
        } else {
          type = SyntaxTokenType.plain;
        }

        tokens.add(SyntaxToken(word, type));
        continue;
      }

      // Operator or punctuation
      final char = code[i];
      if (_isOperator(char)) {
        tokens.add(SyntaxToken(char, SyntaxTokenType.operator));
      } else if (_isPunctuation(char)) {
        tokens.add(SyntaxToken(char, SyntaxTokenType.punctuation));
      } else {
        tokens.add(SyntaxToken(char, SyntaxTokenType.plain));
      }
      i++;
    }

    return tokens;
  }

  List<SyntaxToken> _tokenizeJson(String code) {
    final tokens = <SyntaxToken>[];
    var i = 0;

    while (i < code.length) {
      if (_isWhitespace(code[i])) {
        final start = i;
        while (i < code.length && _isWhitespace(code[i])) {
          i++;
        }
        tokens
            .add(SyntaxToken(code.substring(start, i), SyntaxTokenType.plain));
        continue;
      }

      if (code[i] == '"') {
        final start = i;
        i++;
        while (i < code.length && code[i] != '"') {
          if (code[i] == r'\' && i + 1 < code.length) {
            i += 2;
          } else {
            i++;
          }
        }
        if (i < code.length) i++;

        final str = code.substring(start, i);
        var j = i;
        while (j < code.length && _isWhitespace(code[j])) {
          j++;
        }
        final isKey = j < code.length && code[j] == ':';

        tokens.add(
          SyntaxToken(
            str,
            isKey ? SyntaxTokenType.variable : SyntaxTokenType.string,
          ),
        );
        continue;
      }

      if (_isDigit(code[i]) ||
          (code[i] == '-' &&
              i + 1 < code.length &&
              _isDigit(code[i + 1]) &&
              _isJsonNegativeStart(code, i))) {
        final start = i;
        while (i < code.length && _isJsonNumberChar(code[i])) {
          i++;
        }
        tokens
            .add(SyntaxToken(code.substring(start, i), SyntaxTokenType.number));
        continue;
      }

      if (code.startsWith('true', i) ||
          code.startsWith('false', i) ||
          code.startsWith('null', i)) {
        final word = code.startsWith('true', i)
            ? 'true'
            : code.startsWith('false', i)
                ? 'false'
                : 'null';
        tokens.add(SyntaxToken(word, SyntaxTokenType.keyword));
        i += word.length;
        continue;
      }

      tokens.add(SyntaxToken(code[i], SyntaxTokenType.punctuation));
      i++;
    }

    return tokens;
  }

  List<SyntaxToken> _tokenizeYaml(String code) {
    final tokens = <SyntaxToken>[];
    final lines = code.split('\n');

    for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];
      var i = 0;

      while (i < line.length) {
        if (line[i] == '#') {
          tokens.add(SyntaxToken(line.substring(i), SyntaxTokenType.comment));
          break;
        }

        final keyMatch = _yamlKeyRe.matchAsPrefix(line, i);
        if (keyMatch != null) {
          final key = keyMatch.group(0)!;
          tokens
            ..add(
              SyntaxToken(
                key.substring(0, key.length - 1),
                SyntaxTokenType.variable,
              ),
            )
            ..add(const SyntaxToken(':', SyntaxTokenType.punctuation));
          i += key.length;
          continue;
        }

        if (line[i] == '"' || line[i] == "'") {
          final quote = line[i];
          final start = i;
          i++;
          while (i < line.length && line[i] != quote) {
            i++;
          }
          if (i < line.length) i++;
          tokens.add(
            SyntaxToken(line.substring(start, i), SyntaxTokenType.string),
          );
          continue;
        }

        final wordMatch = _yamlWordRe.matchAsPrefix(line, i);
        if (wordMatch != null) {
          final word = wordMatch.group(0)!;
          SyntaxTokenType type;
          if (word == 'true' || word == 'false' || word == 'null') {
            type = SyntaxTokenType.keyword;
          } else if (_yamlNumberRe.hasMatch(word)) {
            type = SyntaxTokenType.number;
          } else {
            type = SyntaxTokenType.string;
          }
          tokens.add(SyntaxToken(word, type));
          i += word.length;
          continue;
        }

        tokens.add(SyntaxToken(line[i], SyntaxTokenType.plain));
        i++;
      }

      if (lineIndex < lines.length - 1) {
        tokens.add(const SyntaxToken('\n', SyntaxTokenType.plain));
      }
    }

    return tokens;
  }

  List<SyntaxToken> _tokenizeHtml(String code) {
    final tokens = <SyntaxToken>[];
    var i = 0;

    while (i < code.length) {
      if (code.startsWith('<!--', i)) {
        final start = i;
        i += 4;
        while (i < code.length && !code.startsWith('-->', i)) {
          i++;
        }
        if (i < code.length) i += 3;
        tokens.add(
          SyntaxToken(code.substring(start, i), SyntaxTokenType.comment),
        );
        continue;
      }

      if (code[i] == '<') {
        tokens.add(const SyntaxToken('<', SyntaxTokenType.punctuation));
        i++;

        if (i < code.length && code[i] == '/') {
          tokens.add(const SyntaxToken('/', SyntaxTokenType.punctuation));
          i++;
        }

        final start = i;
        while (i < code.length && _isWordChar(code[i])) {
          i++;
        }
        if (i > start) {
          tokens.add(
            SyntaxToken(code.substring(start, i), SyntaxTokenType.keyword),
          );
        }

        while (i < code.length && code[i] != '>') {
          if (_isWhitespace(code[i])) {
            final spaceStart = i;
            while (i < code.length && _isWhitespace(code[i])) {
              i++;
            }
            tokens.add(
              SyntaxToken(
                code.substring(spaceStart, i),
                SyntaxTokenType.plain,
              ),
            );
            continue;
          }

          final attrStart = i;
          while (i < code.length && _isWordChar(code[i])) {
            i++;
          }
          if (i > attrStart) {
            tokens.add(
              SyntaxToken(
                code.substring(attrStart, i),
                SyntaxTokenType.variable,
              ),
            );
          }

          if (i < code.length && code[i] == '=') {
            tokens.add(const SyntaxToken('=', SyntaxTokenType.operator));
            i++;
          }

          if (i < code.length && (code[i] == '"' || code[i] == "'")) {
            final quote = code[i];
            final valStart = i;
            i++;
            while (i < code.length && code[i] != quote) {
              i++;
            }
            if (i < code.length) i++;
            tokens.add(
              SyntaxToken(
                code.substring(valStart, i),
                SyntaxTokenType.string,
              ),
            );
            continue;
          }

          if (i < code.length && code[i] != '>' && code[i] != '/') {
            tokens.add(SyntaxToken(code[i], SyntaxTokenType.plain));
            i++;
          }
        }

        if (i < code.length && code[i] == '/') {
          tokens.add(const SyntaxToken('/', SyntaxTokenType.punctuation));
          i++;
        }

        if (i < code.length && code[i] == '>') {
          tokens.add(const SyntaxToken('>', SyntaxTokenType.punctuation));
          i++;
        }
        continue;
      }

      final start = i;
      while (i < code.length && code[i] != '<') {
        i++;
      }
      if (i > start) {
        tokens
            .add(SyntaxToken(code.substring(start, i), SyntaxTokenType.plain));
      }
    }

    return tokens;
  }

  List<SyntaxToken> _tokenizeCss(String code) {
    final tokens = <SyntaxToken>[];
    var i = 0;

    while (i < code.length) {
      if (code.startsWith('/*', i)) {
        final start = i;
        i += 2;
        while (i < code.length && !code.startsWith('*/', i)) {
          i++;
        }
        if (i < code.length) i += 2;
        tokens.add(
          SyntaxToken(code.substring(start, i), SyntaxTokenType.comment),
        );
        continue;
      }

      if (code[i] == '"' || code[i] == "'") {
        final quote = code[i];
        final start = i;
        i++;
        while (i < code.length && code[i] != quote) {
          i++;
        }
        if (i < code.length) i++;
        tokens
            .add(SyntaxToken(code.substring(start, i), SyntaxTokenType.string));
        continue;
      }

      if (_isCssSelectorStart(code[i])) {
        final start = i;
        while (i < code.length && _isCssSelectorChar(code[i])) {
          i++;
        }
        final word = code.substring(start, i);

        SyntaxTokenType type;
        if (word.startsWith('#') || word.startsWith('.')) {
          type = SyntaxTokenType.className;
        } else if (word.startsWith('@')) {
          type = SyntaxTokenType.keyword;
        } else {
          type = SyntaxTokenType.variable;
        }

        tokens.add(SyntaxToken(word, type));
        continue;
      }

      if (_isDigit(code[i])) {
        final start = i;
        while (i < code.length && _isCssNumberChar(code[i])) {
          i++;
        }
        tokens
            .add(SyntaxToken(code.substring(start, i), SyntaxTokenType.number));
        continue;
      }

      if (_isWhitespace(code[i])) {
        final start = i;
        while (i < code.length && _isWhitespace(code[i])) {
          i++;
        }
        tokens
            .add(SyntaxToken(code.substring(start, i), SyntaxTokenType.plain));
        continue;
      }

      tokens.add(SyntaxToken(code[i], SyntaxTokenType.punctuation));
      i++;
    }

    return tokens;
  }

  // Helper methods using direct character code comparisons for performance
  static final RegExp _classNameOnlyUpperRe = RegExp(r'^[A-Z_]+$');

  // YAML tokenizer patterns
  static final RegExp _yamlKeyRe = RegExp(r'[\w\-]+:');
  static final RegExp _yamlWordRe = RegExp(r'[\w\-.]+');
  static final RegExp _yamlNumberRe = RegExp(r'^-?[0-9.]+$');

  bool _isWhitespace(String char) {
    if (char.length != 1) return false;
    final c = char.codeUnitAt(0);
    return c == 32 || c == 9 || c == 10 || c == 13; // space, tab, newline, carriage return
  }

  bool _isDigit(String char) {
    if (char.length != 1) return false;
    final c = char.codeUnitAt(0);
    return c >= 48 && c <= 57; // '0'-'9'
  }

  bool _isWordChar(String char) {
    if (char.length != 1) return false;
    final c = char.codeUnitAt(0);
    return (c >= 65 && c <= 90) || // 'A'-'Z'
        (c >= 97 && c <= 122) || // 'a'-'z'
        (c >= 48 && c <= 57) || // '0'-'9'
        c == 95 || c == 46; // '_', '.'
  }

  bool _isIdentifierStart(String char) {
    if (char.length != 1) return false;
    final c = char.codeUnitAt(0);
    return (c >= 65 && c <= 90) || // 'A'-'Z'
        (c >= 97 && c <= 122) || // 'a'-'z'
        c == 95 || c == 36; // '_', '$'
  }

  bool _isIdentifierChar(String char) {
    if (char.length != 1) return false;
    final c = char.codeUnitAt(0);
    return (c >= 65 && c <= 90) || // 'A'-'Z'
        (c >= 97 && c <= 122) || // 'a'-'z'
        (c >= 48 && c <= 57) || // '0'-'9'
        c == 95 || c == 36; // '_', '$'
  }

  bool _isNumberChar(String char) {
    if (char.length != 1) return false;
    final c = char.codeUnitAt(0);
    return (c >= 48 && c <= 57) || // '0'-'9'
        (c >= 65 && c <= 70) || // 'A'-'F'
        (c >= 97 && c <= 102) || // 'a'-'f'
        c == 46 || // '.'
        c == 120 || c == 88 || // 'x', 'X'
        c == 101 || c == 69 || // 'e', 'E'
        c == 95; // '_'
  }

  bool _isJsonNumberChar(String char) {
    if (char.length != 1) return false;
    final c = char.codeUnitAt(0);
    return (c >= 48 && c <= 57) || // '0'-'9'
        c == 46 || // '.'
        c == 101 || c == 69 || // 'e', 'E'
        c == 43 || c == 45; // '+', '-'
  }

  bool _isOperator(String char) {
    if (char.length != 1) return false;
    final c = char.codeUnitAt(0);
    return c == 33 || // !
        c == 37 || // %
        c == 38 || // &
        c == 42 || // *
        c == 43 || // +
        c == 45 || // -
        c == 47 || // /
        c == 60 || // <
        c == 61 || // =
        c == 62 || // >
        c == 63 || // ?
        c == 94 || // ^
        c == 124 || // | (pipe)
        c == 126 || // ~
        c == 58; // :
  }

  bool _isPunctuation(String char) {
    if (char.length != 1) return false;
    final c = char.codeUnitAt(0);
    return c == 123 || c == 125 || // { }
        c == 40 || c == 41 || // ( )
        c == 91 || c == 93 || // [ ]
        c == 59 || // ;
        c == 44 || // ,
        c == 46; // .
  }

  bool _isCssSelectorStart(String char) {
    if (char.length != 1) return false;
    final c = char.codeUnitAt(0);
    return (c >= 65 && c <= 90) || // 'A'-'Z'
        (c >= 97 && c <= 122) || // 'a'-'z'
        c == 45 || // '-'
        c == 95 || // '_'
        c == 35 || // '#'
        c == 46 || // '.'
        c == 64; // '@'
  }

  bool _isCssSelectorChar(String char) {
    if (char.length != 1) return false;
    final c = char.codeUnitAt(0);
    return (c >= 65 && c <= 90) || // 'A'-'Z'
        (c >= 97 && c <= 122) || // 'a'-'z'
        (c >= 48 && c <= 57) || // '0'-'9'
        c == 95 || // '_'
        c == 45 || // '-'
        c == 35 || // '#'
        c == 46 || // '.'
        c == 64; // '@'
  }

  bool _isCssNumberChar(String char) {
    if (char.length != 1) return false;
    final c = char.codeUnitAt(0);
    return (c >= 48 && c <= 57) || // '0'-'9'
        c == 46 || // '.'
        c == 37 || // '%'
        (c >= 65 && c <= 90) || // 'A'-'Z'
        (c >= 97 && c <= 122); // 'a'-'z'
  }

  /// Checks if `-` at [index] in JSON [code] is the start of a negative number.
  /// A `-` starts a number value only if the previous non-whitespace char
  /// is `:`, `,`, `[`, or `{` (indicating start of a value).
  bool _isJsonNegativeStart(String code, int index) {
    var j = index - 1;
    while (j >= 0 && _isWhitespace(code[j])) {
      j--;
    }
    if (j < 0) return true;
    final prevChar = code[j];
    return prevChar == ':' || prevChar == ',' || prevChar == '[' || prevChar == '{';
  }

  bool _isClassName(String word) {
    return word.isNotEmpty &&
        word.length > 1 &&
        // word[0] must be an uppercase letter (not _ or $)
        word[0].toUpperCase() == word[0] &&
        word[0].toLowerCase() != word[0] &&
        !_classNameOnlyUpperRe.hasMatch(word);
  }

  // Keyword sets
  static final _dartKeywords = <String>{
    'abstract',
    'as',
    'assert',
    'async',
    'await',
    'base',
    'break',
    'case',
    'catch',
    'class',
    'const',
    'continue',
    'covariant',
    'default',
    'deferred',
    'do',
    'dynamic',
    'else',
    'enum',
    'export',
    'extends',
    'extension',
    'external',
    'factory',
    'false',
    'final',
    'finally',
    'for',
    'Function',
    'get',
    'hide',
    'if',
    'implements',
    'import',
    'in',
    'interface',
    'is',
    'late',
    'library',
    'mixin',
    'new',
    'null',
    'on',
    'operator',
    'part',
    'required',
    'rethrow',
    'return',
    'sealed',
    'set',
    'show',
    'static',
    'super',
    'switch',
    'sync',
    'this',
    'throw',
    'true',
    'try',
    'typedef',
    'var',
    'void',
    'when',
    'while',
    'with',
    'yield',
  };
  static final _dartTypes = <String>{
    'int',
    'double',
    'num',
    'bool',
    'String',
    'List',
    'Map',
    'Set',
    'Future',
    'Stream',
    'Iterable',
    'Object',
    'Null',
    'Never',
    'dynamic',
    'void',
  };
  static final _jsKeywords = <String>{
    'await',
    'break',
    'case',
    'catch',
    'class',
    'const',
    'continue',
    'debugger',
    'default',
    'delete',
    'do',
    'else',
    'enum',
    'export',
    'extends',
    'false',
    'finally',
    'for',
    'function',
    'if',
    'import',
    'in',
    'instanceof',
    'let',
    'new',
    'null',
    'return',
    'static',
    'super',
    'switch',
    'this',
    'throw',
    'true',
    'try',
    'typeof',
    'undefined',
    'var',
    'void',
    'while',
    'with',
    'yield',
    'async',
    'of',
  };
  static final _jsTypes = <String>{
    'Array',
    'Boolean',
    'Date',
    'Error',
    'Function',
    'JSON',
    'Map',
    'Math',
    'Number',
    'Object',
    'Promise',
    'Proxy',
    'RegExp',
    'Set',
    'String',
    'Symbol',
    'WeakMap',
    'WeakSet',
  };
  static final _tsKeywords = <String>{
    'abstract',
    'any',
    'as',
    'asserts',
    'bigint',
    'boolean',
    'declare',
    'get',
    'implements',
    'infer',
    'interface',
    'is',
    'keyof',
    'module',
    'namespace',
    'never',
    'number',
    'object',
    'override',
    'private',
    'protected',
    'public',
    'readonly',
    'set',
    'string',
    'symbol',
    'type',
    'unknown',
  };
  static final _tsTypes = <String>{
    'Partial',
    'Required',
    'Readonly',
    'Record',
    'Pick',
    'Omit',
    'Exclude',
    'Extract',
    'NonNullable',
    'Parameters',
    'ConstructorParameters',
    'ReturnType',
    'InstanceType',
    'ThisParameterType',
    'OmitThisParameter',
    'ThisType',
  };
  static final _pythonKeywords = <String>{
    'False',
    'None',
    'True',
    'and',
    'as',
    'assert',
    'async',
    'await',
    'break',
    'class',
    'continue',
    'def',
    'del',
    'elif',
    'else',
    'except',
    'finally',
    'for',
    'from',
    'global',
    'if',
    'import',
    'in',
    'is',
    'lambda',
    'nonlocal',
    'not',
    'or',
    'pass',
    'raise',
    'return',
    'try',
    'while',
    'with',
    'yield',
    'match',
    'case',
  };
  static final _pythonTypes = <String>{
    'int',
    'float',
    'str',
    'bool',
    'list',
    'dict',
    'tuple',
    'set',
    'frozenset',
    'bytes',
    'bytearray',
    'memoryview',
    'range',
    'complex',
  };
  static final _javaKeywords = <String>{
    'abstract',
    'assert',
    'boolean',
    'break',
    'byte',
    'case',
    'catch',
    'char',
    'class',
    'const',
    'continue',
    'default',
    'do',
    'double',
    'else',
    'enum',
    'extends',
    'final',
    'finally',
    'float',
    'for',
    'goto',
    'if',
    'implements',
    'import',
    'instanceof',
    'int',
    'interface',
    'long',
    'native',
    'new',
    'package',
    'private',
    'protected',
    'public',
    'return',
    'short',
    'static',
    'strictfp',
    'super',
    'switch',
    'synchronized',
    'this',
    'throw',
    'throws',
    'transient',
    'try',
    'void',
    'volatile',
    'while',
    'true',
    'false',
    'null',
    'var',
    'record',
    'sealed',
    'permits',
  };
  static final _javaTypes = <String>{
    'String',
    'Integer',
    'Boolean',
    'Double',
    'Float',
    'Long',
    'Short',
    'Byte',
    'Character',
    'Object',
    'Class',
    'System',
    'Math',
    'StringBuilder',
    'ArrayList',
    'HashMap',
    'HashSet',
    'List',
    'Map',
    'Set',
  };
  static final _cKeywords = <String>{
    'auto',
    'break',
    'case',
    'char',
    'const',
    'continue',
    'default',
    'do',
    'double',
    'else',
    'enum',
    'extern',
    'float',
    'for',
    'goto',
    'if',
    'inline',
    'int',
    'long',
    'register',
    'restrict',
    'return',
    'short',
    'signed',
    'sizeof',
    'static',
    'struct',
    'switch',
    'typedef',
    'union',
    'unsigned',
    'void',
    'volatile',
    'while',
    '_Bool',
    '_Complex',
    '_Imaginary',
  };
  static final _cTypes = <String>{'size_t', 'ptrdiff_t', 'FILE', 'NULL'};
  static final _cppKeywords = <String>{
    'alignas',
    'alignof',
    'and',
    'and_eq',
    'asm',
    'atomic_cancel',
    'atomic_commit',
    'atomic_noexcept',
    'bitand',
    'bitor',
    'bool',
    'catch',
    'char8_t',
    'char16_t',
    'char32_t',
    'class',
    'compl',
    'concept',
    'consteval',
    'constexpr',
    'constinit',
    'const_cast',
    'co_await',
    'co_return',
    'co_yield',
    'decltype',
    'delete',
    'dynamic_cast',
    'explicit',
    'export',
    'false',
    'friend',
    'mutable',
    'namespace',
    'new',
    'noexcept',
    'not',
    'not_eq',
    'nullptr',
    'operator',
    'or',
    'or_eq',
    'private',
    'protected',
    'public',
    'reflexpr',
    'reinterpret_cast',
    'requires',
    'static_assert',
    'static_cast',
    'synchronized',
    'template',
    'this',
    'thread_local',
    'throw',
    'true',
    'try',
    'typeid',
    'typename',
    'using',
    'virtual',
    'wchar_t',
    'xor',
    'xor_eq',
    'override',
    'final',
  };
  static final _cppTypes = <String>{
    'string',
    'vector',
    'map',
    'set',
    'array',
    'deque',
    'list',
    'forward_list',
    'stack',
    'queue',
    'priority_queue',
    'pair',
    'tuple',
    'unique_ptr',
    'shared_ptr',
    'weak_ptr',
    'optional',
    'variant',
    'any',
  };
  static final _rustKeywords = <String>{
    'as',
    'async',
    'await',
    'break',
    'const',
    'continue',
    'crate',
    'dyn',
    'else',
    'enum',
    'extern',
    'false',
    'fn',
    'for',
    'if',
    'impl',
    'in',
    'let',
    'loop',
    'match',
    'mod',
    'move',
    'mut',
    'pub',
    'ref',
    'return',
    'self',
    'Self',
    'static',
    'struct',
    'super',
    'trait',
    'true',
    'type',
    'unsafe',
    'use',
    'where',
    'while',
    'abstract',
    'become',
    'box',
    'do',
    'final',
    'macro',
    'override',
    'priv',
    'typeof',
    'unsized',
    'virtual',
    'yield',
  };
  static final _rustTypes = <String>{
    'i8',
    'i16',
    'i32',
    'i64',
    'i128',
    'isize',
    'u8',
    'u16',
    'u32',
    'u64',
    'u128',
    'usize',
    'f32',
    'f64',
    'bool',
    'char',
    'str',
    'String',
    'Vec',
    'Option',
    'Result',
    'Box',
    'Rc',
    'Arc',
    'Cell',
    'RefCell',
    'HashMap',
    'HashSet',
    'BTreeMap',
    'BTreeSet',
  };
  static final _goKeywords = <String>{
    'break',
    'case',
    'chan',
    'const',
    'continue',
    'default',
    'defer',
    'else',
    'fallthrough',
    'for',
    'func',
    'go',
    'goto',
    'if',
    'import',
    'interface',
    'map',
    'package',
    'range',
    'return',
    'select',
    'struct',
    'switch',
    'type',
    'var',
    'true',
    'false',
    'nil',
    'iota',
  };
  static final _goTypes = <String>{
    'bool',
    'byte',
    'complex64',
    'complex128',
    'error',
    'float32',
    'float64',
    'int',
    'int8',
    'int16',
    'int32',
    'int64',
    'rune',
    'string',
    'uint',
    'uint8',
    'uint16',
    'uint32',
    'uint64',
    'uintptr',
  };
  static final _swiftKeywords = <String>{
    'associatedtype',
    'class',
    'deinit',
    'enum',
    'extension',
    'fileprivate',
    'func',
    'import',
    'init',
    'inout',
    'internal',
    'let',
    'open',
    'operator',
    'private',
    'protocol',
    'public',
    'rethrows',
    'static',
    'struct',
    'subscript',
    'typealias',
    'var',
    'break',
    'case',
    'continue',
    'default',
    'defer',
    'do',
    'else',
    'fallthrough',
    'for',
    'guard',
    'if',
    'in',
    'repeat',
    'return',
    'switch',
    'where',
    'while',
    'as',
    'Any',
    'catch',
    'false',
    'is',
    'nil',
    'super',
    'self',
    'Self',
    'throw',
    'throws',
    'true',
    'try',
    'async',
    'await',
    'actor',
  };
  static final _swiftTypes = <String>{
    'Int',
    'Int8',
    'Int16',
    'Int32',
    'Int64',
    'UInt',
    'UInt8',
    'UInt16',
    'UInt32',
    'UInt64',
    'Float',
    'Double',
    'Bool',
    'String',
    'Character',
    'Array',
    'Dictionary',
    'Set',
    'Optional',
    'Result',
  };
  static final _kotlinKeywords = <String>{
    'as',
    'break',
    'class',
    'continue',
    'do',
    'else',
    'false',
    'for',
    'fun',
    'if',
    'in',
    'interface',
    'is',
    'null',
    'object',
    'package',
    'return',
    'super',
    'this',
    'throw',
    'true',
    'try',
    'typealias',
    'typeof',
    'val',
    'var',
    'when',
    'while',
    'by',
    'catch',
    'constructor',
    'delegate',
    'dynamic',
    'field',
    'file',
    'finally',
    'get',
    'import',
    'init',
    'param',
    'property',
    'receiver',
    'set',
    'setparam',
    'where',
    'actual',
    'abstract',
    'annotation',
    'companion',
    'const',
    'crossinline',
    'data',
    'enum',
    'expect',
    'external',
    'final',
    'infix',
    'inline',
    'inner',
    'internal',
    'lateinit',
    'noinline',
    'open',
    'operator',
    'out',
    'override',
    'private',
    'protected',
    'public',
    'reified',
    'sealed',
    'suspend',
    'tailrec',
    'vararg',
  };
  static final _kotlinTypes = <String>{
    'Byte',
    'Short',
    'Int',
    'Long',
    'Float',
    'Double',
    'Boolean',
    'Char',
    'String',
    'Array',
    'List',
    'MutableList',
    'Map',
    'MutableMap',
    'Set',
    'MutableSet',
    'Unit',
    'Nothing',
    'Any',
  };
  static final _rubyKeywords = <String>{
    'BEGIN',
    'END',
    'alias',
    'and',
    'begin',
    'break',
    'case',
    'class',
    'def',
    'defined?',
    'do',
    'else',
    'elsif',
    'end',
    'ensure',
    'false',
    'for',
    'if',
    'in',
    'module',
    'next',
    'nil',
    'not',
    'or',
    'redo',
    'rescue',
    'retry',
    'return',
    'self',
    'super',
    'then',
    'true',
    'undef',
    'unless',
    'until',
    'when',
    'while',
    'yield',
    '__FILE__',
    '__LINE__',
    '__ENCODING__',
    'attr_reader',
    'attr_writer',
    'attr_accessor',
    'private',
    'protected',
    'public',
    'require',
    'require_relative',
    'include',
    'extend',
    'prepend',
    'raise',
    'lambda',
    'proc',
  };
  static final _phpKeywords = <String>{
    'abstract',
    'and',
    'array',
    'as',
    'break',
    'callable',
    'case',
    'catch',
    'class',
    'clone',
    'const',
    'continue',
    'declare',
    'default',
    'die',
    'do',
    'echo',
    'else',
    'elseif',
    'empty',
    'enddeclare',
    'endfor',
    'endforeach',
    'endif',
    'endswitch',
    'endwhile',
    'eval',
    'exit',
    'extends',
    'final',
    'finally',
    'fn',
    'for',
    'foreach',
    'function',
    'global',
    'goto',
    'if',
    'implements',
    'include',
    'include_once',
    'instanceof',
    'insteadof',
    'interface',
    'isset',
    'list',
    'match',
    'namespace',
    'new',
    'or',
    'print',
    'private',
    'protected',
    'public',
    'require',
    'require_once',
    'return',
    'static',
    'switch',
    'throw',
    'trait',
    'try',
    'unset',
    'use',
    'var',
    'while',
    'xor',
    'yield',
    'yield from',
    'true',
    'false',
    'null',
  };
  static final _phpTypes = <String>{
    'int',
    'float',
    'bool',
    'string',
    'array',
    'object',
    'callable',
    'iterable',
    'void',
    'mixed',
    'never',
  };
  static final _sqlKeywords = <String>{
    'ADD',
    'ALL',
    'ALTER',
    'AND',
    'ANY',
    'AS',
    'ASC',
    'BACKUP',
    'BETWEEN',
    'BY',
    'CASE',
    'CHECK',
    'COLUMN',
    'CONSTRAINT',
    'CREATE',
    'DATABASE',
    'DEFAULT',
    'DELETE',
    'DESC',
    'DISTINCT',
    'DROP',
    'EXEC',
    'EXISTS',
    'FOREIGN',
    'FROM',
    'FULL',
    'GROUP',
    'HAVING',
    'IN',
    'INDEX',
    'INNER',
    'INSERT',
    'INTO',
    'IS',
    'JOIN',
    'KEY',
    'LEFT',
    'LIKE',
    'LIMIT',
    'NOT',
    'NULL',
    'ON',
    'OR',
    'ORDER',
    'OUTER',
    'PRIMARY',
    'PROCEDURE',
    'RIGHT',
    'ROWNUM',
    'SELECT',
    'SET',
    'TABLE',
    'TOP',
    'TRUNCATE',
    'UNION',
    'UNIQUE',
    'UPDATE',
    'VALUES',
    'VIEW',
    'WHERE',
    'WITH',
  };
  static final _sqlTypes = <String>{
    'INT',
    'INTEGER',
    'SMALLINT',
    'TINYINT',
    'BIGINT',
    'DECIMAL',
    'NUMERIC',
    'FLOAT',
    'REAL',
    'DOUBLE',
    'CHAR',
    'VARCHAR',
    'TEXT',
    'NCHAR',
    'NVARCHAR',
    'NTEXT',
    'BINARY',
    'VARBINARY',
    'IMAGE',
    'DATE',
    'TIME',
    'DATETIME',
    'TIMESTAMP',
    'BOOLEAN',
    'BOOL',
    'BLOB',
    'CLOB',
  };
  static final _bashKeywords = <String>{
    'if',
    'then',
    'else',
    'elif',
    'fi',
    'case',
    'esac',
    'for',
    'select',
    'while',
    'until',
    'do',
    'done',
    'in',
    'function',
    'time',
    'coproc',
    'true',
    'false',
    'return',
    'exit',
    'break',
    'continue',
    'declare',
    'local',
    'readonly',
    'export',
    'unset',
    'shift',
    'eval',
    'exec',
    'source',
    'alias',
    'unalias',
    'set',
    'shopt',
    'trap',
    'cd',
    'pwd',
    'echo',
    'printf',
    'read',
    'test',
  };
}
