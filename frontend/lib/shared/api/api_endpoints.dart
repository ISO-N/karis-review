class ApiEndpoints {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api',
  );

  // Auth
  static const String register = '$baseUrl/auth/register';
  static const String login = '$baseUrl/auth/login';
  static const String logout = '$baseUrl/auth/logout';

  // Settings
  static const String settings = '$baseUrl/settings';

  // Decks
  static const String decks = '$baseUrl/decks';
  static String deck(String id) => '$baseUrl/decks/$id';

  // Cards
  static String deckCards(String deckId) => '$baseUrl/decks/$deckId/cards';
  static String card(String cardId) => '$baseUrl/cards/$cardId';
  static String cardImportPreview(String deckId) =>
      '$baseUrl/decks/$deckId/cards/import/preview';
  static String cardImport(String deckId) =>
      '$baseUrl/decks/$deckId/cards/import';

  // Review
  static const String reviewDue = '$baseUrl/review/due';
  static const String reviewNew = '$baseUrl/review/new';
  static String rateCard(String cardId) => '$baseUrl/review/$cardId/rate';
  static const String reviewSessions = '$baseUrl/review/sessions';
  static String reviewSession(String sessionId) => '$baseUrl/review/sessions/$sessionId';
  static const String reviewSync = '$baseUrl/review/sync';

  // Offline sync
  static const String syncBootstrap = '$baseUrl/sync/bootstrap';
  // Stats
  static const String statsOverview = '$baseUrl/stats/overview';
  static String statsDeck(String deckId) => '$baseUrl/stats/deck/$deckId';
  static const String statsTrend = '$baseUrl/stats/trend';

  // Backup
  static const String backupExport = '$baseUrl/backup/export';
  static const String backupImport = '$baseUrl/backup/import';
}
