import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_markdown_renderer/src/parsing/incremental_markdown_parser.dart';
import 'package:stream_markdown_renderer/src/parsing/markdown_block.dart';

void main() {
  test('Parses nested list with intervening text correctly', () {
    final parser = IncrementalMarkdownParser();
    final markdown = '''
1. Item 1
  Description text
  - Nested A
  - Nested B
''';

    final blocks = parser.parse(markdown);
    expect(blocks.length, 1);
    expect(blocks.first.type, MarkdownBlockType.orderedList);
    
    final items = blocks.first.metadata['items'] as List<dynamic>;
    expect(items.length, 1);
    
    final item1 = items[0] as Map<String, dynamic>;
    expect(item1['content'], contains('Item 1'));
    expect(item1['content'], contains('Description text'));
    
    final children = item1['children'] as List<dynamic>;
    expect(children.length, 2, reason: 'Should have 2 nested items');
    expect(children[0]['content'], 'Nested A');
  });

  test('Parses nested list immediately following item correctly', () {
    final parser = IncrementalMarkdownParser();
    final markdown = '''
1. Item 1
  - Nested A
  - Nested B
''';

    final blocks = parser.parse(markdown);
    expect(blocks.length, 1);
    expect(blocks.first.type, MarkdownBlockType.orderedList);
    
    final items = blocks.first.metadata['items'] as List<dynamic>;
    final item1 = items[0] as Map<String, dynamic>;
    
    final children = item1['children'] as List<dynamic>;
    expect(children.length, 2, reason: 'Should have 2 nested items');
  });
}
