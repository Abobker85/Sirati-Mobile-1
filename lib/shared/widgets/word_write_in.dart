import 'dart:async';
import 'dart:math' as math;

/// Writes text into a field a few whole words at a time, so AI text looks
/// written rather than pasted. Words are never split, so Arabic letters stay
/// joined.
///
/// It takes about [perWord] a word and never longer than [maxDuration]. If
/// someone else changes the field meanwhile (the user types, or Undo), it
/// stops and leaves their text alone.
class WordWriteIn {
  WordWriteIn._(this._frames, this._write, this._current);

  /// Time per frame.
  static const step = Duration(milliseconds: 30);

  /// Pace for short texts.
  static const perWord = Duration(milliseconds: 18);

  /// The whole write-in never takes longer than this.
  static const maxDuration = Duration(milliseconds: 900);

  final List<String> _frames;
  final void Function(String) _write;
  final String Function() _current;
  Timer? _timer;
  int _next = 0;
  String? _last;

  /// Whether it is still writing.
  bool get active => _timer != null;

  /// The texts shown, frame by frame: growing by whole words, ending with
  /// [text] exactly. Empty or one-word text is a single frame.
  static List<String> framesFor(String text) {
    final ends = [
      for (final m in RegExp(r'\s*\S+').allMatches(text)) m.end,
    ];
    if (ends.length <= 1) return [text];
    final words = ends.length;
    final totalMs = math.min(
      maxDuration.inMilliseconds,
      words * perWord.inMilliseconds,
    );
    final count = math.max(1, totalMs ~/ step.inMilliseconds);
    final perFrame = (words / count).ceil();
    return [
      for (var w = perFrame; w < words; w += perFrame)
        text.substring(0, ends[w - 1]),
      text,
    ];
  }

  /// Starts writing [text] through [write]. [current] reads the field, to
  /// notice someone else's change. Without [animate] (reduced motion, a
  /// screen reader) the whole text is written at once.
  static WordWriteIn start({
    required String text,
    required void Function(String) write,
    required String Function() current,
    required bool animate,
  }) {
    final frames = animate ? framesFor(text) : [text];
    final writer = WordWriteIn._(frames, write, current);
    writer._tick();
    if (writer._next < frames.length) {
      writer._timer = Timer.periodic(step, (_) => writer._tick());
    }
    return writer;
  }

  void _tick() {
    if (_last != null && _current() != _last) {
      cancel();
      return;
    }
    final frame = _frames[_next++];
    _last = frame;
    _write(frame);
    if (_next >= _frames.length) cancel();
  }

  /// Stops without writing anything more.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
