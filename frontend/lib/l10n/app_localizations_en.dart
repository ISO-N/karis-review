// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class KarisReviewLocalizationsEn extends KarisReviewLocalizations {
  KarisReviewLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Karis Review';

  @override
  String get navHome => 'Home';

  @override
  String get navDecks => 'Decks';

  @override
  String get navStats => 'Stats';

  @override
  String get navSettings => 'Settings';

  @override
  String get authLoginTitle => 'Login';

  @override
  String get authLoginSubtitle => 'Login to start today\'s review';

  @override
  String get authRegisterSubtitle => 'A focused spaced repetition review space';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authInviteCodeLabel => 'Invitation Code';

  @override
  String get authLoginButton => 'Login';

  @override
  String get authRegisterButton => 'Register';

  @override
  String get authNoAccount => 'Don\'t have an account?';

  @override
  String get authHasAccount => 'Already have an account?';

  @override
  String get authRegisterLink => 'Register';

  @override
  String get authLoginLink => 'Login';

  @override
  String get homeTitle => 'Home';

  @override
  String get homeTodayReview => 'Due Today';

  @override
  String homeReviewedProgress(Object reviewed, Object due) {
    return 'Reviewed $reviewed · $due remaining';
  }

  @override
  String get homeNoCards => 'No cards due today';

  @override
  String get homeNoDecksTitle => 'No decks yet';

  @override
  String get homeNoDecksMessage => 'Create your first deck to start reviewing';

  @override
  String get homeCreateDeck => 'Create Deck';

  @override
  String get deckListTitle => 'All Decks';

  @override
  String get deckCreateTitle => 'New Deck';

  @override
  String get deckRenameTitle => 'Rename Deck';

  @override
  String get deckNameLabel => 'Deck Name';

  @override
  String get deckNameHint => 'e.g. Japanese N5';

  @override
  String get deckCancel => 'Cancel';

  @override
  String get deckCreateButton => 'Create';

  @override
  String get deckSaveButton => 'Save';

  @override
  String get deckDeleteTitle => 'Delete Deck';

  @override
  String deckDeleteConfirm(Object name) {
    return 'Are you sure you want to delete \"$name\"? All cards and review records in this deck will also be deleted.';
  }

  @override
  String get deckDeleteConfirmButton => 'Delete';

  @override
  String get deckDeleteCancel => 'Cancel';

  @override
  String deckStats(Object count, Object due) {
    return '$count cards · $due due';
  }

  @override
  String get deckOperationTooltip => 'Deck operations';

  @override
  String get deckCloseTooltip => 'Close';

  @override
  String get deckRenameLabel => 'Rename';

  @override
  String get deckDeleteLabel => 'Delete';

  @override
  String get deckCardCount => 'c';

  @override
  String get reviewModeNew => 'Learning Mode';

  @override
  String get reviewModeDue => 'Review Mode';

  @override
  String get reviewLoadError => 'Failed to load queue';

  @override
  String get reviewRetry => 'Retry';

  @override
  String get reviewNoNewCards => 'No new cards';

  @override
  String get reviewNoDueCards => 'No cards due';

  @override
  String get reviewAllNewDone => 'All new cards have entered the review queue';

  @override
  String get reviewNoDueMessage =>
      'No cards are due in the current scope, take a break';

  @override
  String get reviewBackToday => 'Back to Today';

  @override
  String get reviewRatingForget => 'Forget';

  @override
  String get reviewRatingVague => 'Vague';

  @override
  String get reviewRatingFamiliar => 'Familiar';

  @override
  String get reviewRatingContinue => 'Continue';

  @override
  String get reviewRatingRelearn => 'Relearn';

  @override
  String reviewRated(Object label, Object interval) {
    return 'Rated: $label · Next $interval';
  }

  @override
  String reviewRatedTitle(Object label) {
    return 'Rated $label';
  }

  @override
  String reviewRatedDetail(Object interval) {
    return 'Next $interval';
  }

  @override
  String get reviewQueue => 'Queue';

  @override
  String get reviewLoadingMore => 'Loading more cards';

  @override
  String reviewOfflinePending(Object count) {
    return 'Offline · $count rating(s) pending sync';
  }

  @override
  String get reviewCardFrontHint => 'Flashcard, tap to show answer';

  @override
  String get reviewCardBackHint => 'Flashcard, tap to show question';

  @override
  String get reviewSessionCompleteNew => 'Learning session complete';

  @override
  String get reviewSessionCompleteDue => 'Today\'s review complete';

  @override
  String reviewSessionStats(Object total, Object reviewed) {
    return '$total cards · $reviewed reviewed';
  }

  @override
  String get reviewErrorQueueFailed =>
      'Failed to load queue, please check your network';

  @override
  String get reviewErrorRatingFailed =>
      'Rating failed, please check your network';

  @override
  String get startModeNew => 'Start Learning';

  @override
  String get startModeDue => 'Start Review';

  @override
  String get startNoDecksTitle => 'No decks yet';

  @override
  String get startNoDecksMessage => 'Create a deck first, then start learning';

  @override
  String get startCreateDeck => 'Create Deck';

  @override
  String startBadgeNew(Object count) {
    return '$count new';
  }

  @override
  String startBadgeDue(Object count) {
    return '$count due';
  }

  @override
  String get startFilterDue => 'Due';

  @override
  String get cardEditorKicker => 'Card';

  @override
  String get cardEditorTitleNew => 'New Card';

  @override
  String get cardEditorTitleEdit => 'Edit Card';

  @override
  String get cardEditorFront => 'Front';

  @override
  String get cardEditorBack => 'Back';

  @override
  String get cardEditorSave => 'Save';

  @override
  String get cardEditorDelete => 'Delete';

  @override
  String get cardEditorCancel => 'Cancel';

  @override
  String get cardImportTitle => 'Import Cards';

  @override
  String get cardImportPasteJson => 'Paste JSON or select .json file';

  @override
  String get cardImportSelectFile => 'Select File';

  @override
  String get cardImportParse => 'Parse';

  @override
  String get cardImportImport => 'Import';

  @override
  String get cardImportCancel => 'Cancel';

  @override
  String get cardImportPreview => 'Preview';

  @override
  String get cardImportValid => 'Valid';

  @override
  String get cardImportInvalid => 'Invalid';

  @override
  String get cardImportError => 'Error';

  @override
  String get cardImportRow => 'Row';

  @override
  String get cardImportUndo => 'Undo Import';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsEmail => 'Email';

  @override
  String get settingsReview => 'Review Settings';

  @override
  String get settingsRefreshTime => 'Daily Refresh Time';

  @override
  String get settingsRefreshSubtitle => 'Past this time, a new day begins';

  @override
  String get settingsData => 'Data Management';

  @override
  String get settingsExport => 'Export Data';

  @override
  String get settingsExportSubtitle =>
      'Save all decks, cards, and review records';

  @override
  String get settingsImport => 'Import Data';

  @override
  String get settingsImportSubtitle => 'Restore from backup file (overwrites)';

  @override
  String get settingsForceServer => 'Use Server Data';

  @override
  String get settingsForceServerSubtitle =>
      'Discard pending sync ratings and re-fetch from server';

  @override
  String get settingsForceServerTitle => 'Use Server Data';

  @override
  String get settingsForceServerContent =>
      'This will discard all unsynced offline ratings and overwrite local data with server data. Continue?';

  @override
  String get settingsForceServerConfirm => 'Overwrite';

  @override
  String get settingsForceServerCancel => 'Cancel';

  @override
  String get settingsImportTitle => 'Import Data';

  @override
  String get settingsImportContent =>
      'Importing will overwrite all current data. This operation is irreversible. Continue?';

  @override
  String get settingsImportConfirm => 'Import';

  @override
  String get settingsImportCancel => 'Cancel';

  @override
  String settingsImportSuccess(Object decks, Object cards, Object logs) {
    return 'Data restored: $decks decks, $cards cards, $logs records';
  }

  @override
  String get settingsExportFail => 'Export failed, please check your network';

  @override
  String get settingsImportFail =>
      'Import failed, please check your network or backup file';

  @override
  String get settingsImportReadFail =>
      'Failed to read backup file, please check the file format';

  @override
  String get settingsSyncFail => 'Sync failed, please check your network';

  @override
  String get settingsLogout => 'Logout';

  @override
  String get settingsChangePassword => 'Change Password';

  @override
  String get settingsChangePasswordSubtitle => 'Update your login password';

  @override
  String get settingsChangePasswordTitle => 'Change Password';

  @override
  String get settingsCurrentPasswordLabel => 'Current Password';

  @override
  String get settingsNewPasswordLabel => 'New Password';

  @override
  String get settingsConfirmPasswordLabel => 'Confirm New Password';

  @override
  String get settingsNewPasswordShort =>
      'Password must be at least 6 characters';

  @override
  String get settingsPasswordMismatch => 'Passwords do not match';

  @override
  String get settingsChangePasswordConfirm => 'Change';

  @override
  String get settingsChangePasswordSuccess =>
      'Password changed, please log in again';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authForgotPasswordSubtitle =>
      'Reset your password with an email code';

  @override
  String get authSendCode => 'Send Code';

  @override
  String get authResetPasswordButton => 'Reset Password';

  @override
  String get authResetPasswordSuccess =>
      'Password reset, please log in with your new password';

  @override
  String get authCodeLabel => 'Verification Code';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageZh => '中文';

  @override
  String get languageEn => 'English';

  @override
  String get statsTitle => 'Statistics';

  @override
  String get statsOverview => 'Overview';

  @override
  String get statsTotalCards => 'Total Cards';

  @override
  String get statsTotalDecks => 'Total Decks';

  @override
  String get statsDueToday => 'Due Today';

  @override
  String get statsReviewedToday => 'Reviewed Today';

  @override
  String get statsLearnedToday => 'Learned Today';

  @override
  String get statsMastered => 'Mastered';

  @override
  String get statsLearning => 'Learning';

  @override
  String get statsTrend => 'Trend';

  @override
  String get statsDeckStats => 'Deck Statistics';

  @override
  String get statsStageDistribution => 'Stage Distribution';

  @override
  String get statsNewCards => 'New Cards';

  @override
  String get cardListTitle => 'Cards';

  @override
  String get cardListFilterAll => 'All';

  @override
  String get cardListFilterDue => 'Due';

  @override
  String get cardListFilterLearning => 'Learning';

  @override
  String get cardListFilterNew => 'New';

  @override
  String get cardListSearch => 'Search';

  @override
  String get cardListBatchDelete => 'Batch Delete';

  @override
  String get cardListNoCards => 'No cards';

  @override
  String cardListConfirmDelete(Object count) {
    return 'Delete $count card(s)?';
  }

  @override
  String get errorLoadFailed => 'Failed to load, please check your network';

  @override
  String get errorSaveFailed => 'Failed to save, please check your network';

  @override
  String get errorRetry => 'Retry';

  @override
  String get themeIntervalRelearn => 'Relearn';

  @override
  String themeIntervalDays(Object days) {
    return '$days days';
  }

  @override
  String get themeIntervalDay => '1 day';

  @override
  String get themeStageNew => 'New';

  @override
  String get cardImportFrontEmpty => 'Front content cannot be empty';

  @override
  String get cardImportFrontMustBeString => 'Front content must be a string';

  @override
  String get cardImportBackEmpty => 'Back content cannot be empty';

  @override
  String get cardImportBackMustBeString => 'Back content must be a string';

  @override
  String get cardImportCardMustBeObject => 'Card must be an object';

  @override
  String get backendAuthRegisterSuccess => 'Registration successful';

  @override
  String get backendAuthLoginSuccess => 'Login successful';

  @override
  String get backendAuthLogoutSuccess => 'Logged out';

  @override
  String get backendAuthInviteRequired => 'Please enter invitation code';

  @override
  String get backendAuthInviteInvalid => 'Invalid invitation code';

  @override
  String get backendAuthEmailRegistered => 'Email already registered';

  @override
  String get backendAuthEmailPasswordWrong => 'Incorrect email or password';

  @override
  String get backendAuthUnauthorized => 'Not logged in or token expired';

  @override
  String get backendDeckNotfound => 'Deck not found';

  @override
  String get backendDeckCreated => 'Deck created';

  @override
  String get backendDeckUpdated => 'Deck updated';

  @override
  String get backendDeckDeleted => 'Deck deleted';

  @override
  String get backendCardNotfound => 'Card not found';

  @override
  String get backendCardCreated => 'Card created';

  @override
  String get backendCardUpdated => 'Card updated';

  @override
  String get backendCardDeleted => 'Card(s) deleted';

  @override
  String get backendCardIdListEmpty => 'Card ID list cannot be empty';

  @override
  String get backendCardSearchTooLong =>
      'Search term cannot exceed 100 characters';

  @override
  String get backendCardFrontEmpty => 'Front content cannot be empty';

  @override
  String get backendCardBackEmpty => 'Back content cannot be empty';

  @override
  String get backendCardImportJsonEmpty => 'JSON content cannot be empty';

  @override
  String get backendCardImportJsonTooLarge =>
      'JSON content too large, maximum 2MB';

  @override
  String get backendCardImportJsonInvalid => 'Invalid JSON format';

  @override
  String get backendCardImportJsonMustBeArray => 'JSON must be an array';

  @override
  String get backendCardImportJsonArrayEmpty => 'JSON array cannot be empty';

  @override
  String backendCardImportTooMany(Object count) {
    return 'Maximum $count cards per import';
  }

  @override
  String get backendCardImportListEmpty => 'Card list cannot be empty';

  @override
  String get backendCardImportDataEmpty => 'Card data cannot be empty';

  @override
  String get backendReviewSessionNotfound => 'Review session not found';

  @override
  String get backendReviewSessionExpired => 'Review session has expired';

  @override
  String get backendReviewSessionClosed => 'Review session closed';

  @override
  String get backendReviewRatingInvalid => 'Invalid rating';

  @override
  String get backendReviewConflictRequest =>
      'Request already processed, but card or rating mismatch';

  @override
  String get backendReviewConflictVersion =>
      'Card state has changed, please refresh and re-rate';

  @override
  String get backendReviewCardNotfound => 'Card not found';

  @override
  String get backendSettingsNotfound => 'User not found';

  @override
  String get backendSettingsUpdated => 'Settings updated';

  @override
  String get backendStatsDeckNotfound => 'Deck not found';

  @override
  String get backendBackupCreated => 'Backup created';

  @override
  String get backendBackupDataEmpty => 'Backup data cannot be empty';

  @override
  String get backendBackupImported => 'Data restored';

  @override
  String get backendSyncUserNotfound => 'User not found';

  @override
  String get backendServerError => 'Internal server error';

  @override
  String get backendServerResourceNotfound => 'Resource not found';

  @override
  String get settingsLogs => 'Operation Logs';

  @override
  String get settingsLogsSubtitle =>
      'View desensitized logs to diagnose issues';

  @override
  String get logTitle => 'Operation Logs';

  @override
  String get logFilterAll => 'All';

  @override
  String get logLevelInfo => 'INFO';

  @override
  String get logLevelWarn => 'WARN';

  @override
  String get logLevelError => 'ERROR';

  @override
  String get logCategoryAuth => 'Auth';

  @override
  String get logCategoryReview => 'Review';

  @override
  String get logCategoryCard => 'Card';

  @override
  String get logCategoryDeck => 'Deck';

  @override
  String get logCategoryBackup => 'Backup';

  @override
  String get logCategorySettings => 'Settings';

  @override
  String get logCategorySystem => 'System';

  @override
  String get logEmpty => 'No logs yet';

  @override
  String get logDetails => 'Details';

  @override
  String get logNoMore => 'No more logs';

  @override
  String get logLoadMore => 'Load more';

  @override
  String get logLevel => 'Level';

  @override
  String get logCategory => 'Category';

  @override
  String get logTime => 'Time';

  @override
  String get logMessage => 'Message';

  @override
  String get logDiagnostics => 'Diagnostics';
}
