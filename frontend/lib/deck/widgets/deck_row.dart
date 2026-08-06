import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../shared/widgets/adaptive_scaffold.dart';
import '../../shared/widgets/stage_ruler.dart';
import '../../shared/widgets/app_semantics.dart';

import '../../l10n/app_localizations.dart';
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
    final colors = context.karisColors;
    final l10n = KarisReviewLocalizations.of(context)!;
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
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.ink,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    KarisIconButton(
                      icon: Icons.close,
                      tooltip: l10n.deckCloseTooltip,
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                SizedBox(height: 14),
                if (onEdit != null)
                  _DeckActionTile(
                    icon: Icons.edit_outlined,
                    label: l10n.deckRenameLabel,
                    color: colors.ink,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      onEdit?.call();
                    },
                  ),
                if (onEdit != null && onDelete != null)
                  SizedBox(height: 10),
                if (onDelete != null)
                  _DeckActionTile(
                    icon: Icons.delete_outline,
                    label: l10n.deckDeleteLabel,
                    color: colors.cinnabar,
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
    final colors = context.karisColors;
    final l10n = KarisReviewLocalizations.of(context)!;
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
            color: colors.surface,
            border: Border.all(color: colors.hairline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.jadeSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  flag,
                  style: TextStyle(
                    color: colors.jade,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.ink,
                        letterSpacing: 0,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '$cardCount 张 · 待复习 $dueCount',
                      style: karisMono(fontSize: 10, color: colors.stone),
                    ),
                    SizedBox(height: 7),
                    MiniStageRuler(distribution: stageDistribution),
                  ],
                ),
              ),
              if (onEdit != null || onDelete != null)
                KarisIconButton(
                  icon: Icons.more_horiz,
                  tooltip: l10n.deckOperationTooltip,
                  color: colors.stone,
                  onPressed: () => _showActions(context),
                )
              else
                Icon(
                  Icons.chevron_right,
                  color: colors.stone,
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
    final colors = context.karisColors;
    return KarisInteractive(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.hairline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              SizedBox(width: 12),
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
