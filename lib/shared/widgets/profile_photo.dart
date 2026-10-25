import 'package:flutter/material.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// The user's round profile photo, or their initial on [background] while
/// there is none or it cannot be loaded.
class ProfilePhoto extends StatelessWidget {
  const ProfilePhoto({
    super.key,
    required this.url,
    required this.name,
    required this.size,
    this.background,
    this.foreground,
  });

  final String? url;
  final String name;
  final double size;
  final Color? background;
  final Color? foreground;

  static const imageKey = ValueKey('profile-photo-image');

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final initial = name.trim().isEmpty ? '' : name.trim().characters.first;
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        color: background ?? c.primaryLight,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: initial.isEmpty
            ? Icon(Icons.person_rounded,
                size: size * .5, color: foreground ?? c.primaryInk)
            : Text(
                initial,
                style: TextStyle(
                  color: foreground ?? c.primaryInk,
                  fontSize: size * .4,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
    final link = url;
    return SizedBox.square(
      dimension: size,
      child: link == null || link.isEmpty
          ? fallback
          : ClipOval(
              child: Image.network(
                link,
                key: imageKey,
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (_, __, ___) => fallback,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : fallback,
              ),
            ),
    );
  }
}
