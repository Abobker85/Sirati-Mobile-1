import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:sirati/core/utils/bidi_text_utils.dart';

import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// Shared form chrome — soft error surfaces, professional borders, RTL-safe copy.
class AppFormStyles {
  AppFormStyles._();

  static const radius = 14.0;

  /// Content padding of a filled field that has a floating label: the label
  /// sits inside the fill, so less vertical padding keeps the field about as
  /// tall as an unlabelled one (and above the 48dp target).
  static const labelledPadding =
      EdgeInsets.symmetric(horizontal: 14, vertical: 8);

  /// Focus ring width on a filled field.
  static const focusRingWidth = 2.0;

  /// Error ring width on a filled field (resting / focused).
  static const errorRingWidth = 1.5;

  /// Inline field error text. The error-container ink holds AA on
  /// every page, on the field fills and on the soft error wash, in both
  /// themes (`error` itself drops to 4.4:1 on the light wash).
  static TextStyle errorTextStyle(SiratiColors c, {bool arabic = true}) =>
      AppTypography.bodySm
          .resolve(arabic: arabic, color: c.onErrorContainer)
          .copyWith(fontWeight: FontWeight.w600);

  static TextStyle successTextStyle(SiratiColors c) =>
      AppTypography.bodySm.resolve(arabic: true, color: c.onSuccessContainer);

  /// The soft red wash behind a field in error, over its [fill].
  static Color errorWash(SiratiColors c, Color fill) =>
      Color.alphaBlend(c.errorLight.withValues(alpha: .35), fill);

  /// The soft green wash behind a valid field, over its [fill].
  static Color successWash(SiratiColors c, Color fill) =>
      Color.alphaBlend(c.successLight.withValues(alpha: .35), fill);

  /// iOS 26 filled fields: [fill] with no resting outline; a primary-ink ring
  /// while focused and an error ring in error (the error text and icon carry
  /// the state too, so it never rests on colour alone).
  static InputDecorationTheme inputThemeFor(
    SiratiColors c, {
    bool arabic = true,
    required Color fill,
  }) {
    FilledFieldBorder ring(Color color, double width) =>
        FilledFieldBorder(borderSide: BorderSide(color: color, width: width));

    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      hoverColor: c.pressed(fill),
      border: const FilledFieldBorder(),
      enabledBorder: const FilledFieldBorder(),
      focusedBorder: ring(c.primaryInk, focusRingWidth),
      errorBorder: ring(c.error, errorRingWidth),
      focusedErrorBorder: ring(c.error, focusRingWidth),
      disabledBorder: const FilledFieldBorder(),
      labelStyle: WidgetStateTextStyle.resolveWith((states) {
        final base = AppTypography.bodyMd.resolve(arabic: arabic);
        if (states.contains(WidgetState.error)) {
          return base.copyWith(color: c.onErrorContainer);
        }
        if (states.contains(WidgetState.focused)) {
          return base.copyWith(color: c.primaryInk);
        }
        if (states.contains(WidgetState.disabled)) {
          return base.copyWith(color: c.textHint);
        }
        return base.copyWith(color: c.textSecondary);
      }),
      floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
        final base = AppTypography.bodySm.resolve(arabic: arabic);
        if (states.contains(WidgetState.error)) {
          return base.copyWith(color: c.onErrorContainer);
        }
        if (states.contains(WidgetState.focused)) {
          return base.copyWith(color: c.primaryInk);
        }
        if (states.contains(WidgetState.disabled)) {
          return base.copyWith(color: c.textHint);
        }
        return base.copyWith(color: c.textSecondary);
      }),
      hintStyle: AppTypography.bodyMd.resolve(
        arabic: arabic,
        color: c.textHint,
      ),
      errorStyle: errorTextStyle(c, arabic: arabic),
      errorMaxLines: 100,
      helperStyle: AppTypography.bodySm.resolve(
        arabic: arabic,
        color: c.textSecondary,
      ),
      prefixIconColor: c.textSecondary,
      suffixIconColor: c.textSecondary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    );
  }

  static InputDecoration decoration({
    String? hintText,
    String? labelText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool dense = false,
  }) {
    return InputDecoration(
      hintText: hintText,
      label: _tokenLabel(labelText),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      isDense: dense,
    );
  }
}

/// Rounded border of a filled field: no line at rest ([BorderSide.none]), a
/// ring of [borderSide] when given one.
///
/// Not an outline border, so the floating label rests inside the fill
/// rather than notching the top edge: every label sits on the fill colour.
class FilledFieldBorder extends InputBorder {
  const FilledFieldBorder({
    super.borderSide = BorderSide.none,
    this.borderRadius =
        const BorderRadius.all(Radius.circular(AppFormStyles.radius)),
  });

  final BorderRadius borderRadius;

  @override
  bool get isOutline => false;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(borderSide.width);

  @override
  FilledFieldBorder copyWith({
    BorderSide? borderSide,
    BorderRadius? borderRadius,
  }) =>
      FilledFieldBorder(
        borderSide: borderSide ?? this.borderSide,
        borderRadius: borderRadius ?? this.borderRadius,
      );

  @override
  ShapeBorder scale(double t) => FilledFieldBorder(
        borderSide: borderSide.scale(t),
        borderRadius: borderRadius * t,
      );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is FilledFieldBorder) {
      return FilledFieldBorder(
        borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
        borderRadius: BorderRadius.lerp(a.borderRadius, borderRadius, t)!,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is FilledFieldBorder) {
      return FilledFieldBorder(
        borderSide: BorderSide.lerp(borderSide, b.borderSide, t),
        borderRadius: BorderRadius.lerp(borderRadius, b.borderRadius, t)!,
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path()
    ..addRRect(
      borderRadius
          .resolve(textDirection)
          .toRRect(rect)
          .deflate(borderSide.width),
    );

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(borderRadius.resolve(textDirection).toRRect(rect));

  @override
  bool get preferPaintInterior => true;

  @override
  void paintInterior(
    Canvas canvas,
    Rect rect,
    Paint paint, {
    TextDirection? textDirection,
  }) {
    canvas.drawRRect(borderRadius.resolve(textDirection).toRRect(rect), paint);
  }

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    if (borderSide.style == BorderStyle.none || borderSide.width == 0) return;
    final ring = borderRadius
        .resolve(textDirection)
        .toRRect(rect)
        .deflate(borderSide.width / 2);
    canvas.drawRRect(ring, borderSide.toPaint());
  }

  @override
  bool operator ==(Object other) =>
      other is FilledFieldBorder &&
      other.borderSide == borderSide &&
      other.borderRadius == borderRadius;

  @override
  int get hashCode => Object.hash(borderSide, borderRadius);
}

/// Compact inline validation message with icon — modern SaaS style.
///
/// Animates in with a small fade + slide when it appears (respects
/// reduced-motion via [MotionSettings]).
class AppFieldError extends StatelessWidget {
  final String message;

  const AppFieldError({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final row = Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(top: 8, start: 2, end: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 18,
              height: 18,
              margin: const EdgeInsetsDirectional.only(top: 1),
              decoration: BoxDecoration(
                color: context.sirati.redLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 13,
                color: context.sirati.onErrorContainer,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                textAlign: TextAlign.start,
                style: AppFormStyles.errorTextStyle(context.sirati),
              ),
            ),
          ],
        ),
      ),
    );

    if (MotionSettings.reduce(context)) return row;

    // Fade + slight upward slide so the error feels like it *appears*,
    // instead of just expanding into space via the parent AnimatedSize.
    return TweenAnimationBuilder<double>(
      key: ValueKey(message),
      tween: Tween(begin: 0, end: 1),
      duration: MotionDurations.medium,
      curve: MotionCurves.enter,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * -4),
          child: child,
        ),
      ),
      child: row,
    );
  }
}

/// Soft banner above a form when submit is blocked by validation.
class AppFormErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  const AppFormErrorBanner({super.key, required this.message, this.onDismiss});

  /// How far it drifts down as it arrives.
  static const drift = 8.0;

  @override
  Widget build(BuildContext context) {
    // Arrives calmly once: fades in while drifting 8 px into place. No
    // shake, no flash.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration:
          MotionSettings.reduce(context) ? Duration.zero : MotionDurations.slow,
      curve: MotionCurves.enter,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, -drift * (1 - t)),
          child: child,
        ),
      ),
      child: _banner(context),
    );
  }

  Widget _banner(BuildContext context) {
    final reduce = MotionSettings.reduce(context);
    return AnimatedSize(
      duration: reduce ? Duration.zero : MotionDurations.fast,
      curve: MotionCurves.state,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.sirati.errorLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.sirati.red.withValues(alpha: .22)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 20,
              color: context.sirati.red,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                textAlign: TextAlign.start,
                // Banner sits on errorLight: use the gated container pair.
                style: AppFormStyles.errorTextStyle(
                  context.sirati,
                ).copyWith(color: context.sirati.onErrorContainer),
              ),
            ),
            if (onDismiss != null)
              IconButton(
                onPressed: onDismiss,
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: context.sirati.red,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Soft green banner mirroring [AppFormErrorBanner] — use for inline
/// confirmations (e.g. "Reset link sent") without opening a snackbar.
class AppFormSuccessBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final IconData icon;

  const AppFormSuccessBanner({
    super.key,
    required this.message,
    this.onDismiss,
    this.icon = Icons.check_circle_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final reduce = MotionSettings.reduce(context);
    return AnimatedSize(
      duration: reduce ? Duration.zero : MotionDurations.fast,
      curve: MotionCurves.state,
      child: TweenAnimationBuilder<double>(
        key: ValueKey(message),
        tween: Tween(begin: 0, end: 1),
        duration: reduce ? Duration.zero : MotionDurations.medium,
        curve: MotionCurves.enter,
        builder: (context, t, child) => Opacity(
          opacity: reduce ? 1 : t,
          child: Transform.translate(
            offset: Offset(
              0,
              reduce ? 0 : (1 - t) * -4,
            ),
            child: child,
          ),
        ),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: context.sirati.successLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: context.sirati.success.withValues(alpha: .35),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22, color: context.sirati.success),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  textAlign: TextAlign.start,
                  style: AppTypography.of(
                    context,
                    AppTypography.bodySm,
                    color: context.sirati.onSuccessContainer,
                  ),
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  onPressed: onDismiss,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: context.sirati.success,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Text field with soft feedback fills and native, attached validation errors.
///
/// **Validation policy:** by default the field stays quiet while typing. Errors
/// appear only after **focus is lost** (blur), then re-validate on each change
/// ([AutovalidateMode.onUserInteraction] after first blur). Pass an explicit
/// [autovalidateMode] to override (e.g. after form submit).
class AppTextFormField extends FormField<String> {
  AppTextFormField({
    super.key,
    this.controller,
    String? initialValue,
    super.validator,
    super.onSaved,
    AutovalidateMode? autovalidateMode,
    String? hintText,
    String? labelText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    bool enabled = true,
    // Nullable so callers can pass `maxLines: null` for a fully auto-growing
    // multiline field (e.g. CV paste). Defaults to 1 (single-line).
    int? maxLines = 1,
    int? minLines,
    int? maxLength,
    bool readOnly = false,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onFieldSubmitted,

    /// Called when the field loses focus after the user interacted with it.
    this.onFocusLost,

    /// Called when the field becomes valid after blur / post-blur typing.
    this.onBecameValid,
    TextAlign textAlign = TextAlign.start,
    TextDirection? textDirection,
    this.focusNode,

    /// Platform autofill tokens (wrap the form in [AutofillGroup] for best results).
    this.autofillHints,
    bool filled = true,
    EdgeInsetsGeometry? contentPadding,

    /// When true, draws a soft red wash behind the field on error.
    bool softErrorFill = true,

    /// Soft green chrome + check when the field is non-empty and valid
    /// (after first blur, or when [autovalidateMode] forces validation).
    this.showSuccessWhenValid = false,
    this.successMessage,

    /// A small check draws at the field's end the first time it becomes
    /// valid with text in it, then fades away: quiet encouragement for long
    /// forms that do not use [showSuccessWhenValid].
    this.tickWhenValid = false,
  })  : _autovalidateMode = autovalidateMode,
        super(
          initialValue:
              controller != null ? controller.text : (initialValue ?? ''),
          // Always disabled at FormField level — blur / manual validate control
          // when errors appear (avoids premature flashing while typing).
          autovalidateMode: AutovalidateMode.disabled,
          builder: (FormFieldState<String> field) {
            final state = field as _AppTextFormFieldState;
            return state.buildField(
              hintText: hintText,
              labelText: labelText,
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              textCapitalization: textCapitalization,
              inputFormatters: inputFormatters,
              obscureText: obscureText,
              enabled: enabled,
              maxLines: maxLines,
              minLines: minLines,
              maxLength: maxLength,
              readOnly: readOnly,
              onChanged: onChanged,
              onFieldSubmitted: onFieldSubmitted,
              textAlign: textAlign,
              textDirection: textDirection,
              filled: filled,
              contentPadding: contentPadding,
              softErrorFill: softErrorFill,
            );
          },
        );

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool showSuccessWhenValid;
  final String? successMessage;
  final bool tickWhenValid;
  final List<String>? autofillHints;
  final ValueChanged<String>? onFocusLost;
  final ValueChanged<String>? onBecameValid;

  /// Explicit mode from the caller, if any. `null` → blur-first policy.
  final AutovalidateMode? _autovalidateMode;

  AutovalidateMode get fieldAutovalidateMode =>
      _autovalidateMode ?? AutovalidateMode.disabled;

  @override
  FormFieldState<String> createState() => _AppTextFormFieldState();
}

class _AppTextFormFieldState extends FormFieldState<String> {
  TextEditingController? _localController;
  FocusNode? _ownedFocusNode;
  bool _hasFocus = false;

  /// After first unfocus, re-validate on each keystroke (onUserInteraction).
  bool _blurredOnce = false;
  bool _wasValid = false;

  /// The valid tick has played (once per field) / is showing now.
  bool _ticked = false;
  bool _showTick = false;

  /// Set when a focused edit fails the validator, until the next frame. A
  /// Form that autovalidates (onUserInteraction after a submit) re-runs
  /// [validate] on every keystroke; while this is set and the field keeps
  /// focus, that call keeps the current error state instead (forgive while
  /// editing). Blur and submit validate normally.
  bool _holdFormValidation = false;

  void _becameValid(String text) {
    widget.onBecameValid?.call(text);
    if (!widget.tickWhenValid || _ticked || text.trim().isEmpty) return;
    _ticked = true;
    if (mounted) setState(() => _showTick = true);
  }

  TextEditingController get _effectiveController =>
      widget.controller ?? _localController!;

  FocusNode get _focusNode => widget.focusNode ?? _ownedFocusNode!;

  @override
  AppTextFormField get widget => super.widget as AppTextFormField;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _localController = TextEditingController(text: widget.initialValue);
    } else {
      widget.controller!.addListener(_handleControllerChanged);
    }
    if (widget.focusNode == null) {
      _ownedFocusNode = FocusNode(debugLabel: 'AppTextFormField');
    }
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant AppTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_handleControllerChanged);
      widget.controller?.addListener(_handleControllerChanged);
      if (oldWidget.controller != null && widget.controller == null) {
        _localController = TextEditingController.fromValue(
          oldWidget.controller!.value,
        );
      }
      if (widget.controller != null) {
        setValue(widget.controller!.text);
        if (oldWidget.controller == null) {
          _localController?.dispose();
          _localController = null;
        }
      }
    }
    if (widget.focusNode != oldWidget.focusNode) {
      (oldWidget.focusNode ?? _ownedFocusNode)?.removeListener(_onFocusChange);
      if (widget.focusNode == null && _ownedFocusNode == null) {
        _ownedFocusNode = FocusNode(debugLabel: 'AppTextFormField');
      }
      if (widget.focusNode != null && oldWidget.focusNode == null) {
        _ownedFocusNode?.dispose();
        _ownedFocusNode = null;
      }
      _focusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    widget.controller?.removeListener(_handleControllerChanged);
    _localController?.dispose();
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    final hasFocus = _focusNode.hasFocus;
    if (_hasFocus == hasFocus) return;

    setState(() => _hasFocus = hasFocus);

    // Strict policy: validate only after focus is lost.
    if (!hasFocus) {
      final text = _effectiveController.text;
      _blurredOnce = true;
      final ok = validate();
      widget.onFocusLost?.call(text);
      if (ok && !_wasValid) {
        _wasValid = true;
        _becameValid(text);
      } else if (!ok) {
        _wasValid = false;
      }
    }
  }

  @override
  void didChange(String? value) {
    super.didChange(value);
    if (_effectiveController.text != value) {
      _effectiveController.value = TextEditingValue(
        text: value ?? '',
        selection: TextSelection.collapsed(offset: (value ?? '').length),
      );
    }
    // After first blur: re-validate as the user types (onUserInteraction).
    // Before first blur: stay quiet — no error flash while typing.
    // An explicit always / onUserInteraction (e.g. after a submit) validates
    // live without waiting for a blur.
    final forceAlways = widget._autovalidateMode == AutovalidateMode.always ||
        widget._autovalidateMode == AutovalidateMode.onUserInteraction;
    // Forgive while editing: as long as the field has focus, typing may
    // clear an error but never add one or change its message. New errors
    // show on blur or submit (the rules themselves are unchanged). This also
    // holds back a parent Form that autovalidates on user interaction.
    final failsWhileFocused =
        _focusNode.hasFocus && widget.validator?.call(value) != null;
    if (failsWhileFocused) {
      _holdFormValidation = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _holdFormValidation = false,
      );
    }
    if (_blurredOnce || forceAlways) {
      if (failsWhileFocused) {
        _wasValid = false;
        return;
      }
      final ok = validate();
      if (ok && !_wasValid) {
        _wasValid = true;
        _becameValid(value ?? '');
      } else if (!ok) {
        _wasValid = false;
      }
    }
  }

  @override
  bool validate() {
    // Only the Form's autovalidation, which runs while the Form builds, is
    // held. A submit's Form.validate() (an event handler) always validates.
    final inBuild = SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks;
    if (_holdFormValidation && _focusNode.hasFocus && inBuild) {
      return !hasError;
    }
    return super.validate();
  }

  @override
  void reset() {
    super.reset();
    _blurredOnce = false;
    _wasValid = false;
    _effectiveController.text = widget.initialValue ?? '';
  }

  void _handleControllerChanged() {
    if (_effectiveController.text != value) {
      didChange(_effectiveController.text);
    }
  }

  bool _isShowingSuccess() {
    if (!widget.showSuccessWhenValid) return false;
    // Never show success chrome before the first blur (unless always mode).
    // An explicit always / onUserInteraction (e.g. after a submit) validates
    // live without waiting for a blur.
    final forceAlways = widget._autovalidateMode == AutovalidateMode.always ||
        widget._autovalidateMode == AutovalidateMode.onUserInteraction;
    if (!_blurredOnce && !forceAlways) return false;
    final text = value?.trim() ?? '';
    if (text.isEmpty) return false;
    if (hasError && (errorText?.isNotEmpty ?? false)) return false;
    final validator = widget.validator;
    if (validator != null && validator(value) != null) return false;
    return true;
  }

  Widget buildField({
    String? hintText,
    String? labelText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    bool enabled = true,
    int? maxLines = 1,
    int? minLines,
    int? maxLength,
    bool readOnly = false,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onFieldSubmitted,
    TextAlign textAlign = TextAlign.start,
    TextDirection? textDirection,
    bool filled = true,
    EdgeInsetsGeometry? contentPadding,
    bool softErrorFill = true,
  }) {
    final showError = hasError && (errorText?.isNotEmpty ?? false);
    final showSuccess = !showError && _isShowingSuccess();
    // An error or success mark that takes the suffix slot ends the tick for
    // good: it plays once per field and must not replay when the slot frees.
    if (showError || showSuccess) _showTick = false;

    final c = context.sirati;
    final base = PageSurface.fillOf(context);
    final fill = showError && softErrorFill
        ? AppFormStyles.errorWash(c, base)
        : showSuccess
            ? AppFormStyles.successWash(c, base)
            : base;
    final resolvedSuffix = showError || showSuccess
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (suffixIcon != null) suffixIcon,
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 10),
                // The error or success mark pops in as it appears.
                child: MotionMorph(
                  morphKey: showError,
                  child: Icon(
                    showError
                        ? Icons.error_outline_rounded
                        : Icons.check_circle_rounded,
                    size: 20,
                    color: showError ? c.error : c.success,
                  ),
                ),
              ),
            ],
          )
        : _showTick
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (suffixIcon != null) suffixIcon,
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 12),
                    child: ValidTick(
                      onDone: () {
                        if (mounted) setState(() => _showTick = false);
                      },
                    ),
                  ),
                ],
              )
            : suffixIcon;
    final successBorder = FilledFieldBorder(
      borderSide: BorderSide(
        color: c.success,
        width: AppFormStyles.errorRingWidth,
      ),
    );

    // A new error shakes the field once (also when a submit finds it).
    return ErrorShake(
      errorKey: showError ? errorText : null,
      child: TextField(
        controller: _effectiveController,
        focusNode: _focusNode,
        enabled: enabled,
        readOnly: readOnly,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        autofillHints: widget.autofillHints,
        maxLines: obscureText ? 1 : maxLines,
        minLines: minLines,
        maxLength: maxLength,
        textAlign: textAlign,
        textDirection: textDirection ??
            BidiTextUtils.detectBaseDirection(
              _effectiveController.text,
              fallback: Directionality.of(context),
            ),
        // Room under the field so its error line and the next field stay
        // visible above the keyboard and any footer.
        scrollPadding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          math.min(120, MediaQuery.sizeOf(context).height * .2),
        ),
        style: AppTypography.of(context, AppTypography.bodyLg),
        cursorColor: c.primaryInk,
        onChanged: (value) {
          didChange(value);
          onChanged?.call(value);
        },
        onSubmitted: onFieldSubmitted,
        decoration: InputDecoration(
          hintText: hintText,
          // An explicit text direction (phone, email) also governs the hint, so
          // "+966 5X XXX XXXX" is not bidi-reordered inside an Arabic UI.
          hintTextDirection: textDirection,
          label: _tokenLabel(labelText),
          // The field's icon takes its state's colour smoothly and lifts a
          // little while the field has focus.
          prefixIcon: prefixIcon == null
              ? null
              : TweenAnimationBuilder<Color?>(
                  tween: ColorTween(
                    end: showError
                        ? c.error
                        : showSuccess
                            ? c.success
                            : _hasFocus
                                ? c.primaryInk
                                : c.textSecondary,
                  ),
                  duration: MotionSettings.reduce(context)
                      ? Duration.zero
                      : MotionDurations.medium,
                  builder: (context, color, child) => IconTheme(
                    data: IconThemeData(color: color, size: 20),
                    child: child!,
                  ),
                  child: AnimatedScale(
                    scale:
                        _hasFocus && !MotionSettings.reduce(context) ? 1.1 : 1,
                    duration: MotionDurations.medium,
                    curve: MotionCurves.settle,
                    child: prefixIcon,
                  ),
                ),
          suffixIcon: resolvedSuffix,
          filled: filled,
          fillColor: fill,
          enabledBorder: showSuccess ? successBorder : null,
          focusedBorder: showSuccess ? successBorder : null,
          // A filled field's label floats inside the fill, so a labelled
          // field trims its vertical padding to keep the old height.
          contentPadding: contentPadding ??
              (labelText == null
                  ? const EdgeInsets.symmetric(horizontal: 14, vertical: 14)
                  : AppFormStyles.labelledPadding),
          // Native errors are associated with the editable semantics node and
          // announced by InputDecorator's live region, including on submit.
          errorText: showError ? errorText : null,
          errorMaxLines: 100,
          helperText: showSuccess ? widget.successMessage : null,
          helperMaxLines: 100,
          helperStyle: AppTypography.of(
            context,
            AppTypography.bodySm,
            color: c.onSuccessContainer,
          ),
          counterText: '',
        ),
      ),
    );
  }
}

/// Label widget that inherits the decoration's resolved (floating/focused) style but replaces Flutter's
/// hard-coded `height: 1` with the typography token's line height.
Widget? _tokenLabel(String? text) {
  if (text == null) return null;
  return Builder(
    builder: (context) => Text(
      text,
      style: DefaultTextStyle.of(context).style.copyWith(
            height: AppTypography.of(context, AppTypography.bodyMd).height,
          ),
    ),
  );
}

/// A check that draws itself in, holds, then fades away, and tells
/// [onDone]. With reduced motion it does not show at all.
class ValidTick extends StatefulWidget {
  const ValidTick({super.key, required this.onDone});

  final VoidCallback onDone;

  /// Draw, hold and fade.
  static const duration = Duration(milliseconds: 1400);

  @override
  State<ValidTick> createState() => _ValidTickState();
}

class _ValidTickState extends State<ValidTick>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: ValidTick.duration);

  static const _draw = Interval(0, .2, curve: MotionCurves.enter);
  static const _fade = Interval(.75, 1, curve: MotionCurves.exit);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isAnimating || _c.isCompleted) return;
    if (MotionSettings.reduce(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDone());
      _c.value = 1;
      return;
    }
    _c.forward().whenComplete(() {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = context.sirati.success;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Opacity(
          opacity: 1 - _fade.transform(_c.value),
          child: CustomPaint(
            size: const Size.square(16),
            painter: _TickPainter(
              progress: _draw.transform(_c.value),
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _TickPainter extends CustomPainter {
  _TickPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final path = Path()
      ..moveTo(size.width * .15, size.height * .55)
      ..lineTo(size.width * .42, size.height * .8)
      ..lineTo(size.width * .88, size.height * .25);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_TickPainter old) =>
      old.progress != progress || old.color != color;
}
