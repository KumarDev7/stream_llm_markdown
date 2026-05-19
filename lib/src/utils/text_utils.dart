/// Strips a trailing high surrogate (U+D800..U+DBFF) from the end of [text]
/// to prevent dangling surrogates during streaming chunk boundaries.
String stripTrailingSurrogate(String text) {
  if (text.isNotEmpty) {
    final lastCodeUnit = text.codeUnitAt(text.length - 1);
    if (lastCodeUnit >= 0xD800 && lastCodeUnit <= 0xDBFF) {
      return text.substring(0, text.length - 1);
    }
  }
  return text;
}
