import 'dart:async';
import 'dart:developer';
import 'dart:math' hide log;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:stream_markdown_renderer/stream_markdown_renderer.dart';

void main() {
  runApp(const MyApp());
}

class DemoPage extends StatefulWidget {
  final bool isDarkMode;

  final VoidCallback onToggleTheme;
  const DemoPage({
    required this.isDarkMode,
    required this.onToggleTheme,
    super.key,
  });

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _DemoPageState extends State<DemoPage> {
  StreamController<String>? _controller;
  final ScrollController _scrollController = ScrollController();
  bool _isStreaming = false;

  @override
  Widget build(BuildContext context) {
    log('Building DemoPage');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stream Markdown Demo'),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isStreaming ? null : _startStream,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(_isStreaming ? 'Streaming...' : 'Start Stream'),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isStreaming ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SelectionArea(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: _controller != null
                    ? StreamMarkdownRenderer(
                        markdownStream: _controller!.stream,
                        showCursor: false,
                        selectionEnabled: true,
                        customPatterns: [
                          MarkdownPattern(
                            pattern: RegExp(r'^custom$'),
                            createRenderObject: (block, theme) {
                              return RenderCustomBox();
                            },
                          ),
                        ],
                        characterDelay: const Duration(
                          milliseconds: 10,
                        ), // Character-by-character animation
                        scrollController: _scrollController,
                        autoScrollToBottom: true,
                        theme: widget.isDarkMode
                            ? MarkdownTheme.dark()
                            : MarkdownTheme.light(),
                        onLinkTapped: (url) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Link tapped: $url')),
                          );
                        },
                        onCheckboxTapped: (index, checked) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Checkbox $index ${checked ? 'checked' : 'unchecked'}',
                              ),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Text(
                          'Press "Start Stream" to begin',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
              ),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.close();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _simulateAiStream(StreamController<String> controller) async {
    const markdown = '''
# Welcome to Stream Markdown Renderer

This is a **high-performance** streaming Markdown renderer built with custom RenderObjects for *maximum efficiency*.

## Features

### Custom Pattern Demo

Here is a custom widget injected via pattern:

\uEB1Ecustom\uEB1E

This widget is rendered using a custom `RenderBox`!

### Text Formatting

You can use **bold**, *italic*, ~~strikethrough~~, and `inline code`.

### Code Blocks

Here's a Dart code example:

```dart
void main() {
  final greeting = 'Hello, World!';
  print(greeting);
  
  // Calculate factorial
  int factorial(int n) {
    if (n <= 1) return 1;
    return n * factorial(n - 1);
  }
  
  print('5! = \${factorial(5)}');
}
```

### Lists

#### Unordered List
- First item
- Second item with **bold**
- Third item with `code`
- Fourth item

#### Ordered List
1. Step one
2. Step two
3. Step three

#### Task List
- [x] Implement parser
- [x] Build render objects
- [x] Add syntax highlighting
- [ ] Write documentation
- [ ] Publish to pub.dev

### Blockquotes

> This is a blockquote with some **important** information.
> 
> It can span multiple lines.

### Tables

| Feature | Status | Priority |
|:--------|:------:|--------:|
| Parsing | Done | High |
| Rendering | Done | High |
| Themes | Done | Medium |
| Testing | Pending | Low |

### Links

Check out [Flutter](https://flutter.dev) for more information.

You can also use autolinks: <https://dart.dev>

### Math (LaTeX)

Inline math: \$E = mc^2\$

Block math:

\$\$
\\sum_{i=1}^{n} i = \\frac{n(n+1)}{2}
\$\$

---

## Performance

This renderer is designed for **extreme performance**:

- Sub-millisecond layout times
- Intelligent diffing for minimal repaints
- Cached text layout
- Zero widget tree overhead

Perfect for AI chat applications! 🚀
''';

    var buffer = '';
    final random = Random();

    // Simulate streaming with realistic chunk sizes and delays
    // Split into words and whitespace to simulate token-based streaming
    final RegExp tokenRegex = RegExp(r'[^\s]+|\s+');
    final matches = tokenRegex.allMatches(markdown);

    var currentChunkWords = 0;
    var targetChunkWords = 5 + random.nextInt(3); // 5, 6, or 7
    var pendingChunk = '';

    for (final match in matches) {
      if (controller.isClosed) break;

      final token = match.group(0)!;
      pendingChunk += token;

      // Count words (non-whitespace tokens)
      if (token.trim().isNotEmpty) {
        currentChunkWords++;
      }

      // If we reached the target chunk size, emit
      if (currentChunkWords >= targetChunkWords) {
        buffer += pendingChunk;
        controller.add(buffer);

        // Reset for next chunk
        pendingChunk = '';
        currentChunkWords = 0;
        targetChunkWords = 5 + random.nextInt(3);

        // Delay between chunks
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }

    // Emit any remaining text
    if (pendingChunk.isNotEmpty && !controller.isClosed) {
      buffer += pendingChunk;
      controller.add(buffer);
    }

    if (!controller.isClosed) {
      setState(() {
        _isStreaming = false;
      });
    }
  }

  void _startStream() {
    _controller?.close();
    _controller = StreamController<String>();
    setState(() {
      _isStreaming = true;
    });

    _simulateAiStream(_controller!);
  }
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    log('Building MaterialApp');
    return MaterialApp(
      title: 'Stream Markdown Renderer Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: _themeMode,
      home: DemoPage(
        isDarkMode: _themeMode == ThemeMode.dark,
        onToggleTheme: _toggleTheme,
      ),
    );
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }
}

class RenderCustomBox extends RenderBox {
  TextPainter? _textPainter;

  @override
  void performLayout() {
    size = const Size(300, 60);
    _textPainter ??= TextPainter(
      text: const TextSpan(
        text: '✨ Custom Widget Pattern ✨',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final paint = Paint()
      ..color = Colors.indigo
      ..style = PaintingStyle.fill;

    final rect = offset & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    context.canvas.drawRRect(rrect, paint);

    _textPainter?.paint(
      context.canvas,
      offset +
          Offset(
            (size.width - (_textPainter?.width ?? 0)) / 2,
            (size.height - (_textPainter?.height ?? 0)) / 2,
          ),
    );
  }

  @override
  void dispose() {
    _textPainter?.dispose();
    super.dispose();
  }
}
