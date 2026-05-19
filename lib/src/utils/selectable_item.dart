import 'package:flutter/rendering.dart';

/// A selectable text item used by render objects that have multiple TextPainters.
class SelectableItem {
  const SelectableItem({
    required this.painter,
    required this.offset,
    required this.startTextOffset,
    required this.endTextOffset,
  });
  final TextPainter painter;
  final Offset offset;
  final int startTextOffset;
  final int endTextOffset;
}
