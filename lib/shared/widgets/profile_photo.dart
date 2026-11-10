import 'package:flutter/material.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// The user's round profile photo, or their initial on [background] while
/// there is none or it cannot be loaded. A Premium account gets a gold ring
/// and a badge at the top end corner.
class ProfilePhoto extends StatelessWidget {
  const ProfilePhoto({
    super.key,
    required this.url,
    required this.name,
    required this.size,
    this.background,
    this.foreground,
    this.premium = false,
  });

  final String? url;
  final String name;
  final double size;
  final Color? background;
  final Color? foreground;

  /// Shows the Premium ring and badge.
  final bool premium;

  static const imageKey = ValueKey('profile-photo-image');
  static const premiumBadgeKey = ValueKey('profile-photo-premium-badge');

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
    final photo = SizedBox.square(
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
    if (!premium) return photo;

    final ring = (size * .04).clamp(2.0, 4.0);
    final badge = (size * .38).clamp(18.0, 32.0);
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: c.amberAccent, width: ring),
              ),
              child: photo,
            ),
          ),
          PositionedDirectional(
            top: -badge * .15,
            end: -badge * .15,
            child: Semantics(
              label: AppLocalizations.of(context).premiumBadgeLabel,
              child: Container(
                key: premiumBadgeKey,
                width: badge,
                height: badge,
                decoration: BoxDecoration(
                  color: c.amberLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.surface, width: 2),
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  size: badge * .62,
                  color: c.onWarningContainer,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
