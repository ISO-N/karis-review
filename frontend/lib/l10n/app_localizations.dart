import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of KarisReviewLocalizations
/// returned by `KarisReviewLocalizations.of(context)`.
///
/// Applications need to include `KarisReviewLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: KarisReviewLocalizations.localizationsDelegates,
///   supportedLocales: KarisReviewLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the KarisReviewLocalizations.supportedLocales
/// property.
abstract class KarisReviewLocalizations {
  KarisReviewLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static KarisReviewLocalizations? of(BuildContext context) {
    return Localizations.of<KarisReviewLocalizations>(
      context,
      KarisReviewLocalizations,
    );
  }

  static const LocalizationsDelegate<KarisReviewLocalizations> delegate =
      _KarisReviewLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'Karis Review'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navDecks.
  ///
  /// In en, this message translates to:
  /// **'Decks'**
  String get navDecks;

  /// No description provided for @navStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get navStats;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @authLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get authLoginTitle;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Login to start today\'s review'**
  String get authLoginSubtitle;

  /// No description provided for @authRegisterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A focused spaced repetition review space'**
  String get authRegisterSubtitle;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authInviteCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Invitation Code'**
  String get authInviteCodeLabel;

  /// No description provided for @authLoginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get authLoginButton;

  /// No description provided for @authRegisterButton.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get authRegisterButton;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get authNoAccount;

  /// No description provided for @authHasAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authHasAccount;

  /// No description provided for @authRegisterLink.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get authRegisterLink;

  /// No description provided for @authLoginLink.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get authLoginLink;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @homeTodayReview.
  ///
  /// In en, this message translates to:
  /// **'Due Today'**
  String get homeTodayReview;

  /// No description provided for @homeReviewedProgress.
  ///
  /// In en, this message translates to:
  /// **'Reviewed {reviewed} · {due} remaining'**
  String homeReviewedProgress(Object reviewed, Object due);

  /// No description provided for @homeNoCards.
  ///
  /// In en, this message translates to:
  /// **'No cards due today'**
  String get homeNoCards;

  /// No description provided for @homeNoDecksTitle.
  ///
  /// In en, this message translates to:
  /// **'No decks yet'**
  String get homeNoDecksTitle;

  /// No description provided for @homeNoDecksMessage.
  ///
  /// In en, this message translates to:
  /// **'Create your first deck to start reviewing'**
  String get homeNoDecksMessage;

  /// No description provided for @homeCreateDeck.
  ///
  /// In en, this message translates to:
  /// **'Create Deck'**
  String get homeCreateDeck;

  /// No description provided for @deckListTitle.
  ///
  /// In en, this message translates to:
  /// **'All Decks'**
  String get deckListTitle;

  /// No description provided for @deckCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New Deck'**
  String get deckCreateTitle;

  /// No description provided for @deckRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename Deck'**
  String get deckRenameTitle;

  /// No description provided for @deckNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Deck Name'**
  String get deckNameLabel;

  /// No description provided for @deckNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Japanese N5'**
  String get deckNameHint;

  /// No description provided for @deckCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get deckCancel;

  /// No description provided for @deckCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get deckCreateButton;

  /// No description provided for @deckSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get deckSaveButton;

  /// No description provided for @deckDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Deck'**
  String get deckDeleteTitle;

  /// No description provided for @deckDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? All cards and review records in this deck will also be deleted.'**
  String deckDeleteConfirm(Object name);

  /// No description provided for @deckDeleteConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deckDeleteConfirmButton;

  /// No description provided for @deckDeleteCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get deckDeleteCancel;

  /// No description provided for @deckStats.
  ///
  /// In en, this message translates to:
  /// **'{count} cards · {due} due'**
  String deckStats(Object count, Object due);

  /// No description provided for @deckOperationTooltip.
  ///
  /// In en, this message translates to:
  /// **'Deck operations'**
  String get deckOperationTooltip;

  /// No description provided for @deckCloseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get deckCloseTooltip;

  /// No description provided for @deckRenameLabel.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get deckRenameLabel;

  /// No description provided for @deckDeleteLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deckDeleteLabel;

  /// No description provided for @deckCardCount.
  ///
  /// In en, this message translates to:
  /// **'c'**
  String get deckCardCount;

  /// No description provided for @reviewModeNew.
  ///
  /// In en, this message translates to:
  /// **'Learning Mode'**
  String get reviewModeNew;

  /// No description provided for @reviewModeDue.
  ///
  /// In en, this message translates to:
  /// **'Review Mode'**
  String get reviewModeDue;

  /// No description provided for @reviewLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load queue'**
  String get reviewLoadError;

  /// No description provided for @reviewRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get reviewRetry;

  /// No description provided for @reviewNoNewCards.
  ///
  /// In en, this message translates to:
  /// **'No new cards'**
  String get reviewNoNewCards;

  /// No description provided for @reviewNoDueCards.
  ///
  /// In en, this message translates to:
  /// **'No cards due'**
  String get reviewNoDueCards;

  /// No description provided for @reviewAllNewDone.
  ///
  /// In en, this message translates to:
  /// **'All new cards have entered the review queue'**
  String get reviewAllNewDone;

  /// No description provided for @reviewNoDueMessage.
  ///
  /// In en, this message translates to:
  /// **'No cards are due in the current scope, take a break'**
  String get reviewNoDueMessage;

  /// No description provided for @reviewBackToday.
  ///
  /// In en, this message translates to:
  /// **'Back to Today'**
  String get reviewBackToday;

  /// No description provided for @reviewRatingForget.
  ///
  /// In en, this message translates to:
  /// **'Forget'**
  String get reviewRatingForget;

  /// No description provided for @reviewRatingVague.
  ///
  /// In en, this message translates to:
  /// **'Vague'**
  String get reviewRatingVague;

  /// No description provided for @reviewRatingFamiliar.
  ///
  /// In en, this message translates to:
  /// **'Familiar'**
  String get reviewRatingFamiliar;

  /// No description provided for @reviewRatingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get reviewRatingContinue;

  /// No description provided for @reviewRatingRelearn.
  ///
  /// In en, this message translates to:
  /// **'Relearn'**
  String get reviewRatingRelearn;

  /// No description provided for @reviewRated.
  ///
  /// In en, this message translates to:
  /// **'Rated: {label} · Next {interval}'**
  String reviewRated(Object label, Object interval);

  /// No description provided for @reviewRatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Rated {label}'**
  String reviewRatedTitle(Object label);

  /// No description provided for @reviewRatedDetail.
  ///
  /// In en, this message translates to:
  /// **'Next {interval}'**
  String reviewRatedDetail(Object interval);

  /// No description provided for @reviewQueue.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get reviewQueue;

  /// No description provided for @reviewLoadingMore.
  ///
  /// In en, this message translates to:
  /// **'Loading more cards'**
  String get reviewLoadingMore;

  /// No description provided for @reviewOfflinePending.
  ///
  /// In en, this message translates to:
  /// **'Offline · {count} rating(s) pending sync'**
  String reviewOfflinePending(Object count);

  /// No description provided for @reviewCardFrontHint.
  ///
  /// In en, this message translates to:
  /// **'Flashcard, tap to show answer'**
  String get reviewCardFrontHint;

  /// No description provided for @reviewCardBackHint.
  ///
  /// In en, this message translates to:
  /// **'Flashcard, tap to show question'**
  String get reviewCardBackHint;

  /// No description provided for @reviewSessionCompleteNew.
  ///
  /// In en, this message translates to:
  /// **'Learning session complete'**
  String get reviewSessionCompleteNew;

  /// No description provided for @reviewSessionCompleteDue.
  ///
  /// In en, this message translates to:
  /// **'Today\'s review complete'**
  String get reviewSessionCompleteDue;

  /// No description provided for @reviewSessionStats.
  ///
  /// In en, this message translates to:
  /// **'{total} cards · {reviewed} reviewed'**
  String reviewSessionStats(Object total, Object reviewed);

  /// No description provided for @reviewErrorQueueFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load queue, please check your network'**
  String get reviewErrorQueueFailed;

  /// No description provided for @reviewErrorRatingFailed.
  ///
  /// In en, this message translates to:
  /// **'Rating failed, please check your network'**
  String get reviewErrorRatingFailed;

  /// No description provided for @startModeNew.
  ///
  /// In en, this message translates to:
  /// **'Start Learning'**
  String get startModeNew;

  /// No description provided for @startModeDue.
  ///
  /// In en, this message translates to:
  /// **'Start Review'**
  String get startModeDue;

  /// No description provided for @startNoDecksTitle.
  ///
  /// In en, this message translates to:
  /// **'No decks yet'**
  String get startNoDecksTitle;

  /// No description provided for @startNoDecksMessage.
  ///
  /// In en, this message translates to:
  /// **'Create a deck first, then start learning'**
  String get startNoDecksMessage;

  /// No description provided for @startCreateDeck.
  ///
  /// In en, this message translates to:
  /// **'Create Deck'**
  String get startCreateDeck;

  /// No description provided for @startBadgeNew.
  ///
  /// In en, this message translates to:
  /// **'{count} new'**
  String startBadgeNew(Object count);

  /// No description provided for @startBadgeDue.
  ///
  /// In en, this message translates to:
  /// **'{count} due'**
  String startBadgeDue(Object count);

  /// No description provided for @startFilterDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get startFilterDue;

  /// No description provided for @cardEditorKicker.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get cardEditorKicker;

  /// No description provided for @cardEditorTitleNew.
  ///
  /// In en, this message translates to:
  /// **'New Card'**
  String get cardEditorTitleNew;

  /// No description provided for @cardEditorTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Card'**
  String get cardEditorTitleEdit;

  /// No description provided for @cardEditorFront.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get cardEditorFront;

  /// No description provided for @cardEditorBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get cardEditorBack;

  /// No description provided for @cardEditorSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get cardEditorSave;

  /// No description provided for @cardEditorDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get cardEditorDelete;

  /// No description provided for @cardEditorCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cardEditorCancel;

  /// No description provided for @cardImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Cards'**
  String get cardImportTitle;

  /// No description provided for @cardImportPasteJson.
  ///
  /// In en, this message translates to:
  /// **'Paste JSON or select .json file'**
  String get cardImportPasteJson;

  /// No description provided for @cardImportSelectFile.
  ///
  /// In en, this message translates to:
  /// **'Select File'**
  String get cardImportSelectFile;

  /// No description provided for @cardImportParse.
  ///
  /// In en, this message translates to:
  /// **'Parse'**
  String get cardImportParse;

  /// No description provided for @cardImportImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get cardImportImport;

  /// No description provided for @cardImportCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cardImportCancel;

  /// No description provided for @cardImportPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get cardImportPreview;

  /// No description provided for @cardImportValid.
  ///
  /// In en, this message translates to:
  /// **'Valid'**
  String get cardImportValid;

  /// No description provided for @cardImportInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get cardImportInvalid;

  /// No description provided for @cardImportError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get cardImportError;

  /// No description provided for @cardImportRow.
  ///
  /// In en, this message translates to:
  /// **'Row'**
  String get cardImportRow;

  /// No description provided for @cardImportUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo Import'**
  String get cardImportUndo;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get settingsEmail;

  /// No description provided for @settingsReview.
  ///
  /// In en, this message translates to:
  /// **'Review Settings'**
  String get settingsReview;

  /// No description provided for @settingsRefreshTime.
  ///
  /// In en, this message translates to:
  /// **'Daily Refresh Time'**
  String get settingsRefreshTime;

  /// No description provided for @settingsRefreshSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Past this time, a new day begins'**
  String get settingsRefreshSubtitle;

  /// No description provided for @settingsData.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get settingsData;

  /// No description provided for @settingsExport.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get settingsExport;

  /// No description provided for @settingsExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save all decks, cards, and review records'**
  String get settingsExportSubtitle;

  /// No description provided for @settingsImport.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get settingsImport;

  /// No description provided for @settingsImportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Restore from backup file (overwrites)'**
  String get settingsImportSubtitle;

  /// No description provided for @settingsForceServer.
  ///
  /// In en, this message translates to:
  /// **'Use Server Data'**
  String get settingsForceServer;

  /// No description provided for @settingsForceServerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Discard pending sync ratings and re-fetch from server'**
  String get settingsForceServerSubtitle;

  /// No description provided for @settingsForceServerTitle.
  ///
  /// In en, this message translates to:
  /// **'Use Server Data'**
  String get settingsForceServerTitle;

  /// No description provided for @settingsForceServerContent.
  ///
  /// In en, this message translates to:
  /// **'This will discard all unsynced offline ratings and overwrite local data with server data. Continue?'**
  String get settingsForceServerContent;

  /// No description provided for @settingsForceServerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Overwrite'**
  String get settingsForceServerConfirm;

  /// No description provided for @settingsForceServerCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settingsForceServerCancel;

  /// No description provided for @settingsImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get settingsImportTitle;

  /// No description provided for @settingsImportContent.
  ///
  /// In en, this message translates to:
  /// **'Importing will overwrite all current data. This operation is irreversible. Continue?'**
  String get settingsImportContent;

  /// No description provided for @settingsImportConfirm.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get settingsImportConfirm;

  /// No description provided for @settingsImportCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settingsImportCancel;

  /// No description provided for @settingsImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Data restored: {decks} decks, {cards} cards, {logs} records'**
  String settingsImportSuccess(Object decks, Object cards, Object logs);

  /// No description provided for @settingsExportFail.
  ///
  /// In en, this message translates to:
  /// **'Export failed, please check your network'**
  String get settingsExportFail;

  /// No description provided for @settingsImportFail.
  ///
  /// In en, this message translates to:
  /// **'Import failed, please check your network or backup file'**
  String get settingsImportFail;

  /// No description provided for @settingsImportReadFail.
  ///
  /// In en, this message translates to:
  /// **'Failed to read backup file, please check the file format'**
  String get settingsImportReadFail;

  /// No description provided for @settingsSyncFail.
  ///
  /// In en, this message translates to:
  /// **'Sync failed, please check your network'**
  String get settingsSyncFail;

  /// No description provided for @settingsLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get settingsLogout;

  /// No description provided for @settingsChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get settingsChangePassword;

  /// No description provided for @settingsChangePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your login password'**
  String get settingsChangePasswordSubtitle;

  /// No description provided for @settingsChangePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get settingsChangePasswordTitle;

  /// No description provided for @settingsCurrentPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get settingsCurrentPasswordLabel;

  /// No description provided for @settingsNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get settingsNewPasswordLabel;

  /// No description provided for @settingsConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get settingsConfirmPasswordLabel;

  /// No description provided for @settingsNewPasswordShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get settingsNewPasswordShort;

  /// No description provided for @settingsPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get settingsPasswordMismatch;

  /// No description provided for @settingsChangePasswordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get settingsChangePasswordConfirm;

  /// No description provided for @settingsChangePasswordSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password changed, please log in again'**
  String get settingsChangePasswordSuccess;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authForgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password with an email code'**
  String get authForgotPasswordSubtitle;

  /// No description provided for @authSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get authSendCode;

  /// No description provided for @authResetPasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get authResetPasswordButton;

  /// No description provided for @authResetPasswordSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset, please log in with your new password'**
  String get authResetPasswordSuccess;

  /// No description provided for @authCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get authCodeLabel;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @languageZh.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get languageZh;

  /// No description provided for @languageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statsTitle;

  /// No description provided for @statsOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get statsOverview;

  /// No description provided for @statsTotalCards.
  ///
  /// In en, this message translates to:
  /// **'Total Cards'**
  String get statsTotalCards;

  /// No description provided for @statsTotalDecks.
  ///
  /// In en, this message translates to:
  /// **'Total Decks'**
  String get statsTotalDecks;

  /// No description provided for @statsDueToday.
  ///
  /// In en, this message translates to:
  /// **'Due Today'**
  String get statsDueToday;

  /// No description provided for @statsReviewedToday.
  ///
  /// In en, this message translates to:
  /// **'Reviewed Today'**
  String get statsReviewedToday;

  /// No description provided for @statsLearnedToday.
  ///
  /// In en, this message translates to:
  /// **'Learned Today'**
  String get statsLearnedToday;

  /// No description provided for @statsMastered.
  ///
  /// In en, this message translates to:
  /// **'Mastered'**
  String get statsMastered;

  /// No description provided for @statsLearning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get statsLearning;

  /// No description provided for @statsTrend.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get statsTrend;

  /// No description provided for @statsDeckStats.
  ///
  /// In en, this message translates to:
  /// **'Deck Statistics'**
  String get statsDeckStats;

  /// No description provided for @statsStageDistribution.
  ///
  /// In en, this message translates to:
  /// **'Stage Distribution'**
  String get statsStageDistribution;

  /// No description provided for @statsNewCards.
  ///
  /// In en, this message translates to:
  /// **'New Cards'**
  String get statsNewCards;

  /// No description provided for @cardListTitle.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get cardListTitle;

  /// No description provided for @cardListFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get cardListFilterAll;

  /// No description provided for @cardListFilterDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get cardListFilterDue;

  /// No description provided for @cardListFilterLearning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get cardListFilterLearning;

  /// No description provided for @cardListFilterNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get cardListFilterNew;

  /// No description provided for @cardListSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get cardListSearch;

  /// No description provided for @cardListBatchDelete.
  ///
  /// In en, this message translates to:
  /// **'Batch Delete'**
  String get cardListBatchDelete;

  /// No description provided for @cardListNoCards.
  ///
  /// In en, this message translates to:
  /// **'No cards'**
  String get cardListNoCards;

  /// No description provided for @cardListConfirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} card(s)?'**
  String cardListConfirmDelete(Object count);

  /// No description provided for @errorLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load, please check your network'**
  String get errorLoadFailed;

  /// No description provided for @errorSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save, please check your network'**
  String get errorSaveFailed;

  /// No description provided for @errorRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get errorRetry;

  /// No description provided for @themeIntervalRelearn.
  ///
  /// In en, this message translates to:
  /// **'Relearn'**
  String get themeIntervalRelearn;

  /// No description provided for @themeIntervalDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String themeIntervalDays(Object days);

  /// No description provided for @themeIntervalDay.
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get themeIntervalDay;

  /// No description provided for @themeStageNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get themeStageNew;

  /// No description provided for @cardImportFrontEmpty.
  ///
  /// In en, this message translates to:
  /// **'Front content cannot be empty'**
  String get cardImportFrontEmpty;

  /// No description provided for @cardImportFrontMustBeString.
  ///
  /// In en, this message translates to:
  /// **'Front content must be a string'**
  String get cardImportFrontMustBeString;

  /// No description provided for @cardImportBackEmpty.
  ///
  /// In en, this message translates to:
  /// **'Back content cannot be empty'**
  String get cardImportBackEmpty;

  /// No description provided for @cardImportBackMustBeString.
  ///
  /// In en, this message translates to:
  /// **'Back content must be a string'**
  String get cardImportBackMustBeString;

  /// No description provided for @cardImportCardMustBeObject.
  ///
  /// In en, this message translates to:
  /// **'Card must be an object'**
  String get cardImportCardMustBeObject;

  /// No description provided for @backendAuthRegisterSuccess.
  ///
  /// In en, this message translates to:
  /// **'Registration successful'**
  String get backendAuthRegisterSuccess;

  /// No description provided for @backendAuthLoginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Login successful'**
  String get backendAuthLoginSuccess;

  /// No description provided for @backendAuthLogoutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Logged out'**
  String get backendAuthLogoutSuccess;

  /// No description provided for @backendAuthInviteRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter invitation code'**
  String get backendAuthInviteRequired;

  /// No description provided for @backendAuthInviteInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid invitation code'**
  String get backendAuthInviteInvalid;

  /// No description provided for @backendAuthEmailRegistered.
  ///
  /// In en, this message translates to:
  /// **'Email already registered'**
  String get backendAuthEmailRegistered;

  /// No description provided for @backendAuthEmailPasswordWrong.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password'**
  String get backendAuthEmailPasswordWrong;

  /// No description provided for @backendAuthUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Not logged in or token expired'**
  String get backendAuthUnauthorized;

  /// No description provided for @backendDeckNotfound.
  ///
  /// In en, this message translates to:
  /// **'Deck not found'**
  String get backendDeckNotfound;

  /// No description provided for @backendDeckCreated.
  ///
  /// In en, this message translates to:
  /// **'Deck created'**
  String get backendDeckCreated;

  /// No description provided for @backendDeckUpdated.
  ///
  /// In en, this message translates to:
  /// **'Deck updated'**
  String get backendDeckUpdated;

  /// No description provided for @backendDeckDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deck deleted'**
  String get backendDeckDeleted;

  /// No description provided for @backendCardNotfound.
  ///
  /// In en, this message translates to:
  /// **'Card not found'**
  String get backendCardNotfound;

  /// No description provided for @backendCardCreated.
  ///
  /// In en, this message translates to:
  /// **'Card created'**
  String get backendCardCreated;

  /// No description provided for @backendCardUpdated.
  ///
  /// In en, this message translates to:
  /// **'Card updated'**
  String get backendCardUpdated;

  /// No description provided for @backendCardDeleted.
  ///
  /// In en, this message translates to:
  /// **'Card(s) deleted'**
  String get backendCardDeleted;

  /// No description provided for @backendCardIdListEmpty.
  ///
  /// In en, this message translates to:
  /// **'Card ID list cannot be empty'**
  String get backendCardIdListEmpty;

  /// No description provided for @backendCardSearchTooLong.
  ///
  /// In en, this message translates to:
  /// **'Search term cannot exceed 100 characters'**
  String get backendCardSearchTooLong;

  /// No description provided for @backendCardFrontEmpty.
  ///
  /// In en, this message translates to:
  /// **'Front content cannot be empty'**
  String get backendCardFrontEmpty;

  /// No description provided for @backendCardBackEmpty.
  ///
  /// In en, this message translates to:
  /// **'Back content cannot be empty'**
  String get backendCardBackEmpty;

  /// No description provided for @backendCardImportJsonEmpty.
  ///
  /// In en, this message translates to:
  /// **'JSON content cannot be empty'**
  String get backendCardImportJsonEmpty;

  /// No description provided for @backendCardImportJsonTooLarge.
  ///
  /// In en, this message translates to:
  /// **'JSON content too large, maximum 2MB'**
  String get backendCardImportJsonTooLarge;

  /// No description provided for @backendCardImportJsonInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid JSON format'**
  String get backendCardImportJsonInvalid;

  /// No description provided for @backendCardImportJsonMustBeArray.
  ///
  /// In en, this message translates to:
  /// **'JSON must be an array'**
  String get backendCardImportJsonMustBeArray;

  /// No description provided for @backendCardImportJsonArrayEmpty.
  ///
  /// In en, this message translates to:
  /// **'JSON array cannot be empty'**
  String get backendCardImportJsonArrayEmpty;

  /// No description provided for @backendCardImportTooMany.
  ///
  /// In en, this message translates to:
  /// **'Maximum {count} cards per import'**
  String backendCardImportTooMany(Object count);

  /// No description provided for @backendCardImportListEmpty.
  ///
  /// In en, this message translates to:
  /// **'Card list cannot be empty'**
  String get backendCardImportListEmpty;

  /// No description provided for @backendCardImportDataEmpty.
  ///
  /// In en, this message translates to:
  /// **'Card data cannot be empty'**
  String get backendCardImportDataEmpty;

  /// No description provided for @backendReviewSessionNotfound.
  ///
  /// In en, this message translates to:
  /// **'Review session not found'**
  String get backendReviewSessionNotfound;

  /// No description provided for @backendReviewSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Review session has expired'**
  String get backendReviewSessionExpired;

  /// No description provided for @backendReviewSessionClosed.
  ///
  /// In en, this message translates to:
  /// **'Review session closed'**
  String get backendReviewSessionClosed;

  /// No description provided for @backendReviewRatingInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid rating'**
  String get backendReviewRatingInvalid;

  /// No description provided for @backendReviewConflictRequest.
  ///
  /// In en, this message translates to:
  /// **'Request already processed, but card or rating mismatch'**
  String get backendReviewConflictRequest;

  /// No description provided for @backendReviewConflictVersion.
  ///
  /// In en, this message translates to:
  /// **'Card state has changed, please refresh and re-rate'**
  String get backendReviewConflictVersion;

  /// No description provided for @backendReviewCardNotfound.
  ///
  /// In en, this message translates to:
  /// **'Card not found'**
  String get backendReviewCardNotfound;

  /// No description provided for @backendSettingsNotfound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get backendSettingsNotfound;

  /// No description provided for @backendSettingsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Settings updated'**
  String get backendSettingsUpdated;

  /// No description provided for @backendStatsDeckNotfound.
  ///
  /// In en, this message translates to:
  /// **'Deck not found'**
  String get backendStatsDeckNotfound;

  /// No description provided for @backendBackupCreated.
  ///
  /// In en, this message translates to:
  /// **'Backup created'**
  String get backendBackupCreated;

  /// No description provided for @backendBackupDataEmpty.
  ///
  /// In en, this message translates to:
  /// **'Backup data cannot be empty'**
  String get backendBackupDataEmpty;

  /// No description provided for @backendBackupImported.
  ///
  /// In en, this message translates to:
  /// **'Data restored'**
  String get backendBackupImported;

  /// No description provided for @backendSyncUserNotfound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get backendSyncUserNotfound;

  /// No description provided for @backendServerError.
  ///
  /// In en, this message translates to:
  /// **'Internal server error'**
  String get backendServerError;

  /// No description provided for @backendServerResourceNotfound.
  ///
  /// In en, this message translates to:
  /// **'Resource not found'**
  String get backendServerResourceNotfound;

  /// No description provided for @settingsLogs.
  ///
  /// In en, this message translates to:
  /// **'Operation Logs'**
  String get settingsLogs;

  /// No description provided for @settingsLogsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View desensitized logs to diagnose issues'**
  String get settingsLogsSubtitle;

  /// No description provided for @logTitle.
  ///
  /// In en, this message translates to:
  /// **'Operation Logs'**
  String get logTitle;

  /// No description provided for @logFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get logFilterAll;

  /// No description provided for @logLevelInfo.
  ///
  /// In en, this message translates to:
  /// **'INFO'**
  String get logLevelInfo;

  /// No description provided for @logLevelWarn.
  ///
  /// In en, this message translates to:
  /// **'WARN'**
  String get logLevelWarn;

  /// No description provided for @logLevelError.
  ///
  /// In en, this message translates to:
  /// **'ERROR'**
  String get logLevelError;

  /// No description provided for @logCategoryAuth.
  ///
  /// In en, this message translates to:
  /// **'Auth'**
  String get logCategoryAuth;

  /// No description provided for @logCategoryReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get logCategoryReview;

  /// No description provided for @logCategoryCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get logCategoryCard;

  /// No description provided for @logCategoryDeck.
  ///
  /// In en, this message translates to:
  /// **'Deck'**
  String get logCategoryDeck;

  /// No description provided for @logCategoryBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get logCategoryBackup;

  /// No description provided for @logCategorySettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get logCategorySettings;

  /// No description provided for @logCategorySystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get logCategorySystem;

  /// No description provided for @logEmpty.
  ///
  /// In en, this message translates to:
  /// **'No logs yet'**
  String get logEmpty;

  /// No description provided for @logDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get logDetails;

  /// No description provided for @logNoMore.
  ///
  /// In en, this message translates to:
  /// **'No more logs'**
  String get logNoMore;

  /// No description provided for @logLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get logLoadMore;

  /// No description provided for @logLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get logLevel;

  /// No description provided for @logCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get logCategory;

  /// No description provided for @logTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get logTime;

  /// No description provided for @logMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get logMessage;

  /// No description provided for @logDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get logDiagnostics;
}

class _KarisReviewLocalizationsDelegate
    extends LocalizationsDelegate<KarisReviewLocalizations> {
  const _KarisReviewLocalizationsDelegate();

  @override
  Future<KarisReviewLocalizations> load(Locale locale) {
    return SynchronousFuture<KarisReviewLocalizations>(
      lookupKarisReviewLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_KarisReviewLocalizationsDelegate old) => false;
}

KarisReviewLocalizations lookupKarisReviewLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return KarisReviewLocalizationsEn();
    case 'zh':
      return KarisReviewLocalizationsZh();
  }

  throw FlutterError(
    'KarisReviewLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
