import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// Side of the uploaded photo, in pixels.
const avatarOutputSize = 512;

/// The part of the image, in image pixels, that shows through a square
/// [viewport] when the image is drawn at [baseScale] and then moved/zoomed by
/// [transform] (an [InteractiveViewer] value). Clamped to the image.
Rect avatarSourceRect({
  required Size image,
  required double viewport,
  required double baseScale,
  required Matrix4 transform,
}) {
  final scale = transform.getMaxScaleOnAxis() * baseScale;
  final translation = transform.getTranslation();
  final side = math.min(viewport / scale, math.min(image.width, image.height));
  final left =
      (-translation.x / scale).clamp(0.0, image.width - side).toDouble();
  final top =
      (-translation.y / scale).clamp(0.0, image.height - side).toDouble();
  return Rect.fromLTWH(left, top, side, side);
}

/// Pinch and drag a photo under a round window, then hand back a square PNG
/// of what the window shows (Salem review, issue 5). Pops with the PNG bytes,
/// or null when cancelled or the image cannot be read.
class AvatarCropScreen extends StatefulWidget {
  const AvatarCropScreen({super.key, required this.bytes});

  final Uint8List bytes;

  static const doneKey = ValueKey('avatar-crop-done');

  @override
  State<AvatarCropScreen> createState() => _AvatarCropScreenState();
}

class _AvatarCropScreenState extends State<AvatarCropScreen> {
  final _transform = TransformationController();
  ui.Image? _image;
  bool _failed = false;
  bool _saving = false;
  double? _viewport;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  Future<void> _decode() async {
    try {
      // Large camera photos are decoded at a sane size.
      final codec = await ui.instantiateImageCodec(
        widget.bytes,
        targetWidth: 2048,
        allowUpscaling: false,
      );
      final frame = await codec.getNextFrame();
      if (mounted) setState(() => _image = frame.image);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _transform.dispose();
    _image?.dispose();
    super.dispose();
  }

  double _baseScale(ui.Image image, double viewport) =>
      viewport / math.min(image.width, image.height);

  void _centre(ui.Image image, double viewport) {
    final scale = _baseScale(image, viewport);
    _transform.value = Matrix4.translationValues(
      (viewport - image.width * scale) / 2,
      (viewport - image.height * scale) / 2,
      0,
    );
  }

  Future<void> _done() async {
    final image = _image;
    final viewport = _viewport;
    if (image == null || viewport == null || _saving) return;
    setState(() => _saving = true);
    final source = avatarSourceRect(
      image: Size(image.width.toDouble(), image.height.toDouble()),
      viewport: viewport,
      baseScale: _baseScale(image, viewport),
      transform: _transform.value,
    );
    final recorder = ui.PictureRecorder();
    const out =
        Rect.fromLTWH(0, 0, avatarOutputSize + 0.0, avatarOutputSize + 0.0);
    Canvas(recorder, out).drawImageRect(
      image,
      source,
      out,
      Paint()..filterQuality = FilterQuality.high,
    );
    final picture = recorder.endRecording();
    final cropped = await picture.toImage(avatarOutputSize, avatarOutputSize);
    final png = await cropped.toByteData(format: ui.ImageByteFormat.png);
    cropped.dispose();
    picture.dispose();
    if (!mounted) return;
    Navigator.of(context).pop(png?.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.sirati;
    final image = _image;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: Text(l10n.settingsAvatarCropTitle),
      ),
      body: SafeArea(
        child: _failed
            ? Center(
                child: Text(
                  l10n.settingsAvatarOpenFailed,
                  style: TextStyle(color: c.textPrimary),
                ),
              )
            : image == null
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final viewport = math.min(
                            constraints.maxWidth,
                            constraints.maxHeight - 120,
                          ) -
                          32;
                      if (_viewport != viewport) {
                        _viewport = viewport;
                        _centre(image, viewport);
                      }
                      final scale = _baseScale(image, viewport);
                      return Column(
                        children: [
                          const Spacer(),
                          Center(
                            child: SizedBox.square(
                              dimension: viewport,
                              child: ClipRect(
                                child: Stack(
                                  children: [
                                    InteractiveViewer(
                                      key: const ValueKey('avatar-crop-viewer'),
                                      transformationController: _transform,
                                      constrained: false,
                                      minScale: 1,
                                      maxScale: 5,
                                      boundaryMargin: EdgeInsets.zero,
                                      child: SizedBox(
                                        width: image.width * scale,
                                        height: image.height * scale,
                                        child: RawImage(
                                          image: image,
                                          fit: BoxFit.fill,
                                        ),
                                      ),
                                    ),
                                    IgnorePointer(
                                      child: CustomPaint(
                                        size: Size.infinite,
                                        painter: _RoundWindow(
                                          shade: c.background
                                              .withValues(alpha: .6),
                                          ring: c.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(48),
                                      foregroundColor: c.textPrimary,
                                      side: BorderSide(color: c.borderStrong),
                                    ),
                                    child: Text(l10n.cancel),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: FilledButton(
                                    key: AvatarCropScreen.doneKey,
                                    onPressed: _saving ? null : _done,
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size.fromHeight(48),
                                      backgroundColor: c.primary,
                                      foregroundColor: c.onPrimary,
                                    ),
                                    child: Text(l10n.settingsAvatarUsePhoto),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
      ),
    );
  }
}

/// Darkens everything outside the round window the photo will be shown in.
class _RoundWindow extends CustomPainter {
  const _RoundWindow({required this.shade, required this.ring});

  final Color shade;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(rect),
        Path()..addOval(rect),
      ),
      Paint()..color = shade,
    );
    canvas.drawOval(
      rect.deflate(1),
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _RoundWindow oldDelegate) =>
      oldDelegate.shade != shade || oldDelegate.ring != ring;
}
