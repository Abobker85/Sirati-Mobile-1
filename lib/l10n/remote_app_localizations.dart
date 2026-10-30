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
  String get cvShareSubscriptionRequired =>
      remote.text('cvShareSubscriptionRequired') ??
      _base.cvShareSubscriptionRequired;

  @override
  String get cvShareFailed =>
      remote.text('cvShareFailed') ?? _base.cvShareFailed;

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

  @override
  String get sharedErrorNetworkSubtitle =>
      remote.text('sharedErrorNetworkSubtitle') ??
      _base.sharedErrorNetworkSubtitle;

  @override
  String get sharedErrorTimeoutSubtitle =>
      remote.text('sharedErrorTimeoutSubtitle') ??
      _base.sharedErrorTimeoutSubtitle;

  @override
  String get sharedErrorTitleNetwork =>
      remote.text('sharedErrorTitleNetwork') ?? _base.sharedErrorTitleNetwork;

  @override
  String get sharedErrorTitleTimeout =>
      remote.text('sharedErrorTitleTimeout') ?? _base.sharedErrorTitleTimeout;

  @override
  String get sharedErrorTitleAuth =>
      remote.text('sharedErrorTitleAuth') ?? _base.sharedErrorTitleAuth;

  @override
  String get sharedErrorTitleNotFound =>
      remote.text('sharedErrorTitleNotFound') ?? _base.sharedErrorTitleNotFound;

  @override
  String get sharedErrorTitleServer =>
      remote.text('sharedErrorTitleServer') ?? _base.sharedErrorTitleServer;

  @override
  String get sharedErrorTitleRateLimited =>
      remote.text('sharedErrorTitleRateLimited') ??
      _base.sharedErrorTitleRateLimited;

  @override
  String get sharedErrorTitleUnknown =>
      remote.text('sharedErrorTitleUnknown') ?? _base.sharedErrorTitleUnknown;

  @override
  String get sharedCreateNewCv =>
      remote.text('sharedCreateNewCv') ?? _base.sharedCreateNewCv;

  @override
  String get sharedOk => remote.text('sharedOk') ?? _base.sharedOk;

  @override
  String get sharedLanguageToggleShort =>
      remote.text('sharedLanguageToggleShort') ??
      _base.sharedLanguageToggleShort;

  @override
  String get sharedPasswordStrengthEmpty =>
      remote.text('sharedPasswordStrengthEmpty') ??
      _base.sharedPasswordStrengthEmpty;

  @override
  String get sharedPasswordStrengthWeak =>
      remote.text('sharedPasswordStrengthWeak') ??
      _base.sharedPasswordStrengthWeak;

  @override
  String get sharedPasswordStrengthMedium =>
      remote.text('sharedPasswordStrengthMedium') ??
      _base.sharedPasswordStrengthMedium;

  @override
  String get sharedPasswordStrengthStrong =>
      remote.text('sharedPasswordStrengthStrong') ??
      _base.sharedPasswordStrengthStrong;

  @override
  String sharedPasswordStrengthSemantics(String label) =>
      remote.format(
        'sharedPasswordStrengthSemantics',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'label': label},
        ),
      ) ??
      _base.sharedPasswordStrengthSemantics(label);

  @override
  String get sharedOfflineShowingSaved =>
      remote.text('sharedOfflineShowingSaved') ??
      _base.sharedOfflineShowingSaved;

  @override
  String get sharedOfflineTitle =>
      remote.text('sharedOfflineTitle') ?? _base.sharedOfflineTitle;

  @override
  String get sharedOfflineBody =>
      remote.text('sharedOfflineBody') ?? _base.sharedOfflineBody;

  @override
  String get sharedOfflineWaiting =>
      remote.text('sharedOfflineWaiting') ?? _base.sharedOfflineWaiting;

  @override
  String get sharedOfflineChecking =>
      remote.text('sharedOfflineChecking') ?? _base.sharedOfflineChecking;

  @override
  String get sharedOfflineTipsTitle =>
      remote.text('sharedOfflineTipsTitle') ?? _base.sharedOfflineTipsTitle;

  @override
  String get sharedOfflineTipAirplane =>
      remote.text('sharedOfflineTipAirplane') ?? _base.sharedOfflineTipAirplane;

  @override
  String get sharedOfflineTipSignal =>
      remote.text('sharedOfflineTipSignal') ?? _base.sharedOfflineTipSignal;

  @override
  String get sharedOfflineOpenSaved =>
      remote.text('sharedOfflineOpenSaved') ?? _base.sharedOfflineOpenSaved;

  @override
  String get sharedNoDataAvailable =>
      remote.text('sharedNoDataAvailable') ?? _base.sharedNoDataAvailable;

  @override
  String get sharedSomethingWentWrong =>
      remote.text('sharedSomethingWentWrong') ?? _base.sharedSomethingWentWrong;

  @override
  String get sharedAiImprovingWording =>
      remote.text('sharedAiImprovingWording') ?? _base.sharedAiImprovingWording;

  @override
  String get sharedAiWorkingOnField =>
      remote.text('sharedAiWorkingOnField') ?? _base.sharedAiWorkingOnField;

  @override
  String sharedAiEnhancingField(String field) =>
      remote.format(
        'sharedAiEnhancingField',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'field': field},
        ),
      ) ??
      _base.sharedAiEnhancingField(field);

  @override
  String sharedAiCharacterCount(int count, int minimum) =>
      remote.format(
        'sharedAiCharacterCount',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'count': count, 'minimum': minimum},
        ),
      ) ??
      _base.sharedAiCharacterCount(count, minimum);

  @override
  String get sharedAiEnhance =>
      remote.text('sharedAiEnhance') ?? _base.sharedAiEnhance;

  @override
  String get sharedAiEnhancing =>
      remote.text('sharedAiEnhancing') ?? _base.sharedAiEnhancing;

  @override
  String sharedAiEnhanceMinimumHint(int minimum) =>
      remote.format(
        'sharedAiEnhanceMinimumHint',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'minimum': minimum},
        ),
      ) ??
      _base.sharedAiEnhanceMinimumHint(minimum);

  @override
  String get sharedAiWhatImproved =>
      remote.text('sharedAiWhatImproved') ?? _base.sharedAiWhatImproved;

  @override
  String get sharedDismiss =>
      remote.text('sharedDismiss') ?? _base.sharedDismiss;

  @override
  String get sharedAiCompleteFacts =>
      remote.text('sharedAiCompleteFacts') ?? _base.sharedAiCompleteFacts;

  @override
  String get sharedAiVerifyDetails =>
      remote.text('sharedAiVerifyDetails') ?? _base.sharedAiVerifyDetails;

  @override
  String get sharedJobTitleSelectHint =>
      remote.text('sharedJobTitleSelectHint') ?? _base.sharedJobTitleSelectHint;

  @override
  String get sharedJobTitleSheetTitle =>
      remote.text('sharedJobTitleSheetTitle') ?? _base.sharedJobTitleSheetTitle;

  @override
  String get sharedClear => remote.text('sharedClear') ?? _base.sharedClear;

  @override
  String get sharedJobTitleSearchHint =>
      remote.text('sharedJobTitleSearchHint') ?? _base.sharedJobTitleSearchHint;

  @override
  String get sharedJobTitleNoMatches =>
      remote.text('sharedJobTitleNoMatches') ?? _base.sharedJobTitleNoMatches;

  @override
  String sharedJobTitleEnterManually(String query) =>
      remote.format(
        'sharedJobTitleEnterManually',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'query': query},
        ),
      ) ??
      _base.sharedJobTitleEnterManually(query);

  @override
  String get sharedNotifications =>
      remote.text('sharedNotifications') ?? _base.sharedNotifications;

  @override
  String sharedNotificationsUnread(int count) =>
      remote.format(
        'sharedNotificationsUnread',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'count': count},
        ),
      ) ??
      _base.sharedNotificationsUnread(count);

  @override
  String get sharedProfile =>
      remote.text('sharedProfile') ?? _base.sharedProfile;

  @override
  String get sharedCareerReadiness =>
      remote.text('sharedCareerReadiness') ?? _base.sharedCareerReadiness;

  @override
  String sharedCareerReadinessPercent(int percent) =>
      remote.format(
        'sharedCareerReadinessPercent',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'percent': percent},
        ),
      ) ??
      _base.sharedCareerReadinessPercent(percent);

  @override
  String get sharedAiProgressBarrier =>
      remote.text('sharedAiProgressBarrier') ?? _base.sharedAiProgressBarrier;

  @override
  String get sharedAiStageGenerationQueued =>
      remote.text('sharedAiStageGenerationQueued') ??
      _base.sharedAiStageGenerationQueued;

  @override
  String get sharedAiStageGenerationWriting =>
      remote.text('sharedAiStageGenerationWriting') ??
      _base.sharedAiStageGenerationWriting;

  @override
  String get sharedAiStageGenerationSaving =>
      remote.text('sharedAiStageGenerationSaving') ??
      _base.sharedAiStageGenerationSaving;

  @override
  String get sharedAiStageAnalysisReading =>
      remote.text('sharedAiStageAnalysisReading') ??
      _base.sharedAiStageAnalysisReading;

  @override
  String get sharedAiStageAnalysisScoring =>
      remote.text('sharedAiStageAnalysisScoring') ??
      _base.sharedAiStageAnalysisScoring;

  @override
  String get sharedAiStageAnalysisPreparing =>
      remote.text('sharedAiStageAnalysisPreparing') ??
      _base.sharedAiStageAnalysisPreparing;

  @override
  String get sharedAiLongWait =>
      remote.text('sharedAiLongWait') ?? _base.sharedAiLongWait;

  @override
  String get sharedAiDoneGeneration =>
      remote.text('sharedAiDoneGeneration') ?? _base.sharedAiDoneGeneration;

  @override
  String get sharedAiDoneAnalysis =>
      remote.text('sharedAiDoneAnalysis') ?? _base.sharedAiDoneAnalysis;

  @override
  String get sharedAiWorking =>
      remote.text('sharedAiWorking') ?? _base.sharedAiWorking;

  @override
  String get sharedAiProcessingRequest =>
      remote.text('sharedAiProcessingRequest') ??
      _base.sharedAiProcessingRequest;

  @override
  String get coreGreetingWelcome =>
      remote.text('coreGreetingWelcome') ?? _base.coreGreetingWelcome;

  @override
  String coreGreetingHello(String name) =>
      remote.format(
        'coreGreetingHello',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'name': name},
        ),
      ) ??
      _base.coreGreetingHello(name);

  @override
  String get dashboardInputMethodFile =>
      remote.text('dashboardInputMethodFile') ?? _base.dashboardInputMethodFile;

  @override
  String get dashboardInputMethodMixed =>
      remote.text('dashboardInputMethodMixed') ??
      _base.dashboardInputMethodMixed;

  @override
  String get dashboardInputMethodPaste =>
      remote.text('dashboardInputMethodPaste') ??
      _base.dashboardInputMethodPaste;

  @override
  String get dashboardSplashPreparing =>
      remote.text('dashboardSplashPreparing') ?? _base.dashboardSplashPreparing;

  @override
  String get dashboardWelcomeSlogan =>
      remote.text('dashboardWelcomeSlogan') ?? _base.dashboardWelcomeSlogan;

  @override
  String get dashboardWelcomeValueTitle =>
      remote.text('dashboardWelcomeValueTitle') ??
      _base.dashboardWelcomeValueTitle;

  @override
  String get dashboardWelcomePointBuild =>
      remote.text('dashboardWelcomePointBuild') ??
      _base.dashboardWelcomePointBuild;

  @override
  String get dashboardWelcomePointAnalyze =>
      remote.text('dashboardWelcomePointAnalyze') ??
      _base.dashboardWelcomePointAnalyze;

  @override
  String get dashboardWelcomePointTailor =>
      remote.text('dashboardWelcomePointTailor') ??
      _base.dashboardWelcomePointTailor;

  @override
  String get dashboardWelcomePointLearning =>
      remote.text('dashboardWelcomePointLearning') ??
      _base.dashboardWelcomePointLearning;

  @override
  String get dashboardWelcomePointJobs =>
      remote.text('dashboardWelcomePointJobs') ??
      _base.dashboardWelcomePointJobs;

  @override
  String get dashboardWelcomePrivacyPolicy =>
      remote.text('dashboardWelcomePrivacyPolicy') ??
      _base.dashboardWelcomePrivacyPolicy;

  @override
  String get dashboardNotFoundTitle =>
      remote.text('dashboardNotFoundTitle') ?? _base.dashboardNotFoundTitle;

  @override
  String get dashboardNotFoundSubtitle =>
      remote.text('dashboardNotFoundSubtitle') ??
      _base.dashboardNotFoundSubtitle;

  @override
  String get dashboardNotFoundGoHome =>
      remote.text('dashboardNotFoundGoHome') ?? _base.dashboardNotFoundGoHome;

  @override
  String get dashboardPressBackAgainToExit =>
      remote.text('dashboardPressBackAgainToExit') ??
      _base.dashboardPressBackAgainToExit;

  @override
  String get dashboardHistory =>
      remote.text('dashboardHistory') ?? _base.dashboardHistory;

  @override
  String get dashboardRefresh =>
      remote.text('dashboardRefresh') ?? _base.dashboardRefresh;

  @override
  String get dashboardHistoryGeneratedCvsTab =>
      remote.text('dashboardHistoryGeneratedCvsTab') ??
      _base.dashboardHistoryGeneratedCvsTab;

  @override
  String get dashboardHistoryLoadFailed =>
      remote.text('dashboardHistoryLoadFailed') ??
      _base.dashboardHistoryLoadFailed;

  @override
  String get dashboardHistoryAnalysesEmptySubtitle =>
      remote.text('dashboardHistoryAnalysesEmptySubtitle') ??
      _base.dashboardHistoryAnalysesEmptySubtitle;

  @override
  String get dashboardHistoryAnalyzeCv =>
      remote.text('dashboardHistoryAnalyzeCv') ??
      _base.dashboardHistoryAnalyzeCv;

  @override
  String get dashboardHistoryCvsEmptyTitle =>
      remote.text('dashboardHistoryCvsEmptyTitle') ??
      _base.dashboardHistoryCvsEmptyTitle;

  @override
  String get dashboardHistoryCvsEmptySubtitle =>
      remote.text('dashboardHistoryCvsEmptySubtitle') ??
      _base.dashboardHistoryCvsEmptySubtitle;

  @override
  String get dashboardCreateCv =>
      remote.text('dashboardCreateCv') ?? _base.dashboardCreateCv;

  @override
  String dashboardScoreBadgeSemantics(int score, String grade) =>
      remote.format(
        'dashboardScoreBadgeSemantics',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'score': score, 'grade': grade},
        ),
      ) ??
      _base.dashboardScoreBadgeSemantics(score, grade);

  @override
  String get dashboardLoadMoreLoading =>
      remote.text('dashboardLoadMoreLoading') ?? _base.dashboardLoadMoreLoading;

  @override
  String get dashboardLoadMoreFailed =>
      remote.text('dashboardLoadMoreFailed') ?? _base.dashboardLoadMoreFailed;

  @override
  String get dashboardLoadMore =>
      remote.text('dashboardLoadMore') ?? _base.dashboardLoadMore;

  @override
  String get dashboardHomeLoadFailed =>
      remote.text('dashboardHomeLoadFailed') ?? _base.dashboardHomeLoadFailed;

  @override
  String get dashboardViewAll =>
      remote.text('dashboardViewAll') ?? _base.dashboardViewAll;

  @override
  String dashboardHeaderNotificationsUnread(int count) =>
      remote.format(
        'dashboardHeaderNotificationsUnread',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'count': count},
        ),
      ) ??
      _base.dashboardHeaderNotificationsUnread(count);

  @override
  String get dashboardNavHome =>
      remote.text('dashboardNavHome') ?? _base.dashboardNavHome;

  @override
  String get dashboardNavMyCvs =>
      remote.text('dashboardNavMyCvs') ?? _base.dashboardNavMyCvs;

  @override
  String get dashboardNavEducation =>
      remote.text('dashboardNavEducation') ?? _base.dashboardNavEducation;

  @override
  String get dashboardNavJobNews =>
      remote.text('dashboardNavJobNews') ?? _base.dashboardNavJobNews;

  @override
  String get dashboardEducationInterestThanks =>
      remote.text('dashboardEducationInterestThanks') ??
      _base.dashboardEducationInterestThanks;

  @override
  String get dashboardEducationTitle =>
      remote.text('dashboardEducationTitle') ?? _base.dashboardEducationTitle;

  @override
  String get dashboardEducationSubtitle =>
      remote.text('dashboardEducationSubtitle') ??
      _base.dashboardEducationSubtitle;

  @override
  String get dashboardEducationWhatsComing =>
      remote.text('dashboardEducationWhatsComing') ??
      _base.dashboardEducationWhatsComing;

  @override
  String get dashboardEducationCoursesTitle =>
      remote.text('dashboardEducationCoursesTitle') ??
      _base.dashboardEducationCoursesTitle;

  @override
  String get dashboardEducationCoursesBody =>
      remote.text('dashboardEducationCoursesBody') ??
      _base.dashboardEducationCoursesBody;

  @override
  String get dashboardEducationInterviewTitle =>
      remote.text('dashboardEducationInterviewTitle') ??
      _base.dashboardEducationInterviewTitle;

  @override
  String get dashboardEducationInterviewBody =>
      remote.text('dashboardEducationInterviewBody') ??
      _base.dashboardEducationInterviewBody;

  @override
  String get dashboardEducationAtsGuidesTitle =>
      remote.text('dashboardEducationAtsGuidesTitle') ??
      _base.dashboardEducationAtsGuidesTitle;

  @override
  String get dashboardEducationAtsGuidesBody =>
      remote.text('dashboardEducationAtsGuidesBody') ??
      _base.dashboardEducationAtsGuidesBody;

  @override
  String get dashboardEducationComingSoonBadge =>
      remote.text('dashboardEducationComingSoonBadge') ??
      _base.dashboardEducationComingSoonBadge;

  @override
  String get dashboardEducationHeroTitle =>
      remote.text('dashboardEducationHeroTitle') ??
      _base.dashboardEducationHeroTitle;

  @override
  String get dashboardEducationHeroBody =>
      remote.text('dashboardEducationHeroBody') ??
      _base.dashboardEducationHeroBody;

  @override
  String get dashboardEducationInterestRegistered =>
      remote.text('dashboardEducationInterestRegistered') ??
      _base.dashboardEducationInterestRegistered;

  @override
  String get dashboardEducationCtaTitle =>
      remote.text('dashboardEducationCtaTitle') ??
      _base.dashboardEducationCtaTitle;

  @override
  String get dashboardEducationCtaBody =>
      remote.text('dashboardEducationCtaBody') ??
      _base.dashboardEducationCtaBody;

  @override
  String get dashboardEducationDetailTitle =>
      remote.text('dashboardEducationDetailTitle') ??
      _base.dashboardEducationDetailTitle;

  @override
  String get dashboardEducationDetailLoadFailed =>
      remote.text('dashboardEducationDetailLoadFailed') ??
      _base.dashboardEducationDetailLoadFailed;

  @override
  String get dashboardUntitled =>
      remote.text('dashboardUntitled') ?? _base.dashboardUntitled;

  @override
  String get dashboardEducationDetailNoContent =>
      remote.text('dashboardEducationDetailNoContent') ??
      _base.dashboardEducationDetailNoContent;

  @override
  String get cvDraftAvailable =>
      remote.text('cvDraftAvailable') ?? _base.cvDraftAvailable;

  @override
  String get cvDraftContinueTitle =>
      remote.text('cvDraftContinueTitle') ?? _base.cvDraftContinueTitle;

  @override
  String get cvDraftStartFresh =>
      remote.text('cvDraftStartFresh') ?? _base.cvDraftStartFresh;

  @override
  String get cvDraftRestore =>
      remote.text('cvDraftRestore') ?? _base.cvDraftRestore;

  @override
  String get cvDiscardChangesTitle =>
      remote.text('cvDiscardChangesTitle') ?? _base.cvDiscardChangesTitle;

  @override
  String get cvDiscardChangesBody =>
      remote.text('cvDiscardChangesBody') ?? _base.cvDiscardChangesBody;

  @override
  String get cvDiscard => remote.text('cvDiscard') ?? _base.cvDiscard;

  @override
  String get cvSaveProgressTitle =>
      remote.text('cvSaveProgressTitle') ?? _base.cvSaveProgressTitle;

  @override
  String get cvSaveProgressBody =>
      remote.text('cvSaveProgressBody') ?? _base.cvSaveProgressBody;

  @override
  String get cvSaveDraft => remote.text('cvSaveDraft') ?? _base.cvSaveDraft;

  @override
  String get cvEntryRequired =>
      remote.text('cvEntryRequired') ?? _base.cvEntryRequired;

  @override
  String get cvEntryChooseStart =>
      remote.text('cvEntryChooseStart') ?? _base.cvEntryChooseStart;

  @override
  String get cvEntryChooseEnd =>
      remote.text('cvEntryChooseEnd') ?? _base.cvEntryChooseEnd;

  @override
  String get cvEntryEndBeforeStart =>
      remote.text('cvEntryEndBeforeStart') ?? _base.cvEntryEndBeforeStart;

  @override
  String get cvEntryFrom => remote.text('cvEntryFrom') ?? _base.cvEntryFrom;

  @override
  String get cvEntryTo => remote.text('cvEntryTo') ?? _base.cvEntryTo;

  @override
  String get cvEntryJobTitle =>
      remote.text('cvEntryJobTitle') ?? _base.cvEntryJobTitle;

  @override
  String get cvEntryJobTitleHint =>
      remote.text('cvEntryJobTitleHint') ?? _base.cvEntryJobTitleHint;

  @override
  String get cvEntryCompany =>
      remote.text('cvEntryCompany') ?? _base.cvEntryCompany;

  @override
  String get cvEntryCity => remote.text('cvEntryCity') ?? _base.cvEntryCity;

  @override
  String get cvEntryWorkCurrent =>
      remote.text('cvEntryWorkCurrent') ?? _base.cvEntryWorkCurrent;

  @override
  String get cvEntryDuties =>
      remote.text('cvEntryDuties') ?? _base.cvEntryDuties;

  @override
  String get cvEntryDutiesHint =>
      remote.text('cvEntryDutiesHint') ?? _base.cvEntryDutiesHint;

  @override
  String get cvEntryDegree =>
      remote.text('cvEntryDegree') ?? _base.cvEntryDegree;

  @override
  String get cvEntryDegreeHint =>
      remote.text('cvEntryDegreeHint') ?? _base.cvEntryDegreeHint;

  @override
  String get cvEntryInstitution =>
      remote.text('cvEntryInstitution') ?? _base.cvEntryInstitution;

  @override
  String get cvEntryStudyCurrent =>
      remote.text('cvEntryStudyCurrent') ?? _base.cvEntryStudyCurrent;

  @override
  String get cvEntryEducationDetails =>
      remote.text('cvEntryEducationDetails') ?? _base.cvEntryEducationDetails;

  @override
  String get cvEntryCertName =>
      remote.text('cvEntryCertName') ?? _base.cvEntryCertName;

  @override
  String get cvEntryCertIssuer =>
      remote.text('cvEntryCertIssuer') ?? _base.cvEntryCertIssuer;

  @override
  String get cvEntryCertDate =>
      remote.text('cvEntryCertDate') ?? _base.cvEntryCertDate;

  @override
  String get cvEntriesCompleteHighlighted =>
      remote.text('cvEntriesCompleteHighlighted') ??
      _base.cvEntriesCompleteHighlighted;

  @override
  String get cvEntriesAddOne =>
      remote.text('cvEntriesAddOne') ?? _base.cvEntriesAddOne;

  @override
  String get cvEntriesMoreDetail =>
      remote.text('cvEntriesMoreDetail') ?? _base.cvEntriesMoreDetail;

  @override
  String get cvEntryRemove =>
      remote.text('cvEntryRemove') ?? _base.cvEntryRemove;

  @override
  String get cvMonthChoose =>
      remote.text('cvMonthChoose') ?? _base.cvMonthChoose;

  @override
  String get cvMonthYearTitle =>
      remote.text('cvMonthYearTitle') ?? _base.cvMonthYearTitle;

  @override
  String get cvMonthYearDone =>
      remote.text('cvMonthYearDone') ?? _base.cvMonthYearDone;

  @override
  String get cvWizardUpdate =>
      remote.text('cvWizardUpdate') ?? _base.cvWizardUpdate;

  @override
  String get cvWizardGenerate =>
      remote.text('cvWizardGenerate') ?? _base.cvWizardGenerate;

  @override
  String get cvWizardGenerating =>
      remote.text('cvWizardGenerating') ?? _base.cvWizardGenerating;

  @override
  String get cvWizardStepPersonal =>
      remote.text('cvWizardStepPersonal') ?? _base.cvWizardStepPersonal;

  @override
  String get cvWizardStepSkills =>
      remote.text('cvWizardStepSkills') ?? _base.cvWizardStepSkills;

  @override
  String get cvWizardStepExperience =>
      remote.text('cvWizardStepExperience') ?? _base.cvWizardStepExperience;

  @override
  String get cvWizardStepEducation =>
      remote.text('cvWizardStepEducation') ?? _base.cvWizardStepEducation;

  @override
  String cvWizardStepOf(int step, int total) =>
      remote.format(
        'cvWizardStepOf',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'step': step, 'total': total},
        ),
      ) ??
      _base.cvWizardStepOf(step, total);

  @override
  String get cvWizardReviewFields =>
      remote.text('cvWizardReviewFields') ?? _base.cvWizardReviewFields;

  @override
  String get cvEducationStepTitle =>
      remote.text('cvEducationStepTitle') ?? _base.cvEducationStepTitle;

  @override
  String get cvEducationLabel =>
      remote.text('cvEducationLabel') ?? _base.cvEducationLabel;

  @override
  String get cvEducationAdd =>
      remote.text('cvEducationAdd') ?? _base.cvEducationAdd;

  @override
  String get cvCertificationsLabel =>
      remote.text('cvCertificationsLabel') ?? _base.cvCertificationsLabel;

  @override
  String get cvCertificationsAdd =>
      remote.text('cvCertificationsAdd') ?? _base.cvCertificationsAdd;

  @override
  String get cvExperienceStepTitle =>
      remote.text('cvExperienceStepTitle') ?? _base.cvExperienceStepTitle;

  @override
  String get cvExperienceLabel =>
      remote.text('cvExperienceLabel') ?? _base.cvExperienceLabel;

  @override
  String get cvExperienceHelper =>
      remote.text('cvExperienceHelper') ?? _base.cvExperienceHelper;

  @override
  String get cvExperienceXyzBuilder =>
      remote.text('cvExperienceXyzBuilder') ?? _base.cvExperienceXyzBuilder;

  @override
  String get cvExperienceAdd =>
      remote.text('cvExperienceAdd') ?? _base.cvExperienceAdd;

  @override
  String get cvPersonalStepTitle =>
      remote.text('cvPersonalStepTitle') ?? _base.cvPersonalStepTitle;

  @override
  String get cvPersonalFullName =>
      remote.text('cvPersonalFullName') ?? _base.cvPersonalFullName;

  @override
  String get cvPersonalFullNameHint =>
      remote.text('cvPersonalFullNameHint') ?? _base.cvPersonalFullNameHint;

  @override
  String get cvPersonalFullNameRequired =>
      remote.text('cvPersonalFullNameRequired') ??
      _base.cvPersonalFullNameRequired;

  @override
  String get cvPersonalEmailRequired =>
      remote.text('cvPersonalEmailRequired') ?? _base.cvPersonalEmailRequired;

  @override
  String get cvPersonalEmailInvalid =>
      remote.text('cvPersonalEmailInvalid') ?? _base.cvPersonalEmailInvalid;

  @override
  String get cvPersonalPhone =>
      remote.text('cvPersonalPhone') ?? _base.cvPersonalPhone;

  @override
  String get cvPersonalPhoneRequired =>
      remote.text('cvPersonalPhoneRequired') ?? _base.cvPersonalPhoneRequired;

  @override
  String get cvPersonalLinkedin =>
      remote.text('cvPersonalLinkedin') ?? _base.cvPersonalLinkedin;

  @override
  String get cvPersonalTargetJob =>
      remote.text('cvPersonalTargetJob') ?? _base.cvPersonalTargetJob;

  @override
  String get cvPersonalTargetJobHint =>
      remote.text('cvPersonalTargetJobHint') ?? _base.cvPersonalTargetJobHint;

  @override
  String get cvPersonalTargetJobRequired =>
      remote.text('cvPersonalTargetJobRequired') ??
      _base.cvPersonalTargetJobRequired;

  @override
  String get cvPersonalJobDescription =>
      remote.text('cvPersonalJobDescription') ?? _base.cvPersonalJobDescription;

  @override
  String get cvPersonalCvLanguage =>
      remote.text('cvPersonalCvLanguage') ?? _base.cvPersonalCvLanguage;

  @override
  String get cvPersonalEnhancingJobDescription =>
      remote.text('cvPersonalEnhancingJobDescription') ??
      _base.cvPersonalEnhancingJobDescription;

  @override
  String get cvPersonalJobDescriptionHint =>
      remote.text('cvPersonalJobDescriptionHint') ??
      _base.cvPersonalJobDescriptionHint;

  @override
  String get cvEnhance => remote.text('cvEnhance') ?? _base.cvEnhance;

  @override
  String get cvEnhancing => remote.text('cvEnhancing') ?? _base.cvEnhancing;

  @override
  String get cvPersonalWriteMore =>
      remote.text('cvPersonalWriteMore') ?? _base.cvPersonalWriteMore;

  @override
  String get cvSkillsStepTitle =>
      remote.text('cvSkillsStepTitle') ?? _base.cvSkillsStepTitle;

  @override
  String get cvSkillsCore => remote.text('cvSkillsCore') ?? _base.cvSkillsCore;

  @override
  String get cvSkillsHelper =>
      remote.text('cvSkillsHelper') ?? _base.cvSkillsHelper;

  @override
  String get cvSkillsRequired =>
      remote.text('cvSkillsRequired') ?? _base.cvSkillsRequired;

  @override
  String get cvSummaryLabel =>
      remote.text('cvSummaryLabel') ?? _base.cvSummaryLabel;

  @override
  String get cvSummaryHelper =>
      remote.text('cvSummaryHelper') ?? _base.cvSummaryHelper;

  @override
  String get cvSummaryHint =>
      remote.text('cvSummaryHint') ?? _base.cvSummaryHint;

  @override
  String get cvDraftSaved => remote.text('cvDraftSaved') ?? _base.cvDraftSaved;

  @override
  String get cvAchievementDuplicate =>
      remote.text('cvAchievementDuplicate') ?? _base.cvAchievementDuplicate;

  @override
  String get cvAchievementAdded =>
      remote.text('cvAchievementAdded') ?? _base.cvAchievementAdded;

  @override
  String get cvGenerationCancelled =>
      remote.text('cvGenerationCancelled') ?? _base.cvGenerationCancelled;

  @override
  String get cvRetryShort => remote.text('cvRetryShort') ?? _base.cvRetryShort;

  @override
  String get cvGenerationUnexpectedError =>
      remote.text('cvGenerationUnexpectedError') ??
      _base.cvGenerationUnexpectedError;

  @override
  String get cvGenerationStillRunning =>
      remote.text('cvGenerationStillRunning') ?? _base.cvGenerationStillRunning;

  @override
  String get cvEnterTargetJobFirst =>
      remote.text('cvEnterTargetJobFirst') ?? _base.cvEnterTargetJobFirst;

  @override
  String get cvEnhanceFieldFailed =>
      remote.text('cvEnhanceFieldFailed') ?? _base.cvEnhanceFieldFailed;

  @override
  String get cvFieldEnhanced =>
      remote.text('cvFieldEnhanced') ?? _base.cvFieldEnhanced;

  @override
  String get cvUndo => remote.text('cvUndo') ?? _base.cvUndo;

  @override
  String get cvJobDescriptionTooShort =>
      remote.text('cvJobDescriptionTooShort') ?? _base.cvJobDescriptionTooShort;

  @override
  String get cvEnhanceJobDescriptionFailed =>
      remote.text('cvEnhanceJobDescriptionFailed') ??
      _base.cvEnhanceJobDescriptionFailed;

  @override
  String get cvJobDescriptionEnhanced =>
      remote.text('cvJobDescriptionEnhanced') ?? _base.cvJobDescriptionEnhanced;

  @override
  String get cvGeneratorEditTitle =>
      remote.text('cvGeneratorEditTitle') ?? _base.cvGeneratorEditTitle;

  @override
  String get cvGeneratorCreateTitle =>
      remote.text('cvGeneratorCreateTitle') ?? _base.cvGeneratorCreateTitle;

  @override
  String get cvOpenFailed => remote.text('cvOpenFailed') ?? _base.cvOpenFailed;

  @override
  String get cvNotReadyToSend =>
      remote.text('cvNotReadyToSend') ?? _base.cvNotReadyToSend;

  @override
  String get cvOpeningPdf => remote.text('cvOpeningPdf') ?? _base.cvOpeningPdf;

  @override
  String get cvPdfLinkUnavailable =>
      remote.text('cvPdfLinkUnavailable') ?? _base.cvPdfLinkUnavailable;

  @override
  String get cvPdfLinkOpenFailed =>
      remote.text('cvPdfLinkOpenFailed') ?? _base.cvPdfLinkOpenFailed;

  @override
  String get cvTemplatesLoadFailed =>
      remote.text('cvTemplatesLoadFailed') ?? _base.cvTemplatesLoadFailed;

  @override
  String get cvDeleteTitle =>
      remote.text('cvDeleteTitle') ?? _base.cvDeleteTitle;

  @override
  String get cvDeleteBody => remote.text('cvDeleteBody') ?? _base.cvDeleteBody;

  @override
  String get cvDeleteFailed =>
      remote.text('cvDeleteFailed') ?? _base.cvDeleteFailed;

  @override
  String get cvPdfLinkNotFound =>
      remote.text('cvPdfLinkNotFound') ?? _base.cvPdfLinkNotFound;

  @override
  String get cvPdfOpenFailed =>
      remote.text('cvPdfOpenFailed') ?? _base.cvPdfOpenFailed;

  @override
  String get cvListLoadFailed =>
      remote.text('cvListLoadFailed') ?? _base.cvListLoadFailed;

  @override
  String get cvListEmptyTitle =>
      remote.text('cvListEmptyTitle') ?? _base.cvListEmptyTitle;

  @override
  String get cvListEmptyBody =>
      remote.text('cvListEmptyBody') ?? _base.cvListEmptyBody;

  @override
  String get cvCreateNew => remote.text('cvCreateNew') ?? _base.cvCreateNew;

  @override
  String get cvUntitled => remote.text('cvUntitled') ?? _base.cvUntitled;

  @override
  String get cvCardEdit => remote.text('cvCardEdit') ?? _base.cvCardEdit;

  @override
  String get cvCardDownload =>
      remote.text('cvCardDownload') ?? _base.cvCardDownload;

  @override
  String get cvTemplatePickerTitle =>
      remote.text('cvTemplatePickerTitle') ?? _base.cvTemplatePickerTitle;

  @override
  String get cvTemplateDefault =>
      remote.text('cvTemplateDefault') ?? _base.cvTemplateDefault;

  @override
  String get cvXyzFormula => remote.text('cvXyzFormula') ?? _base.cvXyzFormula;

  @override
  String get cvXyzPresetsTitle =>
      remote.text('cvXyzPresetsTitle') ?? _base.cvXyzPresetsTitle;

  @override
  String get cvXyzPresetTech =>
      remote.text('cvXyzPresetTech') ?? _base.cvXyzPresetTech;

  @override
  String get cvXyzPresetSales =>
      remote.text('cvXyzPresetSales') ?? _base.cvXyzPresetSales;

  @override
  String get cvXyzPresetProject =>
      remote.text('cvXyzPresetProject') ?? _base.cvXyzPresetProject;

  @override
  String get cvXyzActionLabel =>
      remote.text('cvXyzActionLabel') ?? _base.cvXyzActionLabel;

  @override
  String get cvXyzActionHint =>
      remote.text('cvXyzActionHint') ?? _base.cvXyzActionHint;

  @override
  String get cvXyzMetricLabel =>
      remote.text('cvXyzMetricLabel') ?? _base.cvXyzMetricLabel;

  @override
  String get cvXyzMetricHint =>
      remote.text('cvXyzMetricHint') ?? _base.cvXyzMetricHint;

  @override
  String get cvXyzMethodLabel =>
      remote.text('cvXyzMethodLabel') ?? _base.cvXyzMethodLabel;

  @override
  String get cvXyzMethodHint =>
      remote.text('cvXyzMethodHint') ?? _base.cvXyzMethodHint;

  @override
  String get cvXyzPreviewTitle =>
      remote.text('cvXyzPreviewTitle') ?? _base.cvXyzPreviewTitle;

  @override
  String get cvXyzInsert => remote.text('cvXyzInsert') ?? _base.cvXyzInsert;

  @override
  String cvSkillsSelectedCount(int count) =>
      remote.format(
        'cvSkillsSelectedCount',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'count': count},
        ),
      ) ??
      _base.cvSkillsSelectedCount(count);

  @override
  String get cvSkillsClearAll =>
      remote.text('cvSkillsClearAll') ?? _base.cvSkillsClearAll;

  @override
  String get cvSkillsEmpty =>
      remote.text('cvSkillsEmpty') ?? _base.cvSkillsEmpty;

  @override
  String get cvSkillsInputHint =>
      remote.text('cvSkillsInputHint') ?? _base.cvSkillsInputHint;

  @override
  String get cvSkillsSuggested =>
      remote.text('cvSkillsSuggested') ?? _base.cvSkillsSuggested;

  @override
  String get cvExportOptionsTitle =>
      remote.text('cvExportOptionsTitle') ?? _base.cvExportOptionsTitle;

  @override
  String get cvExportLanguage =>
      remote.text('cvExportLanguage') ?? _base.cvExportLanguage;

  @override
  String get cvExportSelectedTemplate =>
      remote.text('cvExportSelectedTemplate') ?? _base.cvExportSelectedTemplate;

  @override
  String get cvExportFileName =>
      remote.text('cvExportFileName') ?? _base.cvExportFileName;

  @override
  String get cvExportLatinFilename =>
      remote.text('cvExportLatinFilename') ?? _base.cvExportLatinFilename;

  @override
  String get cvExportPremiumWatermark =>
      remote.text('cvExportPremiumWatermark') ?? _base.cvExportPremiumWatermark;

  @override
  String get cvExportSubscriptionRequired =>
      remote.text('cvExportSubscriptionRequired') ??
      _base.cvExportSubscriptionRequired;

  @override
  String get cvExportUpgrade =>
      remote.text('cvExportUpgrade') ?? _base.cvExportUpgrade;

  @override
  String get cvExportPreparing =>
      remote.text('cvExportPreparing') ?? _base.cvExportPreparing;

  @override
  String get cvExportDownload =>
      remote.text('cvExportDownload') ?? _base.cvExportDownload;

  @override
  String get cvExportSuccess =>
      remote.text('cvExportSuccess') ?? _base.cvExportSuccess;

  @override
  String get cvExportSharePdf =>
      remote.text('cvExportSharePdf') ?? _base.cvExportSharePdf;

  @override
  String get settingsOnboardingWelcomeBody =>
      remote.text('settingsOnboardingWelcomeBody') ??
      _base.settingsOnboardingWelcomeBody;

  @override
  String get settingsOnboardingAtsTitle =>
      remote.text('settingsOnboardingAtsTitle') ??
      _base.settingsOnboardingAtsTitle;

  @override
  String get settingsOnboardingAtsBody =>
      remote.text('settingsOnboardingAtsBody') ??
      _base.settingsOnboardingAtsBody;

  @override
  String get settingsOnboardingAiTitle =>
      remote.text('settingsOnboardingAiTitle') ??
      _base.settingsOnboardingAiTitle;

  @override
  String get settingsOnboardingAiBody =>
      remote.text('settingsOnboardingAiBody') ?? _base.settingsOnboardingAiBody;

  @override
  String get settingsOnboardingPrevious =>
      remote.text('settingsOnboardingPrevious') ??
      _base.settingsOnboardingPrevious;

  @override
  String get settingsOnboardingSkip =>
      remote.text('settingsOnboardingSkip') ?? _base.settingsOnboardingSkip;

  @override
  String settingsOnboardingPageOf(int page, int count) =>
      remote.format(
        'settingsOnboardingPageOf',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'page': page, 'count': count},
        ),
      ) ??
      _base.settingsOnboardingPageOf(page, count);

  @override
  String authFieldTooLong(int max) =>
      remote.format(
        'authFieldTooLong',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'max': max},
        ),
      ) ??
      _base.authFieldTooLong(max);

  @override
  String authPasswordTooShort(int min) =>
      remote.format(
        'authPasswordTooShort',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'min': min},
        ),
      ) ??
      _base.authPasswordTooShort(min);

  @override
  String get authEmailInvalid =>
      remote.text('authEmailInvalid') ?? _base.authEmailInvalid;

  @override
  String get authPhoneInvalid =>
      remote.text('authPhoneInvalid') ?? _base.authPhoneInvalid;

  @override
  String get authRegisterHeroTitle =>
      remote.text('authRegisterHeroTitle') ?? _base.authRegisterHeroTitle;

  @override
  String get authRegisterHeroSubtitle =>
      remote.text('authRegisterHeroSubtitle') ?? _base.authRegisterHeroSubtitle;

  @override
  String get authTermsAgreePrefix =>
      remote.text('authTermsAgreePrefix') ?? _base.authTermsAgreePrefix;

  @override
  String get authTermsLink =>
      remote.text('authTermsLink') ?? _base.authTermsLink;

  @override
  String get authHaveAccount =>
      remote.text('authHaveAccount') ?? _base.authHaveAccount;

  @override
  String get authAgreeTermsRequired =>
      remote.text('authAgreeTermsRequired') ?? _base.authAgreeTermsRequired;

  @override
  String get authRetry => remote.text('authRetry') ?? _base.authRetry;

  @override
  String get authRegisterUnexpectedError =>
      remote.text('authRegisterUnexpectedError') ??
      _base.authRegisterUnexpectedError;

  @override
  String get authLooksGood =>
      remote.text('authLooksGood') ?? _base.authLooksGood;

  @override
  String get authJobTitleOtherRequired =>
      remote.text('authJobTitleOtherRequired') ??
      _base.authJobTitleOtherRequired;

  @override
  String get authFixHighlightedFields =>
      remote.text('authFixHighlightedFields') ?? _base.authFixHighlightedFields;

  @override
  String get authFullNameLabel =>
      remote.text('authFullNameLabel') ?? _base.authFullNameLabel;

  @override
  String get authFullNameHint =>
      remote.text('authFullNameHint') ?? _base.authFullNameHint;

  @override
  String get authNameRequired =>
      remote.text('authNameRequired') ?? _base.authNameRequired;

  @override
  String get authEmailAddressLabel =>
      remote.text('authEmailAddressLabel') ?? _base.authEmailAddressLabel;

  @override
  String get authEmailRequired =>
      remote.text('authEmailRequired') ?? _base.authEmailRequired;

  @override
  String get authPhoneLabel =>
      remote.text('authPhoneLabel') ?? _base.authPhoneLabel;

  @override
  String get authPhoneRequired =>
      remote.text('authPhoneRequired') ?? _base.authPhoneRequired;

  @override
  String get authLocationLabel =>
      remote.text('authLocationLabel') ?? _base.authLocationLabel;

  @override
  String get authLocationHint =>
      remote.text('authLocationHint') ?? _base.authLocationHint;

  @override
  String get authLocationRequired =>
      remote.text('authLocationRequired') ?? _base.authLocationRequired;

  @override
  String get authJobTitleOptionalLabel =>
      remote.text('authJobTitleOptionalLabel') ??
      _base.authJobTitleOptionalLabel;

  @override
  String get authJobTitleOtherLabel =>
      remote.text('authJobTitleOtherLabel') ?? _base.authJobTitleOtherLabel;

  @override
  String get authJobTitleOtherHint =>
      remote.text('authJobTitleOtherHint') ?? _base.authJobTitleOtherHint;

  @override
  String get authPasswordLabel =>
      remote.text('authPasswordLabel') ?? _base.authPasswordLabel;

  @override
  String get authPasswordRequired =>
      remote.text('authPasswordRequired') ?? _base.authPasswordRequired;

  @override
  String get authCreateAccountButton =>
      remote.text('authCreateAccountButton') ?? _base.authCreateAccountButton;

  @override
  String get authCreatingAccount =>
      remote.text('authCreatingAccount') ?? _base.authCreatingAccount;

  @override
  String get authContinueWithoutAccount =>
      remote.text('authContinueWithoutAccount') ??
      _base.authContinueWithoutAccount;

  @override
  String get authSessionExpired =>
      remote.text('authSessionExpired') ?? _base.authSessionExpired;

  @override
  String get authSessionExpiredBadge =>
      remote.text('authSessionExpiredBadge') ?? _base.authSessionExpiredBadge;

  @override
  String get authSessionExpiredChip =>
      remote.text('authSessionExpiredChip') ?? _base.authSessionExpiredChip;

  @override
  String get authSessionExpiredTitle =>
      remote.text('authSessionExpiredTitle') ?? _base.authSessionExpiredTitle;

  @override
  String get authSessionExpiredBody =>
      remote.text('authSessionExpiredBody') ?? _base.authSessionExpiredBody;

  @override
  String get authSessionExpiredDataSafe =>
      remote.text('authSessionExpiredDataSafe') ??
      _base.authSessionExpiredDataSafe;

  @override
  String get authSessionExpiredSignIn =>
      remote.text('authSessionExpiredSignIn') ?? _base.authSessionExpiredSignIn;

  @override
  String get authSessionExpiredHelp =>
      remote.text('authSessionExpiredHelp') ?? _base.authSessionExpiredHelp;

  @override
  String get authLoginUnexpectedError =>
      remote.text('authLoginUnexpectedError') ?? _base.authLoginUnexpectedError;

  @override
  String authSocialSignInSoon(String provider) =>
      remote.format(
        'authSocialSignInSoon',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'provider': provider},
        ),
      ) ??
      _base.authSocialSignInSoon(provider);

  @override
  String authSocialSignInNotConfigured(String provider) =>
      remote.format(
        'authSocialSignInNotConfigured',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'provider': provider},
        ),
      ) ??
      _base.authSocialSignInNotConfigured(provider);

  @override
  String get authLoginSubtitle =>
      remote.text('authLoginSubtitle') ?? _base.authLoginSubtitle;

  @override
  String get authForgotPasswordLink =>
      remote.text('authForgotPasswordLink') ?? _base.authForgotPasswordLink;

  @override
  String get authSignInButton =>
      remote.text('authSignInButton') ?? _base.authSignInButton;

  @override
  String get authSigningIn =>
      remote.text('authSigningIn') ?? _base.authSigningIn;

  @override
  String get authOrContinueWith =>
      remote.text('authOrContinueWith') ?? _base.authOrContinueWith;

  @override
  String get authNoAccount =>
      remote.text('authNoAccount') ?? _base.authNoAccount;

  @override
  String get authCreateAccountLink =>
      remote.text('authCreateAccountLink') ?? _base.authCreateAccountLink;

  @override
  String get authForgotEmailInvalidNotice =>
      remote.text('authForgotEmailInvalidNotice') ??
      _base.authForgotEmailInvalidNotice;

  @override
  String get authForgotSendFailed =>
      remote.text('authForgotSendFailed') ?? _base.authForgotSendFailed;

  @override
  String get authForgotResetFailed =>
      remote.text('authForgotResetFailed') ?? _base.authForgotResetFailed;

  @override
  String get authForgotTitle =>
      remote.text('authForgotTitle') ?? _base.authForgotTitle;

  @override
  String get authForgotCodeIntro =>
      remote.text('authForgotCodeIntro') ?? _base.authForgotCodeIntro;

  @override
  String get authForgotEmailIntro =>
      remote.text('authForgotEmailIntro') ?? _base.authForgotEmailIntro;

  @override
  String get authForgotEmailInvalid =>
      remote.text('authForgotEmailInvalid') ?? _base.authForgotEmailInvalid;

  @override
  String get authForgotSendCode =>
      remote.text('authForgotSendCode') ?? _base.authForgotSendCode;

  @override
  String get authSending => remote.text('authSending') ?? _base.authSending;

  @override
  String get authVerificationCodeLabel =>
      remote.text('authVerificationCodeLabel') ??
      _base.authVerificationCodeLabel;

  @override
  String get authCodeRequired =>
      remote.text('authCodeRequired') ?? _base.authCodeRequired;

  @override
  String get authNewPasswordLabel =>
      remote.text('authNewPasswordLabel') ?? _base.authNewPasswordLabel;

  @override
  String get authForgotNewPasswordRequired =>
      remote.text('authForgotNewPasswordRequired') ??
      _base.authForgotNewPasswordRequired;

  @override
  String get authForgotConfirmPasswordLabel =>
      remote.text('authForgotConfirmPasswordLabel') ??
      _base.authForgotConfirmPasswordLabel;

  @override
  String get authForgotConfirmPasswordRequired =>
      remote.text('authForgotConfirmPasswordRequired') ??
      _base.authForgotConfirmPasswordRequired;

  @override
  String get authPasswordsDoNotMatch =>
      remote.text('authPasswordsDoNotMatch') ?? _base.authPasswordsDoNotMatch;

  @override
  String get authForgotResetButton =>
      remote.text('authForgotResetButton') ?? _base.authForgotResetButton;

  @override
  String get authSaving => remote.text('authSaving') ?? _base.authSaving;

  @override
  String authResendCodeIn(int seconds) =>
      remote.format(
        'authResendCodeIn',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'seconds': seconds},
        ),
      ) ??
      _base.authResendCodeIn(seconds);

  @override
  String get authResendCode =>
      remote.text('authResendCode') ?? _base.authResendCode;

  @override
  String get authForgotUseDifferentEmail =>
      remote.text('authForgotUseDifferentEmail') ??
      _base.authForgotUseDifferentEmail;

  @override
  String get authVerifySuccess =>
      remote.text('authVerifySuccess') ?? _base.authVerifySuccess;

  @override
  String get authVerifyUnexpectedError =>
      remote.text('authVerifyUnexpectedError') ??
      _base.authVerifyUnexpectedError;

  @override
  String get authVerifyResendFailed =>
      remote.text('authVerifyResendFailed') ?? _base.authVerifyResendFailed;

  @override
  String get authVerifyBackToSignIn =>
      remote.text('authVerifyBackToSignIn') ?? _base.authVerifyBackToSignIn;

  @override
  String get authVerifyTitle =>
      remote.text('authVerifyTitle') ?? _base.authVerifyTitle;

  @override
  String get authVerifyCodeSentTo =>
      remote.text('authVerifyCodeSentTo') ?? _base.authVerifyCodeSentTo;

  @override
  String get authVerifyButton =>
      remote.text('authVerifyButton') ?? _base.authVerifyButton;

  @override
  String get authVerifying =>
      remote.text('authVerifying') ?? _base.authVerifying;

  @override
  String get authVerifyCheckSpam =>
      remote.text('authVerifyCheckSpam') ?? _base.authVerifyCheckSpam;

  @override
  String get settingsPrivacyTitle =>
      remote.text('settingsPrivacyTitle') ?? _base.settingsPrivacyTitle;

  @override
  String get settingsPrivacyCollectTitle =>
      remote.text('settingsPrivacyCollectTitle') ??
      _base.settingsPrivacyCollectTitle;

  @override
  String get settingsPrivacyCollectBody =>
      remote.text('settingsPrivacyCollectBody') ??
      _base.settingsPrivacyCollectBody;

  @override
  String get settingsPrivacyUseTitle =>
      remote.text('settingsPrivacyUseTitle') ?? _base.settingsPrivacyUseTitle;

  @override
  String get settingsPrivacyUseBody =>
      remote.text('settingsPrivacyUseBody') ?? _base.settingsPrivacyUseBody;

  @override
  String get settingsPrivacyProcessorsTitle =>
      remote.text('settingsPrivacyProcessorsTitle') ??
      _base.settingsPrivacyProcessorsTitle;

  @override
  String get settingsPrivacyProcessorsBody =>
      remote.text('settingsPrivacyProcessorsBody') ??
      _base.settingsPrivacyProcessorsBody;

  @override
  String get settingsPrivacyRetentionTitle =>
      remote.text('settingsPrivacyRetentionTitle') ??
      _base.settingsPrivacyRetentionTitle;

  @override
  String get settingsPrivacyRetentionBody =>
      remote.text('settingsPrivacyRetentionBody') ??
      _base.settingsPrivacyRetentionBody;

  @override
  String get settingsPrivacyContactTitle =>
      remote.text('settingsPrivacyContactTitle') ??
      _base.settingsPrivacyContactTitle;

  @override
  String settingsPrivacyContactBody(String email) =>
      remote.format(
        'settingsPrivacyContactBody',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'email': email},
        ),
      ) ??
      _base.settingsPrivacyContactBody(email);

  @override
  String get settingsNotificationsUpdateFailed =>
      remote.text('settingsNotificationsUpdateFailed') ??
      _base.settingsNotificationsUpdateFailed;

  @override
  String get settingsNotificationsTitle =>
      remote.text('settingsNotificationsTitle') ??
      _base.settingsNotificationsTitle;

  @override
  String get settingsNotificationsReadAll =>
      remote.text('settingsNotificationsReadAll') ??
      _base.settingsNotificationsReadAll;

  @override
  String get settingsNotificationsLoadFailed =>
      remote.text('settingsNotificationsLoadFailed') ??
      _base.settingsNotificationsLoadFailed;

  @override
  String get settingsNotificationsEmptyTitle =>
      remote.text('settingsNotificationsEmptyTitle') ??
      _base.settingsNotificationsEmptyTitle;

  @override
  String get settingsNotificationsEmptyBody =>
      remote.text('settingsNotificationsEmptyBody') ??
      _base.settingsNotificationsEmptyBody;

  @override
  String get settingsNotificationsUnread =>
      remote.text('settingsNotificationsUnread') ??
      _base.settingsNotificationsUnread;

  @override
  String get settingsCleanupFailed =>
      remote.text('settingsCleanupFailed') ?? _base.settingsCleanupFailed;

  @override
  String get settingsCleanupMessage =>
      remote.text('settingsCleanupMessage') ?? _base.settingsCleanupMessage;

  @override
  String get settingsCleanupRetry =>
      remote.text('settingsCleanupRetry') ?? _base.settingsCleanupRetry;

  @override
  String get settingsCleanupClearing =>
      remote.text('settingsCleanupClearing') ?? _base.settingsCleanupClearing;

  @override
  String get settingsPasswordChanged =>
      remote.text('settingsPasswordChanged') ?? _base.settingsPasswordChanged;

  @override
  String get settingsCurrentPasswordIncorrect =>
      remote.text('settingsCurrentPasswordIncorrect') ??
      _base.settingsCurrentPasswordIncorrect;

  @override
  String get settingsPasswordChangeFailed =>
      remote.text('settingsPasswordChangeFailed') ??
      _base.settingsPasswordChangeFailed;

  @override
  String get settingsCurrentPasswordLabel =>
      remote.text('settingsCurrentPasswordLabel') ??
      _base.settingsCurrentPasswordLabel;

  @override
  String get settingsCurrentPasswordRequired =>
      remote.text('settingsCurrentPasswordRequired') ??
      _base.settingsCurrentPasswordRequired;

  @override
  String get settingsNewPasswordRequired =>
      remote.text('settingsNewPasswordRequired') ??
      _base.settingsNewPasswordRequired;

  @override
  String get settingsNewPasswordSameAsCurrent =>
      remote.text('settingsNewPasswordSameAsCurrent') ??
      _base.settingsNewPasswordSameAsCurrent;

  @override
  String get settingsConfirmNewPasswordLabel =>
      remote.text('settingsConfirmNewPasswordLabel') ??
      _base.settingsConfirmNewPasswordLabel;

  @override
  String get settingsConfirmNewPasswordRequired =>
      remote.text('settingsConfirmNewPasswordRequired') ??
      _base.settingsConfirmNewPasswordRequired;

  @override
  String get settingsUpdatePassword =>
      remote.text('settingsUpdatePassword') ?? _base.settingsUpdatePassword;

  @override
  String get settingsUpdatingPassword =>
      remote.text('settingsUpdatingPassword') ?? _base.settingsUpdatingPassword;

  @override
  String get settingsDeleteConfirmTitle =>
      remote.text('settingsDeleteConfirmTitle') ??
      _base.settingsDeleteConfirmTitle;

  @override
  String get settingsDeleteConfirmBody =>
      remote.text('settingsDeleteConfirmBody') ??
      _base.settingsDeleteConfirmBody;

  @override
  String get settingsDeleteForever =>
      remote.text('settingsDeleteForever') ?? _base.settingsDeleteForever;

  @override
  String get settingsAccountDeleted =>
      remote.text('settingsAccountDeleted') ?? _base.settingsAccountDeleted;

  @override
  String get settingsDeletePasswordIncorrect =>
      remote.text('settingsDeletePasswordIncorrect') ??
      _base.settingsDeletePasswordIncorrect;

  @override
  String get settingsDeleteFailed =>
      remote.text('settingsDeleteFailed') ?? _base.settingsDeleteFailed;

  @override
  String get settingsDeleteWarning =>
      remote.text('settingsDeleteWarning') ?? _base.settingsDeleteWarning;

  @override
  String get settingsDeleteConfirmWithPassword =>
      remote.text('settingsDeleteConfirmWithPassword') ??
      _base.settingsDeleteConfirmWithPassword;

  @override
  String get settingsDeleteConfirmWithProvider =>
      remote.text('settingsDeleteConfirmWithProvider') ??
      _base.settingsDeleteConfirmWithProvider;

  @override
  String settingsDeleteWithProvider(String provider) =>
      remote.format(
        'settingsDeleteWithProvider',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'provider': provider},
        ),
      ) ??
      _base.settingsDeleteWithProvider(provider);

  @override
  String settingsDeleteProviderMismatch(String provider) =>
      remote.format(
        'settingsDeleteProviderMismatch',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'provider': provider},
        ),
      ) ??
      _base.settingsDeleteProviderMismatch(provider);

  @override
  String get settingsDeletePasswordRequired =>
      remote.text('settingsDeletePasswordRequired') ??
      _base.settingsDeletePasswordRequired;

  @override
  String get settingsDeleteMyAccount =>
      remote.text('settingsDeleteMyAccount') ?? _base.settingsDeleteMyAccount;

  @override
  String get settingsDeleting =>
      remote.text('settingsDeleting') ?? _base.settingsDeleting;

  @override
  String get settingsAvatarCropTitle =>
      remote.text('settingsAvatarCropTitle') ?? _base.settingsAvatarCropTitle;

  @override
  String get settingsAvatarOpenFailed =>
      remote.text('settingsAvatarOpenFailed') ?? _base.settingsAvatarOpenFailed;

  @override
  String get settingsAvatarUsePhoto =>
      remote.text('settingsAvatarUsePhoto') ?? _base.settingsAvatarUsePhoto;

  @override
  String get settingsPhotoGallery =>
      remote.text('settingsPhotoGallery') ?? _base.settingsPhotoGallery;

  @override
  String get settingsPhotoCamera =>
      remote.text('settingsPhotoCamera') ?? _base.settingsPhotoCamera;

  @override
  String get settingsPhotoRemove =>
      remote.text('settingsPhotoRemove') ?? _base.settingsPhotoRemove;

  @override
  String get settingsPhotoRemoved =>
      remote.text('settingsPhotoRemoved') ?? _base.settingsPhotoRemoved;

  @override
  String get settingsPhotoUpdated =>
      remote.text('settingsPhotoUpdated') ?? _base.settingsPhotoUpdated;

  @override
  String get settingsPhotoUpdateFailed =>
      remote.text('settingsPhotoUpdateFailed') ??
      _base.settingsPhotoUpdateFailed;

  @override
  String get settingsPhotoChange =>
      remote.text('settingsPhotoChange') ?? _base.settingsPhotoChange;

  @override
  String get settingsPhotoHint =>
      remote.text('settingsPhotoHint') ?? _base.settingsPhotoHint;

  @override
  String get settingsProfileUpdated =>
      remote.text('settingsProfileUpdated') ?? _base.settingsProfileUpdated;

  @override
  String get settingsProfileUpdateFailed =>
      remote.text('settingsProfileUpdateFailed') ??
      _base.settingsProfileUpdateFailed;

  @override
  String get settingsProfileLoadFailed =>
      remote.text('settingsProfileLoadFailed') ??
      _base.settingsProfileLoadFailed;

  @override
  String get settingsProfileFullNameLabel =>
      remote.text('settingsProfileFullNameLabel') ??
      _base.settingsProfileFullNameLabel;

  @override
  String get settingsProfileNameHint =>
      remote.text('settingsProfileNameHint') ?? _base.settingsProfileNameHint;

  @override
  String get settingsProfileNameRequired =>
      remote.text('settingsProfileNameRequired') ??
      _base.settingsProfileNameRequired;

  @override
  String get settingsProfileJobTitleLabel =>
      remote.text('settingsProfileJobTitleLabel') ??
      _base.settingsProfileJobTitleLabel;

  @override
  String get settingsProfileJobTitlesLoadFailed =>
      remote.text('settingsProfileJobTitlesLoadFailed') ??
      _base.settingsProfileJobTitlesLoadFailed;

  @override
  String get settingsProfileEmailReadOnly =>
      remote.text('settingsProfileEmailReadOnly') ??
      _base.settingsProfileEmailReadOnly;

  @override
  String get settingsProfilePhoneLabel =>
      remote.text('settingsProfilePhoneLabel') ??
      _base.settingsProfilePhoneLabel;

  @override
  String get settingsProfileSaveChanges =>
      remote.text('settingsProfileSaveChanges') ??
      _base.settingsProfileSaveChanges;

  @override
  String get settingsProfileTitle =>
      remote.text('settingsProfileTitle') ?? _base.settingsProfileTitle;

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
  String get atsCategoryGeneral =>
      remote.text('atsCategoryGeneral') ?? _base.atsCategoryGeneral;

  @override
  String atsHiddenMore(int count) =>
      remote.format(
        'atsHiddenMore',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'count': count},
        ),
      ) ??
      _base.atsHiddenMore(count);

  @override
  String get myCvsHeaderSubtitle =>
      remote.text('myCvsHeaderSubtitle') ?? _base.myCvsHeaderSubtitle;

  @override
  String get myCvsToolsTitle =>
      remote.text('myCvsToolsTitle') ?? _base.myCvsToolsTitle;

  @override
  String get myCvsToolCreateTitle =>
      remote.text('myCvsToolCreateTitle') ?? _base.myCvsToolCreateTitle;

  @override
  String get myCvsToolCreateBody =>
      remote.text('myCvsToolCreateBody') ?? _base.myCvsToolCreateBody;

  @override
  String get myCvsToolScanTitle =>
      remote.text('myCvsToolScanTitle') ?? _base.myCvsToolScanTitle;

  @override
  String get myCvsToolScanBody =>
      remote.text('myCvsToolScanBody') ?? _base.myCvsToolScanBody;

  @override
  String get myCvsToolUploadTitle =>
      remote.text('myCvsToolUploadTitle') ?? _base.myCvsToolUploadTitle;

  @override
  String get myCvsToolUploadBody =>
      remote.text('myCvsToolUploadBody') ?? _base.myCvsToolUploadBody;

  @override
  String get myCvsToolTargetTitle =>
      remote.text('myCvsToolTargetTitle') ?? _base.myCvsToolTargetTitle;

  @override
  String get myCvsToolTargetBody =>
      remote.text('myCvsToolTargetBody') ?? _base.myCvsToolTargetBody;

  @override
  String get myCvsListTitle =>
      remote.text('myCvsListTitle') ?? _base.myCvsListTitle;

  @override
  String get myCvsEmptyBody =>
      remote.text('myCvsEmptyBody') ?? _base.myCvsEmptyBody;

  @override
  String get myCvsEmptyCreate =>
      remote.text('myCvsEmptyCreate') ?? _base.myCvsEmptyCreate;

  @override
  String get myCvsEmptyUpload =>
      remote.text('myCvsEmptyUpload') ?? _base.myCvsEmptyUpload;

  @override
  String get cvCardOpen => remote.text('cvCardOpen') ?? _base.cvCardOpen;

  @override
  String get cvCardMore => remote.text('cvCardMore') ?? _base.cvCardMore;

  @override
  String cvCardScore(int score) =>
      remote.format(
        'cvCardScore',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'score': score},
        ),
      ) ??
      _base.cvCardScore(score);

  @override
  String get cvCardNotScanned =>
      remote.text('cvCardNotScanned') ?? _base.cvCardNotScanned;

  @override
  String get cvCardScanNow =>
      remote.text('cvCardScanNow') ?? _base.cvCardScanNow;

  @override
  String get cvCardNeedsWork =>
      remote.text('cvCardNeedsWork') ?? _base.cvCardNeedsWork;

  @override
  String get settingsNotificationsFilterAll =>
      remote.text('settingsNotificationsFilterAll') ??
      _base.settingsNotificationsFilterAll;

  @override
  String get settingsNotificationsCategoryCv =>
      remote.text('settingsNotificationsCategoryCv') ??
      _base.settingsNotificationsCategoryCv;

  @override
  String get settingsNotificationsCategoryJobs =>
      remote.text('settingsNotificationsCategoryJobs') ??
      _base.settingsNotificationsCategoryJobs;

  @override
  String get settingsNotificationsCategoryAnalysis =>
      remote.text('settingsNotificationsCategoryAnalysis') ??
      _base.settingsNotificationsCategoryAnalysis;

  @override
  String get settingsNotificationsCategoryLearning =>
      remote.text('settingsNotificationsCategoryLearning') ??
      _base.settingsNotificationsCategoryLearning;

  @override
  String get settingsNotificationsCategoryGeneral =>
      remote.text('settingsNotificationsCategoryGeneral') ??
      _base.settingsNotificationsCategoryGeneral;

  @override
  String get settingsNotificationsToday =>
      remote.text('settingsNotificationsToday') ??
      _base.settingsNotificationsToday;

  @override
  String get settingsNotificationsYesterday =>
      remote.text('settingsNotificationsYesterday') ??
      _base.settingsNotificationsYesterday;

  @override
  String get settingsNotificationsThisWeek =>
      remote.text('settingsNotificationsThisWeek') ??
      _base.settingsNotificationsThisWeek;

  @override
  String get settingsNotificationsEarlier =>
      remote.text('settingsNotificationsEarlier') ??
      _base.settingsNotificationsEarlier;

  @override
  String settingsNotificationsNewCount(int count) =>
      remote.format(
        'settingsNotificationsNewCount',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'count': count},
        ),
      ) ??
      _base.settingsNotificationsNewCount(count);

  @override
  String settingsNotificationsCount(int count) =>
      remote.format(
        'settingsNotificationsCount',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'count': count},
        ),
      ) ??
      _base.settingsNotificationsCount(count);

  @override
  String get settingsNotificationsViewCv =>
      remote.text('settingsNotificationsViewCv') ??
      _base.settingsNotificationsViewCv;

  @override
  String get settingsNotificationsScanCta =>
      remote.text('settingsNotificationsScanCta') ??
      _base.settingsNotificationsScanCta;

  @override
  String get settingsNotificationsFilterEmpty =>
      remote.text('settingsNotificationsFilterEmpty') ??
      _base.settingsNotificationsFilterEmpty;

  @override
  String get settingsNotificationsPreviewTitle =>
      remote.text('settingsNotificationsPreviewTitle') ??
      _base.settingsNotificationsPreviewTitle;

  @override
  String get settingsNotificationsPreviewCvTitle =>
      remote.text('settingsNotificationsPreviewCvTitle') ??
      _base.settingsNotificationsPreviewCvTitle;

  @override
  String get settingsNotificationsPreviewCvBody =>
      remote.text('settingsNotificationsPreviewCvBody') ??
      _base.settingsNotificationsPreviewCvBody;

  @override
  String get settingsNotificationsPreviewJobsTitle =>
      remote.text('settingsNotificationsPreviewJobsTitle') ??
      _base.settingsNotificationsPreviewJobsTitle;

  @override
  String get settingsNotificationsPreviewJobsBody =>
      remote.text('settingsNotificationsPreviewJobsBody') ??
      _base.settingsNotificationsPreviewJobsBody;

  @override
  String get settingsNotificationsPreviewAnalysisTitle =>
      remote.text('settingsNotificationsPreviewAnalysisTitle') ??
      _base.settingsNotificationsPreviewAnalysisTitle;

  @override
  String get settingsNotificationsPreviewAnalysisBody =>
      remote.text('settingsNotificationsPreviewAnalysisBody') ??
      _base.settingsNotificationsPreviewAnalysisBody;

  @override
  String get settingsNotificationsCreateCvCta =>
      remote.text('settingsNotificationsCreateCvCta') ??
      _base.settingsNotificationsCreateCvCta;

  @override
  String get authSignInRequiredTitle =>
      remote.text('authSignInRequiredTitle') ?? _base.authSignInRequiredTitle;

  @override
  String get authSignInRequiredSubtitle =>
      remote.text('authSignInRequiredSubtitle') ??
      _base.authSignInRequiredSubtitle;

  @override
  String get authSignInRequiredCardTitle =>
      remote.text('authSignInRequiredCardTitle') ??
      _base.authSignInRequiredCardTitle;

  @override
  String get authSignInRequiredBody =>
      remote.text('authSignInRequiredBody') ?? _base.authSignInRequiredBody;

  @override
  String get authSignInRequiredBrowseJobs =>
      remote.text('authSignInRequiredBrowseJobs') ??
      _base.authSignInRequiredBrowseJobs;

  @override
  String get jobsRegionAll =>
      remote.text('jobsRegionAll') ?? _base.jobsRegionAll;

  @override
  String get jobsRegionCentral =>
      remote.text('jobsRegionCentral') ?? _base.jobsRegionCentral;

  @override
  String get jobsRegionEastern =>
      remote.text('jobsRegionEastern') ?? _base.jobsRegionEastern;

  @override
  String get jobsRegionWestern =>
      remote.text('jobsRegionWestern') ?? _base.jobsRegionWestern;

  @override
  String get jobsRegionNorthern =>
      remote.text('jobsRegionNorthern') ?? _base.jobsRegionNorthern;

  @override
  String get jobsRegionSouthern =>
      remote.text('jobsRegionSouthern') ?? _base.jobsRegionSouthern;

  @override
  String jobsEmptyRegionTitle(String region) =>
      remote.format(
        'jobsEmptyRegionTitle',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'region': region},
        ),
      ) ??
      _base.jobsEmptyRegionTitle(region);

  @override
  String get jobsEmptyRegionBody =>
      remote.text('jobsEmptyRegionBody') ?? _base.jobsEmptyRegionBody;

  @override
  String get jobsShowAllRegions =>
      remote.text('jobsShowAllRegions') ?? _base.jobsShowAllRegions;

  @override
  String get jobsMatchedNeedsTitle =>
      remote.text('jobsMatchedNeedsTitle') ?? _base.jobsMatchedNeedsTitle;

  @override
  String get jobsMatchedSetTitle =>
      remote.text('jobsMatchedSetTitle') ?? _base.jobsMatchedSetTitle;

  @override
  String jobsMatchedBasedOn(String title) =>
      remote.format(
        'jobsMatchedBasedOn',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'title': title},
        ),
      ) ??
      _base.jobsMatchedBasedOn(title);

  @override
  String get jobsHowToApply =>
      remote.text('jobsHowToApply') ?? _base.jobsHowToApply;

  @override
  String jobsApplyOpensHost(String host) =>
      remote.format(
        'jobsApplyOpensHost',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'host': host},
        ),
      ) ??
      _base.jobsApplyOpensHost(host);

  @override
  String get jobsApplyByEmail =>
      remote.text('jobsApplyByEmail') ?? _base.jobsApplyByEmail;

  @override
  String get jobsApplyEmailHint =>
      remote.text('jobsApplyEmailHint') ?? _base.jobsApplyEmailHint;

  @override
  String get jobsCopyEmail =>
      remote.text('jobsCopyEmail') ?? _base.jobsCopyEmail;

  @override
  String get jobsEmailCopied =>
      remote.text('jobsEmailCopied') ?? _base.jobsEmailCopied;

  @override
  String get jobsOpenEmailFailed =>
      remote.text('jobsOpenEmailFailed') ?? _base.jobsOpenEmailFailed;

  @override
  String get jobsNoDirectApply =>
      remote.text('jobsNoDirectApply') ?? _base.jobsNoDirectApply;

  @override
  String get jobsNoDirectApplyHint =>
      remote.text('jobsNoDirectApplyHint') ?? _base.jobsNoDirectApplyHint;

  @override
  String get jobsApplyMethodLink =>
      remote.text('jobsApplyMethodLink') ?? _base.jobsApplyMethodLink;

  @override
  String get jobsApplyMethodEmail =>
      remote.text('jobsApplyMethodEmail') ?? _base.jobsApplyMethodEmail;

  @override
  String jobsSourceName(String source) =>
      remote.format(
        'jobsSourceName',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'source': source},
        ),
      ) ??
      _base.jobsSourceName(source);

  @override
  String get jobsViewSourcePost =>
      remote.text('jobsViewSourcePost') ?? _base.jobsViewSourcePost;

  @override
  String get jobsShare => remote.text('jobsShare') ?? _base.jobsShare;

  @override
  String get jobsRemoteChip =>
      remote.text('jobsRemoteChip') ?? _base.jobsRemoteChip;

  @override
  String get homeProfileSubtitle =>
      remote.text('homeProfileSubtitle') ?? _base.homeProfileSubtitle;

  @override
  String get homeProfileOpen =>
      remote.text('homeProfileOpen') ?? _base.homeProfileOpen;

  @override
  String get homeStartCreateTitle =>
      remote.text('homeStartCreateTitle') ?? _base.homeStartCreateTitle;

  @override
  String get homeStartCreateBody =>
      remote.text('homeStartCreateBody') ?? _base.homeStartCreateBody;

  @override
  String get homeStartAtsTitle =>
      remote.text('homeStartAtsTitle') ?? _base.homeStartAtsTitle;

  @override
  String get homeStartAtsBody =>
      remote.text('homeStartAtsBody') ?? _base.homeStartAtsBody;

  @override
  String get homeServiceUpload =>
      remote.text('homeServiceUpload') ?? _base.homeServiceUpload;

  @override
  String get homeServiceTarget =>
      remote.text('homeServiceTarget') ?? _base.homeServiceTarget;

  @override
  String get homeServiceEducation =>
      remote.text('homeServiceEducation') ?? _base.homeServiceEducation;

  @override
  String get homeSoon => remote.text('homeSoon') ?? _base.homeSoon;

  @override
  String homeServiceSoonA11y(String service) =>
      remote.format(
        'homeServiceSoonA11y',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'service': service},
        ),
      ) ??
      _base.homeServiceSoonA11y(service);

  @override
  String get homeMyCvTitle =>
      remote.text('homeMyCvTitle') ?? _base.homeMyCvTitle;

  @override
  String homeMyCvEdited(String time) =>
      remote.format(
        'homeMyCvEdited',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'time': time},
        ),
      ) ??
      _base.homeMyCvEdited(time);

  @override
  String get homeMyCvEdit => remote.text('homeMyCvEdit') ?? _base.homeMyCvEdit;

  @override
  String get homeMyCvCheck =>
      remote.text('homeMyCvCheck') ?? _base.homeMyCvCheck;

  @override
  String get homeMyCvEmptyTitle =>
      remote.text('homeMyCvEmptyTitle') ?? _base.homeMyCvEmptyTitle;

  @override
  String get homeMyCvEmptyBody =>
      remote.text('homeMyCvEmptyBody') ?? _base.homeMyCvEmptyBody;

  @override
  String get homeHonesty => remote.text('homeHonesty') ?? _base.homeHonesty;

  @override
  String get authEmailHint =>
      remote.text('authEmailHint') ?? _base.authEmailHint;

  @override
  String get authPhoneHint =>
      remote.text('authPhoneHint') ?? _base.authPhoneHint;

  @override
  String get cvPersonalEmailHint =>
      remote.text('cvPersonalEmailHint') ?? _base.cvPersonalEmailHint;

  @override
  String get cvPersonalPhoneHint =>
      remote.text('cvPersonalPhoneHint') ?? _base.cvPersonalPhoneHint;

  @override
  String get cvPersonalLinkedinHint =>
      remote.text('cvPersonalLinkedinHint') ?? _base.cvPersonalLinkedinHint;

  @override
  String get authSocialGoogle =>
      remote.text('authSocialGoogle') ?? _base.authSocialGoogle;

  @override
  String get authSocialApple =>
      remote.text('authSocialApple') ?? _base.authSocialApple;

  @override
  String get authRegisterEmailHint =>
      remote.text('authRegisterEmailHint') ?? _base.authRegisterEmailHint;

  @override
  String get timeJustNow => remote.text('timeJustNow') ?? _base.timeJustNow;

  @override
  String timeMinutesAgo(int count) =>
      remote.format(
        'timeMinutesAgo',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'count': count},
        ),
      ) ??
      _base.timeMinutesAgo(count);

  @override
  String timeHoursAgo(int count) =>
      remote.format(
        'timeHoursAgo',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'count': count},
        ),
      ) ??
      _base.timeHoursAgo(count);

  @override
  String get timeYesterday =>
      remote.text('timeYesterday') ?? _base.timeYesterday;

  @override
  String get savedJustNow => remote.text('savedJustNow') ?? _base.savedJustNow;

  @override
  String savedAgo(String time) =>
      remote.format(
        'savedAgo',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'time': time},
        ),
      ) ??
      _base.savedAgo(time);

  @override
  String get untitledTitle =>
      remote.text('untitledTitle') ?? _base.untitledTitle;

  @override
  String get aiErrorTooLong =>
      remote.text('aiErrorTooLong') ?? _base.aiErrorTooLong;

  @override
  String get aiErrorTryAgain =>
      remote.text('aiErrorTryAgain') ?? _base.aiErrorTryAgain;

  @override
  String aiGenerationFailed(String detail) =>
      remote.format(
        'aiGenerationFailed',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'detail': detail},
        ),
      ) ??
      _base.aiGenerationFailed(detail);

  @override
  String aiSuggestionsFailed(String detail) =>
      remote.format(
        'aiSuggestionsFailed',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'detail': detail},
        ),
      ) ??
      _base.aiSuggestionsFailed(detail);

  @override
  String aiLocalFallback(String detail) =>
      remote.format(
        'aiLocalFallback',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'detail': detail},
        ),
      ) ??
      _base.aiLocalFallback(detail);

  @override
  String get jobNewsTitle => remote.text('jobNewsTitle') ?? _base.jobNewsTitle;

  @override
  String get crashMessage => remote.text('crashMessage') ?? _base.crashMessage;

  @override
  String get avatarFallbackInitial =>
      remote.text('avatarFallbackInitial') ?? _base.avatarFallbackInitial;

  @override
  String get coreApiErrorBadResponse =>
      remote.text('coreApiErrorBadResponse') ?? _base.coreApiErrorBadResponse;

  @override
  String get coreApiErrorEmptyResponse =>
      remote.text('coreApiErrorEmptyResponse') ??
      _base.coreApiErrorEmptyResponse;

  @override
  String get coreApiErrorUnexpected =>
      remote.text('coreApiErrorUnexpected') ?? _base.coreApiErrorUnexpected;

  @override
  String get coreApiErrorRequestFailed =>
      remote.text('coreApiErrorRequestFailed') ??
      _base.coreApiErrorRequestFailed;

  @override
  String coreApiErrorStatus(int code) =>
      remote.format(
        'coreApiErrorStatus',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'code': code},
        ),
      ) ??
      _base.coreApiErrorStatus(code);

  @override
  String get authVerifyCodeResent =>
      remote.text('authVerifyCodeResent') ?? _base.authVerifyCodeResent;

  @override
  String get authForgotCodeSent =>
      remote.text('authForgotCodeSent') ?? _base.authForgotCodeSent;

  @override
  String get authForgotPasswordReset =>
      remote.text('authForgotPasswordReset') ?? _base.authForgotPasswordReset;

  @override
  String get serverDashboardStatusActive =>
      remote.text('serverDashboardStatusActive') ??
      _base.serverDashboardStatusActive;

  @override
  String get serverDashboardCreateCvTitle =>
      remote.text('serverDashboardCreateCvTitle') ??
      _base.serverDashboardCreateCvTitle;

  @override
  String get serverDashboardCreateCvSubtitle =>
      remote.text('serverDashboardCreateCvSubtitle') ??
      _base.serverDashboardCreateCvSubtitle;

  @override
  String get serverDashboardCreateCvButton =>
      remote.text('serverDashboardCreateCvButton') ??
      _base.serverDashboardCreateCvButton;

  @override
  String get serverDashboardAnalyzeTitle =>
      remote.text('serverDashboardAnalyzeTitle') ??
      _base.serverDashboardAnalyzeTitle;

  @override
  String get serverDashboardAnalyzeSubtitle =>
      remote.text('serverDashboardAnalyzeSubtitle') ??
      _base.serverDashboardAnalyzeSubtitle;

  @override
  String get serverDashboardAnalyzeButton =>
      remote.text('serverDashboardAnalyzeButton') ??
      _base.serverDashboardAnalyzeButton;

  @override
  String get serverMyCvsTitle =>
      remote.text('serverMyCvsTitle') ?? _base.serverMyCvsTitle;

  @override
  String serverMyCvsSummary(int count) =>
      remote.format(
        'serverMyCvsSummary',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'count': count},
        ),
      ) ??
      _base.serverMyCvsSummary(count);

  @override
  String serverMyCvsUpdated(String date) =>
      remote.format(
        'serverMyCvsUpdated',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'date': date},
        ),
      ) ??
      _base.serverMyCvsUpdated(date);

  @override
  String get serverMyCvsUpdatedUnknown =>
      remote.text('serverMyCvsUpdatedUnknown') ??
      _base.serverMyCvsUpdatedUnknown;

  @override
  String serverMyCvsTailoredTitle(String title) =>
      remote.format(
        'serverMyCvsTailoredTitle',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'title': title},
        ),
      ) ??
      _base.serverMyCvsTailoredTitle(title);

  @override
  String get serverCvTemplatesTitle =>
      remote.text('serverCvTemplatesTitle') ?? _base.serverCvTemplatesTitle;

  @override
  String get serverCvTemplatesSubtitle =>
      remote.text('serverCvTemplatesSubtitle') ??
      _base.serverCvTemplatesSubtitle;

  @override
  String get serverEducationTitle =>
      remote.text('serverEducationTitle') ?? _base.serverEducationTitle;

  @override
  String get serverEducationSubtitle =>
      remote.text('serverEducationSubtitle') ?? _base.serverEducationSubtitle;

  @override
  String get serverEducationTargetLabel =>
      remote.text('serverEducationTargetLabel') ??
      _base.serverEducationTargetLabel;

  @override
  String get serverEducationTabNews =>
      remote.text('serverEducationTabNews') ?? _base.serverEducationTabNews;

  @override
  String get serverEducationTabCertificates =>
      remote.text('serverEducationTabCertificates') ??
      _base.serverEducationTabCertificates;

  @override
  String get serverEducationTabStudy =>
      remote.text('serverEducationTabStudy') ?? _base.serverEducationTabStudy;

  @override
  String get serverEducationStartLearning =>
      remote.text('serverEducationStartLearning') ??
      _base.serverEducationStartLearning;

  @override
  String get serverJobsTitle =>
      remote.text('serverJobsTitle') ?? _base.serverJobsTitle;

  @override
  String get serverJobsSubtitle =>
      remote.text('serverJobsSubtitle') ?? _base.serverJobsSubtitle;

  @override
  String serverJobsApplyBy(String date) =>
      remote.format(
        'serverJobsApplyBy',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'date': date},
        ),
      ) ??
      _base.serverJobsApplyBy(date);

  @override
  String get serverJobsSourceGovLabel =>
      remote.text('serverJobsSourceGovLabel') ?? _base.serverJobsSourceGovLabel;

  @override
  String get serverJobsSourceGovBadge =>
      remote.text('serverJobsSourceGovBadge') ?? _base.serverJobsSourceGovBadge;

  @override
  String get serverJobsSourceCompanyLabel =>
      remote.text('serverJobsSourceCompanyLabel') ??
      _base.serverJobsSourceCompanyLabel;

  @override
  String get serverJobsSourceCompanyBadge =>
      remote.text('serverJobsSourceCompanyBadge') ??
      _base.serverJobsSourceCompanyBadge;

  @override
  String get serverJobsSourceTamheerLabel =>
      remote.text('serverJobsSourceTamheerLabel') ??
      _base.serverJobsSourceTamheerLabel;

  @override
  String get serverJobsSourceTamheerBadge =>
      remote.text('serverJobsSourceTamheerBadge') ??
      _base.serverJobsSourceTamheerBadge;

  @override
  String get serverJobsSourceStartupLabel =>
      remote.text('serverJobsSourceStartupLabel') ??
      _base.serverJobsSourceStartupLabel;

  @override
  String get serverJobsSourceStartupBadge =>
      remote.text('serverJobsSourceStartupBadge') ??
      _base.serverJobsSourceStartupBadge;

  @override
  String serverJobsSalaryRange(String min, String max, String currency) =>
      remote.format(
        'serverJobsSalaryRange',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'min': min, 'max': max, 'currency': currency},
        ),
      ) ??
      _base.serverJobsSalaryRange(min, max, currency);

  @override
  String serverJobsSalaryFrom(String min, String currency) =>
      remote.format(
        'serverJobsSalaryFrom',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'min': min, 'currency': currency},
        ),
      ) ??
      _base.serverJobsSalaryFrom(min, currency);

  @override
  String serverJobsSalaryUpTo(String max, String currency) =>
      remote.format(
        'serverJobsSalaryUpTo',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'max': max, 'currency': currency},
        ),
      ) ??
      _base.serverJobsSalaryUpTo(max, currency);

  @override
  String get serverJobsCurrencySar =>
      remote.text('serverJobsCurrencySar') ?? _base.serverJobsCurrencySar;

  @override
  String get serverNotificationsAllRead =>
      remote.text('serverNotificationsAllRead') ??
      _base.serverNotificationsAllRead;

  @override
  String get serverNotificationsPreferencesUpdated =>
      remote.text('serverNotificationsPreferencesUpdated') ??
      _base.serverNotificationsPreferencesUpdated;

  @override
  String get serverNotificationsOpenRecorded =>
      remote.text('serverNotificationsOpenRecorded') ??
      _base.serverNotificationsOpenRecorded;

  @override
  String get serverNotificationsActivityRecorded =>
      remote.text('serverNotificationsActivityRecorded') ??
      _base.serverNotificationsActivityRecorded;

  @override
  String get serverNotificationsConversionRecorded =>
      remote.text('serverNotificationsConversionRecorded') ??
      _base.serverNotificationsConversionRecorded;

  @override
  String get serverNotificationsTokenRegistered =>
      remote.text('serverNotificationsTokenRegistered') ??
      _base.serverNotificationsTokenRegistered;

  @override
  String get serverNotificationsTokenRemoved =>
      remote.text('serverNotificationsTokenRemoved') ??
      _base.serverNotificationsTokenRemoved;

  @override
  String get serverAuthInvalidCredentials =>
      remote.text('serverAuthInvalidCredentials') ??
      _base.serverAuthInvalidCredentials;

  @override
  String get serverAuthEmailVerified =>
      remote.text('serverAuthEmailVerified') ?? _base.serverAuthEmailVerified;

  @override
  String get serverAuthEmailAlreadyVerified =>
      remote.text('serverAuthEmailAlreadyVerified') ??
      _base.serverAuthEmailAlreadyVerified;

  @override
  String get serverAuthVerificationCodeSent =>
      remote.text('serverAuthVerificationCodeSent') ??
      _base.serverAuthVerificationCodeSent;

  @override
  String get serverAuthResetCodeSent =>
      remote.text('serverAuthResetCodeSent') ?? _base.serverAuthResetCodeSent;

  @override
  String get serverAuthInvalidCode =>
      remote.text('serverAuthInvalidCode') ?? _base.serverAuthInvalidCode;

  @override
  String get serverAuthPasswordReset =>
      remote.text('serverAuthPasswordReset') ?? _base.serverAuthPasswordReset;

  @override
  String get serverAuthLoggedOut =>
      remote.text('serverAuthLoggedOut') ?? _base.serverAuthLoggedOut;

  @override
  String get serverAuthCurrentPasswordWrong =>
      remote.text('serverAuthCurrentPasswordWrong') ??
      _base.serverAuthCurrentPasswordWrong;

  @override
  String get serverAuthPasswordChanged =>
      remote.text('serverAuthPasswordChanged') ??
      _base.serverAuthPasswordChanged;

  @override
  String get serverAuthAvatarSaveFailed =>
      remote.text('serverAuthAvatarSaveFailed') ??
      _base.serverAuthAvatarSaveFailed;

  @override
  String get serverAuthPasswordWrong =>
      remote.text('serverAuthPasswordWrong') ?? _base.serverAuthPasswordWrong;

  @override
  String get serverAuthSocialAccountMismatch =>
      remote.text('serverAuthSocialAccountMismatch') ??
      _base.serverAuthSocialAccountMismatch;

  @override
  String get serverAuthAccountDeleted =>
      remote.text('serverAuthAccountDeleted') ?? _base.serverAuthAccountDeleted;

  @override
  String get serverAuthJobTitleOtherRequired =>
      remote.text('serverAuthJobTitleOtherRequired') ??
      _base.serverAuthJobTitleOtherRequired;

  @override
  String get serverAuthVerificationResendWait =>
      remote.text('serverAuthVerificationResendWait') ??
      _base.serverAuthVerificationResendWait;

  @override
  String get serverAuthResetResendWait =>
      remote.text('serverAuthResetResendWait') ??
      _base.serverAuthResetResendWait;

  @override
  String get serverAuthEmailNotVerified =>
      remote.text('serverAuthEmailNotVerified') ??
      _base.serverAuthEmailNotVerified;

  @override
  String serverAuthSocialUnavailable(String provider) =>
      remote.format(
        'serverAuthSocialUnavailable',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'provider': provider},
        ),
      ) ??
      _base.serverAuthSocialUnavailable(provider);

  @override
  String serverAuthSocialInvalidToken(String provider) =>
      remote.format(
        'serverAuthSocialInvalidToken',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'provider': provider},
        ),
      ) ??
      _base.serverAuthSocialInvalidToken(provider);

  @override
  String serverAuthSocialEmailUnverified(String provider) =>
      remote.format(
        'serverAuthSocialEmailUnverified',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'provider': provider},
        ),
      ) ??
      _base.serverAuthSocialEmailUnverified(provider);

  @override
  String get serverCvDeleted =>
      remote.text('serverCvDeleted') ?? _base.serverCvDeleted;

  @override
  String get serverCvTemplateUnavailable =>
      remote.text('serverCvTemplateUnavailable') ??
      _base.serverCvTemplateUnavailable;

  @override
  String get serverCvTemplatePremiumOnly =>
      remote.text('serverCvTemplatePremiumOnly') ??
      _base.serverCvTemplatePremiumOnly;

  @override
  String get serverCvEnhanceUnavailable =>
      remote.text('serverCvEnhanceUnavailable') ??
      _base.serverCvEnhanceUnavailable;

  @override
  String get serverCvEnhanceFailed =>
      remote.text('serverCvEnhanceFailed') ?? _base.serverCvEnhanceFailed;

  @override
  String get serverCvExportGenerating =>
      remote.text('serverCvExportGenerating') ?? _base.serverCvExportGenerating;

  @override
  String get serverCvExportMissingContact =>
      remote.text('serverCvExportMissingContact') ??
      _base.serverCvExportMissingContact;

  @override
  String get serverCvExportUnstructuredExperience =>
      remote.text('serverCvExportUnstructuredExperience') ??
      _base.serverCvExportUnstructuredExperience;

  @override
  String serverCvTemplateHidesSections(String sections) =>
      remote.format(
        'serverCvTemplateHidesSections',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'sections': sections},
        ),
      ) ??
      _base.serverCvTemplateHidesSections(sections);

  @override
  String get serverCvTemplateSectionListSeparator =>
      remote.text('serverCvTemplateSectionListSeparator') ??
      _base.serverCvTemplateSectionListSeparator;

  @override
  String get serverCvSectionSummary =>
      remote.text('serverCvSectionSummary') ?? _base.serverCvSectionSummary;

  @override
  String get serverCvSectionSkills =>
      remote.text('serverCvSectionSkills') ?? _base.serverCvSectionSkills;

  @override
  String get serverCvSectionExperience =>
      remote.text('serverCvSectionExperience') ??
      _base.serverCvSectionExperience;

  @override
  String get serverCvSectionEducation =>
      remote.text('serverCvSectionEducation') ?? _base.serverCvSectionEducation;

  @override
  String get serverCvSectionCertifications =>
      remote.text('serverCvSectionCertifications') ??
      _base.serverCvSectionCertifications;

  @override
  String get serverCvSectionProjects =>
      remote.text('serverCvSectionProjects') ?? _base.serverCvSectionProjects;

  @override
  String get serverCvSectionLanguages =>
      remote.text('serverCvSectionLanguages') ?? _base.serverCvSectionLanguages;

  @override
  String get serverCvSectionCustom =>
      remote.text('serverCvSectionCustom') ?? _base.serverCvSectionCustom;

  @override
  String get serverCvFileTypeUnsupported =>
      remote.text('serverCvFileTypeUnsupported') ??
      _base.serverCvFileTypeUnsupported;

  @override
  String serverCvTextTooShort(int min) =>
      remote.format(
        'serverCvTextTooShort',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'min': min},
        ),
      ) ??
      _base.serverCvTextTooShort(min);

  @override
  String get serverCvPdfUnreadable =>
      remote.text('serverCvPdfUnreadable') ?? _base.serverCvPdfUnreadable;

  @override
  String get serverAnalysisResumeRequired =>
      remote.text('serverAnalysisResumeRequired') ??
      _base.serverAnalysisResumeRequired;

  @override
  String get serverAnalysisLockedTitle =>
      remote.text('serverAnalysisLockedTitle') ??
      _base.serverAnalysisLockedTitle;

  @override
  String serverAnalysisLockedMessage(int count) =>
      remote.format(
        'serverAnalysisLockedMessage',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'count': count},
        ),
      ) ??
      _base.serverAnalysisLockedMessage(count);

  @override
  String get serverAnalysisLockedCta =>
      remote.text('serverAnalysisLockedCta') ?? _base.serverAnalysisLockedCta;

  @override
  String get serverPaywallTitle =>
      remote.text('serverPaywallTitle') ?? _base.serverPaywallTitle;

  @override
  String get serverPaywallCta =>
      remote.text('serverPaywallCta') ?? _base.serverPaywallCta;

  @override
  String get serverPaywallJobMatch =>
      remote.text('serverPaywallJobMatch') ?? _base.serverPaywallJobMatch;

  @override
  String get serverPaywallDownload =>
      remote.text('serverPaywallDownload') ?? _base.serverPaywallDownload;

  @override
  String get serverPaywallEnhance =>
      remote.text('serverPaywallEnhance') ?? _base.serverPaywallEnhance;

  @override
  String serverPaywallDailyCvLimit(int limit) =>
      remote.format(
        'serverPaywallDailyCvLimit',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'limit': limit},
        ),
      ) ??
      _base.serverPaywallDailyCvLimit(limit);

  @override
  String serverPaywallDailyAnalysisLimit(int limit) =>
      remote.format(
        'serverPaywallDailyAnalysisLimit',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'limit': limit},
        ),
      ) ??
      _base.serverPaywallDailyAnalysisLimit(limit);

  @override
  String get serverPaywallBenefitPdf =>
      remote.text('serverPaywallBenefitPdf') ?? _base.serverPaywallBenefitPdf;

  @override
  String get serverPaywallBenefitEnhance =>
      remote.text('serverPaywallBenefitEnhance') ??
      _base.serverPaywallBenefitEnhance;

  @override
  String get serverPaywallBenefitAnalysis =>
      remote.text('serverPaywallBenefitAnalysis') ??
      _base.serverPaywallBenefitAnalysis;

  @override
  String get serverPaywallBenefitUnlimited =>
      remote.text('serverPaywallBenefitUnlimited') ??
      _base.serverPaywallBenefitUnlimited;

  @override
  String get serverJobMatchDailyLimit =>
      remote.text('serverJobMatchDailyLimit') ?? _base.serverJobMatchDailyLimit;

  @override
  String get serverPlanMonthlyName =>
      remote.text('serverPlanMonthlyName') ?? _base.serverPlanMonthlyName;

  @override
  String get serverPlanSixMonthsName =>
      remote.text('serverPlanSixMonthsName') ?? _base.serverPlanSixMonthsName;

  @override
  String get serverPlanSixMonthsBadge =>
      remote.text('serverPlanSixMonthsBadge') ?? _base.serverPlanSixMonthsBadge;

  @override
  String get serverPlanAnnualName =>
      remote.text('serverPlanAnnualName') ?? _base.serverPlanAnnualName;

  @override
  String get serverErrorUnauthenticated =>
      remote.text('serverErrorUnauthenticated') ??
      _base.serverErrorUnauthenticated;

  @override
  String get serverErrorForbidden =>
      remote.text('serverErrorForbidden') ?? _base.serverErrorForbidden;

  @override
  String get serverErrorNotFound =>
      remote.text('serverErrorNotFound') ?? _base.serverErrorNotFound;

  @override
  String get serverErrorMethodNotAllowed =>
      remote.text('serverErrorMethodNotAllowed') ??
      _base.serverErrorMethodNotAllowed;

  @override
  String get serverErrorTooManyRequests =>
      remote.text('serverErrorTooManyRequests') ??
      _base.serverErrorTooManyRequests;

  @override
  String get serverErrorServer =>
      remote.text('serverErrorServer') ?? _base.serverErrorServer;

  @override
  String get serverErrorUnavailable =>
      remote.text('serverErrorUnavailable') ?? _base.serverErrorUnavailable;

  @override
  String get serverErrorRequestFailed =>
      remote.text('serverErrorRequestFailed') ?? _base.serverErrorRequestFailed;

  @override
  String serverValidationRequired(String attribute) =>
      remote.format(
        'serverValidationRequired',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'attribute': attribute},
        ),
      ) ??
      _base.serverValidationRequired(attribute);

  @override
  String serverValidationString(String attribute) =>
      remote.format(
        'serverValidationString',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'attribute': attribute},
        ),
      ) ??
      _base.serverValidationString(attribute);

  @override
  String get serverValidationEmail =>
      remote.text('serverValidationEmail') ?? _base.serverValidationEmail;

  @override
  String serverValidationFile(String attribute) =>
      remote.format(
        'serverValidationFile',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'attribute': attribute},
        ),
      ) ??
      _base.serverValidationFile(attribute);

  @override
  String serverValidationImage(String attribute) =>
      remote.format(
        'serverValidationImage',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'attribute': attribute},
        ),
      ) ??
      _base.serverValidationImage(attribute);

  @override
  String serverValidationMimes(String attribute, String values) =>
      remote.format(
        'serverValidationMimes',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'attribute': attribute, 'values': values},
        ),
      ) ??
      _base.serverValidationMimes(attribute, values);

  @override
  String serverValidationMaxString(String attribute, String max) =>
      remote.format(
        'serverValidationMaxString',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'attribute': attribute, 'max': max},
        ),
      ) ??
      _base.serverValidationMaxString(attribute, max);

  @override
  String serverValidationMaxFile(String attribute, String max) =>
      remote.format(
        'serverValidationMaxFile',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'attribute': attribute, 'max': max},
        ),
      ) ??
      _base.serverValidationMaxFile(attribute, max);

  @override
  String serverValidationMaxNumeric(String attribute, String max) =>
      remote.format(
        'serverValidationMaxNumeric',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'attribute': attribute, 'max': max},
        ),
      ) ??
      _base.serverValidationMaxNumeric(attribute, max);

  @override
  String serverValidationMaxArray(String attribute, String max) =>
      remote.format(
        'serverValidationMaxArray',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'attribute': attribute, 'max': max},
        ),
      ) ??
      _base.serverValidationMaxArray(attribute, max);

  @override
  String serverValidationMinString(String attribute, String min) =>
      remote.format(
        'serverValidationMinString',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'attribute': attribute, 'min': min},
        ),
      ) ??
      _base.serverValidationMinString(attribute, min);

  @override
  String serverValidationMinFile(String attribute, String min) =>
      remote.format(
        'serverValidationMinFile',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'attribute': attribute, 'min': min},
        ),
      ) ??
      _base.serverValidationMinFile(attribute, min);

  @override
  String serverValidationMinNumeric(String attribute, String min) =>
      remote.format(
        'serverValidationMinNumeric',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'attribute': attribute, 'min': min},
        ),
      ) ??
      _base.serverValidationMinNumeric(attribute, min);

  @override
  String serverValidationMinArray(String attribute, String min) =>
      remote.format(
        'serverValidationMinArray',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'attribute': attribute, 'min': min},
        ),
      ) ??
      _base.serverValidationMinArray(attribute, min);

  @override
  String serverValidationBetweenNumeric(
          String attribute, String min, String max) =>
      remote.format(
        'serverValidationBetweenNumeric',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'attribute': attribute, 'min': min, 'max': max},
        ),
      ) ??
      _base.serverValidationBetweenNumeric(attribute, min, max);

  @override
  String serverValidationBetweenString(
          String attribute, String min, String max) =>
      remote.format(
        'serverValidationBetweenString',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'attribute': attribute, 'min': min, 'max': max},
        ),
      ) ??
      _base.serverValidationBetweenString(attribute, min, max);

  @override
  String serverValidationSizeString(String attribute, String size) =>
      remote.format(
        'serverValidationSizeString',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'attribute': attribute, 'size': size},
        ),
      ) ??
      _base.serverValidationSizeString(attribute, size);

  @override
  String serverValidationIn(String attribute) =>
      remote.format(
        'serverValidationIn',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'attribute': attribute},
        ),
      ) ??
      _base.serverValidationIn(attribute);

  @override
  String serverValidationInteger(String attribute) =>
      remote.format(
        'serverValidationInteger',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'attribute': attribute},
        ),
      ) ??
      _base.serverValidationInteger(attribute);

  @override
  String serverValidationNumeric(String attribute) =>
      remote.format(
        'serverValidationNumeric',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'attribute': attribute},
        ),
      ) ??
      _base.serverValidationNumeric(attribute);

  @override
  String serverValidationBoolean(String attribute) =>
      remote.format(
        'serverValidationBoolean',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'attribute': attribute},
        ),
      ) ??
      _base.serverValidationBoolean(attribute);

  @override
  String serverValidationArray(String attribute) =>
      remote.format(
        'serverValidationArray',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'attribute': attribute},
        ),
      ) ??
      _base.serverValidationArray(attribute);

  @override
  String serverValidationRegex(String attribute) =>
      remote.format(
        'serverValidationRegex',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'attribute': attribute},
        ),
      ) ??
      _base.serverValidationRegex(attribute);

  @override
  String serverValidationUrl(String attribute) =>
      remote.format(
        'serverValidationUrl',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'attribute': attribute},
        ),
      ) ??
      _base.serverValidationUrl(attribute);

  @override
  String serverValidationDate(String attribute) =>
      remote.format(
        'serverValidationDate',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'attribute': attribute},
        ),
      ) ??
      _base.serverValidationDate(attribute);

  @override
  String serverValidationExists(String attribute) =>
      remote.format(
        'serverValidationExists',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'attribute': attribute},
        ),
      ) ??
      _base.serverValidationExists(attribute);

  @override
  String serverValidationUnique(String attribute) =>
      remote.format(
        'serverValidationUnique',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'attribute': attribute},
        ),
      ) ??
      _base.serverValidationUnique(attribute);

  @override
  String serverValidationConfirmed(String attribute) =>
      remote.format(
        'serverValidationConfirmed',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'attribute': attribute},
        ),
      ) ??
      _base.serverValidationConfirmed(attribute);

  @override
  String serverValidationRequiredIf(String attribute) =>
      remote.format(
        'serverValidationRequiredIf',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'attribute': attribute},
        ),
      ) ??
      _base.serverValidationRequiredIf(attribute);

  @override
  String serverValidationAccepted(String attribute) =>
      remote.format(
        'serverValidationAccepted',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'attribute': attribute},
        ),
      ) ??
      _base.serverValidationAccepted(attribute);

  @override
  String serverValidationAlphaDash(String attribute) =>
      remote.format(
        'serverValidationAlphaDash',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'attribute': attribute},
        ),
      ) ??
      _base.serverValidationAlphaDash(attribute);

  @override
  String serverValidationMoreErrors(String message, int count) =>
      remote.format(
        'serverValidationMoreErrors',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'message': message, 'count': count},
        ),
      ) ??
      _base.serverValidationMoreErrors(message, count);

  @override
  String get serverAttributeName =>
      remote.text('serverAttributeName') ?? _base.serverAttributeName;

  @override
  String get serverAttributeFullName =>
      remote.text('serverAttributeFullName') ?? _base.serverAttributeFullName;

  @override
  String get serverAttributeEmail =>
      remote.text('serverAttributeEmail') ?? _base.serverAttributeEmail;

  @override
  String get serverAttributePassword =>
      remote.text('serverAttributePassword') ?? _base.serverAttributePassword;

  @override
  String get serverAttributeCurrentPassword =>
      remote.text('serverAttributeCurrentPassword') ??
      _base.serverAttributeCurrentPassword;

  @override
  String get serverAttributeCode =>
      remote.text('serverAttributeCode') ?? _base.serverAttributeCode;

  @override
  String get serverAttributePhone =>
      remote.text('serverAttributePhone') ?? _base.serverAttributePhone;

  @override
  String get serverAttributeLocation =>
      remote.text('serverAttributeLocation') ?? _base.serverAttributeLocation;

  @override
  String get serverAttributeJobTitle =>
      remote.text('serverAttributeJobTitle') ?? _base.serverAttributeJobTitle;

  @override
  String get serverAttributeJobTitleOther =>
      remote.text('serverAttributeJobTitleOther') ??
      _base.serverAttributeJobTitleOther;

  @override
  String get serverAttributeAvatar =>
      remote.text('serverAttributeAvatar') ?? _base.serverAttributeAvatar;

  @override
  String get serverAttributeRoleInterest =>
      remote.text('serverAttributeRoleInterest') ??
      _base.serverAttributeRoleInterest;

  @override
  String get serverAttributeTargetJobTitle =>
      remote.text('serverAttributeTargetJobTitle') ??
      _base.serverAttributeTargetJobTitle;

  @override
  String get serverAttributeNotes =>
      remote.text('serverAttributeNotes') ?? _base.serverAttributeNotes;

  @override
  String get serverAttributeResumeText =>
      remote.text('serverAttributeResumeText') ??
      _base.serverAttributeResumeText;

  @override
  String get serverAttributeResumeFile =>
      remote.text('serverAttributeResumeFile') ??
      _base.serverAttributeResumeFile;

  @override
  String get serverAttributeLinkedin =>
      remote.text('serverAttributeLinkedin') ?? _base.serverAttributeLinkedin;

  @override
  String get serverAttributeLanguage =>
      remote.text('serverAttributeLanguage') ?? _base.serverAttributeLanguage;

  @override
  String get serverAttributeSummary =>
      remote.text('serverAttributeSummary') ?? _base.serverAttributeSummary;

  @override
  String get serverAttributeSkills =>
      remote.text('serverAttributeSkills') ?? _base.serverAttributeSkills;

  @override
  String get serverAttributeExperience =>
      remote.text('serverAttributeExperience') ??
      _base.serverAttributeExperience;

  @override
  String get serverAttributeEducation =>
      remote.text('serverAttributeEducation') ?? _base.serverAttributeEducation;

  @override
  String get serverAttributeCertifications =>
      remote.text('serverAttributeCertifications') ??
      _base.serverAttributeCertifications;

  @override
  String get serverAttributeJobDescription =>
      remote.text('serverAttributeJobDescription') ??
      _base.serverAttributeJobDescription;

  @override
  String get serverAttributeDraft =>
      remote.text('serverAttributeDraft') ?? _base.serverAttributeDraft;

  @override
  String get serverAttributeTemplate =>
      remote.text('serverAttributeTemplate') ?? _base.serverAttributeTemplate;

  @override
  String get serverNotifyFirstAnalysisTitle =>
      remote.text('serverNotifyFirstAnalysisTitle') ??
      _base.serverNotifyFirstAnalysisTitle;

  @override
  String get serverNotifyFirstAnalysisBody =>
      remote.text('serverNotifyFirstAnalysisBody') ??
      _base.serverNotifyFirstAnalysisBody;

  @override
  String get serverNotifyLowScoreTitle =>
      remote.text('serverNotifyLowScoreTitle') ??
      _base.serverNotifyLowScoreTitle;

  @override
  String serverNotifyLowScoreBodyScoreTip(String score, String tip) =>
      remote.format(
        'serverNotifyLowScoreBodyScoreTip',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'score': score, 'tip': tip},
        ),
      ) ??
      _base.serverNotifyLowScoreBodyScoreTip(score, tip);

  @override
  String serverNotifyLowScoreBodyTip(String tip) =>
      remote.format(
        'serverNotifyLowScoreBodyTip',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'tip': tip},
        ),
      ) ??
      _base.serverNotifyLowScoreBodyTip(tip);

  @override
  String serverNotifyLowScoreBodyScore(String score) =>
      remote.format(
        'serverNotifyLowScoreBodyScore',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'score': score},
        ),
      ) ??
      _base.serverNotifyLowScoreBodyScore(score);

  @override
  String get serverNotifyLowScoreBody =>
      remote.text('serverNotifyLowScoreBody') ?? _base.serverNotifyLowScoreBody;

  @override
  String get serverNotifyAnalysisToCvTitle =>
      remote.text('serverNotifyAnalysisToCvTitle') ??
      _base.serverNotifyAnalysisToCvTitle;

  @override
  String get serverNotifyAnalysisToCvBody =>
      remote.text('serverNotifyAnalysisToCvBody') ??
      _base.serverNotifyAnalysisToCvBody;

  @override
  String get serverNotifyStaleCvTitle =>
      remote.text('serverNotifyStaleCvTitle') ?? _base.serverNotifyStaleCvTitle;

  @override
  String get serverNotifyStaleCvBody =>
      remote.text('serverNotifyStaleCvBody') ?? _base.serverNotifyStaleCvBody;

  @override
  String get serverNotifyMatchingJobTitle =>
      remote.text('serverNotifyMatchingJobTitle') ??
      _base.serverNotifyMatchingJobTitle;

  @override
  String serverNotifyMatchingJobBodyTitleCompany(
          String jobTitle, String company) =>
      remote.format(
        'serverNotifyMatchingJobBodyTitleCompany',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'jobTitle': jobTitle, 'company': company},
        ),
      ) ??
      _base.serverNotifyMatchingJobBodyTitleCompany(jobTitle, company);

  @override
  String serverNotifyMatchingJobBodyTitle(String jobTitle) =>
      remote.format(
        'serverNotifyMatchingJobBodyTitle',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'jobTitle': jobTitle},
        ),
      ) ??
      _base.serverNotifyMatchingJobBodyTitle(jobTitle);

  @override
  String get serverNotifyMatchingJobBody =>
      remote.text('serverNotifyMatchingJobBody') ??
      _base.serverNotifyMatchingJobBody;

  @override
  String get serverNotifyEducationTitle =>
      remote.text('serverNotifyEducationTitle') ??
      _base.serverNotifyEducationTitle;

  @override
  String serverNotifyEducationBodyTitle(String title) =>
      remote.format(
        'serverNotifyEducationBodyTitle',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'title': title},
        ),
      ) ??
      _base.serverNotifyEducationBodyTitle(title);

  @override
  String get serverNotifyEducationBody =>
      remote.text('serverNotifyEducationBody') ??
      _base.serverNotifyEducationBody;

  @override
  String get serverNotifyTipTitle =>
      remote.text('serverNotifyTipTitle') ?? _base.serverNotifyTipTitle;

  @override
  String get serverNotifyTipBody =>
      remote.text('serverNotifyTipBody') ?? _base.serverNotifyTipBody;

  @override
  String get serverNotifyCvReadyTitle =>
      remote.text('serverNotifyCvReadyTitle') ?? _base.serverNotifyCvReadyTitle;

  @override
  String get serverNotifyCvReadyBody =>
      remote.text('serverNotifyCvReadyBody') ?? _base.serverNotifyCvReadyBody;

  @override
  String get serverNotifyCvFailedTitle =>
      remote.text('serverNotifyCvFailedTitle') ??
      _base.serverNotifyCvFailedTitle;

  @override
  String get serverNotifyCvFailedBody =>
      remote.text('serverNotifyCvFailedBody') ?? _base.serverNotifyCvFailedBody;

  @override
  String get serverNotifyNewJobTitle =>
      remote.text('serverNotifyNewJobTitle') ?? _base.serverNotifyNewJobTitle;

  @override
  String serverNotifyNewJobBody(String jobTitle) =>
      remote.format(
        'serverNotifyNewJobBody',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'jobTitle': jobTitle},
        ),
      ) ??
      _base.serverNotifyNewJobBody(jobTitle);

  @override
  String serverNotifyNewJobBodyCompany(String jobTitle, String company) =>
      remote.format(
        'serverNotifyNewJobBodyCompany',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'jobTitle': jobTitle, 'company': company},
        ),
      ) ??
      _base.serverNotifyNewJobBodyCompany(jobTitle, company);

  @override
  String serverNotifyNewJobBodyLocation(String jobTitle, String location) =>
      remote.format(
        'serverNotifyNewJobBodyLocation',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'jobTitle': jobTitle, 'location': location},
        ),
      ) ??
      _base.serverNotifyNewJobBodyLocation(jobTitle, location);

  @override
  String serverNotifyNewJobBodyLocationCompany(
          String jobTitle, String location, String company) =>
      remote.format(
        'serverNotifyNewJobBodyLocationCompany',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {
            'jobTitle': jobTitle,
            'location': location,
            'company': company
          },
        ),
      ) ??
      _base.serverNotifyNewJobBodyLocationCompany(jobTitle, location, company);

  @override
  String get serverAnalysisNotResume =>
      remote.text('serverAnalysisNotResume') ?? _base.serverAnalysisNotResume;

  @override
  String get serverPlanFreeTitle =>
      remote.text('serverPlanFreeTitle') ?? _base.serverPlanFreeTitle;

  @override
  String get serverPlanFreeIncludesJobs =>
      remote.text('serverPlanFreeIncludesJobs') ??
      _base.serverPlanFreeIncludesJobs;

  @override
  String get serverPlanFreeIncludesAts =>
      remote.text('serverPlanFreeIncludesAts') ??
      _base.serverPlanFreeIncludesAts;

  @override
  String get serverPlanFreeIncludesPreview =>
      remote.text('serverPlanFreeIncludesPreview') ??
      _base.serverPlanFreeIncludesPreview;

  @override
  String serverPlanFreeIncludesDailyLimits(int cvs, int analyses) =>
      remote.format(
        'serverPlanFreeIncludesDailyLimits',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'cvs': cvs, 'analyses': analyses},
        ),
      ) ??
      _base.serverPlanFreeIncludesDailyLimits(cvs, analyses);

  @override
  String serverPlanFreeExcludesRecommendations(int count) =>
      remote.format(
        'serverPlanFreeExcludesRecommendations',
        (icuMessage, icuLocale) => IcuLite.format(
          icuMessage,
          locale: icuLocale,
          args: {'count': count},
        ),
      ) ??
      _base.serverPlanFreeExcludesRecommendations(count);

  @override
  String get serverCvDownloadLocked =>
      remote.text('serverCvDownloadLocked') ?? _base.serverCvDownloadLocked;

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
    'cvShareSubscriptionRequired': [],
    'cvShareFailed': [],
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
    'sharedErrorNetworkSubtitle': [],
    'sharedErrorTimeoutSubtitle': [],
    'sharedErrorTitleNetwork': [],
    'sharedErrorTitleTimeout': [],
    'sharedErrorTitleAuth': [],
    'sharedErrorTitleNotFound': [],
    'sharedErrorTitleServer': [],
    'sharedErrorTitleRateLimited': [],
    'sharedErrorTitleUnknown': [],
    'sharedCreateNewCv': [],
    'sharedOk': [],
    'sharedLanguageToggleShort': [],
    'sharedPasswordStrengthEmpty': [],
    'sharedPasswordStrengthWeak': [],
    'sharedPasswordStrengthMedium': [],
    'sharedPasswordStrengthStrong': [],
    'sharedPasswordStrengthSemantics': ['String'],
    'sharedOfflineShowingSaved': [],
    'sharedOfflineTitle': [],
    'sharedOfflineBody': [],
    'sharedOfflineWaiting': [],
    'sharedOfflineChecking': [],
    'sharedOfflineTipsTitle': [],
    'sharedOfflineTipAirplane': [],
    'sharedOfflineTipSignal': [],
    'sharedOfflineOpenSaved': [],
    'sharedNoDataAvailable': [],
    'sharedSomethingWentWrong': [],
    'sharedAiImprovingWording': [],
    'sharedAiWorkingOnField': [],
    'sharedAiEnhancingField': ['String'],
    'sharedAiCharacterCount': ['int', 'int'],
    'sharedAiEnhance': [],
    'sharedAiEnhancing': [],
    'sharedAiEnhanceMinimumHint': ['int'],
    'sharedAiWhatImproved': [],
    'sharedDismiss': [],
    'sharedAiCompleteFacts': [],
    'sharedAiVerifyDetails': [],
    'sharedJobTitleSelectHint': [],
    'sharedJobTitleSheetTitle': [],
    'sharedClear': [],
    'sharedJobTitleSearchHint': [],
    'sharedJobTitleNoMatches': [],
    'sharedJobTitleEnterManually': ['String'],
    'sharedNotifications': [],
    'sharedNotificationsUnread': ['int'],
    'sharedProfile': [],
    'sharedCareerReadiness': [],
    'sharedCareerReadinessPercent': ['int'],
    'sharedAiProgressBarrier': [],
    'sharedAiStageGenerationQueued': [],
    'sharedAiStageGenerationWriting': [],
    'sharedAiStageGenerationSaving': [],
    'sharedAiStageAnalysisReading': [],
    'sharedAiStageAnalysisScoring': [],
    'sharedAiStageAnalysisPreparing': [],
    'sharedAiLongWait': [],
    'sharedAiDoneGeneration': [],
    'sharedAiDoneAnalysis': [],
    'sharedAiWorking': [],
    'sharedAiProcessingRequest': [],
    'coreGreetingWelcome': [],
    'coreGreetingHello': ['String'],
    'dashboardInputMethodFile': [],
    'dashboardInputMethodMixed': [],
    'dashboardInputMethodPaste': [],
    'dashboardSplashPreparing': [],
    'dashboardWelcomeSlogan': [],
    'dashboardWelcomeValueTitle': [],
    'dashboardWelcomePointBuild': [],
    'dashboardWelcomePointAnalyze': [],
    'dashboardWelcomePointTailor': [],
    'dashboardWelcomePointLearning': [],
    'dashboardWelcomePointJobs': [],
    'dashboardWelcomePrivacyPolicy': [],
    'dashboardNotFoundTitle': [],
    'dashboardNotFoundSubtitle': [],
    'dashboardNotFoundGoHome': [],
    'dashboardPressBackAgainToExit': [],
    'dashboardHistory': [],
    'dashboardRefresh': [],
    'dashboardHistoryGeneratedCvsTab': [],
    'dashboardHistoryLoadFailed': [],
    'dashboardHistoryAnalysesEmptySubtitle': [],
    'dashboardHistoryAnalyzeCv': [],
    'dashboardHistoryCvsEmptyTitle': [],
    'dashboardHistoryCvsEmptySubtitle': [],
    'dashboardCreateCv': [],
    'dashboardScoreBadgeSemantics': ['int', 'String'],
    'dashboardLoadMoreLoading': [],
    'dashboardLoadMoreFailed': [],
    'dashboardLoadMore': [],
    'dashboardHomeLoadFailed': [],
    'dashboardViewAll': [],
    'dashboardHeaderNotificationsUnread': ['int'],
    'dashboardNavHome': [],
    'dashboardNavMyCvs': [],
    'dashboardNavEducation': [],
    'dashboardNavJobNews': [],
    'dashboardEducationInterestThanks': [],
    'dashboardEducationTitle': [],
    'dashboardEducationSubtitle': [],
    'dashboardEducationWhatsComing': [],
    'dashboardEducationCoursesTitle': [],
    'dashboardEducationCoursesBody': [],
    'dashboardEducationInterviewTitle': [],
    'dashboardEducationInterviewBody': [],
    'dashboardEducationAtsGuidesTitle': [],
    'dashboardEducationAtsGuidesBody': [],
    'dashboardEducationComingSoonBadge': [],
    'dashboardEducationHeroTitle': [],
    'dashboardEducationHeroBody': [],
    'dashboardEducationInterestRegistered': [],
    'dashboardEducationCtaTitle': [],
    'dashboardEducationCtaBody': [],
    'dashboardEducationDetailTitle': [],
    'dashboardEducationDetailLoadFailed': [],
    'dashboardUntitled': [],
    'dashboardEducationDetailNoContent': [],
    'cvDraftAvailable': [],
    'cvDraftContinueTitle': [],
    'cvDraftStartFresh': [],
    'cvDraftRestore': [],
    'cvDiscardChangesTitle': [],
    'cvDiscardChangesBody': [],
    'cvDiscard': [],
    'cvSaveProgressTitle': [],
    'cvSaveProgressBody': [],
    'cvSaveDraft': [],
    'cvEntryRequired': [],
    'cvEntryChooseStart': [],
    'cvEntryChooseEnd': [],
    'cvEntryEndBeforeStart': [],
    'cvEntryFrom': [],
    'cvEntryTo': [],
    'cvEntryJobTitle': [],
    'cvEntryJobTitleHint': [],
    'cvEntryCompany': [],
    'cvEntryCity': [],
    'cvEntryWorkCurrent': [],
    'cvEntryDuties': [],
    'cvEntryDutiesHint': [],
    'cvEntryDegree': [],
    'cvEntryDegreeHint': [],
    'cvEntryInstitution': [],
    'cvEntryStudyCurrent': [],
    'cvEntryEducationDetails': [],
    'cvEntryCertName': [],
    'cvEntryCertIssuer': [],
    'cvEntryCertDate': [],
    'cvEntriesCompleteHighlighted': [],
    'cvEntriesAddOne': [],
    'cvEntriesMoreDetail': [],
    'cvEntryRemove': [],
    'cvMonthChoose': [],
    'cvMonthYearTitle': [],
    'cvMonthYearDone': [],
    'cvWizardUpdate': [],
    'cvWizardGenerate': [],
    'cvWizardGenerating': [],
    'cvWizardStepPersonal': [],
    'cvWizardStepSkills': [],
    'cvWizardStepExperience': [],
    'cvWizardStepEducation': [],
    'cvWizardStepOf': ['int', 'int'],
    'cvWizardReviewFields': [],
    'cvEducationStepTitle': [],
    'cvEducationLabel': [],
    'cvEducationAdd': [],
    'cvCertificationsLabel': [],
    'cvCertificationsAdd': [],
    'cvExperienceStepTitle': [],
    'cvExperienceLabel': [],
    'cvExperienceHelper': [],
    'cvExperienceXyzBuilder': [],
    'cvExperienceAdd': [],
    'cvPersonalStepTitle': [],
    'cvPersonalFullName': [],
    'cvPersonalFullNameHint': [],
    'cvPersonalFullNameRequired': [],
    'cvPersonalEmailRequired': [],
    'cvPersonalEmailInvalid': [],
    'cvPersonalPhone': [],
    'cvPersonalPhoneRequired': [],
    'cvPersonalLinkedin': [],
    'cvPersonalTargetJob': [],
    'cvPersonalTargetJobHint': [],
    'cvPersonalTargetJobRequired': [],
    'cvPersonalJobDescription': [],
    'cvPersonalCvLanguage': [],
    'cvPersonalEnhancingJobDescription': [],
    'cvPersonalJobDescriptionHint': [],
    'cvEnhance': [],
    'cvEnhancing': [],
    'cvPersonalWriteMore': [],
    'cvSkillsStepTitle': [],
    'cvSkillsCore': [],
    'cvSkillsHelper': [],
    'cvSkillsRequired': [],
    'cvSummaryLabel': [],
    'cvSummaryHelper': [],
    'cvSummaryHint': [],
    'cvDraftSaved': [],
    'cvAchievementDuplicate': [],
    'cvAchievementAdded': [],
    'cvGenerationCancelled': [],
    'cvRetryShort': [],
    'cvGenerationUnexpectedError': [],
    'cvGenerationStillRunning': [],
    'cvEnterTargetJobFirst': [],
    'cvEnhanceFieldFailed': [],
    'cvFieldEnhanced': [],
    'cvUndo': [],
    'cvJobDescriptionTooShort': [],
    'cvEnhanceJobDescriptionFailed': [],
    'cvJobDescriptionEnhanced': [],
    'cvGeneratorEditTitle': [],
    'cvGeneratorCreateTitle': [],
    'cvOpenFailed': [],
    'cvNotReadyToSend': [],
    'cvOpeningPdf': [],
    'cvPdfLinkUnavailable': [],
    'cvPdfLinkOpenFailed': [],
    'cvTemplatesLoadFailed': [],
    'cvDeleteTitle': [],
    'cvDeleteBody': [],
    'cvDeleteFailed': [],
    'cvPdfLinkNotFound': [],
    'cvPdfOpenFailed': [],
    'cvListLoadFailed': [],
    'cvListEmptyTitle': [],
    'cvListEmptyBody': [],
    'cvCreateNew': [],
    'cvUntitled': [],
    'cvCardEdit': [],
    'cvCardDownload': [],
    'cvTemplatePickerTitle': [],
    'cvTemplateDefault': [],
    'cvXyzFormula': [],
    'cvXyzPresetsTitle': [],
    'cvXyzPresetTech': [],
    'cvXyzPresetSales': [],
    'cvXyzPresetProject': [],
    'cvXyzActionLabel': [],
    'cvXyzActionHint': [],
    'cvXyzMetricLabel': [],
    'cvXyzMetricHint': [],
    'cvXyzMethodLabel': [],
    'cvXyzMethodHint': [],
    'cvXyzPreviewTitle': [],
    'cvXyzInsert': [],
    'cvSkillsSelectedCount': ['int'],
    'cvSkillsClearAll': [],
    'cvSkillsEmpty': [],
    'cvSkillsInputHint': [],
    'cvSkillsSuggested': [],
    'cvExportOptionsTitle': [],
    'cvExportLanguage': [],
    'cvExportSelectedTemplate': [],
    'cvExportFileName': [],
    'cvExportLatinFilename': [],
    'cvExportPremiumWatermark': [],
    'cvExportSubscriptionRequired': [],
    'cvExportUpgrade': [],
    'cvExportPreparing': [],
    'cvExportDownload': [],
    'cvExportSuccess': [],
    'cvExportSharePdf': [],
    'settingsOnboardingWelcomeBody': [],
    'settingsOnboardingAtsTitle': [],
    'settingsOnboardingAtsBody': [],
    'settingsOnboardingAiTitle': [],
    'settingsOnboardingAiBody': [],
    'settingsOnboardingPrevious': [],
    'settingsOnboardingSkip': [],
    'settingsOnboardingPageOf': ['int', 'int'],
    'authFieldTooLong': ['int'],
    'authPasswordTooShort': ['int'],
    'authEmailInvalid': [],
    'authPhoneInvalid': [],
    'authRegisterHeroTitle': [],
    'authRegisterHeroSubtitle': [],
    'authTermsAgreePrefix': [],
    'authTermsLink': [],
    'authHaveAccount': [],
    'authAgreeTermsRequired': [],
    'authRetry': [],
    'authRegisterUnexpectedError': [],
    'authLooksGood': [],
    'authJobTitleOtherRequired': [],
    'authFixHighlightedFields': [],
    'authFullNameLabel': [],
    'authFullNameHint': [],
    'authNameRequired': [],
    'authEmailAddressLabel': [],
    'authEmailRequired': [],
    'authPhoneLabel': [],
    'authPhoneRequired': [],
    'authLocationLabel': [],
    'authLocationHint': [],
    'authLocationRequired': [],
    'authJobTitleOptionalLabel': [],
    'authJobTitleOtherLabel': [],
    'authJobTitleOtherHint': [],
    'authPasswordLabel': [],
    'authPasswordRequired': [],
    'authCreateAccountButton': [],
    'authCreatingAccount': [],
    'authContinueWithoutAccount': [],
    'authSessionExpired': [],
    'authSessionExpiredBadge': [],
    'authSessionExpiredChip': [],
    'authSessionExpiredTitle': [],
    'authSessionExpiredBody': [],
    'authSessionExpiredDataSafe': [],
    'authSessionExpiredSignIn': [],
    'authSessionExpiredHelp': [],
    'authLoginUnexpectedError': [],
    'authSocialSignInSoon': ['String'],
    'authSocialSignInNotConfigured': ['String'],
    'authLoginSubtitle': [],
    'authForgotPasswordLink': [],
    'authSignInButton': [],
    'authSigningIn': [],
    'authOrContinueWith': [],
    'authNoAccount': [],
    'authCreateAccountLink': [],
    'authForgotEmailInvalidNotice': [],
    'authForgotSendFailed': [],
    'authForgotResetFailed': [],
    'authForgotTitle': [],
    'authForgotCodeIntro': [],
    'authForgotEmailIntro': [],
    'authForgotEmailInvalid': [],
    'authForgotSendCode': [],
    'authSending': [],
    'authVerificationCodeLabel': [],
    'authCodeRequired': [],
    'authNewPasswordLabel': [],
    'authForgotNewPasswordRequired': [],
    'authForgotConfirmPasswordLabel': [],
    'authForgotConfirmPasswordRequired': [],
    'authPasswordsDoNotMatch': [],
    'authForgotResetButton': [],
    'authSaving': [],
    'authResendCodeIn': ['int'],
    'authResendCode': [],
    'authForgotUseDifferentEmail': [],
    'authVerifySuccess': [],
    'authVerifyUnexpectedError': [],
    'authVerifyResendFailed': [],
    'authVerifyBackToSignIn': [],
    'authVerifyTitle': [],
    'authVerifyCodeSentTo': [],
    'authVerifyButton': [],
    'authVerifying': [],
    'authVerifyCheckSpam': [],
    'settingsPrivacyTitle': [],
    'settingsPrivacyCollectTitle': [],
    'settingsPrivacyCollectBody': [],
    'settingsPrivacyUseTitle': [],
    'settingsPrivacyUseBody': [],
    'settingsPrivacyProcessorsTitle': [],
    'settingsPrivacyProcessorsBody': [],
    'settingsPrivacyRetentionTitle': [],
    'settingsPrivacyRetentionBody': [],
    'settingsPrivacyContactTitle': [],
    'settingsPrivacyContactBody': ['String'],
    'settingsNotificationsUpdateFailed': [],
    'settingsNotificationsTitle': [],
    'settingsNotificationsReadAll': [],
    'settingsNotificationsLoadFailed': [],
    'settingsNotificationsEmptyTitle': [],
    'settingsNotificationsEmptyBody': [],
    'settingsNotificationsUnread': [],
    'settingsCleanupFailed': [],
    'settingsCleanupMessage': [],
    'settingsCleanupRetry': [],
    'settingsCleanupClearing': [],
    'settingsPasswordChanged': [],
    'settingsCurrentPasswordIncorrect': [],
    'settingsPasswordChangeFailed': [],
    'settingsCurrentPasswordLabel': [],
    'settingsCurrentPasswordRequired': [],
    'settingsNewPasswordRequired': [],
    'settingsNewPasswordSameAsCurrent': [],
    'settingsConfirmNewPasswordLabel': [],
    'settingsConfirmNewPasswordRequired': [],
    'settingsUpdatePassword': [],
    'settingsUpdatingPassword': [],
    'settingsDeleteConfirmTitle': [],
    'settingsDeleteConfirmBody': [],
    'settingsDeleteForever': [],
    'settingsAccountDeleted': [],
    'settingsDeletePasswordIncorrect': [],
    'settingsDeleteFailed': [],
    'settingsDeleteWarning': [],
    'settingsDeleteConfirmWithPassword': [],
    'settingsDeleteConfirmWithProvider': [],
    'settingsDeleteWithProvider': ['String'],
    'settingsDeleteProviderMismatch': ['String'],
    'settingsDeletePasswordRequired': [],
    'settingsDeleteMyAccount': [],
    'settingsDeleting': [],
    'settingsAvatarCropTitle': [],
    'settingsAvatarOpenFailed': [],
    'settingsAvatarUsePhoto': [],
    'settingsPhotoGallery': [],
    'settingsPhotoCamera': [],
    'settingsPhotoRemove': [],
    'settingsPhotoRemoved': [],
    'settingsPhotoUpdated': [],
    'settingsPhotoUpdateFailed': [],
    'settingsPhotoChange': [],
    'settingsPhotoHint': [],
    'settingsProfileUpdated': [],
    'settingsProfileUpdateFailed': [],
    'settingsProfileLoadFailed': [],
    'settingsProfileFullNameLabel': [],
    'settingsProfileNameHint': [],
    'settingsProfileNameRequired': [],
    'settingsProfileJobTitleLabel': [],
    'settingsProfileJobTitlesLoadFailed': [],
    'settingsProfileEmailReadOnly': [],
    'settingsProfilePhoneLabel': [],
    'settingsProfileSaveChanges': [],
    'settingsProfileTitle': [],
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
    'jobsEmptyFeed': [],
    'jobsLoadFailed': [],
    'jobsLatestPostings': [],
    'jobsDetailTitle': [],
    'jobsVerifiedSourceDetail': [],
    'jobsTamheerProgram': [],
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
    'atsBenchmark': ['String'],
    'atsCategoryGeneral': [],
    'atsHiddenMore': ['int'],
    'myCvsHeaderSubtitle': [],
    'myCvsToolsTitle': [],
    'myCvsToolCreateTitle': [],
    'myCvsToolCreateBody': [],
    'myCvsToolScanTitle': [],
    'myCvsToolScanBody': [],
    'myCvsToolUploadTitle': [],
    'myCvsToolUploadBody': [],
    'myCvsToolTargetTitle': [],
    'myCvsToolTargetBody': [],
    'myCvsListTitle': [],
    'myCvsEmptyBody': [],
    'myCvsEmptyCreate': [],
    'myCvsEmptyUpload': [],
    'cvCardOpen': [],
    'cvCardMore': [],
    'cvCardScore': ['int'],
    'cvCardNotScanned': [],
    'cvCardScanNow': [],
    'cvCardNeedsWork': [],
    'settingsNotificationsFilterAll': [],
    'settingsNotificationsCategoryCv': [],
    'settingsNotificationsCategoryJobs': [],
    'settingsNotificationsCategoryAnalysis': [],
    'settingsNotificationsCategoryLearning': [],
    'settingsNotificationsCategoryGeneral': [],
    'settingsNotificationsToday': [],
    'settingsNotificationsYesterday': [],
    'settingsNotificationsThisWeek': [],
    'settingsNotificationsEarlier': [],
    'settingsNotificationsNewCount': ['int'],
    'settingsNotificationsCount': ['int'],
    'settingsNotificationsViewCv': [],
    'settingsNotificationsScanCta': [],
    'settingsNotificationsFilterEmpty': [],
    'settingsNotificationsPreviewTitle': [],
    'settingsNotificationsPreviewCvTitle': [],
    'settingsNotificationsPreviewCvBody': [],
    'settingsNotificationsPreviewJobsTitle': [],
    'settingsNotificationsPreviewJobsBody': [],
    'settingsNotificationsPreviewAnalysisTitle': [],
    'settingsNotificationsPreviewAnalysisBody': [],
    'settingsNotificationsCreateCvCta': [],
    'authSignInRequiredTitle': [],
    'authSignInRequiredSubtitle': [],
    'authSignInRequiredCardTitle': [],
    'authSignInRequiredBody': [],
    'authSignInRequiredBrowseJobs': [],
    'jobsRegionAll': [],
    'jobsRegionCentral': [],
    'jobsRegionEastern': [],
    'jobsRegionWestern': [],
    'jobsRegionNorthern': [],
    'jobsRegionSouthern': [],
    'jobsEmptyRegionTitle': ['String'],
    'jobsEmptyRegionBody': [],
    'jobsShowAllRegions': [],
    'jobsMatchedNeedsTitle': [],
    'jobsMatchedSetTitle': [],
    'jobsMatchedBasedOn': ['String'],
    'jobsHowToApply': [],
    'jobsApplyOpensHost': ['String'],
    'jobsApplyByEmail': [],
    'jobsApplyEmailHint': [],
    'jobsCopyEmail': [],
    'jobsEmailCopied': [],
    'jobsOpenEmailFailed': [],
    'jobsNoDirectApply': [],
    'jobsNoDirectApplyHint': [],
    'jobsApplyMethodLink': [],
    'jobsApplyMethodEmail': [],
    'jobsSourceName': ['String'],
    'jobsViewSourcePost': [],
    'jobsShare': [],
    'jobsRemoteChip': [],
    'homeProfileSubtitle': [],
    'homeProfileOpen': [],
    'homeStartCreateTitle': [],
    'homeStartCreateBody': [],
    'homeStartAtsTitle': [],
    'homeStartAtsBody': [],
    'homeServiceUpload': [],
    'homeServiceTarget': [],
    'homeServiceEducation': [],
    'homeSoon': [],
    'homeServiceSoonA11y': ['String'],
    'homeMyCvTitle': [],
    'homeMyCvEdited': ['String'],
    'homeMyCvEdit': [],
    'homeMyCvCheck': [],
    'homeMyCvEmptyTitle': [],
    'homeMyCvEmptyBody': [],
    'homeHonesty': [],
    'authEmailHint': [],
    'authPhoneHint': [],
    'cvPersonalEmailHint': [],
    'cvPersonalPhoneHint': [],
    'cvPersonalLinkedinHint': [],
    'authSocialGoogle': [],
    'authSocialApple': [],
    'authRegisterEmailHint': [],
    'timeJustNow': [],
    'timeMinutesAgo': ['int'],
    'timeHoursAgo': ['int'],
    'timeYesterday': [],
    'savedJustNow': [],
    'savedAgo': ['String'],
    'untitledTitle': [],
    'aiErrorTooLong': [],
    'aiErrorTryAgain': [],
    'aiGenerationFailed': ['String'],
    'aiSuggestionsFailed': ['String'],
    'aiLocalFallback': ['String'],
    'jobNewsTitle': [],
    'crashMessage': [],
    'avatarFallbackInitial': [],
    'coreApiErrorBadResponse': [],
    'coreApiErrorEmptyResponse': [],
    'coreApiErrorUnexpected': [],
    'coreApiErrorRequestFailed': [],
    'coreApiErrorStatus': ['int'],
    'authVerifyCodeResent': [],
    'authForgotCodeSent': [],
    'authForgotPasswordReset': [],
    'serverDashboardStatusActive': [],
    'serverDashboardCreateCvTitle': [],
    'serverDashboardCreateCvSubtitle': [],
    'serverDashboardCreateCvButton': [],
    'serverDashboardAnalyzeTitle': [],
    'serverDashboardAnalyzeSubtitle': [],
    'serverDashboardAnalyzeButton': [],
    'serverMyCvsTitle': [],
    'serverMyCvsSummary': ['int'],
    'serverMyCvsUpdated': ['String'],
    'serverMyCvsUpdatedUnknown': [],
    'serverMyCvsTailoredTitle': ['String'],
    'serverCvTemplatesTitle': [],
    'serverCvTemplatesSubtitle': [],
    'serverEducationTitle': [],
    'serverEducationSubtitle': [],
    'serverEducationTargetLabel': [],
    'serverEducationTabNews': [],
    'serverEducationTabCertificates': [],
    'serverEducationTabStudy': [],
    'serverEducationStartLearning': [],
    'serverJobsTitle': [],
    'serverJobsSubtitle': [],
    'serverJobsApplyBy': ['String'],
    'serverJobsSourceGovLabel': [],
    'serverJobsSourceGovBadge': [],
    'serverJobsSourceCompanyLabel': [],
    'serverJobsSourceCompanyBadge': [],
    'serverJobsSourceTamheerLabel': [],
    'serverJobsSourceTamheerBadge': [],
    'serverJobsSourceStartupLabel': [],
    'serverJobsSourceStartupBadge': [],
    'serverJobsSalaryRange': ['String', 'String', 'String'],
    'serverJobsSalaryFrom': ['String', 'String'],
    'serverJobsSalaryUpTo': ['String', 'String'],
    'serverJobsCurrencySar': [],
    'serverNotificationsAllRead': [],
    'serverNotificationsPreferencesUpdated': [],
    'serverNotificationsOpenRecorded': [],
    'serverNotificationsActivityRecorded': [],
    'serverNotificationsConversionRecorded': [],
    'serverNotificationsTokenRegistered': [],
    'serverNotificationsTokenRemoved': [],
    'serverAuthInvalidCredentials': [],
    'serverAuthEmailVerified': [],
    'serverAuthEmailAlreadyVerified': [],
    'serverAuthVerificationCodeSent': [],
    'serverAuthResetCodeSent': [],
    'serverAuthInvalidCode': [],
    'serverAuthPasswordReset': [],
    'serverAuthLoggedOut': [],
    'serverAuthCurrentPasswordWrong': [],
    'serverAuthPasswordChanged': [],
    'serverAuthAvatarSaveFailed': [],
    'serverAuthPasswordWrong': [],
    'serverAuthSocialAccountMismatch': [],
    'serverAuthAccountDeleted': [],
    'serverAuthJobTitleOtherRequired': [],
    'serverAuthVerificationResendWait': [],
    'serverAuthResetResendWait': [],
    'serverAuthEmailNotVerified': [],
    'serverAuthSocialUnavailable': ['String'],
    'serverAuthSocialInvalidToken': ['String'],
    'serverAuthSocialEmailUnverified': ['String'],
    'serverCvDeleted': [],
    'serverCvTemplateUnavailable': [],
    'serverCvTemplatePremiumOnly': [],
    'serverCvEnhanceUnavailable': [],
    'serverCvEnhanceFailed': [],
    'serverCvExportGenerating': [],
    'serverCvExportMissingContact': [],
    'serverCvExportUnstructuredExperience': [],
    'serverCvTemplateHidesSections': ['String'],
    'serverCvTemplateSectionListSeparator': [],
    'serverCvSectionSummary': [],
    'serverCvSectionSkills': [],
    'serverCvSectionExperience': [],
    'serverCvSectionEducation': [],
    'serverCvSectionCertifications': [],
    'serverCvSectionProjects': [],
    'serverCvSectionLanguages': [],
    'serverCvSectionCustom': [],
    'serverCvFileTypeUnsupported': [],
    'serverCvTextTooShort': ['int'],
    'serverCvPdfUnreadable': [],
    'serverAnalysisResumeRequired': [],
    'serverAnalysisLockedTitle': [],
    'serverAnalysisLockedMessage': ['int'],
    'serverAnalysisLockedCta': [],
    'serverPaywallTitle': [],
    'serverPaywallCta': [],
    'serverPaywallJobMatch': [],
    'serverPaywallDownload': [],
    'serverPaywallEnhance': [],
    'serverPaywallDailyCvLimit': ['int'],
    'serverPaywallDailyAnalysisLimit': ['int'],
    'serverPaywallBenefitPdf': [],
    'serverPaywallBenefitEnhance': [],
    'serverPaywallBenefitAnalysis': [],
    'serverPaywallBenefitUnlimited': [],
    'serverJobMatchDailyLimit': [],
    'serverPlanMonthlyName': [],
    'serverPlanSixMonthsName': [],
    'serverPlanSixMonthsBadge': [],
    'serverPlanAnnualName': [],
    'serverErrorUnauthenticated': [],
    'serverErrorForbidden': [],
    'serverErrorNotFound': [],
    'serverErrorMethodNotAllowed': [],
    'serverErrorTooManyRequests': [],
    'serverErrorServer': [],
    'serverErrorUnavailable': [],
    'serverErrorRequestFailed': [],
    'serverValidationRequired': ['String'],
    'serverValidationString': ['String'],
    'serverValidationEmail': [],
    'serverValidationFile': ['String'],
    'serverValidationImage': ['String'],
    'serverValidationMimes': ['String', 'String'],
    'serverValidationMaxString': ['String', 'String'],
    'serverValidationMaxFile': ['String', 'String'],
    'serverValidationMaxNumeric': ['String', 'String'],
    'serverValidationMaxArray': ['String', 'String'],
    'serverValidationMinString': ['String', 'String'],
    'serverValidationMinFile': ['String', 'String'],
    'serverValidationMinNumeric': ['String', 'String'],
    'serverValidationMinArray': ['String', 'String'],
    'serverValidationBetweenNumeric': ['String', 'String', 'String'],
    'serverValidationBetweenString': ['String', 'String', 'String'],
    'serverValidationSizeString': ['String', 'String'],
    'serverValidationIn': ['String'],
    'serverValidationInteger': ['String'],
    'serverValidationNumeric': ['String'],
    'serverValidationBoolean': ['String'],
    'serverValidationArray': ['String'],
    'serverValidationRegex': ['String'],
    'serverValidationUrl': ['String'],
    'serverValidationDate': ['String'],
    'serverValidationExists': ['String'],
    'serverValidationUnique': ['String'],
    'serverValidationConfirmed': ['String'],
    'serverValidationRequiredIf': ['String'],
    'serverValidationAccepted': ['String'],
    'serverValidationAlphaDash': ['String'],
    'serverValidationMoreErrors': ['String', 'int'],
    'serverAttributeName': [],
    'serverAttributeFullName': [],
    'serverAttributeEmail': [],
    'serverAttributePassword': [],
    'serverAttributeCurrentPassword': [],
    'serverAttributeCode': [],
    'serverAttributePhone': [],
    'serverAttributeLocation': [],
    'serverAttributeJobTitle': [],
    'serverAttributeJobTitleOther': [],
    'serverAttributeAvatar': [],
    'serverAttributeRoleInterest': [],
    'serverAttributeTargetJobTitle': [],
    'serverAttributeNotes': [],
    'serverAttributeResumeText': [],
    'serverAttributeResumeFile': [],
    'serverAttributeLinkedin': [],
    'serverAttributeLanguage': [],
    'serverAttributeSummary': [],
    'serverAttributeSkills': [],
    'serverAttributeExperience': [],
    'serverAttributeEducation': [],
    'serverAttributeCertifications': [],
    'serverAttributeJobDescription': [],
    'serverAttributeDraft': [],
    'serverAttributeTemplate': [],
    'serverNotifyFirstAnalysisTitle': [],
    'serverNotifyFirstAnalysisBody': [],
    'serverNotifyLowScoreTitle': [],
    'serverNotifyLowScoreBodyScoreTip': ['String', 'String'],
    'serverNotifyLowScoreBodyTip': ['String'],
    'serverNotifyLowScoreBodyScore': ['String'],
    'serverNotifyLowScoreBody': [],
    'serverNotifyAnalysisToCvTitle': [],
    'serverNotifyAnalysisToCvBody': [],
    'serverNotifyStaleCvTitle': [],
    'serverNotifyStaleCvBody': [],
    'serverNotifyMatchingJobTitle': [],
    'serverNotifyMatchingJobBodyTitleCompany': ['String', 'String'],
    'serverNotifyMatchingJobBodyTitle': ['String'],
    'serverNotifyMatchingJobBody': [],
    'serverNotifyEducationTitle': [],
    'serverNotifyEducationBodyTitle': ['String'],
    'serverNotifyEducationBody': [],
    'serverNotifyTipTitle': [],
    'serverNotifyTipBody': [],
    'serverNotifyCvReadyTitle': [],
    'serverNotifyCvReadyBody': [],
    'serverNotifyCvFailedTitle': [],
    'serverNotifyCvFailedBody': [],
    'serverNotifyNewJobTitle': [],
    'serverNotifyNewJobBody': ['String'],
    'serverNotifyNewJobBodyCompany': ['String', 'String'],
    'serverNotifyNewJobBodyLocation': ['String', 'String'],
    'serverNotifyNewJobBodyLocationCompany': ['String', 'String', 'String'],
    'serverAnalysisNotResume': [],
    'serverPlanFreeTitle': [],
    'serverPlanFreeIncludesJobs': [],
    'serverPlanFreeIncludesAts': [],
    'serverPlanFreeIncludesPreview': [],
    'serverPlanFreeIncludesDailyLimits': ['int', 'int'],
    'serverPlanFreeExcludesRecommendations': ['int'],
    'serverCvDownloadLocked': [],
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
        'cvShareSubscriptionRequired' => l.cvShareSubscriptionRequired,
        'cvShareFailed' => l.cvShareFailed,
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
        'sharedErrorNetworkSubtitle' => l.sharedErrorNetworkSubtitle,
        'sharedErrorTimeoutSubtitle' => l.sharedErrorTimeoutSubtitle,
        'sharedErrorTitleNetwork' => l.sharedErrorTitleNetwork,
        'sharedErrorTitleTimeout' => l.sharedErrorTitleTimeout,
        'sharedErrorTitleAuth' => l.sharedErrorTitleAuth,
        'sharedErrorTitleNotFound' => l.sharedErrorTitleNotFound,
        'sharedErrorTitleServer' => l.sharedErrorTitleServer,
        'sharedErrorTitleRateLimited' => l.sharedErrorTitleRateLimited,
        'sharedErrorTitleUnknown' => l.sharedErrorTitleUnknown,
        'sharedCreateNewCv' => l.sharedCreateNewCv,
        'sharedOk' => l.sharedOk,
        'sharedLanguageToggleShort' => l.sharedLanguageToggleShort,
        'sharedPasswordStrengthEmpty' => l.sharedPasswordStrengthEmpty,
        'sharedPasswordStrengthWeak' => l.sharedPasswordStrengthWeak,
        'sharedPasswordStrengthMedium' => l.sharedPasswordStrengthMedium,
        'sharedPasswordStrengthStrong' => l.sharedPasswordStrengthStrong,
        'sharedPasswordStrengthSemantics' =>
          l.sharedPasswordStrengthSemantics(a[0] as String),
        'sharedOfflineShowingSaved' => l.sharedOfflineShowingSaved,
        'sharedOfflineTitle' => l.sharedOfflineTitle,
        'sharedOfflineBody' => l.sharedOfflineBody,
        'sharedOfflineWaiting' => l.sharedOfflineWaiting,
        'sharedOfflineChecking' => l.sharedOfflineChecking,
        'sharedOfflineTipsTitle' => l.sharedOfflineTipsTitle,
        'sharedOfflineTipAirplane' => l.sharedOfflineTipAirplane,
        'sharedOfflineTipSignal' => l.sharedOfflineTipSignal,
        'sharedOfflineOpenSaved' => l.sharedOfflineOpenSaved,
        'sharedNoDataAvailable' => l.sharedNoDataAvailable,
        'sharedSomethingWentWrong' => l.sharedSomethingWentWrong,
        'sharedAiImprovingWording' => l.sharedAiImprovingWording,
        'sharedAiWorkingOnField' => l.sharedAiWorkingOnField,
        'sharedAiEnhancingField' => l.sharedAiEnhancingField(a[0] as String),
        'sharedAiCharacterCount' =>
          l.sharedAiCharacterCount(a[0] as int, a[1] as int),
        'sharedAiEnhance' => l.sharedAiEnhance,
        'sharedAiEnhancing' => l.sharedAiEnhancing,
        'sharedAiEnhanceMinimumHint' =>
          l.sharedAiEnhanceMinimumHint(a[0] as int),
        'sharedAiWhatImproved' => l.sharedAiWhatImproved,
        'sharedDismiss' => l.sharedDismiss,
        'sharedAiCompleteFacts' => l.sharedAiCompleteFacts,
        'sharedAiVerifyDetails' => l.sharedAiVerifyDetails,
        'sharedJobTitleSelectHint' => l.sharedJobTitleSelectHint,
        'sharedJobTitleSheetTitle' => l.sharedJobTitleSheetTitle,
        'sharedClear' => l.sharedClear,
        'sharedJobTitleSearchHint' => l.sharedJobTitleSearchHint,
        'sharedJobTitleNoMatches' => l.sharedJobTitleNoMatches,
        'sharedJobTitleEnterManually' =>
          l.sharedJobTitleEnterManually(a[0] as String),
        'sharedNotifications' => l.sharedNotifications,
        'sharedNotificationsUnread' => l.sharedNotificationsUnread(a[0] as int),
        'sharedProfile' => l.sharedProfile,
        'sharedCareerReadiness' => l.sharedCareerReadiness,
        'sharedCareerReadinessPercent' =>
          l.sharedCareerReadinessPercent(a[0] as int),
        'sharedAiProgressBarrier' => l.sharedAiProgressBarrier,
        'sharedAiStageGenerationQueued' => l.sharedAiStageGenerationQueued,
        'sharedAiStageGenerationWriting' => l.sharedAiStageGenerationWriting,
        'sharedAiStageGenerationSaving' => l.sharedAiStageGenerationSaving,
        'sharedAiStageAnalysisReading' => l.sharedAiStageAnalysisReading,
        'sharedAiStageAnalysisScoring' => l.sharedAiStageAnalysisScoring,
        'sharedAiStageAnalysisPreparing' => l.sharedAiStageAnalysisPreparing,
        'sharedAiLongWait' => l.sharedAiLongWait,
        'sharedAiDoneGeneration' => l.sharedAiDoneGeneration,
        'sharedAiDoneAnalysis' => l.sharedAiDoneAnalysis,
        'sharedAiWorking' => l.sharedAiWorking,
        'sharedAiProcessingRequest' => l.sharedAiProcessingRequest,
        'coreGreetingWelcome' => l.coreGreetingWelcome,
        'coreGreetingHello' => l.coreGreetingHello(a[0] as String),
        'dashboardInputMethodFile' => l.dashboardInputMethodFile,
        'dashboardInputMethodMixed' => l.dashboardInputMethodMixed,
        'dashboardInputMethodPaste' => l.dashboardInputMethodPaste,
        'dashboardSplashPreparing' => l.dashboardSplashPreparing,
        'dashboardWelcomeSlogan' => l.dashboardWelcomeSlogan,
        'dashboardWelcomeValueTitle' => l.dashboardWelcomeValueTitle,
        'dashboardWelcomePointBuild' => l.dashboardWelcomePointBuild,
        'dashboardWelcomePointAnalyze' => l.dashboardWelcomePointAnalyze,
        'dashboardWelcomePointTailor' => l.dashboardWelcomePointTailor,
        'dashboardWelcomePointLearning' => l.dashboardWelcomePointLearning,
        'dashboardWelcomePointJobs' => l.dashboardWelcomePointJobs,
        'dashboardWelcomePrivacyPolicy' => l.dashboardWelcomePrivacyPolicy,
        'dashboardNotFoundTitle' => l.dashboardNotFoundTitle,
        'dashboardNotFoundSubtitle' => l.dashboardNotFoundSubtitle,
        'dashboardNotFoundGoHome' => l.dashboardNotFoundGoHome,
        'dashboardPressBackAgainToExit' => l.dashboardPressBackAgainToExit,
        'dashboardHistory' => l.dashboardHistory,
        'dashboardRefresh' => l.dashboardRefresh,
        'dashboardHistoryGeneratedCvsTab' => l.dashboardHistoryGeneratedCvsTab,
        'dashboardHistoryLoadFailed' => l.dashboardHistoryLoadFailed,
        'dashboardHistoryAnalysesEmptySubtitle' =>
          l.dashboardHistoryAnalysesEmptySubtitle,
        'dashboardHistoryAnalyzeCv' => l.dashboardHistoryAnalyzeCv,
        'dashboardHistoryCvsEmptyTitle' => l.dashboardHistoryCvsEmptyTitle,
        'dashboardHistoryCvsEmptySubtitle' =>
          l.dashboardHistoryCvsEmptySubtitle,
        'dashboardCreateCv' => l.dashboardCreateCv,
        'dashboardScoreBadgeSemantics' =>
          l.dashboardScoreBadgeSemantics(a[0] as int, a[1] as String),
        'dashboardLoadMoreLoading' => l.dashboardLoadMoreLoading,
        'dashboardLoadMoreFailed' => l.dashboardLoadMoreFailed,
        'dashboardLoadMore' => l.dashboardLoadMore,
        'dashboardHomeLoadFailed' => l.dashboardHomeLoadFailed,
        'dashboardViewAll' => l.dashboardViewAll,
        'dashboardHeaderNotificationsUnread' =>
          l.dashboardHeaderNotificationsUnread(a[0] as int),
        'dashboardNavHome' => l.dashboardNavHome,
        'dashboardNavMyCvs' => l.dashboardNavMyCvs,
        'dashboardNavEducation' => l.dashboardNavEducation,
        'dashboardNavJobNews' => l.dashboardNavJobNews,
        'dashboardEducationInterestThanks' =>
          l.dashboardEducationInterestThanks,
        'dashboardEducationTitle' => l.dashboardEducationTitle,
        'dashboardEducationSubtitle' => l.dashboardEducationSubtitle,
        'dashboardEducationWhatsComing' => l.dashboardEducationWhatsComing,
        'dashboardEducationCoursesTitle' => l.dashboardEducationCoursesTitle,
        'dashboardEducationCoursesBody' => l.dashboardEducationCoursesBody,
        'dashboardEducationInterviewTitle' =>
          l.dashboardEducationInterviewTitle,
        'dashboardEducationInterviewBody' => l.dashboardEducationInterviewBody,
        'dashboardEducationAtsGuidesTitle' =>
          l.dashboardEducationAtsGuidesTitle,
        'dashboardEducationAtsGuidesBody' => l.dashboardEducationAtsGuidesBody,
        'dashboardEducationComingSoonBadge' =>
          l.dashboardEducationComingSoonBadge,
        'dashboardEducationHeroTitle' => l.dashboardEducationHeroTitle,
        'dashboardEducationHeroBody' => l.dashboardEducationHeroBody,
        'dashboardEducationInterestRegistered' =>
          l.dashboardEducationInterestRegistered,
        'dashboardEducationCtaTitle' => l.dashboardEducationCtaTitle,
        'dashboardEducationCtaBody' => l.dashboardEducationCtaBody,
        'dashboardEducationDetailTitle' => l.dashboardEducationDetailTitle,
        'dashboardEducationDetailLoadFailed' =>
          l.dashboardEducationDetailLoadFailed,
        'dashboardUntitled' => l.dashboardUntitled,
        'dashboardEducationDetailNoContent' =>
          l.dashboardEducationDetailNoContent,
        'cvDraftAvailable' => l.cvDraftAvailable,
        'cvDraftContinueTitle' => l.cvDraftContinueTitle,
        'cvDraftStartFresh' => l.cvDraftStartFresh,
        'cvDraftRestore' => l.cvDraftRestore,
        'cvDiscardChangesTitle' => l.cvDiscardChangesTitle,
        'cvDiscardChangesBody' => l.cvDiscardChangesBody,
        'cvDiscard' => l.cvDiscard,
        'cvSaveProgressTitle' => l.cvSaveProgressTitle,
        'cvSaveProgressBody' => l.cvSaveProgressBody,
        'cvSaveDraft' => l.cvSaveDraft,
        'cvEntryRequired' => l.cvEntryRequired,
        'cvEntryChooseStart' => l.cvEntryChooseStart,
        'cvEntryChooseEnd' => l.cvEntryChooseEnd,
        'cvEntryEndBeforeStart' => l.cvEntryEndBeforeStart,
        'cvEntryFrom' => l.cvEntryFrom,
        'cvEntryTo' => l.cvEntryTo,
        'cvEntryJobTitle' => l.cvEntryJobTitle,
        'cvEntryJobTitleHint' => l.cvEntryJobTitleHint,
        'cvEntryCompany' => l.cvEntryCompany,
        'cvEntryCity' => l.cvEntryCity,
        'cvEntryWorkCurrent' => l.cvEntryWorkCurrent,
        'cvEntryDuties' => l.cvEntryDuties,
        'cvEntryDutiesHint' => l.cvEntryDutiesHint,
        'cvEntryDegree' => l.cvEntryDegree,
        'cvEntryDegreeHint' => l.cvEntryDegreeHint,
        'cvEntryInstitution' => l.cvEntryInstitution,
        'cvEntryStudyCurrent' => l.cvEntryStudyCurrent,
        'cvEntryEducationDetails' => l.cvEntryEducationDetails,
        'cvEntryCertName' => l.cvEntryCertName,
        'cvEntryCertIssuer' => l.cvEntryCertIssuer,
        'cvEntryCertDate' => l.cvEntryCertDate,
        'cvEntriesCompleteHighlighted' => l.cvEntriesCompleteHighlighted,
        'cvEntriesAddOne' => l.cvEntriesAddOne,
        'cvEntriesMoreDetail' => l.cvEntriesMoreDetail,
        'cvEntryRemove' => l.cvEntryRemove,
        'cvMonthChoose' => l.cvMonthChoose,
        'cvMonthYearTitle' => l.cvMonthYearTitle,
        'cvMonthYearDone' => l.cvMonthYearDone,
        'cvWizardUpdate' => l.cvWizardUpdate,
        'cvWizardGenerate' => l.cvWizardGenerate,
        'cvWizardGenerating' => l.cvWizardGenerating,
        'cvWizardStepPersonal' => l.cvWizardStepPersonal,
        'cvWizardStepSkills' => l.cvWizardStepSkills,
        'cvWizardStepExperience' => l.cvWizardStepExperience,
        'cvWizardStepEducation' => l.cvWizardStepEducation,
        'cvWizardStepOf' => l.cvWizardStepOf(a[0] as int, a[1] as int),
        'cvWizardReviewFields' => l.cvWizardReviewFields,
        'cvEducationStepTitle' => l.cvEducationStepTitle,
        'cvEducationLabel' => l.cvEducationLabel,
        'cvEducationAdd' => l.cvEducationAdd,
        'cvCertificationsLabel' => l.cvCertificationsLabel,
        'cvCertificationsAdd' => l.cvCertificationsAdd,
        'cvExperienceStepTitle' => l.cvExperienceStepTitle,
        'cvExperienceLabel' => l.cvExperienceLabel,
        'cvExperienceHelper' => l.cvExperienceHelper,
        'cvExperienceXyzBuilder' => l.cvExperienceXyzBuilder,
        'cvExperienceAdd' => l.cvExperienceAdd,
        'cvPersonalStepTitle' => l.cvPersonalStepTitle,
        'cvPersonalFullName' => l.cvPersonalFullName,
        'cvPersonalFullNameHint' => l.cvPersonalFullNameHint,
        'cvPersonalFullNameRequired' => l.cvPersonalFullNameRequired,
        'cvPersonalEmailRequired' => l.cvPersonalEmailRequired,
        'cvPersonalEmailInvalid' => l.cvPersonalEmailInvalid,
        'cvPersonalPhone' => l.cvPersonalPhone,
        'cvPersonalPhoneRequired' => l.cvPersonalPhoneRequired,
        'cvPersonalLinkedin' => l.cvPersonalLinkedin,
        'cvPersonalTargetJob' => l.cvPersonalTargetJob,
        'cvPersonalTargetJobHint' => l.cvPersonalTargetJobHint,
        'cvPersonalTargetJobRequired' => l.cvPersonalTargetJobRequired,
        'cvPersonalJobDescription' => l.cvPersonalJobDescription,
        'cvPersonalCvLanguage' => l.cvPersonalCvLanguage,
        'cvPersonalEnhancingJobDescription' =>
          l.cvPersonalEnhancingJobDescription,
        'cvPersonalJobDescriptionHint' => l.cvPersonalJobDescriptionHint,
        'cvEnhance' => l.cvEnhance,
        'cvEnhancing' => l.cvEnhancing,
        'cvPersonalWriteMore' => l.cvPersonalWriteMore,
        'cvSkillsStepTitle' => l.cvSkillsStepTitle,
        'cvSkillsCore' => l.cvSkillsCore,
        'cvSkillsHelper' => l.cvSkillsHelper,
        'cvSkillsRequired' => l.cvSkillsRequired,
        'cvSummaryLabel' => l.cvSummaryLabel,
        'cvSummaryHelper' => l.cvSummaryHelper,
        'cvSummaryHint' => l.cvSummaryHint,
        'cvDraftSaved' => l.cvDraftSaved,
        'cvAchievementDuplicate' => l.cvAchievementDuplicate,
        'cvAchievementAdded' => l.cvAchievementAdded,
        'cvGenerationCancelled' => l.cvGenerationCancelled,
        'cvRetryShort' => l.cvRetryShort,
        'cvGenerationUnexpectedError' => l.cvGenerationUnexpectedError,
        'cvGenerationStillRunning' => l.cvGenerationStillRunning,
        'cvEnterTargetJobFirst' => l.cvEnterTargetJobFirst,
        'cvEnhanceFieldFailed' => l.cvEnhanceFieldFailed,
        'cvFieldEnhanced' => l.cvFieldEnhanced,
        'cvUndo' => l.cvUndo,
        'cvJobDescriptionTooShort' => l.cvJobDescriptionTooShort,
        'cvEnhanceJobDescriptionFailed' => l.cvEnhanceJobDescriptionFailed,
        'cvJobDescriptionEnhanced' => l.cvJobDescriptionEnhanced,
        'cvGeneratorEditTitle' => l.cvGeneratorEditTitle,
        'cvGeneratorCreateTitle' => l.cvGeneratorCreateTitle,
        'cvOpenFailed' => l.cvOpenFailed,
        'cvNotReadyToSend' => l.cvNotReadyToSend,
        'cvOpeningPdf' => l.cvOpeningPdf,
        'cvPdfLinkUnavailable' => l.cvPdfLinkUnavailable,
        'cvPdfLinkOpenFailed' => l.cvPdfLinkOpenFailed,
        'cvTemplatesLoadFailed' => l.cvTemplatesLoadFailed,
        'cvDeleteTitle' => l.cvDeleteTitle,
        'cvDeleteBody' => l.cvDeleteBody,
        'cvDeleteFailed' => l.cvDeleteFailed,
        'cvPdfLinkNotFound' => l.cvPdfLinkNotFound,
        'cvPdfOpenFailed' => l.cvPdfOpenFailed,
        'cvListLoadFailed' => l.cvListLoadFailed,
        'cvListEmptyTitle' => l.cvListEmptyTitle,
        'cvListEmptyBody' => l.cvListEmptyBody,
        'cvCreateNew' => l.cvCreateNew,
        'cvUntitled' => l.cvUntitled,
        'cvCardEdit' => l.cvCardEdit,
        'cvCardDownload' => l.cvCardDownload,
        'cvTemplatePickerTitle' => l.cvTemplatePickerTitle,
        'cvTemplateDefault' => l.cvTemplateDefault,
        'cvXyzFormula' => l.cvXyzFormula,
        'cvXyzPresetsTitle' => l.cvXyzPresetsTitle,
        'cvXyzPresetTech' => l.cvXyzPresetTech,
        'cvXyzPresetSales' => l.cvXyzPresetSales,
        'cvXyzPresetProject' => l.cvXyzPresetProject,
        'cvXyzActionLabel' => l.cvXyzActionLabel,
        'cvXyzActionHint' => l.cvXyzActionHint,
        'cvXyzMetricLabel' => l.cvXyzMetricLabel,
        'cvXyzMetricHint' => l.cvXyzMetricHint,
        'cvXyzMethodLabel' => l.cvXyzMethodLabel,
        'cvXyzMethodHint' => l.cvXyzMethodHint,
        'cvXyzPreviewTitle' => l.cvXyzPreviewTitle,
        'cvXyzInsert' => l.cvXyzInsert,
        'cvSkillsSelectedCount' => l.cvSkillsSelectedCount(a[0] as int),
        'cvSkillsClearAll' => l.cvSkillsClearAll,
        'cvSkillsEmpty' => l.cvSkillsEmpty,
        'cvSkillsInputHint' => l.cvSkillsInputHint,
        'cvSkillsSuggested' => l.cvSkillsSuggested,
        'cvExportOptionsTitle' => l.cvExportOptionsTitle,
        'cvExportLanguage' => l.cvExportLanguage,
        'cvExportSelectedTemplate' => l.cvExportSelectedTemplate,
        'cvExportFileName' => l.cvExportFileName,
        'cvExportLatinFilename' => l.cvExportLatinFilename,
        'cvExportPremiumWatermark' => l.cvExportPremiumWatermark,
        'cvExportSubscriptionRequired' => l.cvExportSubscriptionRequired,
        'cvExportUpgrade' => l.cvExportUpgrade,
        'cvExportPreparing' => l.cvExportPreparing,
        'cvExportDownload' => l.cvExportDownload,
        'cvExportSuccess' => l.cvExportSuccess,
        'cvExportSharePdf' => l.cvExportSharePdf,
        'settingsOnboardingWelcomeBody' => l.settingsOnboardingWelcomeBody,
        'settingsOnboardingAtsTitle' => l.settingsOnboardingAtsTitle,
        'settingsOnboardingAtsBody' => l.settingsOnboardingAtsBody,
        'settingsOnboardingAiTitle' => l.settingsOnboardingAiTitle,
        'settingsOnboardingAiBody' => l.settingsOnboardingAiBody,
        'settingsOnboardingPrevious' => l.settingsOnboardingPrevious,
        'settingsOnboardingSkip' => l.settingsOnboardingSkip,
        'settingsOnboardingPageOf' =>
          l.settingsOnboardingPageOf(a[0] as int, a[1] as int),
        'authFieldTooLong' => l.authFieldTooLong(a[0] as int),
        'authPasswordTooShort' => l.authPasswordTooShort(a[0] as int),
        'authEmailInvalid' => l.authEmailInvalid,
        'authPhoneInvalid' => l.authPhoneInvalid,
        'authRegisterHeroTitle' => l.authRegisterHeroTitle,
        'authRegisterHeroSubtitle' => l.authRegisterHeroSubtitle,
        'authTermsAgreePrefix' => l.authTermsAgreePrefix,
        'authTermsLink' => l.authTermsLink,
        'authHaveAccount' => l.authHaveAccount,
        'authAgreeTermsRequired' => l.authAgreeTermsRequired,
        'authRetry' => l.authRetry,
        'authRegisterUnexpectedError' => l.authRegisterUnexpectedError,
        'authLooksGood' => l.authLooksGood,
        'authJobTitleOtherRequired' => l.authJobTitleOtherRequired,
        'authFixHighlightedFields' => l.authFixHighlightedFields,
        'authFullNameLabel' => l.authFullNameLabel,
        'authFullNameHint' => l.authFullNameHint,
        'authNameRequired' => l.authNameRequired,
        'authEmailAddressLabel' => l.authEmailAddressLabel,
        'authEmailRequired' => l.authEmailRequired,
        'authPhoneLabel' => l.authPhoneLabel,
        'authPhoneRequired' => l.authPhoneRequired,
        'authLocationLabel' => l.authLocationLabel,
        'authLocationHint' => l.authLocationHint,
        'authLocationRequired' => l.authLocationRequired,
        'authJobTitleOptionalLabel' => l.authJobTitleOptionalLabel,
        'authJobTitleOtherLabel' => l.authJobTitleOtherLabel,
        'authJobTitleOtherHint' => l.authJobTitleOtherHint,
        'authPasswordLabel' => l.authPasswordLabel,
        'authPasswordRequired' => l.authPasswordRequired,
        'authCreateAccountButton' => l.authCreateAccountButton,
        'authCreatingAccount' => l.authCreatingAccount,
        'authContinueWithoutAccount' => l.authContinueWithoutAccount,
        'authSessionExpired' => l.authSessionExpired,
        'authSessionExpiredBadge' => l.authSessionExpiredBadge,
        'authSessionExpiredChip' => l.authSessionExpiredChip,
        'authSessionExpiredTitle' => l.authSessionExpiredTitle,
        'authSessionExpiredBody' => l.authSessionExpiredBody,
        'authSessionExpiredDataSafe' => l.authSessionExpiredDataSafe,
        'authSessionExpiredSignIn' => l.authSessionExpiredSignIn,
        'authSessionExpiredHelp' => l.authSessionExpiredHelp,
        'authLoginUnexpectedError' => l.authLoginUnexpectedError,
        'authSocialSignInSoon' => l.authSocialSignInSoon(a[0] as String),
        'authSocialSignInNotConfigured' =>
          l.authSocialSignInNotConfigured(a[0] as String),
        'authLoginSubtitle' => l.authLoginSubtitle,
        'authForgotPasswordLink' => l.authForgotPasswordLink,
        'authSignInButton' => l.authSignInButton,
        'authSigningIn' => l.authSigningIn,
        'authOrContinueWith' => l.authOrContinueWith,
        'authNoAccount' => l.authNoAccount,
        'authCreateAccountLink' => l.authCreateAccountLink,
        'authForgotEmailInvalidNotice' => l.authForgotEmailInvalidNotice,
        'authForgotSendFailed' => l.authForgotSendFailed,
        'authForgotResetFailed' => l.authForgotResetFailed,
        'authForgotTitle' => l.authForgotTitle,
        'authForgotCodeIntro' => l.authForgotCodeIntro,
        'authForgotEmailIntro' => l.authForgotEmailIntro,
        'authForgotEmailInvalid' => l.authForgotEmailInvalid,
        'authForgotSendCode' => l.authForgotSendCode,
        'authSending' => l.authSending,
        'authVerificationCodeLabel' => l.authVerificationCodeLabel,
        'authCodeRequired' => l.authCodeRequired,
        'authNewPasswordLabel' => l.authNewPasswordLabel,
        'authForgotNewPasswordRequired' => l.authForgotNewPasswordRequired,
        'authForgotConfirmPasswordLabel' => l.authForgotConfirmPasswordLabel,
        'authForgotConfirmPasswordRequired' =>
          l.authForgotConfirmPasswordRequired,
        'authPasswordsDoNotMatch' => l.authPasswordsDoNotMatch,
        'authForgotResetButton' => l.authForgotResetButton,
        'authSaving' => l.authSaving,
        'authResendCodeIn' => l.authResendCodeIn(a[0] as int),
        'authResendCode' => l.authResendCode,
        'authForgotUseDifferentEmail' => l.authForgotUseDifferentEmail,
        'authVerifySuccess' => l.authVerifySuccess,
        'authVerifyUnexpectedError' => l.authVerifyUnexpectedError,
        'authVerifyResendFailed' => l.authVerifyResendFailed,
        'authVerifyBackToSignIn' => l.authVerifyBackToSignIn,
        'authVerifyTitle' => l.authVerifyTitle,
        'authVerifyCodeSentTo' => l.authVerifyCodeSentTo,
        'authVerifyButton' => l.authVerifyButton,
        'authVerifying' => l.authVerifying,
        'authVerifyCheckSpam' => l.authVerifyCheckSpam,
        'settingsPrivacyTitle' => l.settingsPrivacyTitle,
        'settingsPrivacyCollectTitle' => l.settingsPrivacyCollectTitle,
        'settingsPrivacyCollectBody' => l.settingsPrivacyCollectBody,
        'settingsPrivacyUseTitle' => l.settingsPrivacyUseTitle,
        'settingsPrivacyUseBody' => l.settingsPrivacyUseBody,
        'settingsPrivacyProcessorsTitle' => l.settingsPrivacyProcessorsTitle,
        'settingsPrivacyProcessorsBody' => l.settingsPrivacyProcessorsBody,
        'settingsPrivacyRetentionTitle' => l.settingsPrivacyRetentionTitle,
        'settingsPrivacyRetentionBody' => l.settingsPrivacyRetentionBody,
        'settingsPrivacyContactTitle' => l.settingsPrivacyContactTitle,
        'settingsPrivacyContactBody' =>
          l.settingsPrivacyContactBody(a[0] as String),
        'settingsNotificationsUpdateFailed' =>
          l.settingsNotificationsUpdateFailed,
        'settingsNotificationsTitle' => l.settingsNotificationsTitle,
        'settingsNotificationsReadAll' => l.settingsNotificationsReadAll,
        'settingsNotificationsLoadFailed' => l.settingsNotificationsLoadFailed,
        'settingsNotificationsEmptyTitle' => l.settingsNotificationsEmptyTitle,
        'settingsNotificationsEmptyBody' => l.settingsNotificationsEmptyBody,
        'settingsNotificationsUnread' => l.settingsNotificationsUnread,
        'settingsCleanupFailed' => l.settingsCleanupFailed,
        'settingsCleanupMessage' => l.settingsCleanupMessage,
        'settingsCleanupRetry' => l.settingsCleanupRetry,
        'settingsCleanupClearing' => l.settingsCleanupClearing,
        'settingsPasswordChanged' => l.settingsPasswordChanged,
        'settingsCurrentPasswordIncorrect' =>
          l.settingsCurrentPasswordIncorrect,
        'settingsPasswordChangeFailed' => l.settingsPasswordChangeFailed,
        'settingsCurrentPasswordLabel' => l.settingsCurrentPasswordLabel,
        'settingsCurrentPasswordRequired' => l.settingsCurrentPasswordRequired,
        'settingsNewPasswordRequired' => l.settingsNewPasswordRequired,
        'settingsNewPasswordSameAsCurrent' =>
          l.settingsNewPasswordSameAsCurrent,
        'settingsConfirmNewPasswordLabel' => l.settingsConfirmNewPasswordLabel,
        'settingsConfirmNewPasswordRequired' =>
          l.settingsConfirmNewPasswordRequired,
        'settingsUpdatePassword' => l.settingsUpdatePassword,
        'settingsUpdatingPassword' => l.settingsUpdatingPassword,
        'settingsDeleteConfirmTitle' => l.settingsDeleteConfirmTitle,
        'settingsDeleteConfirmBody' => l.settingsDeleteConfirmBody,
        'settingsDeleteForever' => l.settingsDeleteForever,
        'settingsAccountDeleted' => l.settingsAccountDeleted,
        'settingsDeletePasswordIncorrect' => l.settingsDeletePasswordIncorrect,
        'settingsDeleteFailed' => l.settingsDeleteFailed,
        'settingsDeleteWarning' => l.settingsDeleteWarning,
        'settingsDeleteConfirmWithPassword' =>
          l.settingsDeleteConfirmWithPassword,
        'settingsDeleteConfirmWithProvider' =>
          l.settingsDeleteConfirmWithProvider,
        'settingsDeleteWithProvider' =>
          l.settingsDeleteWithProvider(a[0] as String),
        'settingsDeleteProviderMismatch' =>
          l.settingsDeleteProviderMismatch(a[0] as String),
        'settingsDeletePasswordRequired' => l.settingsDeletePasswordRequired,
        'settingsDeleteMyAccount' => l.settingsDeleteMyAccount,
        'settingsDeleting' => l.settingsDeleting,
        'settingsAvatarCropTitle' => l.settingsAvatarCropTitle,
        'settingsAvatarOpenFailed' => l.settingsAvatarOpenFailed,
        'settingsAvatarUsePhoto' => l.settingsAvatarUsePhoto,
        'settingsPhotoGallery' => l.settingsPhotoGallery,
        'settingsPhotoCamera' => l.settingsPhotoCamera,
        'settingsPhotoRemove' => l.settingsPhotoRemove,
        'settingsPhotoRemoved' => l.settingsPhotoRemoved,
        'settingsPhotoUpdated' => l.settingsPhotoUpdated,
        'settingsPhotoUpdateFailed' => l.settingsPhotoUpdateFailed,
        'settingsPhotoChange' => l.settingsPhotoChange,
        'settingsPhotoHint' => l.settingsPhotoHint,
        'settingsProfileUpdated' => l.settingsProfileUpdated,
        'settingsProfileUpdateFailed' => l.settingsProfileUpdateFailed,
        'settingsProfileLoadFailed' => l.settingsProfileLoadFailed,
        'settingsProfileFullNameLabel' => l.settingsProfileFullNameLabel,
        'settingsProfileNameHint' => l.settingsProfileNameHint,
        'settingsProfileNameRequired' => l.settingsProfileNameRequired,
        'settingsProfileJobTitleLabel' => l.settingsProfileJobTitleLabel,
        'settingsProfileJobTitlesLoadFailed' =>
          l.settingsProfileJobTitlesLoadFailed,
        'settingsProfileEmailReadOnly' => l.settingsProfileEmailReadOnly,
        'settingsProfilePhoneLabel' => l.settingsProfilePhoneLabel,
        'settingsProfileSaveChanges' => l.settingsProfileSaveChanges,
        'settingsProfileTitle' => l.settingsProfileTitle,
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
        'jobsEmptyFeed' => l.jobsEmptyFeed,
        'jobsLoadFailed' => l.jobsLoadFailed,
        'jobsLatestPostings' => l.jobsLatestPostings,
        'jobsDetailTitle' => l.jobsDetailTitle,
        'jobsVerifiedSourceDetail' => l.jobsVerifiedSourceDetail,
        'jobsTamheerProgram' => l.jobsTamheerProgram,
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
        'atsBenchmark' => l.atsBenchmark(a[0] as String),
        'atsCategoryGeneral' => l.atsCategoryGeneral,
        'atsHiddenMore' => l.atsHiddenMore(a[0] as int),
        'myCvsHeaderSubtitle' => l.myCvsHeaderSubtitle,
        'myCvsToolsTitle' => l.myCvsToolsTitle,
        'myCvsToolCreateTitle' => l.myCvsToolCreateTitle,
        'myCvsToolCreateBody' => l.myCvsToolCreateBody,
        'myCvsToolScanTitle' => l.myCvsToolScanTitle,
        'myCvsToolScanBody' => l.myCvsToolScanBody,
        'myCvsToolUploadTitle' => l.myCvsToolUploadTitle,
        'myCvsToolUploadBody' => l.myCvsToolUploadBody,
        'myCvsToolTargetTitle' => l.myCvsToolTargetTitle,
        'myCvsToolTargetBody' => l.myCvsToolTargetBody,
        'myCvsListTitle' => l.myCvsListTitle,
        'myCvsEmptyBody' => l.myCvsEmptyBody,
        'myCvsEmptyCreate' => l.myCvsEmptyCreate,
        'myCvsEmptyUpload' => l.myCvsEmptyUpload,
        'cvCardOpen' => l.cvCardOpen,
        'cvCardMore' => l.cvCardMore,
        'cvCardScore' => l.cvCardScore(a[0] as int),
        'cvCardNotScanned' => l.cvCardNotScanned,
        'cvCardScanNow' => l.cvCardScanNow,
        'cvCardNeedsWork' => l.cvCardNeedsWork,
        'settingsNotificationsFilterAll' => l.settingsNotificationsFilterAll,
        'settingsNotificationsCategoryCv' => l.settingsNotificationsCategoryCv,
        'settingsNotificationsCategoryJobs' =>
          l.settingsNotificationsCategoryJobs,
        'settingsNotificationsCategoryAnalysis' =>
          l.settingsNotificationsCategoryAnalysis,
        'settingsNotificationsCategoryLearning' =>
          l.settingsNotificationsCategoryLearning,
        'settingsNotificationsCategoryGeneral' =>
          l.settingsNotificationsCategoryGeneral,
        'settingsNotificationsToday' => l.settingsNotificationsToday,
        'settingsNotificationsYesterday' => l.settingsNotificationsYesterday,
        'settingsNotificationsThisWeek' => l.settingsNotificationsThisWeek,
        'settingsNotificationsEarlier' => l.settingsNotificationsEarlier,
        'settingsNotificationsNewCount' =>
          l.settingsNotificationsNewCount(a[0] as int),
        'settingsNotificationsCount' =>
          l.settingsNotificationsCount(a[0] as int),
        'settingsNotificationsViewCv' => l.settingsNotificationsViewCv,
        'settingsNotificationsScanCta' => l.settingsNotificationsScanCta,
        'settingsNotificationsFilterEmpty' =>
          l.settingsNotificationsFilterEmpty,
        'settingsNotificationsPreviewTitle' =>
          l.settingsNotificationsPreviewTitle,
        'settingsNotificationsPreviewCvTitle' =>
          l.settingsNotificationsPreviewCvTitle,
        'settingsNotificationsPreviewCvBody' =>
          l.settingsNotificationsPreviewCvBody,
        'settingsNotificationsPreviewJobsTitle' =>
          l.settingsNotificationsPreviewJobsTitle,
        'settingsNotificationsPreviewJobsBody' =>
          l.settingsNotificationsPreviewJobsBody,
        'settingsNotificationsPreviewAnalysisTitle' =>
          l.settingsNotificationsPreviewAnalysisTitle,
        'settingsNotificationsPreviewAnalysisBody' =>
          l.settingsNotificationsPreviewAnalysisBody,
        'settingsNotificationsCreateCvCta' =>
          l.settingsNotificationsCreateCvCta,
        'authSignInRequiredTitle' => l.authSignInRequiredTitle,
        'authSignInRequiredSubtitle' => l.authSignInRequiredSubtitle,
        'authSignInRequiredCardTitle' => l.authSignInRequiredCardTitle,
        'authSignInRequiredBody' => l.authSignInRequiredBody,
        'authSignInRequiredBrowseJobs' => l.authSignInRequiredBrowseJobs,
        'jobsRegionAll' => l.jobsRegionAll,
        'jobsRegionCentral' => l.jobsRegionCentral,
        'jobsRegionEastern' => l.jobsRegionEastern,
        'jobsRegionWestern' => l.jobsRegionWestern,
        'jobsRegionNorthern' => l.jobsRegionNorthern,
        'jobsRegionSouthern' => l.jobsRegionSouthern,
        'jobsEmptyRegionTitle' => l.jobsEmptyRegionTitle(a[0] as String),
        'jobsEmptyRegionBody' => l.jobsEmptyRegionBody,
        'jobsShowAllRegions' => l.jobsShowAllRegions,
        'jobsMatchedNeedsTitle' => l.jobsMatchedNeedsTitle,
        'jobsMatchedSetTitle' => l.jobsMatchedSetTitle,
        'jobsMatchedBasedOn' => l.jobsMatchedBasedOn(a[0] as String),
        'jobsHowToApply' => l.jobsHowToApply,
        'jobsApplyOpensHost' => l.jobsApplyOpensHost(a[0] as String),
        'jobsApplyByEmail' => l.jobsApplyByEmail,
        'jobsApplyEmailHint' => l.jobsApplyEmailHint,
        'jobsCopyEmail' => l.jobsCopyEmail,
        'jobsEmailCopied' => l.jobsEmailCopied,
        'jobsOpenEmailFailed' => l.jobsOpenEmailFailed,
        'jobsNoDirectApply' => l.jobsNoDirectApply,
        'jobsNoDirectApplyHint' => l.jobsNoDirectApplyHint,
        'jobsApplyMethodLink' => l.jobsApplyMethodLink,
        'jobsApplyMethodEmail' => l.jobsApplyMethodEmail,
        'jobsSourceName' => l.jobsSourceName(a[0] as String),
        'jobsViewSourcePost' => l.jobsViewSourcePost,
        'jobsShare' => l.jobsShare,
        'jobsRemoteChip' => l.jobsRemoteChip,
        'homeProfileSubtitle' => l.homeProfileSubtitle,
        'homeProfileOpen' => l.homeProfileOpen,
        'homeStartCreateTitle' => l.homeStartCreateTitle,
        'homeStartCreateBody' => l.homeStartCreateBody,
        'homeStartAtsTitle' => l.homeStartAtsTitle,
        'homeStartAtsBody' => l.homeStartAtsBody,
        'homeServiceUpload' => l.homeServiceUpload,
        'homeServiceTarget' => l.homeServiceTarget,
        'homeServiceEducation' => l.homeServiceEducation,
        'homeSoon' => l.homeSoon,
        'homeServiceSoonA11y' => l.homeServiceSoonA11y(a[0] as String),
        'homeMyCvTitle' => l.homeMyCvTitle,
        'homeMyCvEdited' => l.homeMyCvEdited(a[0] as String),
        'homeMyCvEdit' => l.homeMyCvEdit,
        'homeMyCvCheck' => l.homeMyCvCheck,
        'homeMyCvEmptyTitle' => l.homeMyCvEmptyTitle,
        'homeMyCvEmptyBody' => l.homeMyCvEmptyBody,
        'homeHonesty' => l.homeHonesty,
        'authEmailHint' => l.authEmailHint,
        'authPhoneHint' => l.authPhoneHint,
        'cvPersonalEmailHint' => l.cvPersonalEmailHint,
        'cvPersonalPhoneHint' => l.cvPersonalPhoneHint,
        'cvPersonalLinkedinHint' => l.cvPersonalLinkedinHint,
        'authSocialGoogle' => l.authSocialGoogle,
        'authSocialApple' => l.authSocialApple,
        'authRegisterEmailHint' => l.authRegisterEmailHint,
        'timeJustNow' => l.timeJustNow,
        'timeMinutesAgo' => l.timeMinutesAgo(a[0] as int),
        'timeHoursAgo' => l.timeHoursAgo(a[0] as int),
        'timeYesterday' => l.timeYesterday,
        'savedJustNow' => l.savedJustNow,
        'savedAgo' => l.savedAgo(a[0] as String),
        'untitledTitle' => l.untitledTitle,
        'aiErrorTooLong' => l.aiErrorTooLong,
        'aiErrorTryAgain' => l.aiErrorTryAgain,
        'aiGenerationFailed' => l.aiGenerationFailed(a[0] as String),
        'aiSuggestionsFailed' => l.aiSuggestionsFailed(a[0] as String),
        'aiLocalFallback' => l.aiLocalFallback(a[0] as String),
        'jobNewsTitle' => l.jobNewsTitle,
        'crashMessage' => l.crashMessage,
        'avatarFallbackInitial' => l.avatarFallbackInitial,
        'coreApiErrorBadResponse' => l.coreApiErrorBadResponse,
        'coreApiErrorEmptyResponse' => l.coreApiErrorEmptyResponse,
        'coreApiErrorUnexpected' => l.coreApiErrorUnexpected,
        'coreApiErrorRequestFailed' => l.coreApiErrorRequestFailed,
        'coreApiErrorStatus' => l.coreApiErrorStatus(a[0] as int),
        'authVerifyCodeResent' => l.authVerifyCodeResent,
        'authForgotCodeSent' => l.authForgotCodeSent,
        'authForgotPasswordReset' => l.authForgotPasswordReset,
        'serverDashboardStatusActive' => l.serverDashboardStatusActive,
        'serverDashboardCreateCvTitle' => l.serverDashboardCreateCvTitle,
        'serverDashboardCreateCvSubtitle' => l.serverDashboardCreateCvSubtitle,
        'serverDashboardCreateCvButton' => l.serverDashboardCreateCvButton,
        'serverDashboardAnalyzeTitle' => l.serverDashboardAnalyzeTitle,
        'serverDashboardAnalyzeSubtitle' => l.serverDashboardAnalyzeSubtitle,
        'serverDashboardAnalyzeButton' => l.serverDashboardAnalyzeButton,
        'serverMyCvsTitle' => l.serverMyCvsTitle,
        'serverMyCvsSummary' => l.serverMyCvsSummary(a[0] as int),
        'serverMyCvsUpdated' => l.serverMyCvsUpdated(a[0] as String),
        'serverMyCvsUpdatedUnknown' => l.serverMyCvsUpdatedUnknown,
        'serverMyCvsTailoredTitle' =>
          l.serverMyCvsTailoredTitle(a[0] as String),
        'serverCvTemplatesTitle' => l.serverCvTemplatesTitle,
        'serverCvTemplatesSubtitle' => l.serverCvTemplatesSubtitle,
        'serverEducationTitle' => l.serverEducationTitle,
        'serverEducationSubtitle' => l.serverEducationSubtitle,
        'serverEducationTargetLabel' => l.serverEducationTargetLabel,
        'serverEducationTabNews' => l.serverEducationTabNews,
        'serverEducationTabCertificates' => l.serverEducationTabCertificates,
        'serverEducationTabStudy' => l.serverEducationTabStudy,
        'serverEducationStartLearning' => l.serverEducationStartLearning,
        'serverJobsTitle' => l.serverJobsTitle,
        'serverJobsSubtitle' => l.serverJobsSubtitle,
        'serverJobsApplyBy' => l.serverJobsApplyBy(a[0] as String),
        'serverJobsSourceGovLabel' => l.serverJobsSourceGovLabel,
        'serverJobsSourceGovBadge' => l.serverJobsSourceGovBadge,
        'serverJobsSourceCompanyLabel' => l.serverJobsSourceCompanyLabel,
        'serverJobsSourceCompanyBadge' => l.serverJobsSourceCompanyBadge,
        'serverJobsSourceTamheerLabel' => l.serverJobsSourceTamheerLabel,
        'serverJobsSourceTamheerBadge' => l.serverJobsSourceTamheerBadge,
        'serverJobsSourceStartupLabel' => l.serverJobsSourceStartupLabel,
        'serverJobsSourceStartupBadge' => l.serverJobsSourceStartupBadge,
        'serverJobsSalaryRange' => l.serverJobsSalaryRange(
            a[0] as String, a[1] as String, a[2] as String),
        'serverJobsSalaryFrom' =>
          l.serverJobsSalaryFrom(a[0] as String, a[1] as String),
        'serverJobsSalaryUpTo' =>
          l.serverJobsSalaryUpTo(a[0] as String, a[1] as String),
        'serverJobsCurrencySar' => l.serverJobsCurrencySar,
        'serverNotificationsAllRead' => l.serverNotificationsAllRead,
        'serverNotificationsPreferencesUpdated' =>
          l.serverNotificationsPreferencesUpdated,
        'serverNotificationsOpenRecorded' => l.serverNotificationsOpenRecorded,
        'serverNotificationsActivityRecorded' =>
          l.serverNotificationsActivityRecorded,
        'serverNotificationsConversionRecorded' =>
          l.serverNotificationsConversionRecorded,
        'serverNotificationsTokenRegistered' =>
          l.serverNotificationsTokenRegistered,
        'serverNotificationsTokenRemoved' => l.serverNotificationsTokenRemoved,
        'serverAuthInvalidCredentials' => l.serverAuthInvalidCredentials,
        'serverAuthEmailVerified' => l.serverAuthEmailVerified,
        'serverAuthEmailAlreadyVerified' => l.serverAuthEmailAlreadyVerified,
        'serverAuthVerificationCodeSent' => l.serverAuthVerificationCodeSent,
        'serverAuthResetCodeSent' => l.serverAuthResetCodeSent,
        'serverAuthInvalidCode' => l.serverAuthInvalidCode,
        'serverAuthPasswordReset' => l.serverAuthPasswordReset,
        'serverAuthLoggedOut' => l.serverAuthLoggedOut,
        'serverAuthCurrentPasswordWrong' => l.serverAuthCurrentPasswordWrong,
        'serverAuthPasswordChanged' => l.serverAuthPasswordChanged,
        'serverAuthAvatarSaveFailed' => l.serverAuthAvatarSaveFailed,
        'serverAuthPasswordWrong' => l.serverAuthPasswordWrong,
        'serverAuthSocialAccountMismatch' => l.serverAuthSocialAccountMismatch,
        'serverAuthAccountDeleted' => l.serverAuthAccountDeleted,
        'serverAuthJobTitleOtherRequired' => l.serverAuthJobTitleOtherRequired,
        'serverAuthVerificationResendWait' =>
          l.serverAuthVerificationResendWait,
        'serverAuthResetResendWait' => l.serverAuthResetResendWait,
        'serverAuthEmailNotVerified' => l.serverAuthEmailNotVerified,
        'serverAuthSocialUnavailable' =>
          l.serverAuthSocialUnavailable(a[0] as String),
        'serverAuthSocialInvalidToken' =>
          l.serverAuthSocialInvalidToken(a[0] as String),
        'serverAuthSocialEmailUnverified' =>
          l.serverAuthSocialEmailUnverified(a[0] as String),
        'serverCvDeleted' => l.serverCvDeleted,
        'serverCvTemplateUnavailable' => l.serverCvTemplateUnavailable,
        'serverCvTemplatePremiumOnly' => l.serverCvTemplatePremiumOnly,
        'serverCvEnhanceUnavailable' => l.serverCvEnhanceUnavailable,
        'serverCvEnhanceFailed' => l.serverCvEnhanceFailed,
        'serverCvExportGenerating' => l.serverCvExportGenerating,
        'serverCvExportMissingContact' => l.serverCvExportMissingContact,
        'serverCvExportUnstructuredExperience' =>
          l.serverCvExportUnstructuredExperience,
        'serverCvTemplateHidesSections' =>
          l.serverCvTemplateHidesSections(a[0] as String),
        'serverCvTemplateSectionListSeparator' =>
          l.serverCvTemplateSectionListSeparator,
        'serverCvSectionSummary' => l.serverCvSectionSummary,
        'serverCvSectionSkills' => l.serverCvSectionSkills,
        'serverCvSectionExperience' => l.serverCvSectionExperience,
        'serverCvSectionEducation' => l.serverCvSectionEducation,
        'serverCvSectionCertifications' => l.serverCvSectionCertifications,
        'serverCvSectionProjects' => l.serverCvSectionProjects,
        'serverCvSectionLanguages' => l.serverCvSectionLanguages,
        'serverCvSectionCustom' => l.serverCvSectionCustom,
        'serverCvFileTypeUnsupported' => l.serverCvFileTypeUnsupported,
        'serverCvTextTooShort' => l.serverCvTextTooShort(a[0] as int),
        'serverCvPdfUnreadable' => l.serverCvPdfUnreadable,
        'serverAnalysisResumeRequired' => l.serverAnalysisResumeRequired,
        'serverAnalysisLockedTitle' => l.serverAnalysisLockedTitle,
        'serverAnalysisLockedMessage' =>
          l.serverAnalysisLockedMessage(a[0] as int),
        'serverAnalysisLockedCta' => l.serverAnalysisLockedCta,
        'serverPaywallTitle' => l.serverPaywallTitle,
        'serverPaywallCta' => l.serverPaywallCta,
        'serverPaywallJobMatch' => l.serverPaywallJobMatch,
        'serverPaywallDownload' => l.serverPaywallDownload,
        'serverPaywallEnhance' => l.serverPaywallEnhance,
        'serverPaywallDailyCvLimit' => l.serverPaywallDailyCvLimit(a[0] as int),
        'serverPaywallDailyAnalysisLimit' =>
          l.serverPaywallDailyAnalysisLimit(a[0] as int),
        'serverPaywallBenefitPdf' => l.serverPaywallBenefitPdf,
        'serverPaywallBenefitEnhance' => l.serverPaywallBenefitEnhance,
        'serverPaywallBenefitAnalysis' => l.serverPaywallBenefitAnalysis,
        'serverPaywallBenefitUnlimited' => l.serverPaywallBenefitUnlimited,
        'serverJobMatchDailyLimit' => l.serverJobMatchDailyLimit,
        'serverPlanMonthlyName' => l.serverPlanMonthlyName,
        'serverPlanSixMonthsName' => l.serverPlanSixMonthsName,
        'serverPlanSixMonthsBadge' => l.serverPlanSixMonthsBadge,
        'serverPlanAnnualName' => l.serverPlanAnnualName,
        'serverErrorUnauthenticated' => l.serverErrorUnauthenticated,
        'serverErrorForbidden' => l.serverErrorForbidden,
        'serverErrorNotFound' => l.serverErrorNotFound,
        'serverErrorMethodNotAllowed' => l.serverErrorMethodNotAllowed,
        'serverErrorTooManyRequests' => l.serverErrorTooManyRequests,
        'serverErrorServer' => l.serverErrorServer,
        'serverErrorUnavailable' => l.serverErrorUnavailable,
        'serverErrorRequestFailed' => l.serverErrorRequestFailed,
        'serverValidationRequired' =>
          l.serverValidationRequired(a[0] as String),
        'serverValidationString' => l.serverValidationString(a[0] as String),
        'serverValidationEmail' => l.serverValidationEmail,
        'serverValidationFile' => l.serverValidationFile(a[0] as String),
        'serverValidationImage' => l.serverValidationImage(a[0] as String),
        'serverValidationMimes' =>
          l.serverValidationMimes(a[0] as String, a[1] as String),
        'serverValidationMaxString' =>
          l.serverValidationMaxString(a[0] as String, a[1] as String),
        'serverValidationMaxFile' =>
          l.serverValidationMaxFile(a[0] as String, a[1] as String),
        'serverValidationMaxNumeric' =>
          l.serverValidationMaxNumeric(a[0] as String, a[1] as String),
        'serverValidationMaxArray' =>
          l.serverValidationMaxArray(a[0] as String, a[1] as String),
        'serverValidationMinString' =>
          l.serverValidationMinString(a[0] as String, a[1] as String),
        'serverValidationMinFile' =>
          l.serverValidationMinFile(a[0] as String, a[1] as String),
        'serverValidationMinNumeric' =>
          l.serverValidationMinNumeric(a[0] as String, a[1] as String),
        'serverValidationMinArray' =>
          l.serverValidationMinArray(a[0] as String, a[1] as String),
        'serverValidationBetweenNumeric' => l.serverValidationBetweenNumeric(
            a[0] as String, a[1] as String, a[2] as String),
        'serverValidationBetweenString' => l.serverValidationBetweenString(
            a[0] as String, a[1] as String, a[2] as String),
        'serverValidationSizeString' =>
          l.serverValidationSizeString(a[0] as String, a[1] as String),
        'serverValidationIn' => l.serverValidationIn(a[0] as String),
        'serverValidationInteger' => l.serverValidationInteger(a[0] as String),
        'serverValidationNumeric' => l.serverValidationNumeric(a[0] as String),
        'serverValidationBoolean' => l.serverValidationBoolean(a[0] as String),
        'serverValidationArray' => l.serverValidationArray(a[0] as String),
        'serverValidationRegex' => l.serverValidationRegex(a[0] as String),
        'serverValidationUrl' => l.serverValidationUrl(a[0] as String),
        'serverValidationDate' => l.serverValidationDate(a[0] as String),
        'serverValidationExists' => l.serverValidationExists(a[0] as String),
        'serverValidationUnique' => l.serverValidationUnique(a[0] as String),
        'serverValidationConfirmed' =>
          l.serverValidationConfirmed(a[0] as String),
        'serverValidationRequiredIf' =>
          l.serverValidationRequiredIf(a[0] as String),
        'serverValidationAccepted' =>
          l.serverValidationAccepted(a[0] as String),
        'serverValidationAlphaDash' =>
          l.serverValidationAlphaDash(a[0] as String),
        'serverValidationMoreErrors' =>
          l.serverValidationMoreErrors(a[0] as String, a[1] as int),
        'serverAttributeName' => l.serverAttributeName,
        'serverAttributeFullName' => l.serverAttributeFullName,
        'serverAttributeEmail' => l.serverAttributeEmail,
        'serverAttributePassword' => l.serverAttributePassword,
        'serverAttributeCurrentPassword' => l.serverAttributeCurrentPassword,
        'serverAttributeCode' => l.serverAttributeCode,
        'serverAttributePhone' => l.serverAttributePhone,
        'serverAttributeLocation' => l.serverAttributeLocation,
        'serverAttributeJobTitle' => l.serverAttributeJobTitle,
        'serverAttributeJobTitleOther' => l.serverAttributeJobTitleOther,
        'serverAttributeAvatar' => l.serverAttributeAvatar,
        'serverAttributeRoleInterest' => l.serverAttributeRoleInterest,
        'serverAttributeTargetJobTitle' => l.serverAttributeTargetJobTitle,
        'serverAttributeNotes' => l.serverAttributeNotes,
        'serverAttributeResumeText' => l.serverAttributeResumeText,
        'serverAttributeResumeFile' => l.serverAttributeResumeFile,
        'serverAttributeLinkedin' => l.serverAttributeLinkedin,
        'serverAttributeLanguage' => l.serverAttributeLanguage,
        'serverAttributeSummary' => l.serverAttributeSummary,
        'serverAttributeSkills' => l.serverAttributeSkills,
        'serverAttributeExperience' => l.serverAttributeExperience,
        'serverAttributeEducation' => l.serverAttributeEducation,
        'serverAttributeCertifications' => l.serverAttributeCertifications,
        'serverAttributeJobDescription' => l.serverAttributeJobDescription,
        'serverAttributeDraft' => l.serverAttributeDraft,
        'serverAttributeTemplate' => l.serverAttributeTemplate,
        'serverNotifyFirstAnalysisTitle' => l.serverNotifyFirstAnalysisTitle,
        'serverNotifyFirstAnalysisBody' => l.serverNotifyFirstAnalysisBody,
        'serverNotifyLowScoreTitle' => l.serverNotifyLowScoreTitle,
        'serverNotifyLowScoreBodyScoreTip' =>
          l.serverNotifyLowScoreBodyScoreTip(a[0] as String, a[1] as String),
        'serverNotifyLowScoreBodyTip' =>
          l.serverNotifyLowScoreBodyTip(a[0] as String),
        'serverNotifyLowScoreBodyScore' =>
          l.serverNotifyLowScoreBodyScore(a[0] as String),
        'serverNotifyLowScoreBody' => l.serverNotifyLowScoreBody,
        'serverNotifyAnalysisToCvTitle' => l.serverNotifyAnalysisToCvTitle,
        'serverNotifyAnalysisToCvBody' => l.serverNotifyAnalysisToCvBody,
        'serverNotifyStaleCvTitle' => l.serverNotifyStaleCvTitle,
        'serverNotifyStaleCvBody' => l.serverNotifyStaleCvBody,
        'serverNotifyMatchingJobTitle' => l.serverNotifyMatchingJobTitle,
        'serverNotifyMatchingJobBodyTitleCompany' =>
          l.serverNotifyMatchingJobBodyTitleCompany(
              a[0] as String, a[1] as String),
        'serverNotifyMatchingJobBodyTitle' =>
          l.serverNotifyMatchingJobBodyTitle(a[0] as String),
        'serverNotifyMatchingJobBody' => l.serverNotifyMatchingJobBody,
        'serverNotifyEducationTitle' => l.serverNotifyEducationTitle,
        'serverNotifyEducationBodyTitle' =>
          l.serverNotifyEducationBodyTitle(a[0] as String),
        'serverNotifyEducationBody' => l.serverNotifyEducationBody,
        'serverNotifyTipTitle' => l.serverNotifyTipTitle,
        'serverNotifyTipBody' => l.serverNotifyTipBody,
        'serverNotifyCvReadyTitle' => l.serverNotifyCvReadyTitle,
        'serverNotifyCvReadyBody' => l.serverNotifyCvReadyBody,
        'serverNotifyCvFailedTitle' => l.serverNotifyCvFailedTitle,
        'serverNotifyCvFailedBody' => l.serverNotifyCvFailedBody,
        'serverNotifyNewJobTitle' => l.serverNotifyNewJobTitle,
        'serverNotifyNewJobBody' => l.serverNotifyNewJobBody(a[0] as String),
        'serverNotifyNewJobBodyCompany' =>
          l.serverNotifyNewJobBodyCompany(a[0] as String, a[1] as String),
        'serverNotifyNewJobBodyLocation' =>
          l.serverNotifyNewJobBodyLocation(a[0] as String, a[1] as String),
        'serverNotifyNewJobBodyLocationCompany' =>
          l.serverNotifyNewJobBodyLocationCompany(
              a[0] as String, a[1] as String, a[2] as String),
        'serverAnalysisNotResume' => l.serverAnalysisNotResume,
        'serverPlanFreeTitle' => l.serverPlanFreeTitle,
        'serverPlanFreeIncludesJobs' => l.serverPlanFreeIncludesJobs,
        'serverPlanFreeIncludesAts' => l.serverPlanFreeIncludesAts,
        'serverPlanFreeIncludesPreview' => l.serverPlanFreeIncludesPreview,
        'serverPlanFreeIncludesDailyLimits' =>
          l.serverPlanFreeIncludesDailyLimits(a[0] as int, a[1] as int),
        'serverPlanFreeExcludesRecommendations' =>
          l.serverPlanFreeExcludesRecommendations(a[0] as int),
        'serverCvDownloadLocked' => l.serverCvDownloadLocked,
        _ => throw ArgumentError.value(key, 'key'),
      };
}
