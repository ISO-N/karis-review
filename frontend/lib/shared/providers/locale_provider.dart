import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  static const String _localeKey = 'app_locale';

  LocaleNotifier() : super(const Locale('zh')) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localeKey) ?? 'zh';
    state = Locale(code);
  }

  Future<void> setLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, languageCode);
    state = Locale(languageCode);
  }
}

/// Translate a backend message key using the generated AppLocalizations.
/// Falls back to the key itself if not found.
String trBackend(BuildContext context, String key, [Map<String, Object>? args]) {
  final loc = KarisReviewLocalizations.of(context);
  if (loc == null) return key;
  return _lookupBackendKey(loc, key, args);
}

String _lookupBackendKey(KarisReviewLocalizations loc, String key, [Map<String, Object>? args]) {
  // Map backend message keys to AppLocalizations getters
  // This is a centralized lookup for all backend messages
  switch (key) {
    case 'auth.register.success':
      return loc.backendAuthRegisterSuccess;
    case 'auth.login.success':
      return loc.backendAuthLoginSuccess;
    case 'auth.logout.success':
      return loc.backendAuthLogoutSuccess;
    case 'auth.invite.required':
      return loc.backendAuthInviteRequired;
    case 'auth.invite.invalid':
      return loc.backendAuthInviteInvalid;
    case 'auth.email.registered':
      return loc.backendAuthEmailRegistered;
    case 'auth.email.password.wrong':
      return loc.backendAuthEmailPasswordWrong;
    case 'auth.unauthorized':
      return loc.backendAuthUnauthorized;
    case 'deck.notfound':
      return loc.backendDeckNotfound;
    case 'deck.created':
      return loc.backendDeckCreated;
    case 'deck.updated':
      return loc.backendDeckUpdated;
    case 'deck.deleted':
      return loc.backendDeckDeleted;
    case 'card.notfound':
      return loc.backendCardNotfound;
    case 'card.created':
      return loc.backendCardCreated;
    case 'card.updated':
      return loc.backendCardUpdated;
    case 'card.deleted':
    case 'card.batch.deleted':
      return loc.backendCardDeleted;
    case 'card.id.list.empty':
      return loc.backendCardIdListEmpty;
    case 'card.search.too.long':
      return loc.backendCardSearchTooLong;
    case 'card.front.empty':
      return loc.backendCardFrontEmpty;
    case 'card.back.empty':
      return loc.backendCardBackEmpty;
    case 'card.import.json.empty':
      return loc.backendCardImportJsonEmpty;
    case 'card.import.json.too.large':
      return loc.backendCardImportJsonTooLarge;
    case 'card.import.json.invalid':
      return loc.backendCardImportJsonInvalid;
    case 'card.import.json.must.be.array':
      return loc.backendCardImportJsonMustBeArray;
    case 'card.import.json.array.empty':
      return loc.backendCardImportJsonArrayEmpty;
    case 'card.import.too.many':
      return loc.backendCardImportTooMany(args?['count'] ?? 0);
    case 'card.import.list.empty':
      return loc.backendCardImportListEmpty;
    case 'card.import.data.empty':
      return loc.backendCardImportDataEmpty;
    case 'card.import.front.empty':
      return loc.cardImportFrontEmpty;
    case 'card.import.front.must.be.string':
      return loc.cardImportFrontMustBeString;
    case 'card.import.back.empty':
      return loc.cardImportBackEmpty;
    case 'card.import.back.must.be.string':
      return loc.cardImportBackMustBeString;
    case 'card.import.must.be.object':
      return loc.cardImportCardMustBeObject;
    case 'review.session.notfound':
      return loc.backendReviewSessionNotfound;
    case 'review.session.expired':
      return loc.backendReviewSessionExpired;
    case 'review.session.closed':
      return loc.backendReviewSessionClosed;
    case 'review.rating.invalid':
      return loc.backendReviewRatingInvalid;
    case 'review.conflict.request':
      return loc.backendReviewConflictRequest;
    case 'review.conflict.version':
      return loc.backendReviewConflictVersion;
    case 'review.card.notfound':
      return loc.backendReviewCardNotfound;
    case 'settings.notfound':
      return loc.backendSettingsNotfound;
    case 'settings.updated':
      return loc.backendSettingsUpdated;
    case 'stats.deck.notfound':
      return loc.backendStatsDeckNotfound;
    case 'backup.created':
      return loc.backendBackupCreated;
    case 'backup.data.empty':
      return loc.backendBackupDataEmpty;
    case 'backup.imported':
      return loc.backendBackupImported;
    case 'sync.user.notfound':
      return loc.backendSyncUserNotfound;
    case 'server.error':
      return loc.backendServerError;
    case 'server.resource.notfound':
      return loc.backendServerResourceNotfound;
    default:
      return key;
  }
}