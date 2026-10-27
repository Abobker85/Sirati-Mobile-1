// GENERATED FILE - DO NOT EDIT BY HAND.
//
// Regenerate after changing lib/l10n/app_ar.arb (the template ARB), from flutter_app/:
//   flutter gen-l10n && dart run tool/gen_remote_l10n.dart
// test/localization/remote_l10n_generator_sync_test.dart fails while this file is out of date.
//
// Every label resolves: remote string of the language -> remote string of its
// fallback language -> bundled ARB string. Methods format remote strings with
// IcuLite; a formatting failure uses the bundled result.

import 'package:flutter/foundation.dart';
import 'package:sirati/core/l10n/icu_lite.dart';
import 'package:sirati/core/l10n/remote_strings.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';

class RemoteAppLocalizations extends AppLocalizations {
  RemoteAppLocalizations(
    super.locale, {
    this.base,
    required this.fallbackBase,
    this.remote = const RemoteStringLookup.empty(),
  });

  /// Bundled localization of this language; null when it has no ARB.
  final AppLocalizations? base;

  /// Bundled localization of the language's fallback (default English).
  final AppLocalizations fallbackBase;

  /// Published remote strings, most specific layer first.
  final RemoteStringLookup remote;

  AppLocalizations get _base => base ?? fallbackBase;

  @override
  String get appTitle => remote.text('appTitle') ?? _base.appTitle;

  @override
  String get switchToEnglish =>
      remote.text('switchToEnglish') ?? _base.switchToEnglish;

  @override
  String get switchToArabic =>
      remote.text('switchToArabic') ?? _base.switchToArabic;

  @override
  String get languageEnglish =>
      remote.text('languageEnglish') ?? _base.languageEnglish;

  @override
  String get languageArabic =>
      remote.text('languageArabic') ?? _base.languageArabic;

  @override
  String get somethingWentWrong =>
      remote.text('somethingWentWrong') ?? _base.somethingWentWrong;

  @override
  String get safeRetryMessage =>
      remote.text('safeRetryMessage') ?? _base.safeRetryMessage;

  @override
  String get retry => remote.text('retry') ?? _base.retry;

  @override
  String get cancel => remote.text('cancel') ?? _base.cancel;

  @override
  String get save => remote.text('save') ?? _base.save;

  @override
  String get next => remote.text('next') ?? _base.next;

  @override
  String get back => remote.text('back') ?? _base.back;

  @override
  String get getStarted => remote.text('getStarted') ?? _base.getStarted;

  @override
  String get createCv => remote.text('createCv') ?? _base.createCv;

  @override
  String get generateCv => remote.text('generateCv') ?? _base.generateCv;

  @override
  String get settings => remote.text('settings') ?? _base.settings;

  @override
  String get myCvs => remote.text('myCvs') ?? _base.myCvs;

  @override
  String get analyses => remote.text('analyses') ?? _base.analyses;

  @override
  String greetingName(String name) =>
      remote.format(
        'greetingName',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'name': name},
        ),
      ) ??
      _base.greetingName(name);

  @override
  String atsScoreLabel(int score) =>
      remote.format(
        'atsScoreLabel',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'score': score},
        ),
      ) ??
      _base.atsScoreLabel(score);

  @override
  String cvCount(int count) =>
      remote.format(
        'cvCount',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'count': count},
        ),
      ) ??
      _base.cvCount(count);

  @override
  String analysisCount(int count) =>
      remote.format(
        'analysisCount',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'count': count},
        ),
      ) ??
      _base.analysisCount(count);

  @override
  String get welcomeToSirati =>
      remote.text('welcomeToSirati') ?? _base.welcomeToSirati;

  @override
  String get buildCvProfessionally =>
      remote.text('buildCvProfessionally') ?? _base.buildCvProfessionally;

  @override
  String get createAccount =>
      remote.text('createAccount') ?? _base.createAccount;

  @override
  String get signIn => remote.text('signIn') ?? _base.signIn;

  @override
  String get invalidSaudiPhone =>
      remote.text('invalidSaudiPhone') ?? _base.invalidSaudiPhone;

  @override
  String get invalidUaePhone =>
      remote.text('invalidUaePhone') ?? _base.invalidUaePhone;

  @override
  String get invalidKuwaitPhone =>
      remote.text('invalidKuwaitPhone') ?? _base.invalidKuwaitPhone;

  @override
  String get invalidQatarPhone =>
      remote.text('invalidQatarPhone') ?? _base.invalidQatarPhone;

  @override
  String get invalidBahrainPhone =>
      remote.text('invalidBahrainPhone') ?? _base.invalidBahrainPhone;

  @override
  String get invalidOmanPhone =>
      remote.text('invalidOmanPhone') ?? _base.invalidOmanPhone;

  @override
  String get invalidGulfOrIntlPhone =>
      remote.text('invalidGulfOrIntlPhone') ?? _base.invalidGulfOrIntlPhone;

  @override
  String get invalidEmail => remote.text('invalidEmail') ?? _base.invalidEmail;

  @override
  String get personalDetailsTitle =>
      remote.text('personalDetailsTitle') ?? _base.personalDetailsTitle;

  @override
  String get personalDetailsSubtitle =>
      remote.text('personalDetailsSubtitle') ?? _base.personalDetailsSubtitle;

  @override
  String get inputLanguageLabel =>
      remote.text('inputLanguageLabel') ?? _base.inputLanguageLabel;

  @override
  String get languageModeDual =>
      remote.text('languageModeDual') ?? _base.languageModeDual;

  @override
  String get languageModeArOnly =>
      remote.text('languageModeArOnly') ?? _base.languageModeArOnly;

  @override
  String get languageModeEnOnly =>
      remote.text('languageModeEnOnly') ?? _base.languageModeEnOnly;

  @override
  String get fullNameAr => remote.text('fullNameAr') ?? _base.fullNameAr;

  @override
  String get fullNameArHint =>
      remote.text('fullNameArHint') ?? _base.fullNameArHint;

  @override
  String get fullNameEn => remote.text('fullNameEn') ?? _base.fullNameEn;

  @override
  String get fullNameEnHint =>
      remote.text('fullNameEnHint') ?? _base.fullNameEnHint;

  @override
  String get headlineAr => remote.text('headlineAr') ?? _base.headlineAr;

  @override
  String get headlineArHint =>
      remote.text('headlineArHint') ?? _base.headlineArHint;

  @override
  String get headlineEn => remote.text('headlineEn') ?? _base.headlineEn;

  @override
  String get headlineEnHint =>
      remote.text('headlineEnHint') ?? _base.headlineEnHint;

  @override
  String get locationAr => remote.text('locationAr') ?? _base.locationAr;

  @override
  String get locationArHint =>
      remote.text('locationArHint') ?? _base.locationArHint;

  @override
  String get locationEn => remote.text('locationEn') ?? _base.locationEn;

  @override
  String get locationEnHint =>
      remote.text('locationEnHint') ?? _base.locationEnHint;

  @override
  String get emailLabel => remote.text('emailLabel') ?? _base.emailLabel;

  @override
  String get phoneLabel => remote.text('phoneLabel') ?? _base.phoneLabel;

  @override
  String get phoneHelper => remote.text('phoneHelper') ?? _base.phoneHelper;

  @override
  String get linkedinLabel =>
      remote.text('linkedinLabel') ?? _base.linkedinLabel;

  @override
  String get atsPhotoWarningTitle =>
      remote.text('atsPhotoWarningTitle') ?? _base.atsPhotoWarningTitle;

  @override
  String get atsPhotoWarningBody =>
      remote.text('atsPhotoWarningBody') ?? _base.atsPhotoWarningBody;

  @override
  String get atsPhotoEnabled =>
      remote.text('atsPhotoEnabled') ?? _base.atsPhotoEnabled;

  @override
  String get professionalSummaryTitle =>
      remote.text('professionalSummaryTitle') ?? _base.professionalSummaryTitle;

  @override
  String get professionalSummarySubtitle =>
      remote.text('professionalSummarySubtitle') ??
      _base.professionalSummarySubtitle;

  @override
  String get summaryArLabel =>
      remote.text('summaryArLabel') ?? _base.summaryArLabel;

  @override
  String get summaryArHint =>
      remote.text('summaryArHint') ?? _base.summaryArHint;

  @override
  String get summaryEnLabel =>
      remote.text('summaryEnLabel') ?? _base.summaryEnLabel;

  @override
  String get summaryEnHint =>
      remote.text('summaryEnHint') ?? _base.summaryEnHint;

  @override
  String get summaryAdviceEmpty =>
      remote.text('summaryAdviceEmpty') ?? _base.summaryAdviceEmpty;

  @override
  String get summaryAdviceShort =>
      remote.text('summaryAdviceShort') ?? _base.summaryAdviceShort;

  @override
  String get summaryAdviceGood =>
      remote.text('summaryAdviceGood') ?? _base.summaryAdviceGood;

  @override
  String get summaryAdviceLong =>
      remote.text('summaryAdviceLong') ?? _base.summaryAdviceLong;

  @override
  String summaryWordCountLine(int words, int chars, String advice) =>
      remote.format(
        'summaryWordCountLine',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'words': words, 'chars': chars, 'advice': advice},
        ),
      ) ??
      _base.summaryWordCountLine(words, chars, advice);

  @override
  String get viewProfile => remote.text('viewProfile') ?? _base.viewProfile;

  @override
  String get accountSection =>
      remote.text('accountSection') ?? _base.accountSection;

  @override
  String get editProfile => remote.text('editProfile') ?? _base.editProfile;

  @override
  String get changePassword =>
      remote.text('changePassword') ?? _base.changePassword;

  @override
  String get preferencesSection =>
      remote.text('preferencesSection') ?? _base.preferencesSection;

  @override
  String get language => remote.text('language') ?? _base.language;

  @override
  String get appearance => remote.text('appearance') ?? _base.appearance;

  @override
  String get change => remote.text('change') ?? _base.change;

  @override
  String get themeSystem => remote.text('themeSystem') ?? _base.themeSystem;

  @override
  String get themeLight => remote.text('themeLight') ?? _base.themeLight;

  @override
  String get themeDark => remote.text('themeDark') ?? _base.themeDark;

  @override
  String get pushNotifications =>
      remote.text('pushNotifications') ?? _base.pushNotifications;

  @override
  String get aboutSection => remote.text('aboutSection') ?? _base.aboutSection;

  @override
  String get privacyPolicy =>
      remote.text('privacyPolicy') ?? _base.privacyPolicy;

  @override
  String get contactUs => remote.text('contactUs') ?? _base.contactUs;

  @override
  String get contactUsSubtitle =>
      remote.text('contactUsSubtitle') ?? _base.contactUsSubtitle;

  @override
  String get contactUsEmailSubject =>
      remote.text('contactUsEmailSubject') ?? _base.contactUsEmailSubject;

  @override
  String contactUsFallback(String email) =>
      remote.format(
        'contactUsFallback',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'email': email},
        ),
      ) ??
      _base.contactUsFallback(email);

  @override
  String get replayIntro => remote.text('replayIntro') ?? _base.replayIntro;

  @override
  String get replayIntroSubtitle =>
      remote.text('replayIntroSubtitle') ?? _base.replayIntroSubtitle;

  @override
  String get appVersion => remote.text('appVersion') ?? _base.appVersion;

  @override
  String get dangerZone => remote.text('dangerZone') ?? _base.dangerZone;

  @override
  String get logOut => remote.text('logOut') ?? _base.logOut;

  @override
  String get logOutConfirmTitle =>
      remote.text('logOutConfirmTitle') ?? _base.logOutConfirmTitle;

  @override
  String get logOutConfirmBody =>
      remote.text('logOutConfirmBody') ?? _base.logOutConfirmBody;

  @override
  String get logOutFailed => remote.text('logOutFailed') ?? _base.logOutFailed;

  @override
  String get logOutPartial =>
      remote.text('logOutPartial') ?? _base.logOutPartial;

  @override
  String get deleteAccount =>
      remote.text('deleteAccount') ?? _base.deleteAccount;

  @override
  String get couldNotLoadProfile =>
      remote.text('couldNotLoadProfile') ?? _base.couldNotLoadProfile;

  @override
  String get notificationPrefUpdateFailed =>
      remote.text('notificationPrefUpdateFailed') ??
      _base.notificationPrefUpdateFailed;

  @override
  String get signedOutLocally =>
      remote.text('signedOutLocally') ?? _base.signedOutLocally;

  @override
  String get userFallback => remote.text('userFallback') ?? _base.userFallback;

  @override
  String get cvEditorTitle =>
      remote.text('cvEditorTitle') ?? _base.cvEditorTitle;

  @override
  String get preparingEditor =>
      remote.text('preparingEditor') ?? _base.preparingEditor;

  @override
  String get loadErrorTitle =>
      remote.text('loadErrorTitle') ?? _base.loadErrorTitle;

  @override
  String get cvLoadFailed => remote.text('cvLoadFailed') ?? _base.cvLoadFailed;

  @override
  String get autosaving => remote.text('autosaving') ?? _base.autosaving;

  @override
  String get unsavedEdits => remote.text('unsavedEdits') ?? _base.unsavedEdits;

  @override
  String get saved => remote.text('saved') ?? _base.saved;

  @override
  String get backToEdit => remote.text('backToEdit') ?? _base.backToEdit;

  @override
  String get livePreview => remote.text('livePreview') ?? _base.livePreview;

  @override
  String get saveNow => remote.text('saveNow') ?? _base.saveNow;

  @override
  String get cvSaved => remote.text('cvSaved') ?? _base.cvSaved;

  @override
  String get cvSaveFailed => remote.text('cvSaveFailed') ?? _base.cvSaveFailed;

  @override
  String get tabPersonal => remote.text('tabPersonal') ?? _base.tabPersonal;

  @override
  String get tabExperience =>
      remote.text('tabExperience') ?? _base.tabExperience;

  @override
  String get tabSkills => remote.text('tabSkills') ?? _base.tabSkills;

  @override
  String get tabOrder => remote.text('tabOrder') ?? _base.tabOrder;

  @override
  String get recoverDraftTitle =>
      remote.text('recoverDraftTitle') ?? _base.recoverDraftTitle;

  @override
  String get recoverDraftBody =>
      remote.text('recoverDraftBody') ?? _base.recoverDraftBody;

  @override
  String get discardDraft => remote.text('discardDraft') ?? _base.discardDraft;

  @override
  String get restoreDraft => remote.text('restoreDraft') ?? _base.restoreDraft;

  @override
  String get draftRestored =>
      remote.text('draftRestored') ?? _base.draftRestored;

  @override
  String get sectionOrderTitle =>
      remote.text('sectionOrderTitle') ?? _base.sectionOrderTitle;

  @override
  String get sectionOrderHint =>
      remote.text('sectionOrderHint') ?? _base.sectionOrderHint;

  @override
  String get moveUp => remote.text('moveUp') ?? _base.moveUp;

  @override
  String get moveDown => remote.text('moveDown') ?? _base.moveDown;

  @override
  String get sectionPersonal =>
      remote.text('sectionPersonal') ?? _base.sectionPersonal;

  @override
  String get sectionSummary =>
      remote.text('sectionSummary') ?? _base.sectionSummary;

  @override
  String get sectionExperience =>
      remote.text('sectionExperience') ?? _base.sectionExperience;

  @override
  String get sectionEducation =>
      remote.text('sectionEducation') ?? _base.sectionEducation;

  @override
  String get sectionSkills =>
      remote.text('sectionSkills') ?? _base.sectionSkills;

  @override
  String get sectionLanguages =>
      remote.text('sectionLanguages') ?? _base.sectionLanguages;

  @override
  String get sectionCertifications =>
      remote.text('sectionCertifications') ?? _base.sectionCertifications;

  @override
  String get sectionProjects =>
      remote.text('sectionProjects') ?? _base.sectionProjects;

  @override
  String get sectionCustom =>
      remote.text('sectionCustom') ?? _base.sectionCustom;

  @override
  String get calendarSystemLabel =>
      remote.text('calendarSystemLabel') ?? _base.calendarSystemLabel;

  @override
  String get calendarGregorian =>
      remote.text('calendarGregorian') ?? _base.calendarGregorian;

  @override
  String get calendarHijri =>
      remote.text('calendarHijri') ?? _base.calendarHijri;

  @override
  String get workExperienceTitle =>
      remote.text('workExperienceTitle') ?? _base.workExperienceTitle;

  @override
  String get workExperienceSubtitle =>
      remote.text('workExperienceSubtitle') ?? _base.workExperienceSubtitle;

  @override
  String get addExperience =>
      remote.text('addExperience') ?? _base.addExperience;

  @override
  String get sortChronologically =>
      remote.text('sortChronologically') ?? _base.sortChronologically;

  @override
  String get educationQualificationsTitle =>
      remote.text('educationQualificationsTitle') ??
      _base.educationQualificationsTitle;

  @override
  String get educationQualificationsSubtitle =>
      remote.text('educationQualificationsSubtitle') ??
      _base.educationQualificationsSubtitle;

  @override
  String get addEducation => remote.text('addEducation') ?? _base.addEducation;

  @override
  String get jobTitleAr => remote.text('jobTitleAr') ?? _base.jobTitleAr;

  @override
  String get jobTitleArHint =>
      remote.text('jobTitleArHint') ?? _base.jobTitleArHint;

  @override
  String get jobTitleEn => remote.text('jobTitleEn') ?? _base.jobTitleEn;

  @override
  String get jobTitleEnHint =>
      remote.text('jobTitleEnHint') ?? _base.jobTitleEnHint;

  @override
  String get companyAr => remote.text('companyAr') ?? _base.companyAr;

  @override
  String get companyArHint =>
      remote.text('companyArHint') ?? _base.companyArHint;

  @override
  String get companyEn => remote.text('companyEn') ?? _base.companyEn;

  @override
  String get companyEnHint =>
      remote.text('companyEnHint') ?? _base.companyEnHint;

  @override
  String get startDateLabel =>
      remote.text('startDateLabel') ?? _base.startDateLabel;

  @override
  String get startDateHint =>
      remote.text('startDateHint') ?? _base.startDateHint;

  @override
  String get endDateLabel => remote.text('endDateLabel') ?? _base.endDateLabel;

  @override
  String get endDateHint => remote.text('endDateHint') ?? _base.endDateHint;

  @override
  String get currentlyHere =>
      remote.text('currentlyHere') ?? _base.currentlyHere;

  @override
  String get currentlyWorking =>
      remote.text('currentlyWorking') ?? _base.currentlyWorking;

  @override
  String get achievementsLabel =>
      remote.text('achievementsLabel') ?? _base.achievementsLabel;

  @override
  String get addAchievement =>
      remote.text('addAchievement') ?? _base.addAchievement;

  @override
  String get noAchievementsHint =>
      remote.text('noAchievementsHint') ?? _base.noAchievementsHint;

  @override
  String get achievementHint =>
      remote.text('achievementHint') ?? _base.achievementHint;

  @override
  String get endDateBeforeStart =>
      remote.text('endDateBeforeStart') ?? _base.endDateBeforeStart;

  @override
  String get institutionAr =>
      remote.text('institutionAr') ?? _base.institutionAr;

  @override
  String get institutionArHint =>
      remote.text('institutionArHint') ?? _base.institutionArHint;

  @override
  String get institutionEn =>
      remote.text('institutionEn') ?? _base.institutionEn;

  @override
  String get institutionEnHint =>
      remote.text('institutionEnHint') ?? _base.institutionEnHint;

  @override
  String get degreeLabel => remote.text('degreeLabel') ?? _base.degreeLabel;

  @override
  String get degreeHint => remote.text('degreeHint') ?? _base.degreeHint;

  @override
  String get fieldOfStudyLabel =>
      remote.text('fieldOfStudyLabel') ?? _base.fieldOfStudyLabel;

  @override
  String get fieldOfStudyHint =>
      remote.text('fieldOfStudyHint') ?? _base.fieldOfStudyHint;

  @override
  String get startYearLabel =>
      remote.text('startYearLabel') ?? _base.startYearLabel;

  @override
  String get startYearHint =>
      remote.text('startYearHint') ?? _base.startYearHint;

  @override
  String get graduationYearLabel =>
      remote.text('graduationYearLabel') ?? _base.graduationYearLabel;

  @override
  String get graduationYearHint =>
      remote.text('graduationYearHint') ?? _base.graduationYearHint;

  @override
  String get skillsTitle => remote.text('skillsTitle') ?? _base.skillsTitle;

  @override
  String get skillsSubtitle =>
      remote.text('skillsSubtitle') ?? _base.skillsSubtitle;

  @override
  String get noSkillsHint => remote.text('noSkillsHint') ?? _base.noSkillsHint;

  @override
  String get skillNameHint =>
      remote.text('skillNameHint') ?? _base.skillNameHint;

  @override
  String get addItem => remote.text('addItem') ?? _base.addItem;

  @override
  String get proficiencyLevel =>
      remote.text('proficiencyLevel') ?? _base.proficiencyLevel;

  @override
  String get skillLevelBeginner =>
      remote.text('skillLevelBeginner') ?? _base.skillLevelBeginner;

  @override
  String get skillLevelIntermediate =>
      remote.text('skillLevelIntermediate') ?? _base.skillLevelIntermediate;

  @override
  String get skillLevelAdvanced =>
      remote.text('skillLevelAdvanced') ?? _base.skillLevelAdvanced;

  @override
  String get skillLevelExpert =>
      remote.text('skillLevelExpert') ?? _base.skillLevelExpert;

  @override
  String get skillCategory =>
      remote.text('skillCategory') ?? _base.skillCategory;

  @override
  String get skillCategoryTechnical =>
      remote.text('skillCategoryTechnical') ?? _base.skillCategoryTechnical;

  @override
  String get skillCategorySoft =>
      remote.text('skillCategorySoft') ?? _base.skillCategorySoft;

  @override
  String get skillCategoryTools =>
      remote.text('skillCategoryTools') ?? _base.skillCategoryTools;

  @override
  String get skillCategoryManagement =>
      remote.text('skillCategoryManagement') ?? _base.skillCategoryManagement;

  @override
  String get skillCategoryGeneral =>
      remote.text('skillCategoryGeneral') ?? _base.skillCategoryGeneral;

  @override
  String get languagesTitle =>
      remote.text('languagesTitle') ?? _base.languagesTitle;

  @override
  String get languagesSubtitle =>
      remote.text('languagesSubtitle') ?? _base.languagesSubtitle;

  @override
  String get noLanguagesHint =>
      remote.text('noLanguagesHint') ?? _base.noLanguagesHint;

  @override
  String get languageNameHint =>
      remote.text('languageNameHint') ?? _base.languageNameHint;

  @override
  String get languageLevelNative =>
      remote.text('languageLevelNative') ?? _base.languageLevelNative;

  @override
  String get languageLevelFluent =>
      remote.text('languageLevelFluent') ?? _base.languageLevelFluent;

  @override
  String get languageLevelC1 =>
      remote.text('languageLevelC1') ?? _base.languageLevelC1;

  @override
  String get languageLevelB2 =>
      remote.text('languageLevelB2') ?? _base.languageLevelB2;

  @override
  String get languageLevelA2 =>
      remote.text('languageLevelA2') ?? _base.languageLevelA2;

  @override
  String get certificationsTitle =>
      remote.text('certificationsTitle') ?? _base.certificationsTitle;

  @override
  String get certificationsSubtitle =>
      remote.text('certificationsSubtitle') ?? _base.certificationsSubtitle;

  @override
  String get addCertification =>
      remote.text('addCertification') ?? _base.addCertification;

  @override
  String get certNameLabel =>
      remote.text('certNameLabel') ?? _base.certNameLabel;

  @override
  String get certNameHint => remote.text('certNameHint') ?? _base.certNameHint;

  @override
  String get certIssuerLabel =>
      remote.text('certIssuerLabel') ?? _base.certIssuerLabel;

  @override
  String get certIssuerHint =>
      remote.text('certIssuerHint') ?? _base.certIssuerHint;

  @override
  String get issueYearLabel =>
      remote.text('issueYearLabel') ?? _base.issueYearLabel;

  @override
  String get issueYearHint =>
      remote.text('issueYearHint') ?? _base.issueYearHint;

  @override
  String get expiryYearLabel =>
      remote.text('expiryYearLabel') ?? _base.expiryYearLabel;

  @override
  String get expiryYearHint =>
      remote.text('expiryYearHint') ?? _base.expiryYearHint;

  @override
  String get noExpiry => remote.text('noExpiry') ?? _base.noExpiry;

  @override
  String get certPermanent =>
      remote.text('certPermanent') ?? _base.certPermanent;

  @override
  String get projectsTitle =>
      remote.text('projectsTitle') ?? _base.projectsTitle;

  @override
  String get projectsSubtitle =>
      remote.text('projectsSubtitle') ?? _base.projectsSubtitle;

  @override
  String get addProject => remote.text('addProject') ?? _base.addProject;

  @override
  String get projectTitleLabel =>
      remote.text('projectTitleLabel') ?? _base.projectTitleLabel;

  @override
  String get projectTitleHint =>
      remote.text('projectTitleHint') ?? _base.projectTitleHint;

  @override
  String get projectRoleLabel =>
      remote.text('projectRoleLabel') ?? _base.projectRoleLabel;

  @override
  String get projectRoleHint =>
      remote.text('projectRoleHint') ?? _base.projectRoleHint;

  @override
  String get projectUrlLabel =>
      remote.text('projectUrlLabel') ?? _base.projectUrlLabel;

  @override
  String get invalidProjectUrl =>
      remote.text('invalidProjectUrl') ?? _base.invalidProjectUrl;

  @override
  String get projectDescLabel =>
      remote.text('projectDescLabel') ?? _base.projectDescLabel;

  @override
  String get projectDescHint =>
      remote.text('projectDescHint') ?? _base.projectDescHint;

  @override
  String get deleteItem => remote.text('deleteItem') ?? _base.deleteItem;

  @override
  String get jobMatchTitle =>
      remote.text('jobMatchTitle') ?? _base.jobMatchTitle;

  @override
  String get jobMatchPremiumBadge =>
      remote.text('jobMatchPremiumBadge') ?? _base.jobMatchPremiumBadge;

  @override
  String get jobMatchEntryTitle =>
      remote.text('jobMatchEntryTitle') ?? _base.jobMatchEntryTitle;

  @override
  String get jobMatchEntrySubtitle =>
      remote.text('jobMatchEntrySubtitle') ?? _base.jobMatchEntrySubtitle;

  @override
  String get jobMatchEntryButton =>
      remote.text('jobMatchEntryButton') ?? _base.jobMatchEntryButton;

  @override
  String jobMatchQuotaRemaining(int count) =>
      remote.format(
        'jobMatchQuotaRemaining',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'count': count},
        ),
      ) ??
      _base.jobMatchQuotaRemaining(count);

  @override
  String get jobMatchJobTitleLabel =>
      remote.text('jobMatchJobTitleLabel') ?? _base.jobMatchJobTitleLabel;

  @override
  String get jobMatchJobTitleHint =>
      remote.text('jobMatchJobTitleHint') ?? _base.jobMatchJobTitleHint;

  @override
  String get jobMatchDescriptionLabel =>
      remote.text('jobMatchDescriptionLabel') ?? _base.jobMatchDescriptionLabel;

  @override
  String get jobMatchDescriptionHint =>
      remote.text('jobMatchDescriptionHint') ?? _base.jobMatchDescriptionHint;

  @override
  String get jobMatchDescriptionRequired =>
      remote.text('jobMatchDescriptionRequired') ??
      _base.jobMatchDescriptionRequired;

  @override
  String jobMatchDescriptionTooLong(int max) =>
      remote.format(
        'jobMatchDescriptionTooLong',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'max': max},
        ),
      ) ??
      _base.jobMatchDescriptionTooLong(max);

  @override
  String jobMatchTitleTooLong(int max) =>
      remote.format(
        'jobMatchTitleTooLong',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'max': max},
        ),
      ) ??
      _base.jobMatchTitleTooLong(max);

  @override
  String jobMatchCharCount(int count, int max) =>
      remote.format(
        'jobMatchCharCount',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'count': count, 'max': max},
        ),
      ) ??
      _base.jobMatchCharCount(count, max);

  @override
  String get jobMatchPickCvTitle =>
      remote.text('jobMatchPickCvTitle') ?? _base.jobMatchPickCvTitle;

  @override
  String get jobMatchPickCvRequired =>
      remote.text('jobMatchPickCvRequired') ?? _base.jobMatchPickCvRequired;

  @override
  String get jobMatchNoCvTitle =>
      remote.text('jobMatchNoCvTitle') ?? _base.jobMatchNoCvTitle;

  @override
  String get jobMatchNoCvBody =>
      remote.text('jobMatchNoCvBody') ?? _base.jobMatchNoCvBody;

  @override
  String get jobMatchCreateTailoredCv =>
      remote.text('jobMatchCreateTailoredCv') ?? _base.jobMatchCreateTailoredCv;

  @override
  String get jobMatchOrCreateTailored =>
      remote.text('jobMatchOrCreateTailored') ?? _base.jobMatchOrCreateTailored;

  @override
  String get jobMatchCvsLoadFailed =>
      remote.text('jobMatchCvsLoadFailed') ?? _base.jobMatchCvsLoadFailed;

  @override
  String get jobMatchRetry =>
      remote.text('jobMatchRetry') ?? _base.jobMatchRetry;

  @override
  String get jobMatchSubmit =>
      remote.text('jobMatchSubmit') ?? _base.jobMatchSubmit;

  @override
  String get jobMatchSubmitting =>
      remote.text('jobMatchSubmitting') ?? _base.jobMatchSubmitting;

  @override
  String get jobMatchCvStillPreparing =>
      remote.text('jobMatchCvStillPreparing') ?? _base.jobMatchCvStillPreparing;

  @override
  String get jobMatchUntitledCv =>
      remote.text('jobMatchUntitledCv') ?? _base.jobMatchUntitledCv;

  @override
  String get jobMatchPaywallTitle =>
      remote.text('jobMatchPaywallTitle') ?? _base.jobMatchPaywallTitle;

  @override
  String get jobMatchPaywallBody =>
      remote.text('jobMatchPaywallBody') ?? _base.jobMatchPaywallBody;

  @override
  String jobMatchPaywallTrial(int days) =>
      remote.format(
        'jobMatchPaywallTrial',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'days': days},
        ),
      ) ??
      _base.jobMatchPaywallTrial(days);

  @override
  String get jobMatchPaywallRefresh =>
      remote.text('jobMatchPaywallRefresh') ?? _base.jobMatchPaywallRefresh;

  @override
  String get jobMatchQuotaTitle =>
      remote.text('jobMatchQuotaTitle') ?? _base.jobMatchQuotaTitle;

  @override
  String get jobMatchQuotaBody =>
      remote.text('jobMatchQuotaBody') ?? _base.jobMatchQuotaBody;

  @override
  String get jobMatchUnavailableTitle =>
      remote.text('jobMatchUnavailableTitle') ?? _base.jobMatchUnavailableTitle;

  @override
  String get jobMatchUnavailableBody =>
      remote.text('jobMatchUnavailableBody') ?? _base.jobMatchUnavailableBody;

  @override
  String get jobMatchEntitlementLoadFailed =>
      remote.text('jobMatchEntitlementLoadFailed') ??
      _base.jobMatchEntitlementLoadFailed;

  @override
  String get jobMatchErrorSubscription =>
      remote.text('jobMatchErrorSubscription') ??
      _base.jobMatchErrorSubscription;

  @override
  String get jobMatchErrorLimit =>
      remote.text('jobMatchErrorLimit') ?? _base.jobMatchErrorLimit;

  @override
  String get jobMatchErrorConflict =>
      remote.text('jobMatchErrorConflict') ?? _base.jobMatchErrorConflict;

  @override
  String get jobMatchErrorStale =>
      remote.text('jobMatchErrorStale') ?? _base.jobMatchErrorStale;

  @override
  String get jobMatchErrorCvTooLong =>
      remote.text('jobMatchErrorCvTooLong') ?? _base.jobMatchErrorCvTooLong;

  @override
  String get jobMatchErrorInvalidDescription =>
      remote.text('jobMatchErrorInvalidDescription') ??
      _base.jobMatchErrorInvalidDescription;

  @override
  String get jobMatchErrorInvalidSelection =>
      remote.text('jobMatchErrorInvalidSelection') ??
      _base.jobMatchErrorInvalidSelection;

  @override
  String get jobMatchErrorUnavailable =>
      remote.text('jobMatchErrorUnavailable') ?? _base.jobMatchErrorUnavailable;

  @override
  String get jobMatchErrorNotFound =>
      remote.text('jobMatchErrorNotFound') ?? _base.jobMatchErrorNotFound;

  @override
  String get jobMatchErrorNetwork =>
      remote.text('jobMatchErrorNetwork') ?? _base.jobMatchErrorNetwork;

  @override
  String get jobMatchErrorUnknown =>
      remote.text('jobMatchErrorUnknown') ?? _base.jobMatchErrorUnknown;

  @override
  String get jobMatchResultTitle =>
      remote.text('jobMatchResultTitle') ?? _base.jobMatchResultTitle;

  @override
  String get jobMatchScoreLabel =>
      remote.text('jobMatchScoreLabel') ?? _base.jobMatchScoreLabel;

  @override
  String jobMatchScoreSemantics(int score) =>
      remote.format(
        'jobMatchScoreSemantics',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'score': score},
        ),
      ) ??
      _base.jobMatchScoreSemantics(score);

  @override
  String jobMatchCoverage(int percent) =>
      remote.format(
        'jobMatchCoverage',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'percent': percent},
        ),
      ) ??
      _base.jobMatchCoverage(percent);

  @override
  String jobMatchGrade(String grade) =>
      remote.format(
        'jobMatchGrade',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'grade': grade},
        ),
      ) ??
      _base.jobMatchGrade(grade);

  @override
  String get jobMatchMatchedKeywords =>
      remote.text('jobMatchMatchedKeywords') ?? _base.jobMatchMatchedKeywords;

  @override
  String get jobMatchMissingKeywords =>
      remote.text('jobMatchMissingKeywords') ?? _base.jobMatchMissingKeywords;

  @override
  String get jobMatchNoKeywords =>
      remote.text('jobMatchNoKeywords') ?? _base.jobMatchNoKeywords;

  @override
  String get jobMatchStrengths =>
      remote.text('jobMatchStrengths') ?? _base.jobMatchStrengths;

  @override
  String get jobMatchGaps => remote.text('jobMatchGaps') ?? _base.jobMatchGaps;

  @override
  String get jobMatchSummary =>
      remote.text('jobMatchSummary') ?? _base.jobMatchSummary;

  @override
  String get jobMatchAiPreparing =>
      remote.text('jobMatchAiPreparing') ?? _base.jobMatchAiPreparing;

  @override
  String get jobMatchAiStillProcessing =>
      remote.text('jobMatchAiStillProcessing') ??
      _base.jobMatchAiStillProcessing;

  @override
  String get jobMatchCheckAgain =>
      remote.text('jobMatchCheckAgain') ?? _base.jobMatchCheckAgain;

  @override
  String get jobMatchAiFailed =>
      remote.text('jobMatchAiFailed') ?? _base.jobMatchAiFailed;

  @override
  String get jobMatchAiNotConfigured =>
      remote.text('jobMatchAiNotConfigured') ?? _base.jobMatchAiNotConfigured;

  @override
  String get jobMatchSuggestionsTitle =>
      remote.text('jobMatchSuggestionsTitle') ?? _base.jobMatchSuggestionsTitle;

  @override
  String get jobMatchSuggestionsHint =>
      remote.text('jobMatchSuggestionsHint') ?? _base.jobMatchSuggestionsHint;

  @override
  String get jobMatchNoSuggestions =>
      remote.text('jobMatchNoSuggestions') ?? _base.jobMatchNoSuggestions;

  @override
  String get jobMatchBefore =>
      remote.text('jobMatchBefore') ?? _base.jobMatchBefore;

  @override
  String get jobMatchAfter =>
      remote.text('jobMatchAfter') ?? _base.jobMatchAfter;

  @override
  String get jobMatchAddition =>
      remote.text('jobMatchAddition') ?? _base.jobMatchAddition;

  @override
  String get jobMatchWhy => remote.text('jobMatchWhy') ?? _base.jobMatchWhy;

  @override
  String get jobMatchTargets =>
      remote.text('jobMatchTargets') ?? _base.jobMatchTargets;

  @override
  String get jobMatchNeedsUserFact =>
      remote.text('jobMatchNeedsUserFact') ?? _base.jobMatchNeedsUserFact;

  @override
  String get jobMatchAppliedBadge =>
      remote.text('jobMatchAppliedBadge') ?? _base.jobMatchAppliedBadge;

  @override
  String jobMatchApplySelected(int count) =>
      remote.format(
        'jobMatchApplySelected',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'count': count},
        ),
      ) ??
      _base.jobMatchApplySelected(count);

  @override
  String get jobMatchSelectToApply =>
      remote.text('jobMatchSelectToApply') ?? _base.jobMatchSelectToApply;

  @override
  String get jobMatchApplying =>
      remote.text('jobMatchApplying') ?? _base.jobMatchApplying;

  @override
  String get jobMatchAppliedSuccess =>
      remote.text('jobMatchAppliedSuccess') ?? _base.jobMatchAppliedSuccess;

  @override
  String get jobMatchOpenTailoredCv =>
      remote.text('jobMatchOpenTailoredCv') ?? _base.jobMatchOpenTailoredCv;

  @override
  String get jobMatchNewMatch =>
      remote.text('jobMatchNewMatch') ?? _base.jobMatchNewMatch;

  @override
  String jobMatchSectionName(String section) =>
      remote.format(
        'jobMatchSectionName',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'section': section},
        ),
      ) ??
      _base.jobMatchSectionName(section);

  @override
  String get jobMatchRetrySuggestions =>
      remote.text('jobMatchRetrySuggestions') ?? _base.jobMatchRetrySuggestions;

  @override
  String get jobMatchLoading =>
      remote.text('jobMatchLoading') ?? _base.jobMatchLoading;

  @override
  String get sharedLoading =>
      remote.text('sharedLoading') ?? _base.sharedLoading;

  @override
  String get jm4ConfirmFact =>
      remote.text('jm4ConfirmFact') ?? _base.jm4ConfirmFact;

  @override
  String get jm4HonestyHint =>
      remote.text('jm4HonestyHint') ?? _base.jm4HonestyHint;

  @override
  String get jobsFilterAll =>
      remote.text('jobsFilterAll') ?? _base.jobsFilterAll;

  @override
  String get jobsPresetMatched =>
      remote.text('jobsPresetMatched') ?? _base.jobsPresetMatched;

  @override
  String get jobsPresetGov =>
      remote.text('jobsPresetGov') ?? _base.jobsPresetGov;

  @override
  String get jobsPresetEnterprise =>
      remote.text('jobsPresetEnterprise') ?? _base.jobsPresetEnterprise;

  @override
  String get jobsPresetTamheer =>
      remote.text('jobsPresetTamheer') ?? _base.jobsPresetTamheer;

  @override
  String get jobsFilterRemote =>
      remote.text('jobsFilterRemote') ?? _base.jobsFilterRemote;

  @override
  String get jobsSearchHint =>
      remote.text('jobsSearchHint') ?? _base.jobsSearchHint;

  @override
  String get jobsCategoryTech =>
      remote.text('jobsCategoryTech') ?? _base.jobsCategoryTech;

  @override
  String get jobsCategoryFinance =>
      remote.text('jobsCategoryFinance') ?? _base.jobsCategoryFinance;

  @override
  String get jobsCategoryHealth =>
      remote.text('jobsCategoryHealth') ?? _base.jobsCategoryHealth;

  @override
  String get jobsCityAll => remote.text('jobsCityAll') ?? _base.jobsCityAll;

  @override
  String get jobsCityRiyadh =>
      remote.text('jobsCityRiyadh') ?? _base.jobsCityRiyadh;

  @override
  String get jobsCityJeddah =>
      remote.text('jobsCityJeddah') ?? _base.jobsCityJeddah;

  @override
  String get jobsCityDammam =>
      remote.text('jobsCityDammam') ?? _base.jobsCityDammam;

  @override
  String get jobsCityKhobar =>
      remote.text('jobsCityKhobar') ?? _base.jobsCityKhobar;

  @override
  String get jobsCityMecca =>
      remote.text('jobsCityMecca') ?? _base.jobsCityMecca;

  @override
  String get jobsCityMedina =>
      remote.text('jobsCityMedina') ?? _base.jobsCityMedina;

  @override
  String get jobsPersonalizedTitle =>
      remote.text('jobsPersonalizedTitle') ?? _base.jobsPersonalizedTitle;

  @override
  String get jobsPersonalizedFallback =>
      remote.text('jobsPersonalizedFallback') ?? _base.jobsPersonalizedFallback;

  @override
  String get jobsMatchedActive =>
      remote.text('jobsMatchedActive') ?? _base.jobsMatchedActive;

  @override
  String get jobsMatchToggle =>
      remote.text('jobsMatchToggle') ?? _base.jobsMatchToggle;

  @override
  String get jobsEmptyFeed =>
      remote.text('jobsEmptyFeed') ?? _base.jobsEmptyFeed;

  @override
  String get jobsLoadFailed =>
      remote.text('jobsLoadFailed') ?? _base.jobsLoadFailed;

  @override
  String get jobsLatestPostings =>
      remote.text('jobsLatestPostings') ?? _base.jobsLatestPostings;

  @override
  String get jobsDetailTitle =>
      remote.text('jobsDetailTitle') ?? _base.jobsDetailTitle;

  @override
  String get jobsVerifiedSourceDetail =>
      remote.text('jobsVerifiedSourceDetail') ?? _base.jobsVerifiedSourceDetail;

  @override
  String get jobsTamheerProgram =>
      remote.text('jobsTamheerProgram') ?? _base.jobsTamheerProgram;

  @override
  String get jobsCompatibilityTitle =>
      remote.text('jobsCompatibilityTitle') ?? _base.jobsCompatibilityTitle;

  @override
  String get jobsSkillsRequired =>
      remote.text('jobsSkillsRequired') ?? _base.jobsSkillsRequired;

  @override
  String get jobsDescriptionTitle =>
      remote.text('jobsDescriptionTitle') ?? _base.jobsDescriptionTitle;

  @override
  String get jobsTailorCv => remote.text('jobsTailorCv') ?? _base.jobsTailorCv;

  @override
  String get jobsOpenApplyFailed =>
      remote.text('jobsOpenApplyFailed') ?? _base.jobsOpenApplyFailed;

  @override
  String get jobsApplyOfficialSite =>
      remote.text('jobsApplyOfficialSite') ?? _base.jobsApplyOfficialSite;

  @override
  String get jobsVerifiedSourceCard =>
      remote.text('jobsVerifiedSourceCard') ?? _base.jobsVerifiedSourceCard;

  @override
  String get jobsTamheerBadge =>
      remote.text('jobsTamheerBadge') ?? _base.jobsTamheerBadge;

  @override
  String get jobsNewBadge => remote.text('jobsNewBadge') ?? _base.jobsNewBadge;

  @override
  String get jobsDetailsLink =>
      remote.text('jobsDetailsLink') ?? _base.jobsDetailsLink;

  @override
  String get jobsVerifiedSourceFeatured =>
      remote.text('jobsVerifiedSourceFeatured') ??
      _base.jobsVerifiedSourceFeatured;

  @override
  String get jobsTamheerBadgeFeatured =>
      remote.text('jobsTamheerBadgeFeatured') ?? _base.jobsTamheerBadgeFeatured;

  @override
  String get jobsApplyNow => remote.text('jobsApplyNow') ?? _base.jobsApplyNow;

  @override
  String atsFileTooLarge(int size) =>
      remote.format(
        'atsFileTooLarge',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'size': size},
        ),
      ) ??
      _base.atsFileTooLarge(size);

  @override
  String get atsUnsupportedFileType =>
      remote.text('atsUnsupportedFileType') ?? _base.atsUnsupportedFileType;

  @override
  String get atsResumeRequired =>
      remote.text('atsResumeRequired') ?? _base.atsResumeRequired;

  @override
  String get atsCancelled => remote.text('atsCancelled') ?? _base.atsCancelled;

  @override
  String get atsAiStillWorkingAnalysis =>
      remote.text('atsAiStillWorkingAnalysis') ??
      _base.atsAiStillWorkingAnalysis;

  @override
  String get atsAnalyzeUnexpectedError =>
      remote.text('atsAnalyzeUnexpectedError') ??
      _base.atsAnalyzeUnexpectedError;

  @override
  String get atsOpenAnalysisFailed =>
      remote.text('atsOpenAnalysisFailed') ?? _base.atsOpenAnalysisFailed;

  @override
  String get atsResultsTitle =>
      remote.text('atsResultsTitle') ?? _base.atsResultsTitle;

  @override
  String get atsTabScore => remote.text('atsTabScore') ?? _base.atsTabScore;

  @override
  String get atsTabRecommendations =>
      remote.text('atsTabRecommendations') ?? _base.atsTabRecommendations;

  @override
  String get atsGenerateImprovedCv =>
      remote.text('atsGenerateImprovedCv') ?? _base.atsGenerateImprovedCv;

  @override
  String get atsGenerating =>
      remote.text('atsGenerating') ?? _base.atsGenerating;

  @override
  String get atsGenerateUnexpectedError =>
      remote.text('atsGenerateUnexpectedError') ??
      _base.atsGenerateUnexpectedError;

  @override
  String get atsAiStillWorkingGeneration =>
      remote.text('atsAiStillWorkingGeneration') ??
      _base.atsAiStillWorkingGeneration;

  @override
  String get atsUploadTapHint =>
      remote.text('atsUploadTapHint') ?? _base.atsUploadTapHint;

  @override
  String get atsUploadMaxSize =>
      remote.text('atsUploadMaxSize') ?? _base.atsUploadMaxSize;

  @override
  String get atsRemoveFile =>
      remote.text('atsRemoveFile') ?? _base.atsRemoveFile;

  @override
  String get atsOr => remote.text('atsOr') ?? _base.atsOr;

  @override
  String get atsNoKeywords =>
      remote.text('atsNoKeywords') ?? _base.atsNoKeywords;

  @override
  String atsShowMoreCount(int count) =>
      remote.format(
        'atsShowMoreCount',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'count': count},
        ),
      ) ??
      _base.atsShowMoreCount(count);

  @override
  String atsKeywordDialogTitle(String keyword) =>
      remote.format(
        'atsKeywordDialogTitle',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'keyword': keyword},
        ),
      ) ??
      _base.atsKeywordDialogTitle(keyword);

  @override
  String atsKeywordDialogBody(String keyword) =>
      remote.format(
        'atsKeywordDialogBody',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'keyword': keyword},
        ),
      ) ??
      _base.atsKeywordDialogBody(keyword);

  @override
  String get atsGotIt => remote.text('atsGotIt') ?? _base.atsGotIt;

  @override
  String get atsCriteriaDetails =>
      remote.text('atsCriteriaDetails') ?? _base.atsCriteriaDetails;

  @override
  String get atsKeywordsTitle =>
      remote.text('atsKeywordsTitle') ?? _base.atsKeywordsTitle;

  @override
  String atsGradeLabel(String grade) =>
      remote.format(
        'atsGradeLabel',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'grade': grade},
        ),
      ) ??
      _base.atsGradeLabel(grade);

  @override
  String get atsJobMatchSemantic =>
      remote.text('atsJobMatchSemantic') ?? _base.atsJobMatchSemantic;

  @override
  String get atsJobMatchPercentage =>
      remote.text('atsJobMatchPercentage') ?? _base.atsJobMatchPercentage;

  @override
  String atsKeywordsFound(int count) =>
      remote.format(
        'atsKeywordsFound',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'count': count},
        ),
      ) ??
      _base.atsKeywordsFound(count);

  @override
  String atsKeywordsMissing(int count) =>
      remote.format(
        'atsKeywordsMissing',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'count': count},
        ),
      ) ??
      _base.atsKeywordsMissing(count);

  @override
  String get atsNoStrengths =>
      remote.text('atsNoStrengths') ?? _base.atsNoStrengths;

  @override
  String get atsQuickWins => remote.text('atsQuickWins') ?? _base.atsQuickWins;

  @override
  String get atsNoQuickWins =>
      remote.text('atsNoQuickWins') ?? _base.atsNoQuickWins;

  @override
  String get atsUpgradeTitle =>
      remote.text('atsUpgradeTitle') ?? _base.atsUpgradeTitle;

  @override
  String get atsUpgradeBody =>
      remote.text('atsUpgradeBody') ?? _base.atsUpgradeBody;

  @override
  String get atsKeywordSourceJd =>
      remote.text('atsKeywordSourceJd') ?? _base.atsKeywordSourceJd;

  @override
  String get atsKeywordSourceGeneric =>
      remote.text('atsKeywordSourceGeneric') ?? _base.atsKeywordSourceGeneric;

  @override
  String get atsBandExcellent =>
      remote.text('atsBandExcellent') ?? _base.atsBandExcellent;

  @override
  String get atsBandVeryGood =>
      remote.text('atsBandVeryGood') ?? _base.atsBandVeryGood;

  @override
  String get atsBandFair => remote.text('atsBandFair') ?? _base.atsBandFair;

  @override
  String get atsBandWeak => remote.text('atsBandWeak') ?? _base.atsBandWeak;

  @override
  String jobsMatchScore(int score) =>
      remote.format(
        'jobsMatchScore',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'score': score},
        ),
      ) ??
      _base.jobsMatchScore(score);

  @override
  String atsBenchmark(String category) =>
      remote.format(
        'atsBenchmark',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'category': category},
        ),
      ) ??
      _base.atsBenchmark(category);

  @override
  String get atsInputTitle =>
      remote.text('atsInputTitle') ?? _base.atsInputTitle;

  @override
  String get atsInputIntroduction =>
      remote.text('atsInputIntroduction') ?? _base.atsInputIntroduction;

  @override
  String get atsInputCvSource =>
      remote.text('atsInputCvSource') ?? _base.atsInputCvSource;

  @override
  String get atsInputSavedCv =>
      remote.text('atsInputSavedCv') ?? _base.atsInputSavedCv;

  @override
  String get atsInputUploadFile =>
      remote.text('atsInputUploadFile') ?? _base.atsInputUploadFile;

  @override
  String get atsInputPasteText =>
      remote.text('atsInputPasteText') ?? _base.atsInputPasteText;

  @override
  String get atsInputNoSavedCvs =>
      remote.text('atsInputNoSavedCvs') ?? _base.atsInputNoSavedCvs;

  @override
  String get atsInputSavedCvsError =>
      remote.text('atsInputSavedCvsError') ?? _base.atsInputSavedCvsError;

  @override
  String get atsInputSavedCvHint =>
      remote.text('atsInputSavedCvHint') ?? _base.atsInputSavedCvHint;

  @override
  String get atsInputSelectCv =>
      remote.text('atsInputSelectCv') ?? _base.atsInputSelectCv;

  @override
  String get atsInputCvTextUnavailable =>
      remote.text('atsInputCvTextUnavailable') ??
      _base.atsInputCvTextUnavailable;

  @override
  String get atsInputJobTitle =>
      remote.text('atsInputJobTitle') ?? _base.atsInputJobTitle;

  @override
  String get atsInputJobTitleHint =>
      remote.text('atsInputJobTitleHint') ?? _base.atsInputJobTitleHint;

  @override
  String get atsInputJobTitleRequired =>
      remote.text('atsInputJobTitleRequired') ?? _base.atsInputJobTitleRequired;

  @override
  String get atsInputJobDescription =>
      remote.text('atsInputJobDescription') ?? _base.atsInputJobDescription;

  @override
  String get atsInputJobDescriptionHint =>
      remote.text('atsInputJobDescriptionHint') ??
      _base.atsInputJobDescriptionHint;

  @override
  String atsInputJobDescriptionTooLong(int max) =>
      remote.format(
        'atsInputJobDescriptionTooLong',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'max': max},
        ),
      ) ??
      _base.atsInputJobDescriptionTooLong(max);

  @override
  String get atsInputResumeTextHint =>
      remote.text('atsInputResumeTextHint') ?? _base.atsInputResumeTextHint;

  @override
  String get atsInputResumeTextRequired =>
      remote.text('atsInputResumeTextRequired') ??
      _base.atsInputResumeTextRequired;

  @override
  String get atsInputAnalyze =>
      remote.text('atsInputAnalyze') ?? _base.atsInputAnalyze;

  @override
  String get atsInputAnalyzing =>
      remote.text('atsInputAnalyzing') ?? _base.atsInputAnalyzing;

  @override
  String get atsInputPrivacy =>
      remote.text('atsInputPrivacy') ?? _base.atsInputPrivacy;

  @override
  String get atsResultPrioritizedImprovements =>
      remote.text('atsResultPrioritizedImprovements') ??
      _base.atsResultPrioritizedImprovements;

  @override
  String get atsResultImprovementsAvailability =>
      remote.text('atsResultImprovementsAvailability') ??
      _base.atsResultImprovementsAvailability;

  @override
  String get atsResultHighPriority =>
      remote.text('atsResultHighPriority') ?? _base.atsResultHighPriority;

  @override
  String get atsResultMediumPriority =>
      remote.text('atsResultMediumPriority') ?? _base.atsResultMediumPriority;

  @override
  String get atsResultLowPriority =>
      remote.text('atsResultLowPriority') ?? _base.atsResultLowPriority;

  @override
  String get homeHeroFirstCvTitle =>
      remote.text('homeHeroFirstCvTitle') ?? _base.homeHeroFirstCvTitle;

  @override
  String get homeHeroFirstCvDescription =>
      remote.text('homeHeroFirstCvDescription') ??
      _base.homeHeroFirstCvDescription;

  @override
  String get homeHeroCreateCv =>
      remote.text('homeHeroCreateCv') ?? _base.homeHeroCreateCv;

  @override
  String get homeHeroLatestCv =>
      remote.text('homeHeroLatestCv') ?? _base.homeHeroLatestCv;

  @override
  String get homeHeroNextStep =>
      remote.text('homeHeroNextStep') ?? _base.homeHeroNextStep;

  @override
  String get homeHeroAnalyzeNextStep =>
      remote.text('homeHeroAnalyzeNextStep') ?? _base.homeHeroAnalyzeNextStep;

  @override
  String get homeHeroReviewNextStep =>
      remote.text('homeHeroReviewNextStep') ?? _base.homeHeroReviewNextStep;

  @override
  String get homeHeroReviewCv =>
      remote.text('homeHeroReviewCv') ?? _base.homeHeroReviewCv;

  @override
  String get homeHeroAtsScore =>
      remote.text('homeHeroAtsScore') ?? _base.homeHeroAtsScore;

  @override
  String get homeHeroScoreUnavailable =>
      remote.text('homeHeroScoreUnavailable') ?? _base.homeHeroScoreUnavailable;

  @override
  String get homeToolsTitle =>
      remote.text('homeToolsTitle') ?? _base.homeToolsTitle;

  @override
  String get homeToolsAtsDescription =>
      remote.text('homeToolsAtsDescription') ?? _base.homeToolsAtsDescription;

  @override
  String get homeToolsJobMatchDescription =>
      remote.text('homeToolsJobMatchDescription') ??
      _base.homeToolsJobMatchDescription;

  @override
  String get homeActivityTitle =>
      remote.text('homeActivityTitle') ?? _base.homeActivityTitle;

  @override
  String get homeHeroLatestCvError =>
      remote.text('homeHeroLatestCvError') ?? _base.homeHeroLatestCvError;

  @override
  String get homeHeroSavedCvs =>
      remote.text('homeHeroSavedCvs') ?? _base.homeHeroSavedCvs;

  @override
  String get savedCvsLoading =>
      remote.text('savedCvsLoading') ?? _base.savedCvsLoading;

  @override
  String get homeActivityEmpty =>
      remote.text('homeActivityEmpty') ?? _base.homeActivityEmpty;

  @override
  String atsInputJobTitleTooLong(int max) =>
      remote.format(
        'atsInputJobTitleTooLong',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'max': max},
        ),
      ) ??
      _base.atsInputJobTitleTooLong(max);

  @override
  String get atsInputSelectSourceRequired =>
      remote.text('atsInputSelectSourceRequired') ??
      _base.atsInputSelectSourceRequired;

  @override
  String homeHeroUpdatedAt(String time) =>
      remote.format(
        'homeHeroUpdatedAt',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'time': time},
        ),
      ) ??
      _base.homeHeroUpdatedAt(time);

  @override
  String get homeHeroBandExcellent =>
      remote.text('homeHeroBandExcellent') ?? _base.homeHeroBandExcellent;

  @override
  String get homeHeroBandVeryGood =>
      remote.text('homeHeroBandVeryGood') ?? _base.homeHeroBandVeryGood;

  @override
  String get homeHeroBandFair =>
      remote.text('homeHeroBandFair') ?? _base.homeHeroBandFair;

  @override
  String get homeHeroBandWeak =>
      remote.text('homeHeroBandWeak') ?? _base.homeHeroBandWeak;

  @override
  String get homeStatsCvs => remote.text('homeStatsCvs') ?? _base.homeStatsCvs;

  @override
  String get homeStatsAnalyses =>
      remote.text('homeStatsAnalyses') ?? _base.homeStatsAnalyses;

  @override
  String get homeActivitySavedCv =>
      remote.text('homeActivitySavedCv') ?? _base.homeActivitySavedCv;

  @override
  String atsResultKeywordSummary(int matched, int missing) =>
      remote.format(
        'atsResultKeywordSummary',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'matched': matched, 'missing': missing},
        ),
      ) ??
      _base.atsResultKeywordSummary(matched, missing);

  @override
  String get premiumGateAppBar =>
      remote.text('premiumGateAppBar') ?? _base.premiumGateAppBar;

  @override
  String get premiumGateHeroTitle =>
      remote.text('premiumGateHeroTitle') ?? _base.premiumGateHeroTitle;

  @override
  String get premiumGateHeroBody =>
      remote.text('premiumGateHeroBody') ?? _base.premiumGateHeroBody;

  @override
  String get premiumGateBenefitsTitle =>
      remote.text('premiumGateBenefitsTitle') ?? _base.premiumGateBenefitsTitle;

  @override
  String get premiumGateBenefitPdf =>
      remote.text('premiumGateBenefitPdf') ?? _base.premiumGateBenefitPdf;

  @override
  String get premiumGateBenefitPdfBody =>
      remote.text('premiumGateBenefitPdfBody') ??
      _base.premiumGateBenefitPdfBody;

  @override
  String get premiumGateBenefitAi =>
      remote.text('premiumGateBenefitAi') ?? _base.premiumGateBenefitAi;

  @override
  String get premiumGateBenefitAiBody =>
      remote.text('premiumGateBenefitAiBody') ?? _base.premiumGateBenefitAiBody;

  @override
  String get premiumGateBenefitAts =>
      remote.text('premiumGateBenefitAts') ?? _base.premiumGateBenefitAts;

  @override
  String get premiumGateBenefitAtsBody =>
      remote.text('premiumGateBenefitAtsBody') ??
      _base.premiumGateBenefitAtsBody;

  @override
  String get premiumGateBenefitJobMatch =>
      remote.text('premiumGateBenefitJobMatch') ??
      _base.premiumGateBenefitJobMatch;

  @override
  String get premiumGateBenefitJobMatchBody =>
      remote.text('premiumGateBenefitJobMatchBody') ??
      _base.premiumGateBenefitJobMatchBody;

  @override
  String get premiumGateBenefitLimits =>
      remote.text('premiumGateBenefitLimits') ?? _base.premiumGateBenefitLimits;

  @override
  String get premiumGateBenefitLimitsBody =>
      remote.text('premiumGateBenefitLimitsBody') ??
      _base.premiumGateBenefitLimitsBody;

  @override
  String get premiumGatePlansTitle =>
      remote.text('premiumGatePlansTitle') ?? _base.premiumGatePlansTitle;

  @override
  String premiumGatePrice(String price, String currency) =>
      remote.format(
        'premiumGatePrice',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'price': price, 'currency': currency},
        ),
      ) ??
      _base.premiumGatePrice(price, currency);

  @override
  String get premiumGateCurrencySar =>
      remote.text('premiumGateCurrencySar') ?? _base.premiumGateCurrencySar;

  @override
  String get premiumGatePeriodYear =>
      remote.text('premiumGatePeriodYear') ?? _base.premiumGatePeriodYear;

  @override
  String premiumGatePeriod(int months) =>
      remote.format(
        'premiumGatePeriod',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'months': months},
        ),
      ) ??
      _base.premiumGatePeriod(months);

  @override
  String premiumGatePerMonth(String price, String currency) =>
      remote.format(
        'premiumGatePerMonth',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'price': price, 'currency': currency},
        ),
      ) ??
      _base.premiumGatePerMonth(price, currency);

  @override
  String get premiumGatePriceNote =>
      remote.text('premiumGatePriceNote') ?? _base.premiumGatePriceNote;

  @override
  String get premiumGatePlansFailed =>
      remote.text('premiumGatePlansFailed') ?? _base.premiumGatePlansFailed;

  @override
  String get premiumGateNoPlans =>
      remote.text('premiumGateNoPlans') ?? _base.premiumGateNoPlans;

  @override
  String get premiumGateRetry =>
      remote.text('premiumGateRetry') ?? _base.premiumGateRetry;

  @override
  String get premiumGateRefresh =>
      remote.text('premiumGateRefresh') ?? _base.premiumGateRefresh;

  @override
  String get premiumGateRefreshing =>
      remote.text('premiumGateRefreshing') ?? _base.premiumGateRefreshing;

  @override
  String get premiumGateNotFound =>
      remote.text('premiumGateNotFound') ?? _base.premiumGateNotFound;

  @override
  String get premiumGateRefreshFailed =>
      remote.text('premiumGateRefreshFailed') ?? _base.premiumGateRefreshFailed;

  @override
  String get premiumGateActiveTitle =>
      remote.text('premiumGateActiveTitle') ?? _base.premiumGateActiveTitle;

  @override
  String get premiumGateActiveBody =>
      remote.text('premiumGateActiveBody') ?? _base.premiumGateActiveBody;

  @override
  String get premiumGateContinue =>
      remote.text('premiumGateContinue') ?? _base.premiumGateContinue;

  @override
  String get premiumGateNotNow =>
      remote.text('premiumGateNotNow') ?? _base.premiumGateNotNow;

  @override
  String get premiumGatePrivacy =>
      remote.text('premiumGatePrivacy') ?? _base.premiumGatePrivacy;

  @override
  String get premiumGateJobMatchSeePlans =>
      remote.text('premiumGateJobMatchSeePlans') ??
      _base.premiumGateJobMatchSeePlans;

  @override
  String get premiumGateJobMatchBenefitScore =>
      remote.text('premiumGateJobMatchBenefitScore') ??
      _base.premiumGateJobMatchBenefitScore;

  @override
  String get premiumGateJobMatchBenefitKeywords =>
      remote.text('premiumGateJobMatchBenefitKeywords') ??
      _base.premiumGateJobMatchBenefitKeywords;

  @override
  String get premiumGateJobMatchBenefitEdits =>
      remote.text('premiumGateJobMatchBenefitEdits') ??
      _base.premiumGateJobMatchBenefitEdits;

  @override
  String get jobMatchFailedTitle =>
      remote.text('jobMatchFailedTitle') ?? _base.jobMatchFailedTitle;

  @override
  String get jobMatchFailedManualHint =>
      remote.text('jobMatchFailedManualHint') ?? _base.jobMatchFailedManualHint;

  @override
  String get cvHubTitle => remote.text('cvHubTitle') ?? _base.cvHubTitle;

  @override
  String get cvHubReady => remote.text('cvHubReady') ?? _base.cvHubReady;

  @override
  String get cvHubAtsLabel =>
      remote.text('cvHubAtsLabel') ?? _base.cvHubAtsLabel;

  @override
  String cvHubAtsScore(int score) =>
      remote.format(
        'cvHubAtsScore',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'score': score},
        ),
      ) ??
      _base.cvHubAtsScore(score);

  @override
  String cvHubGrade(String grade) =>
      remote.format(
        'cvHubGrade',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'grade': grade},
        ),
      ) ??
      _base.cvHubGrade(grade);

  @override
  String get cvHubPreview => remote.text('cvHubPreview') ?? _base.cvHubPreview;

  @override
  String get cvHubShowFull =>
      remote.text('cvHubShowFull') ?? _base.cvHubShowFull;

  @override
  String get cvHubShowLess =>
      remote.text('cvHubShowLess') ?? _base.cvHubShowLess;

  @override
  String get cvHubDownload =>
      remote.text('cvHubDownload') ?? _base.cvHubDownload;

  @override
  String get cvHubPreparing =>
      remote.text('cvHubPreparing') ?? _base.cvHubPreparing;

  @override
  String get cvHubShare => remote.text('cvHubShare') ?? _base.cvHubShare;

  @override
  String get cvHubNextSteps =>
      remote.text('cvHubNextSteps') ?? _base.cvHubNextSteps;

  @override
  String get cvHubCheckAts =>
      remote.text('cvHubCheckAts') ?? _base.cvHubCheckAts;

  @override
  String get cvHubCheckAtsBody =>
      remote.text('cvHubCheckAtsBody') ?? _base.cvHubCheckAtsBody;

  @override
  String get cvHubMatchJob =>
      remote.text('cvHubMatchJob') ?? _base.cvHubMatchJob;

  @override
  String get cvHubMatchJobBody =>
      remote.text('cvHubMatchJobBody') ?? _base.cvHubMatchJobBody;

  @override
  String get cvHubEdit => remote.text('cvHubEdit') ?? _base.cvHubEdit;

  @override
  String get cvHubEditBody =>
      remote.text('cvHubEditBody') ?? _base.cvHubEditBody;

  @override
  String get cvHubEmpty => remote.text('cvHubEmpty') ?? _base.cvHubEmpty;

  @override
  String get cvHubAppBar => remote.text('cvHubAppBar') ?? _base.cvHubAppBar;

  @override
  String get cvHubRecommended =>
      remote.text('cvHubRecommended') ?? _base.cvHubRecommended;

  @override
  String get premiumGateAvailabilityNote =>
      remote.text('premiumGateAvailabilityNote') ??
      _base.premiumGateAvailabilityNote;

  @override
  String get registerInterest =>
      remote.text('registerInterest') ?? _base.registerInterest;

  @override
  String get noMatchingJobs =>
      remote.text('noMatchingJobs') ?? _base.noMatchingJobs;

  @override
  String get clearFilters => remote.text('clearFilters') ?? _base.clearFilters;

  @override
  String get compatibilityScoreLabel =>
      remote.text('compatibilityScoreLabel') ?? _base.compatibilityScoreLabel;

  @override
  String compatibilityScoreValue(int score) =>
      remote.format(
        'compatibilityScoreValue',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'score': score},
        ),
      ) ??
      _base.compatibilityScoreValue(score);

  @override
  String get showPassword => remote.text('showPassword') ?? _base.showPassword;

  @override
  String get hidePassword => remote.text('hidePassword') ?? _base.hidePassword;

  @override
  String get atsCriterionFormat =>
      remote.text('atsCriterionFormat') ?? _base.atsCriterionFormat;

  @override
  String get atsCriterionKeywords =>
      remote.text('atsCriterionKeywords') ?? _base.atsCriterionKeywords;

  @override
  String get atsCriterionStructure =>
      remote.text('atsCriterionStructure') ?? _base.atsCriterionStructure;

  @override
  String get atsCriterionExperience =>
      remote.text('atsCriterionExperience') ?? _base.atsCriterionExperience;

  @override
  String get atsCriterionEducation =>
      remote.text('atsCriterionEducation') ?? _base.atsCriterionEducation;

  @override
  String get atsCriterionSummary =>
      remote.text('atsCriterionSummary') ?? _base.atsCriterionSummary;

  @override
  String get atsCriterionContact =>
      remote.text('atsCriterionContact') ?? _base.atsCriterionContact;

  @override
  String get homeHeaderSubtitleNew =>
      remote.text('homeHeaderSubtitleNew') ?? _base.homeHeaderSubtitleNew;

  @override
  String get homeHeaderSubtitleReturning =>
      remote.text('homeHeaderSubtitleReturning') ??
      _base.homeHeaderSubtitleReturning;

  @override
  String get homeHeroStartTitle =>
      remote.text('homeHeroStartTitle') ?? _base.homeHeroStartTitle;

  @override
  String get homeHeroStartBody =>
      remote.text('homeHeroStartBody') ?? _base.homeHeroStartBody;

  @override
  String get homeHeroCreateYourCv =>
      remote.text('homeHeroCreateYourCv') ?? _base.homeHeroCreateYourCv;

  @override
  String get homeHeroUploadOld =>
      remote.text('homeHeroUploadOld') ?? _base.homeHeroUploadOld;

  @override
  String homeHeroScoreTitle(String score) =>
      remote.format(
        'homeHeroScoreTitle',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'score': score},
        ),
      ) ??
      _base.homeHeroScoreTitle(score);

  @override
  String get homeHeroScoreExcellent =>
      remote.text('homeHeroScoreExcellent') ?? _base.homeHeroScoreExcellent;

  @override
  String get homeHeroScoreVeryGood =>
      remote.text('homeHeroScoreVeryGood') ?? _base.homeHeroScoreVeryGood;

  @override
  String get homeHeroScoreFair =>
      remote.text('homeHeroScoreFair') ?? _base.homeHeroScoreFair;

  @override
  String get homeHeroScoreWeak =>
      remote.text('homeHeroScoreWeak') ?? _base.homeHeroScoreWeak;

  @override
  String get homeHeroNextStronger =>
      remote.text('homeHeroNextStronger') ?? _base.homeHeroNextStronger;

  @override
  String get homeHeroImprove =>
      remote.text('homeHeroImprove') ?? _base.homeHeroImprove;

  @override
  String get homeHeroTargetJob =>
      remote.text('homeHeroTargetJob') ?? _base.homeHeroTargetJob;

  @override
  String get homeToolCreateTitle =>
      remote.text('homeToolCreateTitle') ?? _base.homeToolCreateTitle;

  @override
  String get homeToolCreateBody =>
      remote.text('homeToolCreateBody') ?? _base.homeToolCreateBody;

  @override
  String get homeToolAtsTitle =>
      remote.text('homeToolAtsTitle') ?? _base.homeToolAtsTitle;

  @override
  String get homeToolAtsBody =>
      remote.text('homeToolAtsBody') ?? _base.homeToolAtsBody;

  @override
  String get homeToolEducationTitle =>
      remote.text('homeToolEducationTitle') ?? _base.homeToolEducationTitle;

  @override
  String get homeToolEducationBody =>
      remote.text('homeToolEducationBody') ?? _base.homeToolEducationBody;

  @override
  String get homeJobsTitle =>
      remote.text('homeJobsTitle') ?? _base.homeJobsTitle;

  @override
  String get homeJobsViewAll =>
      remote.text('homeJobsViewAll') ?? _base.homeJobsViewAll;

  @override
  String get homeJobsEmpty =>
      remote.text('homeJobsEmpty') ?? _base.homeJobsEmpty;

  /// Placeholder Dart types of every label, in parameter order.
  @visibleForTesting
  static const debugPlaceholderTypes = <String, List<String>>{
    'appTitle': [],
    'switchToEnglish': [],
    'switchToArabic': [],
    'languageEnglish': [],
    'languageArabic': [],
    'somethingWentWrong': [],
    'safeRetryMessage': [],
    'retry': [],
    'cancel': [],
    'save': [],
    'next': [],
    'back': [],
    'getStarted': [],
    'createCv': [],
    'generateCv': [],
    'settings': [],
    'myCvs': [],
    'analyses': [],
    'greetingName': ['String'],
    'atsScoreLabel': ['int'],
    'cvCount': ['int'],
    'analysisCount': ['int'],
    'welcomeToSirati': [],
    'buildCvProfessionally': [],
    'createAccount': [],
    'signIn': [],
    'invalidSaudiPhone': [],
    'invalidUaePhone': [],
    'invalidKuwaitPhone': [],
    'invalidQatarPhone': [],
    'invalidBahrainPhone': [],
    'invalidOmanPhone': [],
    'invalidGulfOrIntlPhone': [],
    'invalidEmail': [],
    'personalDetailsTitle': [],
    'personalDetailsSubtitle': [],
    'inputLanguageLabel': [],
    'languageModeDual': [],
    'languageModeArOnly': [],
    'languageModeEnOnly': [],
    'fullNameAr': [],
    'fullNameArHint': [],
    'fullNameEn': [],
    'fullNameEnHint': [],
    'headlineAr': [],
    'headlineArHint': [],
    'headlineEn': [],
    'headlineEnHint': [],
    'locationAr': [],
    'locationArHint': [],
    'locationEn': [],
    'locationEnHint': [],
    'emailLabel': [],
    'phoneLabel': [],
    'phoneHelper': [],
    'linkedinLabel': [],
    'atsPhotoWarningTitle': [],
    'atsPhotoWarningBody': [],
    'atsPhotoEnabled': [],
    'professionalSummaryTitle': [],
    'professionalSummarySubtitle': [],
    'summaryArLabel': [],
    'summaryArHint': [],
    'summaryEnLabel': [],
    'summaryEnHint': [],
    'summaryAdviceEmpty': [],
    'summaryAdviceShort': [],
    'summaryAdviceGood': [],
    'summaryAdviceLong': [],
    'summaryWordCountLine': ['int', 'int', 'String'],
    'viewProfile': [],
    'accountSection': [],
    'editProfile': [],
    'changePassword': [],
    'preferencesSection': [],
    'language': [],
    'appearance': [],
    'change': [],
    'themeSystem': [],
    'themeLight': [],
    'themeDark': [],
    'pushNotifications': [],
    'aboutSection': [],
    'privacyPolicy': [],
    'contactUs': [],
    'contactUsSubtitle': [],
    'contactUsEmailSubject': [],
    'contactUsFallback': ['String'],
    'replayIntro': [],
    'replayIntroSubtitle': [],
    'appVersion': [],
    'dangerZone': [],
    'logOut': [],
    'logOutConfirmTitle': [],
    'logOutConfirmBody': [],
    'logOutFailed': [],
    'logOutPartial': [],
    'deleteAccount': [],
    'couldNotLoadProfile': [],
    'notificationPrefUpdateFailed': [],
    'signedOutLocally': [],
    'userFallback': [],
    'cvEditorTitle': [],
    'preparingEditor': [],
    'loadErrorTitle': [],
    'cvLoadFailed': [],
    'autosaving': [],
    'unsavedEdits': [],
    'saved': [],
    'backToEdit': [],
    'livePreview': [],
    'saveNow': [],
    'cvSaved': [],
    'cvSaveFailed': [],
    'tabPersonal': [],
    'tabExperience': [],
    'tabSkills': [],
    'tabOrder': [],
    'recoverDraftTitle': [],
    'recoverDraftBody': [],
    'discardDraft': [],
    'restoreDraft': [],
    'draftRestored': [],
    'sectionOrderTitle': [],
    'sectionOrderHint': [],
    'moveUp': [],
    'moveDown': [],
    'sectionPersonal': [],
    'sectionSummary': [],
    'sectionExperience': [],
    'sectionEducation': [],
    'sectionSkills': [],
    'sectionLanguages': [],
    'sectionCertifications': [],
    'sectionProjects': [],
    'sectionCustom': [],
    'calendarSystemLabel': [],
    'calendarGregorian': [],
    'calendarHijri': [],
    'workExperienceTitle': [],
    'workExperienceSubtitle': [],
    'addExperience': [],
    'sortChronologically': [],
    'educationQualificationsTitle': [],
    'educationQualificationsSubtitle': [],
    'addEducation': [],
    'jobTitleAr': [],
    'jobTitleArHint': [],
    'jobTitleEn': [],
    'jobTitleEnHint': [],
    'companyAr': [],
    'companyArHint': [],
    'companyEn': [],
    'companyEnHint': [],
    'startDateLabel': [],
    'startDateHint': [],
    'endDateLabel': [],
    'endDateHint': [],
    'currentlyHere': [],
    'currentlyWorking': [],
    'achievementsLabel': [],
    'addAchievement': [],
    'noAchievementsHint': [],
    'achievementHint': [],
    'endDateBeforeStart': [],
    'institutionAr': [],
    'institutionArHint': [],
    'institutionEn': [],
    'institutionEnHint': [],
    'degreeLabel': [],
    'degreeHint': [],
    'fieldOfStudyLabel': [],
    'fieldOfStudyHint': [],
    'startYearLabel': [],
    'startYearHint': [],
    'graduationYearLabel': [],
    'graduationYearHint': [],
    'skillsTitle': [],
    'skillsSubtitle': [],
    'noSkillsHint': [],
    'skillNameHint': [],
    'addItem': [],
    'proficiencyLevel': [],
    'skillLevelBeginner': [],
    'skillLevelIntermediate': [],
    'skillLevelAdvanced': [],
    'skillLevelExpert': [],
    'skillCategory': [],
    'skillCategoryTechnical': [],
    'skillCategorySoft': [],
    'skillCategoryTools': [],
    'skillCategoryManagement': [],
    'skillCategoryGeneral': [],
    'languagesTitle': [],
    'languagesSubtitle': [],
    'noLanguagesHint': [],
    'languageNameHint': [],
    'languageLevelNative': [],
    'languageLevelFluent': [],
    'languageLevelC1': [],
    'languageLevelB2': [],
    'languageLevelA2': [],
    'certificationsTitle': [],
    'certificationsSubtitle': [],
    'addCertification': [],
    'certNameLabel': [],
    'certNameHint': [],
    'certIssuerLabel': [],
    'certIssuerHint': [],
    'issueYearLabel': [],
    'issueYearHint': [],
    'expiryYearLabel': [],
    'expiryYearHint': [],
    'noExpiry': [],
    'certPermanent': [],
    'projectsTitle': [],
    'projectsSubtitle': [],
    'addProject': [],
    'projectTitleLabel': [],
    'projectTitleHint': [],
    'projectRoleLabel': [],
    'projectRoleHint': [],
    'projectUrlLabel': [],
    'invalidProjectUrl': [],
    'projectDescLabel': [],
    'projectDescHint': [],
    'deleteItem': [],
    'jobMatchTitle': [],
    'jobMatchPremiumBadge': [],
    'jobMatchEntryTitle': [],
    'jobMatchEntrySubtitle': [],
    'jobMatchEntryButton': [],
    'jobMatchQuotaRemaining': ['int'],
    'jobMatchJobTitleLabel': [],
    'jobMatchJobTitleHint': [],
    'jobMatchDescriptionLabel': [],
    'jobMatchDescriptionHint': [],
    'jobMatchDescriptionRequired': [],
    'jobMatchDescriptionTooLong': ['int'],
    'jobMatchTitleTooLong': ['int'],
    'jobMatchCharCount': ['int', 'int'],
    'jobMatchPickCvTitle': [],
    'jobMatchPickCvRequired': [],
    'jobMatchNoCvTitle': [],
    'jobMatchNoCvBody': [],
    'jobMatchCreateTailoredCv': [],
    'jobMatchOrCreateTailored': [],
    'jobMatchCvsLoadFailed': [],
    'jobMatchRetry': [],
    'jobMatchSubmit': [],
    'jobMatchSubmitting': [],
    'jobMatchCvStillPreparing': [],
    'jobMatchUntitledCv': [],
    'jobMatchPaywallTitle': [],
    'jobMatchPaywallBody': [],
    'jobMatchPaywallTrial': ['int'],
    'jobMatchPaywallRefresh': [],
    'jobMatchQuotaTitle': [],
    'jobMatchQuotaBody': [],
    'jobMatchUnavailableTitle': [],
    'jobMatchUnavailableBody': [],
    'jobMatchEntitlementLoadFailed': [],
    'jobMatchErrorSubscription': [],
    'jobMatchErrorLimit': [],
    'jobMatchErrorConflict': [],
    'jobMatchErrorStale': [],
    'jobMatchErrorCvTooLong': [],
    'jobMatchErrorInvalidDescription': [],
    'jobMatchErrorInvalidSelection': [],
    'jobMatchErrorUnavailable': [],
    'jobMatchErrorNotFound': [],
    'jobMatchErrorNetwork': [],
    'jobMatchErrorUnknown': [],
    'jobMatchResultTitle': [],
    'jobMatchScoreLabel': [],
    'jobMatchScoreSemantics': ['int'],
    'jobMatchCoverage': ['int'],
    'jobMatchGrade': ['String'],
    'jobMatchMatchedKeywords': [],
    'jobMatchMissingKeywords': [],
    'jobMatchNoKeywords': [],
    'jobMatchStrengths': [],
    'jobMatchGaps': [],
    'jobMatchSummary': [],
    'jobMatchAiPreparing': [],
    'jobMatchAiStillProcessing': [],
    'jobMatchCheckAgain': [],
    'jobMatchAiFailed': [],
    'jobMatchAiNotConfigured': [],
    'jobMatchSuggestionsTitle': [],
    'jobMatchSuggestionsHint': [],
    'jobMatchNoSuggestions': [],
    'jobMatchBefore': [],
    'jobMatchAfter': [],
    'jobMatchAddition': [],
    'jobMatchWhy': [],
    'jobMatchTargets': [],
    'jobMatchNeedsUserFact': [],
    'jobMatchAppliedBadge': [],
    'jobMatchApplySelected': ['int'],
    'jobMatchSelectToApply': [],
    'jobMatchApplying': [],
    'jobMatchAppliedSuccess': [],
    'jobMatchOpenTailoredCv': [],
    'jobMatchNewMatch': [],
    'jobMatchSectionName': ['String'],
    'jobMatchRetrySuggestions': [],
    'jobMatchLoading': [],
    'sharedLoading': [],
    'jm4ConfirmFact': [],
    'jm4HonestyHint': [],
    'jobsFilterAll': [],
    'jobsPresetMatched': [],
    'jobsPresetGov': [],
    'jobsPresetEnterprise': [],
    'jobsPresetTamheer': [],
    'jobsFilterRemote': [],
    'jobsSearchHint': [],
    'jobsCategoryTech': [],
    'jobsCategoryFinance': [],
    'jobsCategoryHealth': [],
    'jobsCityAll': [],
    'jobsCityRiyadh': [],
    'jobsCityJeddah': [],
    'jobsCityDammam': [],
    'jobsCityKhobar': [],
    'jobsCityMecca': [],
    'jobsCityMedina': [],
    'jobsPersonalizedTitle': [],
    'jobsPersonalizedFallback': [],
    'jobsMatchedActive': [],
    'jobsMatchToggle': [],
    'jobsEmptyFeed': [],
    'jobsLoadFailed': [],
    'jobsLatestPostings': [],
    'jobsDetailTitle': [],
    'jobsVerifiedSourceDetail': [],
    'jobsTamheerProgram': [],
    'jobsCompatibilityTitle': [],
    'jobsSkillsRequired': [],
    'jobsDescriptionTitle': [],
    'jobsTailorCv': [],
    'jobsOpenApplyFailed': [],
    'jobsApplyOfficialSite': [],
    'jobsVerifiedSourceCard': [],
    'jobsTamheerBadge': [],
    'jobsNewBadge': [],
    'jobsDetailsLink': [],
    'jobsVerifiedSourceFeatured': [],
    'jobsTamheerBadgeFeatured': [],
    'jobsApplyNow': [],
    'atsFileTooLarge': ['int'],
    'atsUnsupportedFileType': [],
    'atsResumeRequired': [],
    'atsCancelled': [],
    'atsAiStillWorkingAnalysis': [],
    'atsAnalyzeUnexpectedError': [],
    'atsOpenAnalysisFailed': [],
    'atsResultsTitle': [],
    'atsTabScore': [],
    'atsTabRecommendations': [],
    'atsGenerateImprovedCv': [],
    'atsGenerating': [],
    'atsGenerateUnexpectedError': [],
    'atsAiStillWorkingGeneration': [],
    'atsUploadTapHint': [],
    'atsUploadMaxSize': [],
    'atsRemoveFile': [],
    'atsOr': [],
    'atsNoKeywords': [],
    'atsShowMoreCount': ['int'],
    'atsKeywordDialogTitle': ['String'],
    'atsKeywordDialogBody': ['String'],
    'atsGotIt': [],
    'atsCriteriaDetails': [],
    'atsKeywordsTitle': [],
    'atsGradeLabel': ['String'],
    'atsJobMatchSemantic': [],
    'atsJobMatchPercentage': [],
    'atsKeywordsFound': ['int'],
    'atsKeywordsMissing': ['int'],
    'atsNoStrengths': [],
    'atsQuickWins': [],
    'atsNoQuickWins': [],
    'atsUpgradeTitle': [],
    'atsUpgradeBody': [],
    'atsKeywordSourceJd': [],
    'atsKeywordSourceGeneric': [],
    'atsBandExcellent': [],
    'atsBandVeryGood': [],
    'atsBandFair': [],
    'atsBandWeak': [],
    'jobsMatchScore': ['int'],
    'atsBenchmark': ['String'],
    'atsInputTitle': [],
    'atsInputIntroduction': [],
    'atsInputCvSource': [],
    'atsInputSavedCv': [],
    'atsInputUploadFile': [],
    'atsInputPasteText': [],
    'atsInputNoSavedCvs': [],
    'atsInputSavedCvsError': [],
    'atsInputSavedCvHint': [],
    'atsInputSelectCv': [],
    'atsInputCvTextUnavailable': [],
    'atsInputJobTitle': [],
    'atsInputJobTitleHint': [],
    'atsInputJobTitleRequired': [],
    'atsInputJobDescription': [],
    'atsInputJobDescriptionHint': [],
    'atsInputJobDescriptionTooLong': ['int'],
    'atsInputResumeTextHint': [],
    'atsInputResumeTextRequired': [],
    'atsInputAnalyze': [],
    'atsInputAnalyzing': [],
    'atsInputPrivacy': [],
    'atsResultPrioritizedImprovements': [],
    'atsResultImprovementsAvailability': [],
    'atsResultHighPriority': [],
    'atsResultMediumPriority': [],
    'atsResultLowPriority': [],
    'homeHeroFirstCvTitle': [],
    'homeHeroFirstCvDescription': [],
    'homeHeroCreateCv': [],
    'homeHeroLatestCv': [],
    'homeHeroNextStep': [],
    'homeHeroAnalyzeNextStep': [],
    'homeHeroReviewNextStep': [],
    'homeHeroReviewCv': [],
    'homeHeroAtsScore': [],
    'homeHeroScoreUnavailable': [],
    'homeToolsTitle': [],
    'homeToolsAtsDescription': [],
    'homeToolsJobMatchDescription': [],
    'homeActivityTitle': [],
    'homeHeroLatestCvError': [],
    'homeHeroSavedCvs': [],
    'savedCvsLoading': [],
    'homeActivityEmpty': [],
    'atsInputJobTitleTooLong': ['int'],
    'atsInputSelectSourceRequired': [],
    'homeHeroUpdatedAt': ['String'],
    'homeHeroBandExcellent': [],
    'homeHeroBandVeryGood': [],
    'homeHeroBandFair': [],
    'homeHeroBandWeak': [],
    'homeStatsCvs': [],
    'homeStatsAnalyses': [],
    'homeActivitySavedCv': [],
    'atsResultKeywordSummary': ['int', 'int'],
    'premiumGateAppBar': [],
    'premiumGateHeroTitle': [],
    'premiumGateHeroBody': [],
    'premiumGateBenefitsTitle': [],
    'premiumGateBenefitPdf': [],
    'premiumGateBenefitPdfBody': [],
    'premiumGateBenefitAi': [],
    'premiumGateBenefitAiBody': [],
    'premiumGateBenefitAts': [],
    'premiumGateBenefitAtsBody': [],
    'premiumGateBenefitJobMatch': [],
    'premiumGateBenefitJobMatchBody': [],
    'premiumGateBenefitLimits': [],
    'premiumGateBenefitLimitsBody': [],
    'premiumGatePlansTitle': [],
    'premiumGatePrice': ['String', 'String'],
    'premiumGateCurrencySar': [],
    'premiumGatePeriodYear': [],
    'premiumGatePeriod': ['int'],
    'premiumGatePerMonth': ['String', 'String'],
    'premiumGatePriceNote': [],
    'premiumGatePlansFailed': [],
    'premiumGateNoPlans': [],
    'premiumGateRetry': [],
    'premiumGateRefresh': [],
    'premiumGateRefreshing': [],
    'premiumGateNotFound': [],
    'premiumGateRefreshFailed': [],
    'premiumGateActiveTitle': [],
    'premiumGateActiveBody': [],
    'premiumGateContinue': [],
    'premiumGateNotNow': [],
    'premiumGatePrivacy': [],
    'premiumGateJobMatchSeePlans': [],
    'premiumGateJobMatchBenefitScore': [],
    'premiumGateJobMatchBenefitKeywords': [],
    'premiumGateJobMatchBenefitEdits': [],
    'jobMatchFailedTitle': [],
    'jobMatchFailedManualHint': [],
    'cvHubTitle': [],
    'cvHubReady': [],
    'cvHubAtsLabel': [],
    'cvHubAtsScore': ['int'],
    'cvHubGrade': ['String'],
    'cvHubPreview': [],
    'cvHubShowFull': [],
    'cvHubShowLess': [],
    'cvHubDownload': [],
    'cvHubPreparing': [],
    'cvHubShare': [],
    'cvHubNextSteps': [],
    'cvHubCheckAts': [],
    'cvHubCheckAtsBody': [],
    'cvHubMatchJob': [],
    'cvHubMatchJobBody': [],
    'cvHubEdit': [],
    'cvHubEditBody': [],
    'cvHubEmpty': [],
    'cvHubAppBar': [],
    'cvHubRecommended': [],
    'premiumGateAvailabilityNote': [],
    'registerInterest': [],
    'noMatchingJobs': [],
    'clearFilters': [],
    'compatibilityScoreLabel': [],
    'compatibilityScoreValue': ['int'],
    'showPassword': [],
    'hidePassword': [],
    'atsCriterionFormat': [],
    'atsCriterionKeywords': [],
    'atsCriterionStructure': [],
    'atsCriterionExperience': [],
    'atsCriterionEducation': [],
    'atsCriterionSummary': [],
    'atsCriterionContact': [],
    'homeHeaderSubtitleNew': [],
    'homeHeaderSubtitleReturning': [],
    'homeHeroStartTitle': [],
    'homeHeroStartBody': [],
    'homeHeroCreateYourCv': [],
    'homeHeroUploadOld': [],
    'homeHeroScoreTitle': ['String'],
    'homeHeroScoreExcellent': [],
    'homeHeroScoreVeryGood': [],
    'homeHeroScoreFair': [],
    'homeHeroScoreWeak': [],
    'homeHeroNextStronger': [],
    'homeHeroImprove': [],
    'homeHeroTargetJob': [],
    'homeToolCreateTitle': [],
    'homeToolCreateBody': [],
    'homeToolAtsTitle': [],
    'homeToolAtsBody': [],
    'homeToolEducationTitle': [],
    'homeToolEducationBody': [],
    'homeJobsTitle': [],
    'homeJobsViewAll': [],
    'homeJobsEmpty': [],
  };

  /// Calls label [key] on [l] with positional args [a].
  @visibleForTesting
  static String debugInvoke(
    AppLocalizations l,
    String key,
    List<Object?> a,
  ) =>
      switch (key) {
        'appTitle' => l.appTitle,
        'switchToEnglish' => l.switchToEnglish,
        'switchToArabic' => l.switchToArabic,
        'languageEnglish' => l.languageEnglish,
        'languageArabic' => l.languageArabic,
        'somethingWentWrong' => l.somethingWentWrong,
        'safeRetryMessage' => l.safeRetryMessage,
        'retry' => l.retry,
        'cancel' => l.cancel,
        'save' => l.save,
        'next' => l.next,
        'back' => l.back,
        'getStarted' => l.getStarted,
        'createCv' => l.createCv,
        'generateCv' => l.generateCv,
        'settings' => l.settings,
        'myCvs' => l.myCvs,
        'analyses' => l.analyses,
        'greetingName' => l.greetingName(a[0] as String),
        'atsScoreLabel' => l.atsScoreLabel(a[0] as int),
        'cvCount' => l.cvCount(a[0] as int),
        'analysisCount' => l.analysisCount(a[0] as int),
        'welcomeToSirati' => l.welcomeToSirati,
        'buildCvProfessionally' => l.buildCvProfessionally,
        'createAccount' => l.createAccount,
        'signIn' => l.signIn,
        'invalidSaudiPhone' => l.invalidSaudiPhone,
        'invalidUaePhone' => l.invalidUaePhone,
        'invalidKuwaitPhone' => l.invalidKuwaitPhone,
        'invalidQatarPhone' => l.invalidQatarPhone,
        'invalidBahrainPhone' => l.invalidBahrainPhone,
        'invalidOmanPhone' => l.invalidOmanPhone,
        'invalidGulfOrIntlPhone' => l.invalidGulfOrIntlPhone,
        'invalidEmail' => l.invalidEmail,
        'personalDetailsTitle' => l.personalDetailsTitle,
        'personalDetailsSubtitle' => l.personalDetailsSubtitle,
        'inputLanguageLabel' => l.inputLanguageLabel,
        'languageModeDual' => l.languageModeDual,
        'languageModeArOnly' => l.languageModeArOnly,
        'languageModeEnOnly' => l.languageModeEnOnly,
        'fullNameAr' => l.fullNameAr,
        'fullNameArHint' => l.fullNameArHint,
        'fullNameEn' => l.fullNameEn,
        'fullNameEnHint' => l.fullNameEnHint,
        'headlineAr' => l.headlineAr,
        'headlineArHint' => l.headlineArHint,
        'headlineEn' => l.headlineEn,
        'headlineEnHint' => l.headlineEnHint,
        'locationAr' => l.locationAr,
        'locationArHint' => l.locationArHint,
        'locationEn' => l.locationEn,
        'locationEnHint' => l.locationEnHint,
        'emailLabel' => l.emailLabel,
        'phoneLabel' => l.phoneLabel,
        'phoneHelper' => l.phoneHelper,
        'linkedinLabel' => l.linkedinLabel,
        'atsPhotoWarningTitle' => l.atsPhotoWarningTitle,
        'atsPhotoWarningBody' => l.atsPhotoWarningBody,
        'atsPhotoEnabled' => l.atsPhotoEnabled,
        'professionalSummaryTitle' => l.professionalSummaryTitle,
        'professionalSummarySubtitle' => l.professionalSummarySubtitle,
        'summaryArLabel' => l.summaryArLabel,
        'summaryArHint' => l.summaryArHint,
        'summaryEnLabel' => l.summaryEnLabel,
        'summaryEnHint' => l.summaryEnHint,
        'summaryAdviceEmpty' => l.summaryAdviceEmpty,
        'summaryAdviceShort' => l.summaryAdviceShort,
        'summaryAdviceGood' => l.summaryAdviceGood,
        'summaryAdviceLong' => l.summaryAdviceLong,
        'summaryWordCountLine' =>
          l.summaryWordCountLine(a[0] as int, a[1] as int, a[2] as String),
        'viewProfile' => l.viewProfile,
        'accountSection' => l.accountSection,
        'editProfile' => l.editProfile,
        'changePassword' => l.changePassword,
        'preferencesSection' => l.preferencesSection,
        'language' => l.language,
        'appearance' => l.appearance,
        'change' => l.change,
        'themeSystem' => l.themeSystem,
        'themeLight' => l.themeLight,
        'themeDark' => l.themeDark,
        'pushNotifications' => l.pushNotifications,
        'aboutSection' => l.aboutSection,
        'privacyPolicy' => l.privacyPolicy,
        'contactUs' => l.contactUs,
        'contactUsSubtitle' => l.contactUsSubtitle,
        'contactUsEmailSubject' => l.contactUsEmailSubject,
        'contactUsFallback' => l.contactUsFallback(a[0] as String),
        'replayIntro' => l.replayIntro,
        'replayIntroSubtitle' => l.replayIntroSubtitle,
        'appVersion' => l.appVersion,
        'dangerZone' => l.dangerZone,
        'logOut' => l.logOut,
        'logOutConfirmTitle' => l.logOutConfirmTitle,
        'logOutConfirmBody' => l.logOutConfirmBody,
        'logOutFailed' => l.logOutFailed,
        'logOutPartial' => l.logOutPartial,
        'deleteAccount' => l.deleteAccount,
        'couldNotLoadProfile' => l.couldNotLoadProfile,
        'notificationPrefUpdateFailed' => l.notificationPrefUpdateFailed,
        'signedOutLocally' => l.signedOutLocally,
        'userFallback' => l.userFallback,
        'cvEditorTitle' => l.cvEditorTitle,
        'preparingEditor' => l.preparingEditor,
        'loadErrorTitle' => l.loadErrorTitle,
        'cvLoadFailed' => l.cvLoadFailed,
        'autosaving' => l.autosaving,
        'unsavedEdits' => l.unsavedEdits,
        'saved' => l.saved,
        'backToEdit' => l.backToEdit,
        'livePreview' => l.livePreview,
        'saveNow' => l.saveNow,
        'cvSaved' => l.cvSaved,
        'cvSaveFailed' => l.cvSaveFailed,
        'tabPersonal' => l.tabPersonal,
        'tabExperience' => l.tabExperience,
        'tabSkills' => l.tabSkills,
        'tabOrder' => l.tabOrder,
        'recoverDraftTitle' => l.recoverDraftTitle,
        'recoverDraftBody' => l.recoverDraftBody,
        'discardDraft' => l.discardDraft,
        'restoreDraft' => l.restoreDraft,
        'draftRestored' => l.draftRestored,
        'sectionOrderTitle' => l.sectionOrderTitle,
        'sectionOrderHint' => l.sectionOrderHint,
        'moveUp' => l.moveUp,
        'moveDown' => l.moveDown,
        'sectionPersonal' => l.sectionPersonal,
        'sectionSummary' => l.sectionSummary,
        'sectionExperience' => l.sectionExperience,
        'sectionEducation' => l.sectionEducation,
        'sectionSkills' => l.sectionSkills,
        'sectionLanguages' => l.sectionLanguages,
        'sectionCertifications' => l.sectionCertifications,
        'sectionProjects' => l.sectionProjects,
        'sectionCustom' => l.sectionCustom,
        'calendarSystemLabel' => l.calendarSystemLabel,
        'calendarGregorian' => l.calendarGregorian,
        'calendarHijri' => l.calendarHijri,
        'workExperienceTitle' => l.workExperienceTitle,
        'workExperienceSubtitle' => l.workExperienceSubtitle,
        'addExperience' => l.addExperience,
        'sortChronologically' => l.sortChronologically,
        'educationQualificationsTitle' => l.educationQualificationsTitle,
        'educationQualificationsSubtitle' => l.educationQualificationsSubtitle,
        'addEducation' => l.addEducation,
        'jobTitleAr' => l.jobTitleAr,
        'jobTitleArHint' => l.jobTitleArHint,
        'jobTitleEn' => l.jobTitleEn,
        'jobTitleEnHint' => l.jobTitleEnHint,
        'companyAr' => l.companyAr,
        'companyArHint' => l.companyArHint,
        'companyEn' => l.companyEn,
        'companyEnHint' => l.companyEnHint,
        'startDateLabel' => l.startDateLabel,
        'startDateHint' => l.startDateHint,
        'endDateLabel' => l.endDateLabel,
        'endDateHint' => l.endDateHint,
        'currentlyHere' => l.currentlyHere,
        'currentlyWorking' => l.currentlyWorking,
        'achievementsLabel' => l.achievementsLabel,
        'addAchievement' => l.addAchievement,
        'noAchievementsHint' => l.noAchievementsHint,
        'achievementHint' => l.achievementHint,
        'endDateBeforeStart' => l.endDateBeforeStart,
        'institutionAr' => l.institutionAr,
        'institutionArHint' => l.institutionArHint,
        'institutionEn' => l.institutionEn,
        'institutionEnHint' => l.institutionEnHint,
        'degreeLabel' => l.degreeLabel,
        'degreeHint' => l.degreeHint,
        'fieldOfStudyLabel' => l.fieldOfStudyLabel,
        'fieldOfStudyHint' => l.fieldOfStudyHint,
        'startYearLabel' => l.startYearLabel,
        'startYearHint' => l.startYearHint,
        'graduationYearLabel' => l.graduationYearLabel,
        'graduationYearHint' => l.graduationYearHint,
        'skillsTitle' => l.skillsTitle,
        'skillsSubtitle' => l.skillsSubtitle,
        'noSkillsHint' => l.noSkillsHint,
        'skillNameHint' => l.skillNameHint,
        'addItem' => l.addItem,
        'proficiencyLevel' => l.proficiencyLevel,
        'skillLevelBeginner' => l.skillLevelBeginner,
        'skillLevelIntermediate' => l.skillLevelIntermediate,
        'skillLevelAdvanced' => l.skillLevelAdvanced,
        'skillLevelExpert' => l.skillLevelExpert,
        'skillCategory' => l.skillCategory,
        'skillCategoryTechnical' => l.skillCategoryTechnical,
        'skillCategorySoft' => l.skillCategorySoft,
        'skillCategoryTools' => l.skillCategoryTools,
        'skillCategoryManagement' => l.skillCategoryManagement,
        'skillCategoryGeneral' => l.skillCategoryGeneral,
        'languagesTitle' => l.languagesTitle,
        'languagesSubtitle' => l.languagesSubtitle,
        'noLanguagesHint' => l.noLanguagesHint,
        'languageNameHint' => l.languageNameHint,
        'languageLevelNative' => l.languageLevelNative,
        'languageLevelFluent' => l.languageLevelFluent,
        'languageLevelC1' => l.languageLevelC1,
        'languageLevelB2' => l.languageLevelB2,
        'languageLevelA2' => l.languageLevelA2,
        'certificationsTitle' => l.certificationsTitle,
        'certificationsSubtitle' => l.certificationsSubtitle,
        'addCertification' => l.addCertification,
        'certNameLabel' => l.certNameLabel,
        'certNameHint' => l.certNameHint,
        'certIssuerLabel' => l.certIssuerLabel,
        'certIssuerHint' => l.certIssuerHint,
        'issueYearLabel' => l.issueYearLabel,
        'issueYearHint' => l.issueYearHint,
        'expiryYearLabel' => l.expiryYearLabel,
        'expiryYearHint' => l.expiryYearHint,
        'noExpiry' => l.noExpiry,
        'certPermanent' => l.certPermanent,
        'projectsTitle' => l.projectsTitle,
        'projectsSubtitle' => l.projectsSubtitle,
        'addProject' => l.addProject,
        'projectTitleLabel' => l.projectTitleLabel,
        'projectTitleHint' => l.projectTitleHint,
        'projectRoleLabel' => l.projectRoleLabel,
        'projectRoleHint' => l.projectRoleHint,
        'projectUrlLabel' => l.projectUrlLabel,
        'invalidProjectUrl' => l.invalidProjectUrl,
        'projectDescLabel' => l.projectDescLabel,
        'projectDescHint' => l.projectDescHint,
        'deleteItem' => l.deleteItem,
        'jobMatchTitle' => l.jobMatchTitle,
        'jobMatchPremiumBadge' => l.jobMatchPremiumBadge,
        'jobMatchEntryTitle' => l.jobMatchEntryTitle,
        'jobMatchEntrySubtitle' => l.jobMatchEntrySubtitle,
        'jobMatchEntryButton' => l.jobMatchEntryButton,
        'jobMatchQuotaRemaining' => l.jobMatchQuotaRemaining(a[0] as int),
        'jobMatchJobTitleLabel' => l.jobMatchJobTitleLabel,
        'jobMatchJobTitleHint' => l.jobMatchJobTitleHint,
        'jobMatchDescriptionLabel' => l.jobMatchDescriptionLabel,
        'jobMatchDescriptionHint' => l.jobMatchDescriptionHint,
        'jobMatchDescriptionRequired' => l.jobMatchDescriptionRequired,
        'jobMatchDescriptionTooLong' =>
          l.jobMatchDescriptionTooLong(a[0] as int),
        'jobMatchTitleTooLong' => l.jobMatchTitleTooLong(a[0] as int),
        'jobMatchCharCount' => l.jobMatchCharCount(a[0] as int, a[1] as int),
        'jobMatchPickCvTitle' => l.jobMatchPickCvTitle,
        'jobMatchPickCvRequired' => l.jobMatchPickCvRequired,
        'jobMatchNoCvTitle' => l.jobMatchNoCvTitle,
        'jobMatchNoCvBody' => l.jobMatchNoCvBody,
        'jobMatchCreateTailoredCv' => l.jobMatchCreateTailoredCv,
        'jobMatchOrCreateTailored' => l.jobMatchOrCreateTailored,
        'jobMatchCvsLoadFailed' => l.jobMatchCvsLoadFailed,
        'jobMatchRetry' => l.jobMatchRetry,
        'jobMatchSubmit' => l.jobMatchSubmit,
        'jobMatchSubmitting' => l.jobMatchSubmitting,
        'jobMatchCvStillPreparing' => l.jobMatchCvStillPreparing,
        'jobMatchUntitledCv' => l.jobMatchUntitledCv,
        'jobMatchPaywallTitle' => l.jobMatchPaywallTitle,
        'jobMatchPaywallBody' => l.jobMatchPaywallBody,
        'jobMatchPaywallTrial' => l.jobMatchPaywallTrial(a[0] as int),
        'jobMatchPaywallRefresh' => l.jobMatchPaywallRefresh,
        'jobMatchQuotaTitle' => l.jobMatchQuotaTitle,
        'jobMatchQuotaBody' => l.jobMatchQuotaBody,
        'jobMatchUnavailableTitle' => l.jobMatchUnavailableTitle,
        'jobMatchUnavailableBody' => l.jobMatchUnavailableBody,
        'jobMatchEntitlementLoadFailed' => l.jobMatchEntitlementLoadFailed,
        'jobMatchErrorSubscription' => l.jobMatchErrorSubscription,
        'jobMatchErrorLimit' => l.jobMatchErrorLimit,
        'jobMatchErrorConflict' => l.jobMatchErrorConflict,
        'jobMatchErrorStale' => l.jobMatchErrorStale,
        'jobMatchErrorCvTooLong' => l.jobMatchErrorCvTooLong,
        'jobMatchErrorInvalidDescription' => l.jobMatchErrorInvalidDescription,
        'jobMatchErrorInvalidSelection' => l.jobMatchErrorInvalidSelection,
        'jobMatchErrorUnavailable' => l.jobMatchErrorUnavailable,
        'jobMatchErrorNotFound' => l.jobMatchErrorNotFound,
        'jobMatchErrorNetwork' => l.jobMatchErrorNetwork,
        'jobMatchErrorUnknown' => l.jobMatchErrorUnknown,
        'jobMatchResultTitle' => l.jobMatchResultTitle,
        'jobMatchScoreLabel' => l.jobMatchScoreLabel,
        'jobMatchScoreSemantics' => l.jobMatchScoreSemantics(a[0] as int),
        'jobMatchCoverage' => l.jobMatchCoverage(a[0] as int),
        'jobMatchGrade' => l.jobMatchGrade(a[0] as String),
        'jobMatchMatchedKeywords' => l.jobMatchMatchedKeywords,
        'jobMatchMissingKeywords' => l.jobMatchMissingKeywords,
        'jobMatchNoKeywords' => l.jobMatchNoKeywords,
        'jobMatchStrengths' => l.jobMatchStrengths,
        'jobMatchGaps' => l.jobMatchGaps,
        'jobMatchSummary' => l.jobMatchSummary,
        'jobMatchAiPreparing' => l.jobMatchAiPreparing,
        'jobMatchAiStillProcessing' => l.jobMatchAiStillProcessing,
        'jobMatchCheckAgain' => l.jobMatchCheckAgain,
        'jobMatchAiFailed' => l.jobMatchAiFailed,
        'jobMatchAiNotConfigured' => l.jobMatchAiNotConfigured,
        'jobMatchSuggestionsTitle' => l.jobMatchSuggestionsTitle,
        'jobMatchSuggestionsHint' => l.jobMatchSuggestionsHint,
        'jobMatchNoSuggestions' => l.jobMatchNoSuggestions,
        'jobMatchBefore' => l.jobMatchBefore,
        'jobMatchAfter' => l.jobMatchAfter,
        'jobMatchAddition' => l.jobMatchAddition,
        'jobMatchWhy' => l.jobMatchWhy,
        'jobMatchTargets' => l.jobMatchTargets,
        'jobMatchNeedsUserFact' => l.jobMatchNeedsUserFact,
        'jobMatchAppliedBadge' => l.jobMatchAppliedBadge,
        'jobMatchApplySelected' => l.jobMatchApplySelected(a[0] as int),
        'jobMatchSelectToApply' => l.jobMatchSelectToApply,
        'jobMatchApplying' => l.jobMatchApplying,
        'jobMatchAppliedSuccess' => l.jobMatchAppliedSuccess,
        'jobMatchOpenTailoredCv' => l.jobMatchOpenTailoredCv,
        'jobMatchNewMatch' => l.jobMatchNewMatch,
        'jobMatchSectionName' => l.jobMatchSectionName(a[0] as String),
        'jobMatchRetrySuggestions' => l.jobMatchRetrySuggestions,
        'jobMatchLoading' => l.jobMatchLoading,
        'sharedLoading' => l.sharedLoading,
        'jm4ConfirmFact' => l.jm4ConfirmFact,
        'jm4HonestyHint' => l.jm4HonestyHint,
        'jobsFilterAll' => l.jobsFilterAll,
        'jobsPresetMatched' => l.jobsPresetMatched,
        'jobsPresetGov' => l.jobsPresetGov,
        'jobsPresetEnterprise' => l.jobsPresetEnterprise,
        'jobsPresetTamheer' => l.jobsPresetTamheer,
        'jobsFilterRemote' => l.jobsFilterRemote,
        'jobsSearchHint' => l.jobsSearchHint,
        'jobsCategoryTech' => l.jobsCategoryTech,
        'jobsCategoryFinance' => l.jobsCategoryFinance,
        'jobsCategoryHealth' => l.jobsCategoryHealth,
        'jobsCityAll' => l.jobsCityAll,
        'jobsCityRiyadh' => l.jobsCityRiyadh,
        'jobsCityJeddah' => l.jobsCityJeddah,
        'jobsCityDammam' => l.jobsCityDammam,
        'jobsCityKhobar' => l.jobsCityKhobar,
        'jobsCityMecca' => l.jobsCityMecca,
        'jobsCityMedina' => l.jobsCityMedina,
        'jobsPersonalizedTitle' => l.jobsPersonalizedTitle,
        'jobsPersonalizedFallback' => l.jobsPersonalizedFallback,
        'jobsMatchedActive' => l.jobsMatchedActive,
        'jobsMatchToggle' => l.jobsMatchToggle,
        'jobsEmptyFeed' => l.jobsEmptyFeed,
        'jobsLoadFailed' => l.jobsLoadFailed,
        'jobsLatestPostings' => l.jobsLatestPostings,
        'jobsDetailTitle' => l.jobsDetailTitle,
        'jobsVerifiedSourceDetail' => l.jobsVerifiedSourceDetail,
        'jobsTamheerProgram' => l.jobsTamheerProgram,
        'jobsCompatibilityTitle' => l.jobsCompatibilityTitle,
        'jobsSkillsRequired' => l.jobsSkillsRequired,
        'jobsDescriptionTitle' => l.jobsDescriptionTitle,
        'jobsTailorCv' => l.jobsTailorCv,
        'jobsOpenApplyFailed' => l.jobsOpenApplyFailed,
        'jobsApplyOfficialSite' => l.jobsApplyOfficialSite,
        'jobsVerifiedSourceCard' => l.jobsVerifiedSourceCard,
        'jobsTamheerBadge' => l.jobsTamheerBadge,
        'jobsNewBadge' => l.jobsNewBadge,
        'jobsDetailsLink' => l.jobsDetailsLink,
        'jobsVerifiedSourceFeatured' => l.jobsVerifiedSourceFeatured,
        'jobsTamheerBadgeFeatured' => l.jobsTamheerBadgeFeatured,
        'jobsApplyNow' => l.jobsApplyNow,
        'atsFileTooLarge' => l.atsFileTooLarge(a[0] as int),
        'atsUnsupportedFileType' => l.atsUnsupportedFileType,
        'atsResumeRequired' => l.atsResumeRequired,
        'atsCancelled' => l.atsCancelled,
        'atsAiStillWorkingAnalysis' => l.atsAiStillWorkingAnalysis,
        'atsAnalyzeUnexpectedError' => l.atsAnalyzeUnexpectedError,
        'atsOpenAnalysisFailed' => l.atsOpenAnalysisFailed,
        'atsResultsTitle' => l.atsResultsTitle,
        'atsTabScore' => l.atsTabScore,
        'atsTabRecommendations' => l.atsTabRecommendations,
        'atsGenerateImprovedCv' => l.atsGenerateImprovedCv,
        'atsGenerating' => l.atsGenerating,
        'atsGenerateUnexpectedError' => l.atsGenerateUnexpectedError,
        'atsAiStillWorkingGeneration' => l.atsAiStillWorkingGeneration,
        'atsUploadTapHint' => l.atsUploadTapHint,
        'atsUploadMaxSize' => l.atsUploadMaxSize,
        'atsRemoveFile' => l.atsRemoveFile,
        'atsOr' => l.atsOr,
        'atsNoKeywords' => l.atsNoKeywords,
        'atsShowMoreCount' => l.atsShowMoreCount(a[0] as int),
        'atsKeywordDialogTitle' => l.atsKeywordDialogTitle(a[0] as String),
        'atsKeywordDialogBody' => l.atsKeywordDialogBody(a[0] as String),
        'atsGotIt' => l.atsGotIt,
        'atsCriteriaDetails' => l.atsCriteriaDetails,
        'atsKeywordsTitle' => l.atsKeywordsTitle,
        'atsGradeLabel' => l.atsGradeLabel(a[0] as String),
        'atsJobMatchSemantic' => l.atsJobMatchSemantic,
        'atsJobMatchPercentage' => l.atsJobMatchPercentage,
        'atsKeywordsFound' => l.atsKeywordsFound(a[0] as int),
        'atsKeywordsMissing' => l.atsKeywordsMissing(a[0] as int),
        'atsNoStrengths' => l.atsNoStrengths,
        'atsQuickWins' => l.atsQuickWins,
        'atsNoQuickWins' => l.atsNoQuickWins,
        'atsUpgradeTitle' => l.atsUpgradeTitle,
        'atsUpgradeBody' => l.atsUpgradeBody,
        'atsKeywordSourceJd' => l.atsKeywordSourceJd,
        'atsKeywordSourceGeneric' => l.atsKeywordSourceGeneric,
        'atsBandExcellent' => l.atsBandExcellent,
        'atsBandVeryGood' => l.atsBandVeryGood,
        'atsBandFair' => l.atsBandFair,
        'atsBandWeak' => l.atsBandWeak,
        'jobsMatchScore' => l.jobsMatchScore(a[0] as int),
        'atsBenchmark' => l.atsBenchmark(a[0] as String),
        'atsInputTitle' => l.atsInputTitle,
        'atsInputIntroduction' => l.atsInputIntroduction,
        'atsInputCvSource' => l.atsInputCvSource,
        'atsInputSavedCv' => l.atsInputSavedCv,
        'atsInputUploadFile' => l.atsInputUploadFile,
        'atsInputPasteText' => l.atsInputPasteText,
        'atsInputNoSavedCvs' => l.atsInputNoSavedCvs,
        'atsInputSavedCvsError' => l.atsInputSavedCvsError,
        'atsInputSavedCvHint' => l.atsInputSavedCvHint,
        'atsInputSelectCv' => l.atsInputSelectCv,
        'atsInputCvTextUnavailable' => l.atsInputCvTextUnavailable,
        'atsInputJobTitle' => l.atsInputJobTitle,
        'atsInputJobTitleHint' => l.atsInputJobTitleHint,
        'atsInputJobTitleRequired' => l.atsInputJobTitleRequired,
        'atsInputJobDescription' => l.atsInputJobDescription,
        'atsInputJobDescriptionHint' => l.atsInputJobDescriptionHint,
        'atsInputJobDescriptionTooLong' =>
          l.atsInputJobDescriptionTooLong(a[0] as int),
        'atsInputResumeTextHint' => l.atsInputResumeTextHint,
        'atsInputResumeTextRequired' => l.atsInputResumeTextRequired,
        'atsInputAnalyze' => l.atsInputAnalyze,
        'atsInputAnalyzing' => l.atsInputAnalyzing,
        'atsInputPrivacy' => l.atsInputPrivacy,
        'atsResultPrioritizedImprovements' =>
          l.atsResultPrioritizedImprovements,
        'atsResultImprovementsAvailability' =>
          l.atsResultImprovementsAvailability,
        'atsResultHighPriority' => l.atsResultHighPriority,
        'atsResultMediumPriority' => l.atsResultMediumPriority,
        'atsResultLowPriority' => l.atsResultLowPriority,
        'homeHeroFirstCvTitle' => l.homeHeroFirstCvTitle,
        'homeHeroFirstCvDescription' => l.homeHeroFirstCvDescription,
        'homeHeroCreateCv' => l.homeHeroCreateCv,
        'homeHeroLatestCv' => l.homeHeroLatestCv,
        'homeHeroNextStep' => l.homeHeroNextStep,
        'homeHeroAnalyzeNextStep' => l.homeHeroAnalyzeNextStep,
        'homeHeroReviewNextStep' => l.homeHeroReviewNextStep,
        'homeHeroReviewCv' => l.homeHeroReviewCv,
        'homeHeroAtsScore' => l.homeHeroAtsScore,
        'homeHeroScoreUnavailable' => l.homeHeroScoreUnavailable,
        'homeToolsTitle' => l.homeToolsTitle,
        'homeToolsAtsDescription' => l.homeToolsAtsDescription,
        'homeToolsJobMatchDescription' => l.homeToolsJobMatchDescription,
        'homeActivityTitle' => l.homeActivityTitle,
        'homeHeroLatestCvError' => l.homeHeroLatestCvError,
        'homeHeroSavedCvs' => l.homeHeroSavedCvs,
        'savedCvsLoading' => l.savedCvsLoading,
        'homeActivityEmpty' => l.homeActivityEmpty,
        'atsInputJobTitleTooLong' => l.atsInputJobTitleTooLong(a[0] as int),
        'atsInputSelectSourceRequired' => l.atsInputSelectSourceRequired,
        'homeHeroUpdatedAt' => l.homeHeroUpdatedAt(a[0] as String),
        'homeHeroBandExcellent' => l.homeHeroBandExcellent,
        'homeHeroBandVeryGood' => l.homeHeroBandVeryGood,
        'homeHeroBandFair' => l.homeHeroBandFair,
        'homeHeroBandWeak' => l.homeHeroBandWeak,
        'homeStatsCvs' => l.homeStatsCvs,
        'homeStatsAnalyses' => l.homeStatsAnalyses,
        'homeActivitySavedCv' => l.homeActivitySavedCv,
        'atsResultKeywordSummary' =>
          l.atsResultKeywordSummary(a[0] as int, a[1] as int),
        'premiumGateAppBar' => l.premiumGateAppBar,
        'premiumGateHeroTitle' => l.premiumGateHeroTitle,
        'premiumGateHeroBody' => l.premiumGateHeroBody,
        'premiumGateBenefitsTitle' => l.premiumGateBenefitsTitle,
        'premiumGateBenefitPdf' => l.premiumGateBenefitPdf,
        'premiumGateBenefitPdfBody' => l.premiumGateBenefitPdfBody,
        'premiumGateBenefitAi' => l.premiumGateBenefitAi,
        'premiumGateBenefitAiBody' => l.premiumGateBenefitAiBody,
        'premiumGateBenefitAts' => l.premiumGateBenefitAts,
        'premiumGateBenefitAtsBody' => l.premiumGateBenefitAtsBody,
        'premiumGateBenefitJobMatch' => l.premiumGateBenefitJobMatch,
        'premiumGateBenefitJobMatchBody' => l.premiumGateBenefitJobMatchBody,
        'premiumGateBenefitLimits' => l.premiumGateBenefitLimits,
        'premiumGateBenefitLimitsBody' => l.premiumGateBenefitLimitsBody,
        'premiumGatePlansTitle' => l.premiumGatePlansTitle,
        'premiumGatePrice' =>
          l.premiumGatePrice(a[0] as String, a[1] as String),
        'premiumGateCurrencySar' => l.premiumGateCurrencySar,
        'premiumGatePeriodYear' => l.premiumGatePeriodYear,
        'premiumGatePeriod' => l.premiumGatePeriod(a[0] as int),
        'premiumGatePerMonth' =>
          l.premiumGatePerMonth(a[0] as String, a[1] as String),
        'premiumGatePriceNote' => l.premiumGatePriceNote,
        'premiumGatePlansFailed' => l.premiumGatePlansFailed,
        'premiumGateNoPlans' => l.premiumGateNoPlans,
        'premiumGateRetry' => l.premiumGateRetry,
        'premiumGateRefresh' => l.premiumGateRefresh,
        'premiumGateRefreshing' => l.premiumGateRefreshing,
        'premiumGateNotFound' => l.premiumGateNotFound,
        'premiumGateRefreshFailed' => l.premiumGateRefreshFailed,
        'premiumGateActiveTitle' => l.premiumGateActiveTitle,
        'premiumGateActiveBody' => l.premiumGateActiveBody,
        'premiumGateContinue' => l.premiumGateContinue,
        'premiumGateNotNow' => l.premiumGateNotNow,
        'premiumGatePrivacy' => l.premiumGatePrivacy,
        'premiumGateJobMatchSeePlans' => l.premiumGateJobMatchSeePlans,
        'premiumGateJobMatchBenefitScore' => l.premiumGateJobMatchBenefitScore,
        'premiumGateJobMatchBenefitKeywords' =>
          l.premiumGateJobMatchBenefitKeywords,
        'premiumGateJobMatchBenefitEdits' => l.premiumGateJobMatchBenefitEdits,
        'jobMatchFailedTitle' => l.jobMatchFailedTitle,
        'jobMatchFailedManualHint' => l.jobMatchFailedManualHint,
        'cvHubTitle' => l.cvHubTitle,
        'cvHubReady' => l.cvHubReady,
        'cvHubAtsLabel' => l.cvHubAtsLabel,
        'cvHubAtsScore' => l.cvHubAtsScore(a[0] as int),
        'cvHubGrade' => l.cvHubGrade(a[0] as String),
        'cvHubPreview' => l.cvHubPreview,
        'cvHubShowFull' => l.cvHubShowFull,
        'cvHubShowLess' => l.cvHubShowLess,
        'cvHubDownload' => l.cvHubDownload,
        'cvHubPreparing' => l.cvHubPreparing,
        'cvHubShare' => l.cvHubShare,
        'cvHubNextSteps' => l.cvHubNextSteps,
        'cvHubCheckAts' => l.cvHubCheckAts,
        'cvHubCheckAtsBody' => l.cvHubCheckAtsBody,
        'cvHubMatchJob' => l.cvHubMatchJob,
        'cvHubMatchJobBody' => l.cvHubMatchJobBody,
        'cvHubEdit' => l.cvHubEdit,
        'cvHubEditBody' => l.cvHubEditBody,
        'cvHubEmpty' => l.cvHubEmpty,
        'cvHubAppBar' => l.cvHubAppBar,
        'cvHubRecommended' => l.cvHubRecommended,
        'premiumGateAvailabilityNote' => l.premiumGateAvailabilityNote,
        'registerInterest' => l.registerInterest,
        'noMatchingJobs' => l.noMatchingJobs,
        'clearFilters' => l.clearFilters,
        'compatibilityScoreLabel' => l.compatibilityScoreLabel,
        'compatibilityScoreValue' => l.compatibilityScoreValue(a[0] as int),
        'showPassword' => l.showPassword,
        'hidePassword' => l.hidePassword,
        'atsCriterionFormat' => l.atsCriterionFormat,
        'atsCriterionKeywords' => l.atsCriterionKeywords,
        'atsCriterionStructure' => l.atsCriterionStructure,
        'atsCriterionExperience' => l.atsCriterionExperience,
        'atsCriterionEducation' => l.atsCriterionEducation,
        'atsCriterionSummary' => l.atsCriterionSummary,
        'atsCriterionContact' => l.atsCriterionContact,
        'homeHeaderSubtitleNew' => l.homeHeaderSubtitleNew,
        'homeHeaderSubtitleReturning' => l.homeHeaderSubtitleReturning,
        'homeHeroStartTitle' => l.homeHeroStartTitle,
        'homeHeroStartBody' => l.homeHeroStartBody,
        'homeHeroCreateYourCv' => l.homeHeroCreateYourCv,
        'homeHeroUploadOld' => l.homeHeroUploadOld,
        'homeHeroScoreTitle' => l.homeHeroScoreTitle(a[0] as String),
        'homeHeroScoreExcellent' => l.homeHeroScoreExcellent,
        'homeHeroScoreVeryGood' => l.homeHeroScoreVeryGood,
        'homeHeroScoreFair' => l.homeHeroScoreFair,
        'homeHeroScoreWeak' => l.homeHeroScoreWeak,
        'homeHeroNextStronger' => l.homeHeroNextStronger,
        'homeHeroImprove' => l.homeHeroImprove,
        'homeHeroTargetJob' => l.homeHeroTargetJob,
        'homeToolCreateTitle' => l.homeToolCreateTitle,
        'homeToolCreateBody' => l.homeToolCreateBody,
        'homeToolAtsTitle' => l.homeToolAtsTitle,
        'homeToolAtsBody' => l.homeToolAtsBody,
        'homeToolEducationTitle' => l.homeToolEducationTitle,
        'homeToolEducationBody' => l.homeToolEducationBody,
        'homeJobsTitle' => l.homeJobsTitle,
        'homeJobsViewAll' => l.homeJobsViewAll,
        'homeJobsEmpty' => l.homeJobsEmpty,
        _ => throw ArgumentError.value(key, 'key'),
      };
}
