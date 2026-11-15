import 'package:flutter/widgets.dart';
import 'package:sirati/core/utils/bidi_text_utils.dart';

/// Chooses a text field's direction without flipping it mid-typing.
///
/// The direction is decided from the text (its first strong character, via
/// [BidiTextUtils.detectBaseDirection]) only when the field is not focused,
/// or when typing starts in an empty field. While the user keeps typing it
/// stays put, so "مطور Flutter" or "Flutter مطور" no longer jumps sides
/// with every word, and the caret stays where it was.
class StickyTextDirection {
  TextDirection? _direction;
  bool _wasEmpty = true;

  /// The direction for [text] now.
  TextDirection resolve(
    String text, {
    required bool focused,
    required TextDirection fallback,
  }) {
    final empty = text.trim().isEmpty;
    final current = _direction;
    final TextDirection direction;
    if (current == null || !focused || _wasEmpty || empty) {
      direction = BidiTextUtils.detectBaseDirection(text, fallback: fallback);
    } else {
      direction = current;
    }
    _direction = direction;
    _wasEmpty = empty;
    return direction;
  }
}
