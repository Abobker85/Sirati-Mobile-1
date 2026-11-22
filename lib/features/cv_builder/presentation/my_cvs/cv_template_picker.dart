import 'package:flutter/material.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_template.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/motion.dart';
import 'package:sirati/shared/widgets/template_preview.dart';

/// Bottom sheet listing CV designs; pops with the chosen [CvTemplate].
class CvTemplatePicker extends StatefulWidget {
  const CvTemplatePicker({
    super.key,
    required this.templates,
    required this.english,
  });

  final List<CvTemplate> templates;
  final bool english;

  @override
  State<CvTemplatePicker> createState() => _CvTemplatePickerState();
}

class _CvTemplatePickerState extends State<CvTemplatePicker> {
  String? _selectedSlug;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final reduce = MotionSettings.reduce(context);
    return SafeArea(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
        shrinkWrap: true,
        itemCount: widget.templates.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                AppLocalizations.of(context).cvTemplatePickerTitle,
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
            );
          }
          final template = widget.templates[index - 1];
          final selected = _selectedSlug == template.slug ||
              (_selectedSlug == null && template.isDefault);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: PressScale(
              child: TweenAnimationBuilder<Color?>(
                tween: ColorTween(
                  // White rows on the grey sheet; the chosen design is tinted
                  // and keeps its teal ring as the selection mark.
                  end: selected ? c.primaryLight : c.groupedCard,
                ),
                duration: reduce ? Duration.zero : MotionDurations.fast,
                curve: MotionCurves.state,
                builder: (context, bgColor, listTile) => Material(
                  color: bgColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.cardAll,
                    side: selected
                        ? BorderSide(color: c.primaryInk, width: 1.5)
                        : BorderSide.none,
                  ),
                  child: listTile,
                ),
                child: ListTile(
                  onTap: () {
                    setState(() => _selectedSlug = template.slug);
                    Navigator.pop(context, template);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.cardAll,
                  ),
                  leading: TemplatePreview(
                    imageUrl: template.previewImageUrl,
                    errorFallback: const SiratiMark(size: 22),
                  ),
                  title: Text(
                    template.name,
                    textAlign: TextAlign.start,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    template.isDefault
                        ? AppLocalizations.of(context).cvTemplateDefault
                        : template.slug,
                    textAlign: TextAlign.start,
                  ),
                  trailing: const Icon(Icons.download_rounded),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
