import 'package:flutter/material.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// A job title as the post wrote it, laid out in the post's own language.
///
/// The server cleans titles once at ingestion and stores the language the
/// post is written in, so nothing here splits, reorders or guesses scripts:
/// aggregated posts show in both apps, so direction follows the post, not
/// the app.
class JobTitleDisplay extends StatelessWidget {
  final String title;

  /// The post's language code (`JobNews.language`).
  final String language;
  final TextStyle? style;
  final int? maxLines;

  const JobTitleDisplay({
    super.key,
    required this.title,
    required this.language,
    this.style,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.start,
      textDirection: AppLocale.directionOf(language),
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      style: style ?? AppTextStyles.titleMd(context.sirati),
    );
  }
}
