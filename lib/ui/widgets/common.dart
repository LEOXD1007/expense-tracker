import 'package:flutter/material.dart';

import '../../core/dates.dart';
import '../../core/money.dart';
import '../../domain/models/budget_level.dart';
import '../../domain/models/entry_type.dart';
import '../../domain/models/monthly_stats.dart';
import '../../domain/services/budget_alert_planner.dart';
import '../icons/category_icons.dart';
import '../theme/app_theme.dart';

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(22);
    return Material(
      color: scheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({
    super.key,
    required this.month,
    required this.onShift,
  });

  final DateTime month;
  final ValueChanged<int> onShift;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: '上个月',
          onPressed: () => onShift(-1),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Text(
          formatYearMonth(month),
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        IconButton(
          tooltip: '下个月',
          onPressed: () => onShift(1),
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.stats,
    this.totalBudget,
  });

  final MonthlyStats stats;
  final BudgetProgress? totalBudget;

  @override
  Widget build(BuildContext context) {
    final balance = stats.balanceCents;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [AppColors.jadeDeep, Color(0xFF15956F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '本月结余',
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            Money.format(balance),
            key: const Key('month-balance'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Pill(
                  label: '收入',
                  value: Money.format(stats.incomeCents),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Pill(
                  label: '支出',
                  value: Money.format(stats.expenseCents),
                ),
              ),
            ],
          ),
          if (totalBudget != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: totalBudget!.barValue,
                minHeight: 6,
                backgroundColor: Colors.white24,
                color: totalBudget!.level == BudgetLevel.exceeded
                    ? const Color(0xFFFFD0C8)
                    : Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '预算已用 ${totalBudget!.percent}% · ${Money.format(totalBudget!.spentCents)} / ${Money.format(totalBudget!.budget.amountCents)}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class BudgetBanner extends StatelessWidget {
  const BudgetBanner({super.key, required this.alerts});

  final List<BudgetAlert> alerts;

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();
    final exceeded = alerts.any((alert) => alert.level == BudgetLevel.exceeded);
    final color = exceeded ? AppColors.expense : AppColors.warning;
    final visible = alerts.take(3).toList();
    final extra = alerts.length - visible.length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            exceeded ? Icons.error_outline_rounded : Icons.warning_amber_rounded,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exceeded ? '预算已超支' : '预算提醒',
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                for (final alert in visible)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(alert.message, style: const TextStyle(height: 1.35)),
                  ),
                if (extra > 0)
                  Text('还有 $extra 条提醒', style: TextStyle(color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EntryTile extends StatelessWidget {
  const EntryTile({super.key, required this.entry, required this.onTap});

  final ({
    String categoryName,
    String iconKey,
    int colorValue,
    EntryType type,
    int amountCents,
    String? note,
  })
  entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = Color(entry.colorValue);
    final income = entry.type == EntryType.income;
    return Material(
      color: scheme.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(categoryIcon(entry.iconKey), color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.categoryName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (entry.note != null && entry.note!.isNotEmpty)
                      Text(
                        entry.note!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                      ),
                  ],
                ),
              ),
              Text(
                Money.formatSigned(entry.amountCents, income: income),
                style: TextStyle(
                  color: income ? AppColors.income : AppColors.expense,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyHint extends StatelessWidget {
  const EmptyHint({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
      child: Column(
        children: [
          Icon(icon, size: 42, color: scheme.primary),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          if (action != null) ...[const SizedBox(height: 14), action!],
        ],
      ),
    );
  }
}

void showAppMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> confirmDelete(BuildContext context, {required String title, required String message}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('删除'),
        ),
      ],
    ),
  ).then((value) => value ?? false);
}

Color budgetLevelColor(BudgetLevel level) {
  return switch (level) {
    BudgetLevel.ok => AppColors.income,
    BudgetLevel.warning => AppColors.warning,
    BudgetLevel.exceeded => AppColors.expense,
  };
}
