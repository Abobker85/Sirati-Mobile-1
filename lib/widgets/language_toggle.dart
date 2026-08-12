import 'package:flutter/material.dart';

import '../app_locale.dart';
import '../theme/app_theme.dart';

class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final english = AppLocale.isEnglish(context);

    return Tooltip(
      message: english ? 'Switch to Arabic' : 'Switch to English',
      child: Material(
        color: context.sirati.surfaceLow,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () {
            AppLocale.toggle(context);
          },
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    english ? 'AR' : 'EN',
                    style: TextStyle(
                      color: context.sirati.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
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
