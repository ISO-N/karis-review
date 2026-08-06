import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/loading_widget.dart';
import '../providers/logs_provider.dart';

class LogsPage extends ConsumerStatefulWidget {
  const LogsPage({super.key});

  @override
  ConsumerState<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends ConsumerState<LogsPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() => ref.read(logsProvider.notifier).loadLogs());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(logsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = KarisReviewLocalizations.of(context)!;
    final state = ref.watch(logsProvider);
    final colors = context.karisColors;

    return Scaffold(
      backgroundColor: colors.paper,
      appBar: AppBar(
        backgroundColor: colors.surface,
        surfaceTintColor: colors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => context.go('/settings'),
        ),
        title: Text(
          l10n.logTitle,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colors.ink,
            letterSpacing: 0,
          ),
        ),
      ),
      body: Column(
        children: [
          _FilterBar(
            selectedLevel: state.levelFilter,
            selectedCategory: state.categoryFilter,
            onLevelChanged: (v) => ref.read(logsProvider.notifier).setLevelFilter(v),
            onCategoryChanged: (v) => ref.read(logsProvider.notifier).setCategoryFilter(v),
            l10n: l10n,
          ),
          Divider(height: 1, color: colors.hairline),
          Expanded(
            child: _buildLogList(state, l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList(LogsState state, KarisReviewLocalizations l10n) {
    final colors = context.karisColors;
    if (state.isLoading) {
      return const LoadingWidget();
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 36, color: colors.cinnabar),
              const SizedBox(height: 12),
              Text(
                state.error!,
                style: TextStyle(color: colors.stone, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ref.read(logsProvider.notifier).loadLogs(),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.logs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: colors.jadeSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.terminal, color: colors.jade, size: 26),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.logEmpty,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.ink,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      itemCount: state.logs.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.logs.length) {
          if (state.isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: LoadingWidget(),
            );
          }
          return const SizedBox.shrink();
        }
        return _LogTile(entry: state.logs[index]);
      },
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String? selectedLevel;
  final String? selectedCategory;
  final ValueChanged<String?> onLevelChanged;
  final ValueChanged<String?> onCategoryChanged;
  final KarisReviewLocalizations l10n;

  const _FilterBar({
    required this.selectedLevel,
    required this.selectedCategory,
    required this.onLevelChanged,
    required this.onCategoryChanged,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.karisColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: colors.surface,
      child: Row(
        children: [
          Expanded(
            child: _DropdownFilter(
              label: l10n.logLevel,
              value: selectedLevel,
              items: const [
                DropdownItem(null, 'All'),
                DropdownItem('INFO', 'INFO'),
                DropdownItem('WARN', 'WARN'),
                DropdownItem('ERROR', 'ERROR'),
              ],
              onChanged: onLevelChanged,
              l10n: l10n,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _DropdownFilter(
              label: l10n.logCategory,
              value: selectedCategory,
              items: const [
                DropdownItem(null, 'All'),
                DropdownItem('AUTH', 'Auth'),
                DropdownItem('REVIEW', 'Review'),
                DropdownItem('CARD', 'Card'),
                DropdownItem('DECK', 'Deck'),
                DropdownItem('BACKUP', 'Backup'),
                DropdownItem('SETTINGS', 'Settings'),
                DropdownItem('SYSTEM', 'System'),
              ],
              onChanged: onCategoryChanged,
              l10n: l10n,
            ),
          ),
        ],
      ),
    );
  }
}

class DropdownItem {
  final String? value;
  final String label;
  const DropdownItem(this.value, this.label);
}

class _DropdownFilter extends StatelessWidget {
  final String label;
  final String? value;
  final List<DropdownItem> items;
  final ValueChanged<String?> onChanged;
  final KarisReviewLocalizations l10n;

  const _DropdownFilter({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.karisColors;
    return DropdownButtonFormField<String?>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 12, color: colors.stone),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: colors.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: colors.hairline),
        ),
        isDense: true,
      ),
      items: items.map((item) {
        return DropdownMenuItem<String?>(
          value: item.value,
          child: Text(
            item.label,
            style: TextStyle(fontSize: 13, color: colors.ink),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      style: TextStyle(fontSize: 13, color: colors.ink),
    );
  }
}

class _LogTile extends StatefulWidget {
  final LogEntry entry;

  const _LogTile({required this.entry});

  @override
  State<_LogTile> createState() => _LogTileState();
}

class _LogTileState extends State<_LogTile> {
  bool _expanded = false;

  Color _levelColor() {
    switch (widget.entry.level) {
      case 'ERROR':
        return context.karisColors.cinnabar;
      case 'WARN':
        return const Color(0xFFD4A72C);
      default:
        return context.karisColors.jade;
    }
  }

  Color _levelBgColor() {
    switch (widget.entry.level) {
      case 'ERROR':
        return context.karisColors.cinnabarSoft;
      case 'WARN':
        return const Color(0xFFFFF3CD);
      default:
        return context.karisColors.jadeSoft;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.karisColors;
    final entry = widget.entry;
    final hasDetails = entry.details != null && entry.details!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: hasDetails ? () => setState(() => _expanded = !_expanded) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colors.hairline, width: 0.5),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _levelBgColor(),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    entry.level,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _levelColor(),
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.jadeSoft,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    entry.category,
                    style: karisMono(
                      fontSize: 10,
                      color: colors.jade,
                      weight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.ink,
                          letterSpacing: 0,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(entry.createdAt),
                        style: karisMono(fontSize: 10, color: colors.stone),
                      ),
                    ],
                  ),
                ),
                if (hasDetails)
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: colors.stone,
                  ),
              ],
            ),
          ),
        ),
        if (_expanded && hasDetails)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(
                bottom: BorderSide(color: colors.hairline, width: 0.5),
              ),
            ),
            child: Text(
              const JsonEncoder.withIndent('  ').convert(entry.details),
              style: karisMono(fontSize: 11, color: colors.stone),
            ),
          ),
      ],
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final local = dt.toLocal();
      final h = local.hour.toString().padLeft(2, '0');
      final m = local.minute.toString().padLeft(2, '0');
      final s = local.second.toString().padLeft(2, '0');
      return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} $h:$m:$s';
    } catch (_) {
      return iso;
    }
  }
}