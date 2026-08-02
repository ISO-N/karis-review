import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../shared/widgets/adaptive_scaffold.dart';
import '../../shared/widgets/stage_ruler.dart';
import '../../shared/widgets/app_semantics.dart';

class DeckRow extends StatelessWidget {
  final String name;
  final int cardCount;
  final int dueCount;
  final int newCount;
  final List<int> stageDistribution;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const DeckRow({
    super.key,
    required this.name,
    required this.cardCount,
    required this.dueCount,
    required this.newCount,
    required this.stageDistribution,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  void _showActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: KarisColors.ink,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    KarisIconButton(
                      icon: Icons.close,
                      tooltip: '关闭',
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (onEdit != null)
                  _DeckActionTile(
                    icon: Icons.edit_outlined,
                    label: '重命名',
                    color: KarisColors.ink,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      onEdit?.call();
                    },
                  ),
                if (onEdit != null && onDelete != null)
                  const SizedBox(height: 10),
                if (onDelete != null)
                  _DeckActionTile(
                    icon: Icons.delete_outline,
                    label: '删除',
                    color: KarisColors.cinnabar,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      onDelete?.call();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final flag = name.trim().isEmpty
        ? '牌'
        : String.fromCharCode(name.trim().runes.first);
    return KarisInteractive(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: KarisColors.surface,
            border: Border.all(color: KarisColors.hairline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: KarisColors.jadeSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  flag,
                  style: const TextStyle(
                    color: KarisColors.jade,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: KarisColors.ink,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$cardCount 张 · 待复习 $dueCount',
                      style: karisMono(fontSize: 10, color: KarisColors.stone),
                    ),
                    const SizedBox(height: 7),
                    MiniStageRuler(distribution: stageDistribution),
                  ],
                ),
              ),
              if (onEdit != null || onDelete != null)
                KarisIconButton(
                  icon: Icons.more_horiz,
                  tooltip: '牌组操作',
                  color: KarisColors.stone,
                  onPressed: () => _showActions(context),
                )
              else
                const Icon(
                  Icons.chevron_right,
                  color: KarisColors.stone,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeckActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DeckActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return KarisInteractive(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: KarisColors.surface,
            border: Border.all(color: KarisColors.hairline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
