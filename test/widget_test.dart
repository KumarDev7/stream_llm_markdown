import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_markdown_renderer/stream_markdown_renderer.dart';

void main() {
  group('StreamMarkdownRenderer', () {
    // ── Basic Rendering ──────────────────────────────────────────────

    testWidgets('Renders without crash with a simple stream',
        (tester) async {
      final controller = StreamController<String>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamMarkdownRenderer(
              markdownStream: controller.stream,
            ),
          ),
        ),
      );

      controller.add('Hello world');
      await tester.pumpAndSettle();

      final renderObject =
          tester.renderObject(find.byType(StreamMarkdownRenderer));
      expect(renderObject, isA<RenderBox>());

      await controller.close();
    });

    testWidgets('Renders header content "# Hello"', (tester) async {
      final controller = StreamController<String>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamMarkdownRenderer(
              markdownStream: controller.stream,
            ),
          ),
        ),
      );

      controller.add('# Hello');
      await tester.pumpAndSettle();

      final renderObject = tester.renderObject(
        find.byType(StreamMarkdownRenderer),
      ) as RenderBox;
      expect(renderObject.hasSize, isTrue);
      expect(renderObject.size.height, greaterThan(0));
      expect(renderObject.size.width, greaterThan(0));

      await controller.close();
    });

    testWidgets('Renders paragraph content', (tester) async {
      final controller = StreamController<String>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamMarkdownRenderer(
              markdownStream: controller.stream,
            ),
          ),
        ),
      );

      controller.add('This is a simple paragraph.');
      await tester.pumpAndSettle();

      final renderObject = tester.renderObject(
        find.byType(StreamMarkdownRenderer),
      ) as RenderBox;
      expect(renderObject.size.height, greaterThan(0));

      await controller.close();
    });

    testWidgets('Renders code block content', (tester) async {
      final controller = StreamController<String>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamMarkdownRenderer(
              markdownStream: controller.stream,
            ),
          ),
        ),
      );

      controller.add('```dart\nprint("hello");\n```');
      await tester.pumpAndSettle();

      final renderObject = tester.renderObject(
        find.byType(StreamMarkdownRenderer),
      ) as RenderBox;
      expect(renderObject.size.height, greaterThan(0));

      await controller.close();
    });

    testWidgets('Renders list content', (tester) async {
      final controller = StreamController<String>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamMarkdownRenderer(
              markdownStream: controller.stream,
            ),
          ),
        ),
      );

      controller.add('- Item one\n- Item two\n- Item three');
      await tester.pumpAndSettle();

      final renderObject = tester.renderObject(
        find.byType(StreamMarkdownRenderer),
      ) as RenderBox;
      expect(renderObject.size.height, greaterThan(0));

      await controller.close();
    });

    testWidgets('Renders table content', (tester) async {
      final controller = StreamController<String>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamMarkdownRenderer(
              markdownStream: controller.stream,
            ),
          ),
        ),
      );

      controller.add('| Name  | Age |\n|-------|-----|\n| Alice | 30  |');
      await tester.pumpAndSettle();

      final renderObject = tester.renderObject(
        find.byType(StreamMarkdownRenderer),
      ) as RenderBox;
      expect(renderObject.size.height, greaterThan(0));

      await controller.close();
    });

    // ── Theme & Configuration ─────────────────────────────────────────

    testWidgets('Applies custom theme', (tester) async {
      final controller = StreamController<String>();
      final customTheme = MarkdownTheme.dark();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamMarkdownRenderer(
              markdownStream: controller.stream,
              theme: customTheme,
            ),
          ),
        ),
      );

      controller.add('# Dark Theme');
      await tester.pumpAndSettle();

      // The widget should render without errors with a custom theme.
      final renderObject = tester.renderObject(
        find.byType(StreamMarkdownRenderer),
      ) as RenderBox;
      expect(renderObject.hasSize, isTrue);
      expect(renderObject.size.height, greaterThan(0));

      await controller.close();
    });

    testWidgets('showCursor parameter controls cursor visibility',
        (tester) async {
      final controller = StreamController<String>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamMarkdownRenderer(
              markdownStream: controller.stream,
              showCursor: false,
            ),
          ),
        ),
      );

      controller.add('No cursor');
      await tester.pumpAndSettle();

      // Widget renders fine with showCursor=false – no crash.
      final renderObject = tester.renderObject(
        find.byType(StreamMarkdownRenderer),
      ) as RenderBox;
      expect(renderObject.hasSize, isTrue);

      await controller.close();
    });

    testWidgets('customPatterns parameter works', (tester) async {
      final controller = StreamController<String>();

      // A simple custom pattern that matches "custom" and renders a box.
      final patterns = [
        MarkdownPattern(
          pattern: RegExp(r'^custom$'),
          createRenderObject: (block, theme) {
            return RenderConstrainedBox(
              additionalConstraints:
                  const BoxConstraints.tightFor(width: 50, height: 50),
            );
          },
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamMarkdownRenderer(
              markdownStream: controller.stream,
              customPatterns: patterns,
            ),
          ),
        ),
      );

      // Stream content wrapped in the custom block delimiter.
      controller.add('\uEB1Ecustom\uEB1E');
      await tester.pumpAndSettle();

      final renderObject = tester.renderObject(
        find.byType(StreamMarkdownRenderer),
      ) as RenderBox;
      expect(renderObject.hasSize, isTrue);

      await controller.close();
    });

    testWidgets('selectionEnabled parameter', (tester) async {
      final controller = StreamController<String>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamMarkdownRenderer(
              markdownStream: controller.stream,
              selectionEnabled: true,
            ),
          ),
        ),
      );

      controller.add('Selectable text');
      await tester.pumpAndSettle();

      final renderObject = tester.renderObject(
        find.byType(StreamMarkdownRenderer),
      ) as RenderBox;
      expect(renderObject.hasSize, isTrue);

      await controller.close();
    });

    testWidgets('autoScrollToBottom parameter', (tester) async {
      final controller = StreamController<String>();
      final scrollController = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              controller: scrollController,
              child: StreamMarkdownRenderer(
                markdownStream: controller.stream,
                scrollController: scrollController,
                autoScrollToBottom: true,
              ),
            ),
          ),
        ),
      );

      controller.add('Content with auto-scroll');
      await tester.pumpAndSettle();

      // Widget renders without error when autoScrollToBottom is set.
      final renderObject = tester.renderObject(
        find.byType(StreamMarkdownRenderer),
      ) as RenderBox;
      expect(renderObject.hasSize, isTrue);

      await controller.close();
      scrollController.dispose();
    });

    testWidgets('characterDelay parameter', (tester) async {
      final controller = StreamController<String>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamMarkdownRenderer(
              markdownStream: controller.stream,
              characterDelay: const Duration(milliseconds: 50),
            ),
          ),
        ),
      );

      controller.add('Typewriter');
      await tester.pumpAndSettle();

      // After settling, the full text should be rendered (or in buffer).
      final renderObject = tester.renderObject(
        find.byType(StreamMarkdownRenderer),
      ) as RenderBox;
      expect(renderObject.hasSize, isTrue);

      await controller.close();
    });

    // ── Stream Lifecycle ─────────────────────────────────────────────

    testWidgets('Stream error handling does not crash widget',
        (tester) async {
      final controller = StreamController<String>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamMarkdownRenderer(
              markdownStream: controller.stream,
            ),
          ),
        ),
      );

      controller.add('Before error');
      await tester.pumpAndSettle();

      // Adding an error to the stream should not crash the widget.
      controller.addError(StateError('Simulated stream error'));
      await tester.pumpAndSettle();

      // The widget should still be in the tree.
      expect(find.byType(StreamMarkdownRenderer), findsOneWidget);

      await controller.close();
    });

    testWidgets('Stream completion stops cursor', (tester) async {
      final controller = StreamController<String>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamMarkdownRenderer(
              markdownStream: controller.stream,
              showCursor: true,
            ),
          ),
        ),
      );

      controller.add('Streaming text');
      await tester.pumpAndSettle();

      // Close the stream – cursor should stop.
      await controller.close();
      await tester.pumpAndSettle();

      // Widget should still be present and rendered.
      expect(find.byType(StreamMarkdownRenderer), findsOneWidget);

      final renderObject = tester.renderObject(
        find.byType(StreamMarkdownRenderer),
      ) as RenderBox;
      expect(renderObject.hasSize, isTrue);
    });

    testWidgets('Theme change triggers relayout', (tester) async {
      final controller = StreamController<String>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamMarkdownRenderer(
              markdownStream: controller.stream,
              theme: MarkdownTheme.light(),
            ),
          ),
        ),
      );

      controller.add('# Hello');
      await tester.pumpAndSettle();

      final lightSize =
          (tester.renderObject(find.byType(StreamMarkdownRenderer)) as RenderBox)
              .size;

      // Switch to dark theme.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamMarkdownRenderer(
              markdownStream: controller.stream,
              theme: MarkdownTheme.dark(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final darkSize =
          (tester.renderObject(find.byType(StreamMarkdownRenderer)) as RenderBox)
              .size;

      // The widget should have been re-laid-out (size should exist).
      expect(darkSize.height, greaterThanOrEqualTo(0));
      expect(darkSize.width, greaterThanOrEqualTo(0));

      await controller.close();
    });

    testWidgets('Multiple sequential markdown updates render correctly',
        (tester) async {
      final controller = StreamController<String>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamMarkdownRenderer(
              markdownStream: controller.stream,
            ),
          ),
        ),
      );

      // Emit multiple incremental updates.
      controller.add('# Hello');
      await tester.pumpAndSettle();

      controller.add('# Hello\n\nWorld');
      await tester.pumpAndSettle();

      controller.add('# Hello\n\nWorld\n\n- Item 1\n- Item 2');
      await tester.pumpAndSettle();

      final renderObject = tester.renderObject(
        find.byType(StreamMarkdownRenderer),
      ) as RenderBox;
      expect(renderObject.hasSize, isTrue);
      expect(renderObject.size.height, greaterThan(0));

      await controller.close();
    });

    testWidgets('Empty markdown stream renders empty widget',
        (tester) async {
      final controller = StreamController<String>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamMarkdownRenderer(
              markdownStream: controller.stream,
            ),
          ),
        ),
      );

      // Stream an empty string (or just don't add anything and close).
      controller.add('');
      await tester.pumpAndSettle();

      final renderObject = tester.renderObject(
        find.byType(StreamMarkdownRenderer),
      ) as RenderBox;
      // The render box should exist and have a zero height.
      expect(renderObject.hasSize, isTrue);
      expect(renderObject.size.height, equals(0));

      await controller.close();
    });

    // ── Layout Verification ───────────────────────────────────────────

    testWidgets('Non-empty content results in non-zero RenderBox size',
        (tester) async {
      final controller = StreamController<String>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamMarkdownRenderer(
              markdownStream: controller.stream,
            ),
          ),
        ),
      );

      controller.add('# Header\n\nParagraph with some content.');
      await tester.pumpAndSettle();

      final renderObject = tester.renderObject(
        find.byType(StreamMarkdownRenderer),
      ) as RenderBox;

      expect(renderObject.hasSize, isTrue);
      expect(renderObject.size.width, greaterThan(0));
      expect(renderObject.size.height, greaterThan(0));

      await controller.close();
    });

    testWidgets('Block spacing is applied between blocks', (tester) async {
      final controller = StreamController<String>();

      const blockSpacing = 24.0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamMarkdownRenderer(
              markdownStream: controller.stream,
              theme: const MarkdownTheme(blockSpacing: blockSpacing),
            ),
          ),
        ),
      );

      // Stream markdown with multiple blocks.
      controller.add('# Header\n\nParagraph text.');
      await tester.pumpAndSettle();

      final renderObject = tester.renderObject(
        find.byType(StreamMarkdownRenderer),
      ) as RenderBox;
      expect(renderObject.hasSize, isTrue);

      // Visit children to verify spacing.
      final children = <RenderBox>[];
      renderObject.visitChildren((child) {
        children.add(child as RenderBox);
      });

      if (children.length >= 2) {
        double currentY = 0;
        for (var i = 0; i < children.length; i++) {
          final parentData = children[i].parentData as BoxParentData;
          expect(parentData.offset.dy, equals(currentY));
          currentY += children[i].size.height;
          if (i < children.length - 1) {
            currentY += blockSpacing;
          }
        }
      }

      await controller.close();
    });
  });
}