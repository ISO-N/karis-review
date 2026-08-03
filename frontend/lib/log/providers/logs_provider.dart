import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/logs_repository.dart';

class LogEntry {
  final String id;
  final String level;
  final String category;
  final String message;
  final Map<String, dynamic>? details;
  final String createdAt;

  const LogEntry({
    required this.id,
    required this.level,
    required this.category,
    required this.message,
    this.details,
    required this.createdAt,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      id: json['id'] as String? ?? '',
      level: json['level'] as String? ?? 'INFO',
      category: json['category'] as String? ?? '',
      message: json['message'] as String? ?? '',
      details: json['details'] as Map<String, dynamic>?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class LogsState {
  final List<LogEntry> logs;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final String? levelFilter;
  final String? categoryFilter;
  final String? error;

  const LogsState({
    this.logs = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 0,
    this.levelFilter,
    this.categoryFilter,
    this.error,
  });

  LogsState copyWith({
    List<LogEntry>? logs,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? levelFilter,
    String? categoryFilter,
    String? error,
  }) {
    return LogsState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      levelFilter: levelFilter,
      categoryFilter: categoryFilter,
      error: error,
    );
  }
}

class LogsNotifier extends StateNotifier<LogsState> {
  final LogsRepository _repository;

  LogsNotifier(this._repository) : super(const LogsState());

  Future<void> loadLogs() async {
    state = state.copyWith(isLoading: true, logs: [], page: 0, hasMore: true, error: null);
    try {
      final data = await _repository.getLogs(
        page: 0,
        size: 50,
        level: state.levelFilter,
        category: state.categoryFilter,
      );
      final content = (data['content'] as List<dynamic>?) ?? [];
      final logs = content.map((e) => LogEntry.fromJson(e as Map<String, dynamic>)).toList();
      final totalPages = data['total_pages'] as int? ?? 0;
      final currentPage = data['page'] as int? ?? 0;
      state = state.copyWith(
        logs: logs,
        isLoading: false,
        hasMore: currentPage + 1 < totalPages,
        page: currentPage,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.page + 1;
      final data = await _repository.getLogs(
        page: nextPage,
        size: 50,
        level: state.levelFilter,
        category: state.categoryFilter,
      );
      final content = (data['content'] as List<dynamic>?) ?? [];
      final newLogs = content.map((e) => LogEntry.fromJson(e as Map<String, dynamic>)).toList();
      final totalPages = data['total_pages'] as int? ?? 0;
      state = state.copyWith(
        logs: [...state.logs, ...newLogs],
        isLoadingMore: false,
        hasMore: nextPage + 1 < totalPages,
        page: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  void setLevelFilter(String? level) {
    state = state.copyWith(levelFilter: level);
    loadLogs();
  }

  void setCategoryFilter(String? category) {
    state = state.copyWith(categoryFilter: category);
    loadLogs();
  }
}

final logsProvider = StateNotifierProvider<LogsNotifier, LogsState>((ref) {
  return LogsNotifier(LogsRepository());
});