import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sirati/shared/models/ai_status.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/loading/branded_loader.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// Kind of multi-second AI work — drives staged reassurance copy.
enum AiProgressKind { generation, analysis }

/// Coarse phase of the server-side AI job.
///
/// Generation is queued server-side, so the client actually knows something
/// about where the work is instead of guessing from a timer. [queued] means the
/// record exists but a worker has not picked it up; [working] means the model is
/// producing the CV; [finalizing] covers scoring and persistence.
enum AiProgressPhase {
  queued,
  working,
  finalizing;

  /// Maps the API's `ai_status` string onto a phase.
  ///
  /// Anything that is not explicitly pending (completed, failed,
  /// not_configured) counts as [finalizing]: the job is off the queue and the
  /// caller is about to resolve the overlay one way or the other.
  static AiProgressPhase fromAiStatus(String aiStatus) {
    switch (aiStatus) {
      case AiStatus.queued:
        return AiProgressPhase.queued;
      case AiStatus.processing:
        return AiProgressPhase.working;
      default:
        return AiProgressPhase.finalizing;
    }
  }
}

/// Handle for a presented [AiProgressOverlay].
///
/// Call [dismiss] when the request finishes (success or failure). If the user
/// taps Cancel, [isCancelled] becomes true and the dialog is already closed.
/// While the request runs, push real server state with [setPhase] so the steps
/// reflect the job rather than a stopwatch.
class AiProgressHandle {
  AiProgressHandle._();

  // Not disposed on purpose: the overlay body may still be mid-frame when the
  // route pops, and these are two short-lived notifiers per generation.

  /// Listened to by the overlay body; safe to update before or after mount.
  final ValueNotifier<AiProgressPhase> _phase = ValueNotifier<AiProgressPhase>(
    AiProgressPhase.queued,
  );

  /// Drives the "everything is done" state before the dialog pops.
  final ValueNotifier<bool> _finished = ValueNotifier<bool>(false);

  BuildContext? _dialogContext;
  bool _cancelled = false;
  bool _closed = false;
  bool _pendingDismiss = false;

  bool get isCancelled => _cancelled;

  /// Reports real server progress. Phases only ever move forward, so a poll
  /// that briefly reports a stale status cannot make the UI walk backwards.
  void setPhase(AiProgressPhase phase) {
    if (_closed) return;
    if (phase.index <= _phase.value.index) return;
    _phase.value = phase;
  }

  /// Marks every step complete and lets the success state land before the
  /// caller navigates. Returns once the completion beat has been shown.
  Future<void> complete() async {
    if (_closed || _finished.value) return;
    _phase.value = AiProgressPhase.finalizing;
    _finished.value = true;
    await Future<void>.delayed(const Duration(milliseconds: 420));
  }

  /// Close the overlay if it is still open. Safe to call multiple times.
  Future<void> dismiss() async {
    if (_closed && !_pendingDismiss) return;
    _closed = true;
    final ctx = _dialogContext;
    _dialogContext = null;
    if (ctx != null && ctx.mounted) {
      _pendingDismiss = false;
      final nav = Navigator.of(ctx, rootNavigator: true);
      if (nav.canPop()) {
        nav.pop();
      }
    } else {
      _pendingDismiss = true;
    }
  }

  void _markCancelled() {
    _cancelled = true;
  }
}

/// Full-screen, dismissible-by-back AI progress overlay.
///
/// Shows reported server stages and an indeterminate bar until completion.
/// Elapsed time never completes a checklist item or implies a percentage.
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
        barrierColor: Theme.of(
          context,
        ).colorScheme.scrim.withValues(alpha: 0.55),
        transitionDuration: reduce ? Duration.zero : MotionDurations.medium,
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          handle._dialogContext = dialogContext;
          if (handle._pendingDismiss) {
            handle._pendingDismiss = false;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (dialogContext.mounted) {
                final nav = Navigator.of(dialogContext, rootNavigator: true);
                if (nav.canPop()) nav.pop();
              }
            });
          }
          return _AiProgressOverlayBody(
            kind: kind,
            english: english,
            phase: handle._phase,
            finished: handle._finished,
            onCancel: () {
              final alreadyCancelled = handle.isCancelled;
              handle._markCancelled();
              handle._closed = true;
              final ctx = handle._dialogContext ?? dialogContext;
              handle._dialogContext = null;
              if (ctx.mounted) {
                final nav = Navigator.of(ctx, rootNavigator: true);
                if (nav.canPop()) nav.pop();
              }
              if (!alreadyCancelled) {
                onCancelled?.call();
              }
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

  /// Step labels, one per [AiProgressPhase].
  static List<String> stageMessages(AiProgressKind kind, bool english) {
    switch (kind) {
      case AiProgressKind.generation:
        return english
            ? const [
                'Queued — waiting for a worker',
                'Writing your CV',
                'Saving your CV',
              ]
            : const [
                'في قائمة الانتظار',
                'كتابة سيرتك الذاتية',
                'حفظ سيرتك الذاتية',
              ];
      case AiProgressKind.analysis:
        return english
            ? const [
                'Reading your CV',
                'Scoring against ATS criteria',
                'Preparing your report',
              ]
            : const [
                'قراءة سيرتك الذاتية',
                'التقييم وفق معايير ATS',
                'إعداد تقريرك',
              ];
    }
  }

  static String longWaitMessage(bool english) => english
      ? 'This is taking longer than usual — still working…'
      : 'يستغرق هذا وقتًا أطول من المعتاد — لا يزال العمل جاريًا…';

  static String doneMessage(AiProgressKind kind, bool english) {
    switch (kind) {
      case AiProgressKind.generation:
        return english ? 'Your CV is ready' : 'سيرتك الذاتية جاهزة';
      case AiProgressKind.analysis:
        return english ? 'Your report is ready' : 'تقريرك جاهز';
    }
  }
}

class _AiProgressOverlayBody extends StatefulWidget {
  final AiProgressKind kind;
  final bool english;
  final ValueListenable<AiProgressPhase> phase;
  final ValueListenable<bool> finished;
  final VoidCallback onCancel;

  const _AiProgressOverlayBody({
    required this.kind,
    required this.english,
    required this.phase,
    required this.finished,
    required this.onCancel,
  });

  @override
  State<_AiProgressOverlayBody> createState() => _AiProgressOverlayBodyState();
}

class _AiProgressOverlayBodyState extends State<_AiProgressOverlayBody> {
  static const _longWaitAfter = Duration(seconds: 30);

  late final List<String> _steps;

  bool _longWait = false;

  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();
    _steps = AiProgressOverlay.stageMessages(widget.kind, widget.english);

    _timers.add(
      Timer(_longWaitAfter, () {
        if (!mounted) return;
        setState(() => _longWait = true);
      }),
    );
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

    // System back always cancels and dismisses the overlay immediately.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        widget.onCancel();
      },
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: widget.finished,
                    builder: (context, finished, _) {
                      return ValueListenableBuilder<AiProgressPhase>(
                        valueListenable: widget.phase,
                        builder: (context, phase, __) {
                          final step =
                              (finished ? _steps.length - 1 : phase.index)
                                  .clamp(0, _steps.length - 1);

                          return _card(
                            c: c,
                            en: en,
                            reduce: reduce,
                            step: step,
                            finished: finished,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card({
    required SiratiColors c,
    required bool en,
    required bool reduce,
    required int step,
    required bool finished,
  }) {
    final status = finished
        ? AiProgressOverlay.doneMessage(widget.kind, en)
        : _longWait
            ? AiProgressOverlay.longWaitMessage(en)
            : '${_steps[step]}…';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.border),
        boxShadow: AppShadows.of(c, elevation: AppElevation.dialog),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              liveRegion: true,
              label: finished
                  ? AiProgressOverlay.doneMessage(widget.kind, en)
                  : (en ? 'AI is working' : 'الذكاء الاصطناعي يعمل'),
              child: SizedBox(
                height: 96,
                child: Center(
                  child: finished
                      ? _DoneMark(reduce: reduce)
                      : BrandedLoader(size: 56, halo: !reduce),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            MotionStateSwitcher(
              stateKey: status,
              child: Text(
                status,
                textAlign: TextAlign.center,
                style: AppTypography.of(context, AppTypography.titleMd),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            LinearProgressIndicator(
              value: finished ? 1 : null,
              minHeight: 6,
              backgroundColor: c.primaryLight,
              color: c.primaryInk,
            ),
            const SizedBox(height: AppSpacing.md),
            for (var i = 0; i < _steps.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.xs),
              _StepRow(
                label: _steps[i],
                // The last step only ticks once the caller reports completion,
                // so the checklist never claims to be done before it is.
                done: finished || i < step,
                active: !finished && i == step,
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              en
                  ? 'Processing your request. This can take a little while.'
                  : 'جارٍ معالجة طلبك. قد يستغرق ذلك بعض الوقت.',
              textAlign: TextAlign.center,
              style: AppTypography.of(
                context,
                AppTypography.bodySm,
                color: c.textSecondary,
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppTouchTarget.min),
              child: finished
                  ? null
                  : Center(
                      child: TextButton(
                        onPressed: widget.onCancel,
                        style: TextButton.styleFrom(
                          foregroundColor: c.textSecondary,
                          minimumSize: const Size(88, AppTouchTarget.min),
                        ),
                        child: Text(
                          en ? 'Cancel' : 'إلغاء',
                          style: AppTypography.of(
                            context,
                            AppTypography.labelLg,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String label;
  final bool done;
  final bool active;

  const _StepRow({
    required this.label,
    required this.done,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final color = done
        ? c.textSecondary
        : active
            ? c.textPrimary
            : c.textSecondary;

    return Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: done
              ? Icon(Icons.check_circle_rounded, size: 18, color: c.primaryInk)
              : active
                  ? Padding(
                      padding: const EdgeInsets.all(2),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(c.primaryInk),
                      ),
                    )
                  : Icon(Icons.circle_outlined,
                      size: 16, color: c.textSecondary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.start,
            style: AppTypography.of(
              context,
              AppTypography.bodySm,
              color: color,
            ).copyWith(fontWeight: active ? FontWeight.w700 : FontWeight.w400),
          ),
        ),
      ],
    );
  }
}

/// Success mark shown in place of the loader once the work lands.
class _DoneMark extends StatelessWidget {
  final bool reduce;

  const _DoneMark({required this.reduce});

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final mark = Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: c.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: c.primary.withValues(alpha: 0.32),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(Icons.check_rounded, color: c.onPrimary, size: 34),
    );

    if (reduce) return mark;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.7, end: 1),
      duration: MotionDurations.slow,
      curve: MotionCurves.enter,
      builder: (context, value, child) =>
          Transform.scale(scale: value, child: child),
      child: mark,
    );
  }
}
