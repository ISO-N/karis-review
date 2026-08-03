class CardImportResult {
  final int importedCards;
  final List<String> importedCardIds;

  const CardImportResult({
    required this.importedCards,
    this.importedCardIds = const [],
  });

  factory CardImportResult.fromJson(Map<String, dynamic> json) {
    return CardImportResult(
      importedCards: (json['imported_cards'] as num?)?.toInt() ?? 0,
      importedCardIds: (json['imported_card_ids'] as List<dynamic>? ?? const [])
          .map((id) => id.toString())
          .toList(),
    );
  }
}

class CardImportPreviewItem {
  final int index;
  final String front;
  final String back;
  final bool valid;
  final String? message;

  const CardImportPreviewItem({
    required this.index,
    required this.front,
    required this.back,
    required this.valid,
    this.message,
  });

  factory CardImportPreviewItem.fromJson(Map<String, dynamic> json) {
    return CardImportPreviewItem(
      index: (json['index'] as num?)?.toInt() ?? 0,
      front: json['front'] as String? ?? '',
      back: json['back'] as String? ?? '',
      valid: json['valid'] as bool? ?? false,
      message: json['message'] as String?,
    );
  }

  CardImportPreviewItem copyWith({
    String? front,
    String? back,
    bool? valid,
    String? message,
    bool clearMessage = false,
  }) {
    return CardImportPreviewItem(
      index: index,
      front: front ?? this.front,
      back: back ?? this.back,
      valid: valid ?? this.valid,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}
