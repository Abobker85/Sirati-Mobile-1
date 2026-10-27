import 'package:flutter/material.dart';

import 'package:sirati/core/network/api_config.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/language_toggle.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsPrivacyTitle),
        actions: const [
          Padding(
            padding: EdgeInsetsDirectional.only(end: 12),
            child: LanguageToggle(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          _Section(
            title: l10n.settingsPrivacyCollectTitle,
            body: l10n.settingsPrivacyCollectBody,
          ),
          _Section(
            title: l10n.settingsPrivacyUseTitle,
            body: l10n.settingsPrivacyUseBody,
          ),
          _Section(
            title: l10n.settingsPrivacyProcessorsTitle,
            body: l10n.settingsPrivacyProcessorsBody,
          ),
          _Section(
            title: l10n.settingsPrivacyRetentionTitle,
            body: l10n.settingsPrivacyRetentionBody,
          ),
          _Section(
            title: l10n.settingsPrivacyContactTitle,
            body: l10n.settingsPrivacyContactBody(ApiConfig.supportEmail),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.sirati.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.sirati.border.withValues(alpha: .7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.start,
              style: TextStyle(
                fontSize: 18,
                height: 1.3,
                fontWeight: FontWeight.w700,
                // 18px bold is below the large-text size: needs 4.5:1.
                color: context.sirati.primaryInk,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.start,
            style: TextStyle(
              fontSize: 15,
              height: 1.7,
              color: context.sirati.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
