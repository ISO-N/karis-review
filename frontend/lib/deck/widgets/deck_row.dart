import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../shared/widgets/stage_ruler.dart';

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

  @override
  Widget build(BuildContext context) {
    final flag = name.trim().isEmpty
        ? '牌'
        : String.fromCharCode(name.trim().runes.first);
    return InkWell(
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
              PopupMenuButton<String>(
                tooltip: '牌组操作',
                icon: const Icon(
                  Icons.more_horiz,
                  color: KarisColors.stone,
                  size: 18,
                ),
                onSelected: (value) {
                  if (value == 'edit') onEdit?.call();
                  if (value == 'delete') onDelete?.call();
                },
                itemBuilder: (context) => [
                  if (onEdit != null)
                    const PopupMenuItem(value: 'edit', child: Text('重命名')),
                  if (onDelete != null)
                    const PopupMenuItem(value: 'delete', child: Text('删除')),
                ],
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
    );
  }
}
