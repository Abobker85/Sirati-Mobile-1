import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sirati/core/utils/bidi_text_utils.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// Shared form chrome — soft error surfaces, professional borders, RTL-safe copy.
class AppFormStyles {
  AppFormStyles._();

  static const radius = 14.0;

  /// Inline field error text. `error` on surface/background is a gated AA
  /// pair in both themes (the old static style was light-only).
  static TextStyle errorTextStyle(SiratiColors c, {bool arabic = true}) =>
      AppTypography.bodySm
          .resolve(arabic: arabic, color: c.error)
          .copyWith(fontWeight: FontWeight.w600);

  static TextStyle successTextStyle(SiratiColors c) =>
      AppTypography.bodySm.resolve(arabic: true, color: c.onSuccessContainer);

  static InputDecorationTheme inputThemeFor(
    SiratiColors c, {
    bool arabic = true,
  }) {
    OutlineInputBorder o(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      hoverColor: c.surfaceLow,
      border: o(c.outline, 1),
      enabledBorder: o(c.outline, 1),
      focusedBorder: o(c.primaryInk, 1.8),
      errorBorder: o(c.error, 1.4),
      focusedErrorBorder: o(c.error, 1.8),
      disabledBorder: o(c.outline, 1),
      labelStyle: WidgetStateTextStyle.resolveWith((states) {
        final base = AppTypography.bodyMd.resolve(arabic: arabic);
        if (states.contains(WidgetState.error)) {
          return base.copyWith(color: c.error);
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
          return base.copyWith(color: c.error);
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

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: MotionDurations.fast,
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
    return AnimatedSize(
      duration: MotionDurations.fast,
      curve: MotionCurves.state,
      child: TweenAnimationBuilder<double>(
        key: ValueKey(message),
        tween: Tween(begin: 0, end: 1),
        duration: MotionDurations.medium,
        curve: MotionCurves.enter,
        builder: (context, t, child) => Opacity(
          opacity: MotionSettings.reduce(context) ? 1 : t,
          child: Transform.translate(
            offset: Offset(
              0,
              MotionSettings.reduce(context) ? 0 : (1 - t) * -4,
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
    final forceAlways = widget._autovalidateMode == AutovalidateMode.always;
    if (_blurredOnce || forceAlways) {
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
    final forceAlways = widget._autovalidateMode == AutovalidateMode.always;
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

    final c = context.sirati;
    final fill = showError && softErrorFill
        ? Color.alphaBlend(c.errorLight.withValues(alpha: .35), c.surface)
        : showSuccess
            ? Color.alphaBlend(c.successLight.withValues(alpha: .35), c.surface)
            : c.surface;
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
    final successBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppFormStyles.radius),
      borderSide: BorderSide(color: c.success, width: 1.4),
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
                    curve: MotionCurves.pop,
                    child: prefixIcon,
                  ),
                ),
          suffixIcon: resolvedSuffix,
          filled: filled,
          fillColor: fill,
          enabledBorder: showSuccess ? successBorder : null,
          focusedBorder: showSuccess ? successBorder : null,
          contentPadding: contentPadding ??
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
