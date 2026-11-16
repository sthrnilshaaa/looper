import 'package:flutter/material.dart';

/// [text] on one line with every case-insensitive occurrence of [query] in
/// [highlightStyle] and the rest in [baseStyle].
Widget highlightedText({
  required String text,
  required String query,
  required TextStyle baseStyle,
  required TextStyle highlightStyle,
}) {
  if (query.isEmpty) {
    return Text(text, style: baseStyle);
  }

  final lowerText = text.toLowerCase();
  final lowerQuery = query.toLowerCase();
  final index = lowerText.indexOf(lowerQuery);

  if (index == -1) {
    return Text(text, style: baseStyle);
  }

  final List<TextSpan> spans = [];
  int start = 0;
  int indexOfMatch;

  while ((indexOfMatch = lowerText.indexOf(lowerQuery, start)) != -1) {
    if (indexOfMatch > start) {
      spans.add(
        TextSpan(text: text.substring(start, indexOfMatch), style: baseStyle),
      );
    }
    spans.add(
      TextSpan(
        text: text.substring(indexOfMatch, indexOfMatch + query.length),
        style: highlightStyle,
      ),
    );
    start = indexOfMatch + query.length;
  }

  if (start < text.length) {
    spans.add(TextSpan(text: text.substring(start), style: baseStyle));
  }

  return RichText(
    text: TextSpan(children: spans),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}
