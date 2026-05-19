import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_markdown_renderer/src/text/syntax_highlighter.dart';
import 'package:stream_markdown_renderer/src/theme/markdown_theme.dart';

void main() {
  late SyntaxHighlighter highlighter;
  late SyntaxTheme syntaxTheme;
  late TextStyle baseStyle;

  setUp(() {
    highlighter = const SyntaxHighlighter();
    syntaxTheme = SyntaxTheme.light();
    baseStyle = const TextStyle(fontSize: 14, fontFamily: 'monospace');
  });

  // ── Unknown language ────────────────────────────────────────────

  group('unknown language', () {
    test('tokenize with unknown language returns single plain token', () {
      final tokens = highlighter.tokenize('some code here', 'unknown');
      expect(tokens.length, 1);
      expect(tokens.first.text, 'some code here');
      expect(tokens.first.type, SyntaxTokenType.plain);
    });

    test('tokenize with empty unknown language name returns plain token', () {
      final tokens = highlighter.tokenize('text', '');
      expect(tokens.length, 1);
      expect(tokens.first.type, SyntaxTokenType.plain);
    });
  });

  // ── Dart ────────────────────────────────────────────────────────

  group('Dart', () {
    test('keywords are detected', () {
      final tokens = highlighter.tokenize('class Foo { }', 'dart');
      final classToken = tokens.firstWhere(
        (t) => t.text == 'class',
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(classToken.type, SyntaxTokenType.keyword);
    });

    test('strings are detected', () {
      final tokens = highlighter.tokenize('"hello"', 'dart');
      final stringToken = tokens.firstWhere(
        (t) => t.text.startsWith('"'),
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(stringToken.type, SyntaxTokenType.string);
    });

    test('numbers are detected', () {
      final tokens = highlighter.tokenize('42', 'dart');
      final numberToken = tokens.firstWhere(
        (t) => t.text == '42',
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(numberToken.type, SyntaxTokenType.number);
    });

    test('single-line comments are detected', () {
      final tokens = highlighter.tokenize('// comment', 'dart');
      final commentToken = tokens.firstWhere(
        (t) => t.text.startsWith('//'),
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(commentToken.type, SyntaxTokenType.comment);
    });

    test('Dart types are detected', () {
      final tokens = highlighter.tokenize('int x;', 'dart');
      final intToken = tokens.firstWhere(
        (t) => t.text == 'int',
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(intToken.type, SyntaxTokenType.type);
    });

    test('function calls are detected', () {
      final tokens = highlighter.tokenize('print()', 'dart');
      final funcToken = tokens.firstWhere(
        (t) => t.text == 'print',
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(funcToken.type, SyntaxTokenType.function);
    });

    test('annotations are detected', () {
      final tokens = highlighter.tokenize('@override', 'dart');
      final annotToken = tokens.firstWhere(
        (t) => t.text == '@override',
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(annotToken.type, SyntaxTokenType.annotation);
    });
  });

  // ── JavaScript ─────────────────────────────────────────────────

  group('JavaScript', () {
    test('keywords are detected', () {
      final tokens = highlighter.tokenize('const x = 1;', 'javascript');
      final constToken = tokens.firstWhere(
        (t) => t.text == 'const',
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(constToken.type, SyntaxTokenType.keyword);
    });

    test('JS keywords detected via "js" alias', () {
      final tokens = highlighter.tokenize('let x = 1;', 'js');
      final letToken = tokens.firstWhere(
        (t) => t.text == 'let',
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(letToken.type, SyntaxTokenType.keyword);
    });

    test('function keyword detected', () {
      final tokens = highlighter.tokenize('function foo() {}', 'javascript');
      final funcKwToken = tokens.firstWhere(
        (t) => t.text == 'function',
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(funcKwToken.type, SyntaxTokenType.keyword);
    });

    test('JS types are detected', () {
      final tokens = highlighter.tokenize('Array', 'javascript');
      final arrayToken = tokens.firstWhere(
        (t) => t.text == 'Array',
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(arrayToken.type, SyntaxTokenType.type);
    });
  });

  // ── TypeScript ──────────────────────────────────────────────────

  group('TypeScript', () {
    test('TS-specific keywords detected', () {
      final tokens = highlighter.tokenize('interface Foo {}', 'typescript');
      final ifaceToken = tokens.firstWhere(
        (t) => t.text == 'interface',
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(ifaceToken.type, SyntaxTokenType.keyword);
    });

    test('TS alias "ts" works', () {
      final tokens = highlighter.tokenize('type X = string;', 'ts');
      final typeToken = tokens.firstWhere(
        (t) => t.text == 'type',
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(typeToken.type, SyntaxTokenType.keyword);
    });
  });

  // ── Python ──────────────────────────────────────────────────────

  group('Python', () {
    test('keywords are detected', () {
      final tokens = highlighter.tokenize('def foo():', 'python');
      final defToken = tokens.firstWhere(
        (t) => t.text == 'def',
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(defToken.type, SyntaxTokenType.keyword);
    });

    test('# comments are detected', () {
      final tokens = highlighter.tokenize('# a comment', 'python');
      final commentToken = tokens.firstWhere(
        (t) => t.text.startsWith('#'),
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(commentToken.type, SyntaxTokenType.comment);
    });

    test('Python keywords "True" and "False"', () {
      final tokens = highlighter.tokenize('True', 'python');
      expect(tokens.any((t) => t.text == 'True' && t.type == SyntaxTokenType.keyword), isTrue);
    });

    test('Python "py" alias works', () {
      final tokens = highlighter.tokenize('import os', 'py');
      final importToken = tokens.firstWhere(
        (t) => t.text == 'import',
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(importToken.type, SyntaxTokenType.keyword);
    });

    test('Python types detected', () {
      final tokens = highlighter.tokenize('str', 'python');
      final strToken = tokens.firstWhere(
        (t) => t.text == 'str',
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(strToken.type, SyntaxTokenType.type);
    });
  });

  // ── JSON ─────────────────────────────────────────────────────────

  group('JSON', () {
    test('keys are classified as variables', () {
      final tokens = highlighter.tokenize('{"name": "value"}', 'json');
      final keyToken = tokens.firstWhere(
        (t) => t.text == '"name"',
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(keyToken.type, SyntaxTokenType.variable);
    });

    test('values are classified as strings', () {
      final tokens = highlighter.tokenize('{"key": "value"}', 'json');
      final valueToken = tokens.firstWhere(
        (t) => t.text == '"value"',
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(valueToken.type, SyntaxTokenType.string);
    });

    test('numbers are detected', () {
      final tokens = highlighter.tokenize('{"count": 42}', 'json');
      final numToken = tokens.firstWhere(
        (t) => t.text == '42',
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(numToken.type, SyntaxTokenType.number);
    });

    test('true/false/null are keywords', () {
      final tokens = highlighter.tokenize('true', 'json');
      expect(tokens.first.type, SyntaxTokenType.keyword);
      expect(tokens.first.text, 'true');

      final falseTokens = highlighter.tokenize('false', 'json');
      expect(falseTokens.first.type, SyntaxTokenType.keyword);

      final nullTokens = highlighter.tokenize('null', 'json');
      expect(nullTokens.first.type, SyntaxTokenType.keyword);
    });

    test('punctuation brackets are detected', () {
      final tokens = highlighter.tokenize('{}', 'json');
      expect(tokens.any((t) => t.text == '{' && t.type == SyntaxTokenType.punctuation), isTrue);
      expect(tokens.any((t) => t.text == '}' && t.type == SyntaxTokenType.punctuation), isTrue);
    });

    test('negative numbers are detected', () {
      final tokens = highlighter.tokenize('{"val": -3.14}', 'json');
      final negToken = tokens.firstWhere(
        (t) => t.text.contains('3.14') || t.text == '-3.14',
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(negToken.type, SyntaxTokenType.number);
    });
  });

  // ── YAML ─────────────────────────────────────────────────────────

  group('YAML', () {
    test('keys are classified as variables', () {
      final tokens = highlighter.tokenize('name: value', 'yaml');
      final keyToken = tokens.firstWhere(
        (t) => t.text == 'name',
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(keyToken.type, SyntaxTokenType.variable);
    });

    test('colon punctuation after key', () {
      final tokens = highlighter.tokenize('key: val', 'yaml');
      expect(tokens.any((t) => t.text == ':' && t.type == SyntaxTokenType.punctuation), isTrue);
    });

    test('# comments are detected', () {
      final tokens = highlighter.tokenize('key: val # a comment', 'yaml');
      final commentToken = tokens.firstWhere(
        (t) => t.text.startsWith('#'),
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(commentToken.type, SyntaxTokenType.comment);
    });

    test('boolean values are keywords', () {
      final tokens = highlighter.tokenize('enabled: true', 'yaml');
      expect(tokens.any((t) => t.text == 'true' && t.type == SyntaxTokenType.keyword), isTrue);
    });

    test('quoted string values are strings', () {
      final tokens = highlighter.tokenize('name: "hello"', 'yaml');
      final strToken = tokens.firstWhere(
        (t) => t.text == '"hello"',
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(strToken.type, SyntaxTokenType.string);
    });

    test('"yml" alias works', () {
      final tokens = highlighter.tokenize('key: val', 'yml');
      expect(tokens.any((t) => t.text == 'key' && t.type == SyntaxTokenType.variable), isTrue);
    });
  });

  // ── HTML ─────────────────────────────────────────────────────────

  group('HTML', () {
    test('tag names are classified as keywords', () {
      final tokens = highlighter.tokenize('<div>', 'html');
      final divToken = tokens.firstWhere(
        (t) => t.text == 'div',
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(divToken.type, SyntaxTokenType.keyword);
    });

    test('attributes are classified as variables', () {
      final tokens = highlighter.tokenize('<div class="foo">', 'html');
      final classToken = tokens.firstWhere(
        (t) => t.text == 'class',
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(classToken.type, SyntaxTokenType.variable);
    });

    test('attribute values are classified as strings', () {
      final tokens = highlighter.tokenize('<div class="foo">', 'html');
      final fooToken = tokens.firstWhere(
        (t) => t.text == '"foo"',
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(fooToken.type, SyntaxTokenType.string);
    });

    test('closing tags have keyword type for tag name', () {
      final tokens = highlighter.tokenize('</div>', 'html');
      final divToken = tokens.firstWhere(
        (t) => t.text == 'div',
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(divToken.type, SyntaxTokenType.keyword);
    });

    test('HTML comments are detected', () {
      final tokens = highlighter.tokenize('<!-- comment -->', 'html');
      expect(tokens.any((t) => t.type == SyntaxTokenType.comment), isTrue);
    });

    test('"xml" alias works', () {
      final tokens = highlighter.tokenize('<tag>', 'xml');
      expect(tokens.any((t) => t.text == 'tag' && t.type == SyntaxTokenType.keyword), isTrue);
    });

    test('angle brackets are punctuation', () {
      final tokens = highlighter.tokenize('<br>', 'html');
      expect(tokens.any((t) => t.text == '<' && t.type == SyntaxTokenType.punctuation), isTrue);
      expect(tokens.any((t) => t.text == '>' && t.type == SyntaxTokenType.punctuation), isTrue);
    });
  });

  // ── CSS ──────────────────────────────────────────────────────────

  group('CSS', () {
    test('selectors are classified correctly', () {
      final tokens = highlighter.tokenize('.container { }', 'css');
      final containerToken = tokens.firstWhere(
        (t) => t.text == '.container',
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(containerToken.type, SyntaxTokenType.className);
    });

    test('properties are classified as variables', () {
      final tokens = highlighter.tokenize('color { }', 'css');
      // In the CSS tokenizer, words that start with a letter and don't start
      // with #, ., or @ are classified as variable
      final colorToken = tokens.firstWhere(
        (t) => t.text == 'color',
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(colorToken.type, SyntaxTokenType.variable);
    });

    test('CSS comments are detected', () {
      final tokens = highlighter.tokenize('/* comment */', 'css');
      final commentToken = tokens.firstWhere(
        (t) => t.type == SyntaxTokenType.comment,
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(commentToken.text, contains('comment'));
    });

    test('CSS numbers are detected', () {
      final tokens = highlighter.tokenize('16px', 'css');
      final numToken = tokens.firstWhere(
        (t) => t.type == SyntaxTokenType.number,
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(numToken.text, contains('16'));
    });

    test('@media rules are keywords', () {
      final tokens = highlighter.tokenize('@media', 'css');
      final mediaToken = tokens.firstWhere(
        (t) => t.text == '@media',
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(mediaToken.type, SyntaxTokenType.keyword);
    });

    test('id selectors are className type', () {
      final tokens = highlighter.tokenize('#header { }', 'css');
      final headerToken = tokens.firstWhere(
        (t) => t.text == '#header',
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(headerToken.type, SyntaxTokenType.className);
    });
  });

  // ── String with escapes ─────────────────────────────────────────

  group('string escapes', () {
    test('double-quoted string with escapes is a single token', () {
      final tokens = highlighter.tokenize(r'"hello \"world\""', 'dart');
      final stringToken = tokens.firstWhere(
        (t) => t.type == SyntaxTokenType.string,
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      // The entire escaped string should be one token
      expect(stringToken.text, r'"hello \"world\""');
    });

    test('single-quoted string with escapes is a single token', () {
      final tokens = highlighter.tokenize(r"'it\'s ok'", 'dart');
      final stringToken = tokens.firstWhere(
        (t) => t.type == SyntaxTokenType.string,
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(stringToken.text, r"'it\'s ok'");
    });
  });

  // ── Multi-line comments ─────────────────────────────────────────

  group('multi-line comments', () {
    test('/* comment */ produces a comment token', () {
      final tokens = highlighter.tokenize('/* multi\nline */', 'dart');
      final commentToken = tokens.firstWhere(
        (t) => t.type == SyntaxTokenType.comment,
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(commentToken.text, contains('/*'));
      expect(commentToken.text, contains('*/'));
    });

    test('CSS multi-line comment', () {
      final tokens = highlighter.tokenize('/* style */', 'css');
      expect(tokens.any((t) => t.type == SyntaxTokenType.comment), isTrue);
    });

    test('JavaScript multi-line comment', () {
      final tokens = highlighter.tokenize('/* block */', 'javascript');
      expect(tokens.any((t) => t.type == SyntaxTokenType.comment), isTrue);
    });
  });

  // ── Annotations ──────────────────────────────────────────────────

  group('annotations', () {
    test('@override is annotation token in Dart', () {
      final tokens = highlighter.tokenize('@override', 'dart');
      final annotToken = tokens.firstWhere(
        (t) => t.text == '@override',
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(annotToken.type, SyntaxTokenType.annotation);
    });

    test('@visibleForTesting is annotation in Dart', () {
      final tokens = highlighter.tokenize('@visibleForTesting', 'dart');
      final annotToken = tokens.firstWhere(
        (t) => t.type == SyntaxTokenType.annotation,
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(annotToken.text, '@visibleForTesting');
    });

    test('annotations in Kotlin', () {
      final tokens = highlighter.tokenize('@Composable', 'kotlin');
      final annotToken = tokens.firstWhere(
        (t) => t.type == SyntaxTokenType.annotation,
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(annotToken.text, '@Composable');
    });

    test('annotations in Swift', () {
      final tokens = highlighter.tokenize('@MainActor', 'swift');
      final annotToken = tokens.firstWhere(
        (t) => t.type == SyntaxTokenType.annotation,
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(annotToken.text, '@MainActor');
    });
  });

  // ── Number formats ──────────────────────────────────────────────

  group('number formats', () {
    test('42 is a number token', () {
      final tokens = highlighter.tokenize('42', 'dart');
      expect(tokens.first.type, SyntaxTokenType.number);
      expect(tokens.first.text, '42');
    });

    test('3.14 is a number token', () {
      final tokens = highlighter.tokenize('3.14', 'dart');
      expect(tokens.first.type, SyntaxTokenType.number);
      expect(tokens.first.text, '3.14');
    });

    test('0xFF is a number token (hex)', () {
      final tokens = highlighter.tokenize('0xFF', 'dart');
      final hexToken = tokens.firstWhere(
        (t) => t.type == SyntaxTokenType.number,
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(hexToken.text, '0xFF');
    });

    test('negative number in Python', () {
      final tokens = highlighter.tokenize('-10', 'python');
      final minusToken = tokens.firstWhere(
        (t) => t.text == '-',
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(minusToken.type, SyntaxTokenType.operator);
    });
  });

  // ── Empty code ──────────────────────────────────────────────────

  group('empty code', () {
    test('empty code returns empty list', () {
      final tokens = highlighter.tokenize('', 'dart');
      expect(tokens, isEmpty);
    });

    test('empty code for JSON returns empty list', () {
      final tokens = highlighter.tokenize('', 'json');
      expect(tokens, isEmpty);
    });

    test('empty code for YAML returns empty list', () {
      final tokens = highlighter.tokenize('', 'yaml');
      // YAML splits by \n, so empty string -> single empty line -> no tokens
      expect(tokens, isEmpty);
    });

    test('empty code for HTML returns empty list', () {
      final tokens = highlighter.tokenize('', 'html');
      expect(tokens, isEmpty);
    });

    test('empty code for CSS returns empty list', () {
      final tokens = highlighter.tokenize('', 'css');
      expect(tokens, isEmpty);
    });

    test('empty code for unknown language returns empty plain token', () {
      final tokens = highlighter.tokenize('', 'unknown');
      // Unknown language returns [SyntaxToken('', plain)]
      // But empty string input might produce empty text
      expect(tokens.length, lessThanOrEqualTo(1));
    });
  });

  // ── highlight() method ──────────────────────────────────────────

  group('highlight()', () {
    test('returns TextSpans for Dart code', () {
      final spans = highlighter.highlight(
        'void main() {}',
        'dart',
        syntaxTheme,
        baseStyle,
      );
      expect(spans, isNotEmpty);
      for (final span in spans) {
        expect(span.style, isNotNull);
      }
    });

    test('returns TextSpans for JavaScript code', () {
      final spans = highlighter.highlight(
        'const x = 1;',
        'javascript',
        syntaxTheme,
        baseStyle,
      );
      expect(spans, isNotEmpty);
    });

    test('returns TextSpans for Python code', () {
      final spans = highlighter.highlight(
        'def foo():\n  pass',
        'python',
        syntaxTheme,
        baseStyle,
      );
      expect(spans, isNotEmpty);
    });

    test('returns TextSpans for JSON code', () {
      final spans = highlighter.highlight(
        '{"key": "value"}',
        'json',
        syntaxTheme,
        baseStyle,
      );
      expect(spans, isNotEmpty);
    });

    test('returns TextSpans for YAML code', () {
      final spans = highlighter.highlight(
        'name: test',
        'yaml',
        syntaxTheme,
        baseStyle,
      );
      expect(spans, isNotEmpty);
    });

    test('returns TextSpans for HTML code', () {
      final spans = highlighter.highlight(
        '<div class="foo">bar</div>',
        'html',
        syntaxTheme,
        baseStyle,
      );
      expect(spans, isNotEmpty);
    });

    test('returns TextSpans for CSS code', () {
      final spans = highlighter.highlight(
        '.foo { color: red; }',
        'css',
        syntaxTheme,
        baseStyle,
      );
      expect(spans, isNotEmpty);
    });
  });

  // ── All 15 supported languages ──────────────────────────────────

  group('all 15 supported languages produce output', () {
    const sampleCode = 'function test() {}';

    test('Dart', () {
      final tokens = highlighter.tokenize('class A {}', 'dart');
      expect(tokens, isNotEmpty);
    });

    test('JavaScript', () {
      final tokens = highlighter.tokenize(sampleCode, 'javascript');
      expect(tokens, isNotEmpty);
    });

    test('TypeScript', () {
      final tokens = highlighter.tokenize('interface A {}', 'typescript');
      expect(tokens, isNotEmpty);
    });

    test('Python', () {
      final tokens = highlighter.tokenize('def foo(): pass', 'python');
      expect(tokens, isNotEmpty);
    });

    test('Java', () {
      final tokens = highlighter.tokenize('class A {}', 'java');
      expect(tokens, isNotEmpty);
    });

    test('C', () {
      final tokens = highlighter.tokenize('int main() {}', 'c');
      expect(tokens, isNotEmpty);
    });

    test('C++', () {
      final tokens = highlighter.tokenize('int main() {}', 'cpp');
      expect(tokens, isNotEmpty);
    });

    test('Rust', () {
      final tokens = highlighter.tokenize('fn main() {}', 'rust');
      expect(tokens, isNotEmpty);
    });

    test('Go', () {
      final tokens = highlighter.tokenize('func main() {}', 'go');
      expect(tokens, isNotEmpty);
    });

    test('Swift', () {
      final tokens = highlighter.tokenize('func test() {}', 'swift');
      expect(tokens, isNotEmpty);
    });

    test('Kotlin', () {
      final tokens = highlighter.tokenize('fun main() {}', 'kotlin');
      expect(tokens, isNotEmpty);
    });

    test('Ruby', () {
      final tokens = highlighter.tokenize('def test; end', 'ruby');
      expect(tokens, isNotEmpty);
    });

    test('PHP', () {
      final tokens = highlighter.tokenize('<?php echo "hi";', 'php');
      expect(tokens, isNotEmpty);
    });

    test('SQL', () {
      final tokens = highlighter.tokenize('SELECT * FROM users;', 'sql');
      expect(tokens, isNotEmpty);
    });

    test('Bash', () {
      final tokens = highlighter.tokenize('echo "hello"', 'bash');
      expect(tokens, isNotEmpty);
    });

    test('JSON', () {
      final tokens = highlighter.tokenize('{"key": "value"}', 'json');
      expect(tokens, isNotEmpty);
    });

    test('YAML', () {
      final tokens = highlighter.tokenize('key: value', 'yaml');
      expect(tokens, isNotEmpty);
    });

    test('HTML', () {
      final tokens = highlighter.tokenize('<div>test</div>', 'html');
      expect(tokens, isNotEmpty);
    });

    test('CSS', () {
      final tokens = highlighter.tokenize('.foo { color: red; }', 'css');
      expect(tokens, isNotEmpty);
    });
  });

  // ── Language aliases ────────────────────────────────────────────

  group('language aliases', () {
    test('"js" alias for JavaScript', () {
      final tokens = highlighter.tokenize('let x = 1;', 'js');
      expect(tokens.any((t) => t.text == 'let' && t.type == SyntaxTokenType.keyword), isTrue);
    });

    test('"ts" alias for TypeScript', () {
      final tokens = highlighter.tokenize('interface A {}', 'ts');
      expect(tokens.any((t) => t.text == 'interface' && t.type == SyntaxTokenType.keyword), isTrue);
    });

    test('"py" alias for Python', () {
      final tokens = highlighter.tokenize('def foo():', 'py');
      expect(tokens.any((t) => t.text == 'def' && t.type == SyntaxTokenType.keyword), isTrue);
    });

    test('"rs" alias for Rust', () {
      final tokens = highlighter.tokenize('fn main() {}', 'rs');
      expect(tokens.any((t) => t.text == 'fn' && t.type == SyntaxTokenType.keyword), isTrue);
    });

    test('"kt" alias for Kotlin', () {
      final tokens = highlighter.tokenize('fun main() {}', 'kt');
      expect(tokens.any((t) => t.text == 'fun' && t.type == SyntaxTokenType.keyword), isTrue);
    });

    test('"rb" alias for Ruby', () {
      final tokens = highlighter.tokenize('def test; end', 'rb');
      expect(tokens.any((t) => t.text == 'def' && t.type == SyntaxTokenType.keyword), isTrue);
    });

    test('"yml" alias for YAML', () {
      final tokens = highlighter.tokenize('key: val', 'yml');
      expect(tokens, isNotEmpty);
    });

    test('"c++" alias for C++', () {
      final tokens = highlighter.tokenize('int main() {}', 'c++');
      expect(tokens, isNotEmpty);
    });

    test('"sh" alias for Bash', () {
      final tokens = highlighter.tokenize('echo hi', 'sh');
      expect(tokens.any((t) => t.text == 'echo' && t.type == SyntaxTokenType.keyword), isTrue);
    });

    test('"shell" alias for Bash', () {
      final tokens = highlighter.tokenize('echo hi', 'shell');
      expect(tokens.any((t) => t.text == 'echo' && t.type == SyntaxTokenType.keyword), isTrue);
    });

    test('"xml" alias for HTML', () {
      final tokens = highlighter.tokenize('<tag>text</tag>', 'xml');
      expect(tokens.any((t) => t.type == SyntaxTokenType.keyword), isTrue);
    });
  });

  // ── Operators and punctuation ────────────────────────────────────

  group('operators and punctuation', () {
    test('operators are classified correctly', () {
      final tokens = highlighter.tokenize('a + b', 'dart');
      final plusToken = tokens.firstWhere(
        (t) => t.text == '+',
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(plusToken.type, SyntaxTokenType.operator);
    });

    test('punctuation braces are classified', () {
      final tokens = highlighter.tokenize('{ }', 'dart');
      expect(tokens.any((t) => t.text == '{' && t.type == SyntaxTokenType.punctuation), isTrue);
      expect(tokens.any((t) => t.text == '}' && t.type == SyntaxTokenType.punctuation), isTrue);
    });

    test('semicolon is punctuation', () {
      final tokens = highlighter.tokenize(';', 'dart');
      expect(tokens.first.type, SyntaxTokenType.punctuation);
    });
  });

  // ── Class name detection ────────────────────────────────────────

  group('class name detection', () {
    test('PascalCase identifier not in types list is className', () {
      final tokens = highlighter.tokenize('MyClass', 'dart');
      // MyClass starts with uppercase, not a known type, so should be className
      final myClassToken = tokens.firstWhere(
        (t) => t.text == 'MyClass',
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(myClassToken.type, SyntaxTokenType.className);
    });

    test('all-caps like ABC is NOT className (only upper pattern excluded)', () {
      final tokens = highlighter.tokenize('ABC', 'dart');
      // Single-char uppercase or all-caps-only is excluded by _classNameOnlyUpperRe
      final abcToken = tokens.firstWhere(
        (t) => t.text == 'ABC',
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      // ABC is all uppercase, so _isClassName returns false
      expect(abcToken.type, isNot(equals(SyntaxTokenType.className)));
    });
  });

  // ── SQL specifics ────────────────────────────────────────────────

  group('SQL', () {
    test('SELECT keyword detected', () {
      final tokens = highlighter.tokenize('SELECT * FROM users', 'sql');
      final selectToken = tokens.firstWhere(
        (t) => t.text == 'SELECT',
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(selectToken.type, SyntaxTokenType.keyword);
    });

    test('SQL types detected', () {
      final tokens = highlighter.tokenize('INT', 'sql');
      final intToken = tokens.firstWhere(
        (t) => t.text == 'INT',
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(intToken.type, SyntaxTokenType.type);
    });

    test('-- comments detected', () {
      final tokens = highlighter.tokenize('-- a comment', 'sql');
      final commentToken = tokens.firstWhere(
        (t) => t.type == SyntaxTokenType.comment,
        orElse: () => const SyntaxToken('', SyntaxTokenType.plain),
      );
      expect(commentToken.text, contains('--'));
    });
  });

  // ── highlight() color mapping ───────────────────────────────────

  group('highlight() color mapping', () {
    test('keyword spans use syntaxTheme.keyword color', () {
      final spans = highlighter.highlight('class', 'dart', syntaxTheme, baseStyle);
      final classSpan = spans.firstWhere(
        (s) => s.text == 'class',
        orElse: () => const TextSpan(text: ''),
      );
      expect(classSpan.style?.color, syntaxTheme.keyword);
    });

    test('string spans use syntaxTheme.string color', () {
      final spans = highlighter.highlight('"hello"', 'dart', syntaxTheme, baseStyle);
      final stringSpan = spans.firstWhere(
        (s) => s.text!.startsWith('"'),
        orElse: () => const TextSpan(text: ''),
      );
      expect(stringSpan.style?.color, syntaxTheme.string);
    });

    test('number spans use syntaxTheme.number color', () {
      final spans = highlighter.highlight('42', 'dart', syntaxTheme, baseStyle);
      expect(spans.first.style?.color, syntaxTheme.number);
    });

    test('comment spans use syntaxTheme.comment color', () {
      final spans = highlighter.highlight('// comment', 'dart', syntaxTheme, baseStyle);
      final commentSpan = spans.firstWhere(
        (s) => s.text!.startsWith('//'),
        orElse: () => const TextSpan(text: ''),
      );
      expect(commentSpan.style?.color, syntaxTheme.comment);
    });

    test('dark theme colors are different from light', () {
      final darkTheme = SyntaxTheme.dark();
      expect(darkTheme.keyword, isNot(equals(syntaxTheme.keyword)));
      expect(darkTheme.string, isNot(equals(syntaxTheme.string)));
      expect(darkTheme.number, isNot(equals(syntaxTheme.number)));
      expect(darkTheme.comment, isNot(equals(syntaxTheme.comment)));
    });
  });
}