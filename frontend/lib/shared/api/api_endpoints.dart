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

  // Review
  static const String reviewDue = '$baseUrl/review/due';
  static const String reviewNew = '$baseUrl/review/new';
  static String rateCard(String cardId) => '$baseUrl/review/$cardId/rate';

  // Stats
  static const String statsOverview = '$baseUrl/stats/overview';
  static String statsDeck(String deckId) => '$baseUrl/stats/deck/$deckId';
  static const String statsTrend = '$baseUrl/stats/trend';

  // Backup
  static const String backupExport = '$baseUrl/backup/export';
  static const String backupImport = '$baseUrl/backup/import';
}
