import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../motion.dart';
import 'branded_loader.dart';

/// Kind of multi-second AI work — drives staged reassurance copy.
enum AiProgressKind { generation, analysis }

/// Handle for a presented [AiProgressOverlay].
///
/// Call [dismiss] when the request finishes (success or failure). If the user
/// taps Cancel, [isCancelled] becomes true and the dialog is already closed.
class AiProgressHandle {
  AiProgressHandle._();

  BuildContext? _dialogContext;
  bool _cancelled = false;
  bool _closed = false;

  bool get isCancelled => _cancelled;

  /// Close the overlay if it is still open. Safe to call multiple times.
  Future<void> dismiss() async {
    if (_closed) return;
    _closed = true;
    final ctx = _dialogContext;
    _dialogContext = null;
    if (ctx != null && ctx.mounted) {
      final nav = Navigator.of(ctx, rootNavigator: true);
      if (nav.canPop()) {
        nav.pop();
      }
    }
  }

  void _markCancelled() {
    _cancelled = true;
  }
}

/// Full-screen, non-dismissible-by-tap AI progress overlay.
///
/// Staged status lines are reassurance only (not real progress). Cancel is
/// enabled after 3s; after 30s the copy switches to a soft “taking longer”
/// message while the request continues.
class AiProgressOverlay {
  AiProgressOverlay._();

  /// Presents the overlay and returns a handle. Does not wait for dismissal.
  static Future<AiProgressHandle> show(
    BuildContext context, {
    required AiProgressKind kind,
    required bool english,
    VoidCallback? onCancelled,
  }) async {
    final handle = AiProgressHandle._();
    final reduce = MotionSettings.reduce(context);

    // Fire-and-forget dialog; caller keeps working and dismisses via [handle].
    unawaited(
      showGeneralDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        barrierLabel: english ? 'AI progress' : 'تقدم الذكاء الاصطناعي',
        barrierColor: Colors.black.withValues(alpha: 0.55),
        transitionDuration: reduce ? Duration.zero : MotionDurations.medium,
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          handle._dialogContext = dialogContext;
          return _AiProgressOverlayBody(
            kind: kind,
            english: english,
            onCancel: () {
              if (handle.isCancelled || handle._closed) return;
              handle._markCancelled();
              handle._closed = true;
              handle._dialogContext = null;
              final nav = Navigator.of(dialogContext, rootNavigator: true);
              if (nav.canPop()) nav.pop();
              onCancelled?.call();
            },
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          if (reduce) return child;
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: MotionCurves.enter,
              reverseCurve: MotionCurves.exit,
            ),
            child: child,
          );
        },
      ).whenComplete(() {
        handle._closed = true;
        handle._dialogContext = null;
      }),
    );

    // Let the dialog route insert before the caller starts the network work.
    await Future<void>.delayed(Duration.zero);
    return handle;
  }

  /// Staged reassurance copy (0s / 4s / 9s).
  static List<String> stageMessages(AiProgressKind kind, bool english) {
    switch (kind) {
      case AiProgressKind.generation:
        return english
            ? const [
                'Structuring your information…',
                'Writing your CV…',
                'Polishing the layout…',
              ]
            : const [
                'جارٍ تنظيم معلوماتك…',
                'جارٍ كتابة سيرتك…',
                'جارٍ تحسين التنسيق…',
              ];
      case AiProgressKind.analysis:
        return english
            ? const [
                'Reading your CV…',
                'Scoring against ATS criteria…',
                'Preparing your report…',
              ]
            : const [
                'جارٍ قراءة سيرتك…',
                'جارٍ التقييم وفق معايير ATS…',
                'جارٍ إعداد تقريرك…',
              ];
    }
  }

  static String longWaitMessage(bool english) => english
      ? 'This is taking longer than usual…'
      : 'يستغرق هذا وقتًا أطول من المعتاد…';
}

class _AiProgressOverlayBody extends StatefulWidget {
  final AiProgressKind kind;
  final bool english;
  final VoidCallback onCancel;

  const _AiProgressOverlayBody({
    required this.kind,
    required this.english,
    required this.onCancel,
  });

  @override
  State<_AiProgressOverlayBody> createState() => _AiProgressOverlayBodyState();
}

class _AiProgressOverlayBodyState extends State<_AiProgressOverlayBody> {
  static const _stageDelays = [
    Duration.zero,
    Duration(seconds: 4),
    Duration(seconds: 9),
  ];
  static const _cancelAfter = Duration(seconds: 3);
  static const _longWaitAfter = Duration(seconds: 30);

  late final List<String> _stages;
  late String _status;
  Object _statusKey = 0;
  bool _cancelEnabled = false;
  bool _longWait = false;

  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();
    _stages = AiProgressOverlay.stageMessages(widget.kind, widget.english);
    _status = _stages.first;
    _statusKey = 0;

    for (var i = 1; i < _stages.length && i < _stageDelays.length; i++) {
      final index = i;
      _timers.add(Timer(_stageDelays[index], () {
        if (!mounted || _longWait) return;
        setState(() {
          _status = _stages[index];
          _statusKey = index;
        });
      }));
    }

    _timers.add(Timer(_cancelAfter, () {
      if (!mounted) return;
      setState(() => _cancelEnabled = true);
    }));

    _timers.add(Timer(_longWaitAfter, () {
      if (!mounted) return;
      setState(() {
        _longWait = true;
        _status = AiProgressOverlay.longWaitMessage(widget.english);
        _statusKey = 'long_wait';
      });
    }));
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final en = widget.english;
    final reduce = MotionSettings.reduce(context);

    // Block system back until Cancel is available; then back == cancel.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_cancelEnabled) widget.onCancel();
      },
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.border),
                    boxShadow: c.softShadow,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Semantics(
                          liveRegion: true,
                          label: en
                              ? 'AI is working'
                              : 'الذكاء الاصطناعي يعمل',
                          child: BrandedLoader(size: 64, halo: !reduce),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        // Crossfade staged lines via MotionStateSwitcher.
                        MotionStateSwitcher(
                          stateKey: _statusKey,
                          child: Text(
                            _status,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.45,
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          en
                              ? 'Please keep the app open'
                              : 'يرجى إبقاء التطبيق مفتوحاً',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                            color: c.textHint,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AnimatedOpacity(
                          opacity: _cancelEnabled ? 1 : 0.35,
                          duration: reduce
                              ? Duration.zero
                              : MotionDurations.medium,
                          child: TextButton(
                            onPressed: _cancelEnabled ? widget.onCancel : null,
                            style: TextButton.styleFrom(
                              foregroundColor: c.textSecondary,
                              disabledForegroundColor:
                                  c.textHint.withValues(alpha: .5),
                              minimumSize: const Size(88, 40),
                            ),
                            child: Text(
                              en ? 'Cancel' : 'إلغاء',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
