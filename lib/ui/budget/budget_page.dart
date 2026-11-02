import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/money.dart';
import '../../domain/models/budget_level.dart';
import '../../domain/models/category.dart';
import '../../domain/models/entry_type.dart';
import '../../state/app_controller.dart';
import '../icons/category_icons.dart';
import '../widgets/common.dart';

class BudgetPage extends StatelessWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final byCategory = {
      for (final item in controller.budgetProgress)
        if (!item.isTotal) item.budget.categoryId!: item,
    };
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            '预算',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          MonthSwitcher(month: controller.focusedMonth, onShift: controller.shiftMonth),
          const SizedBox(height: 8),
          if (controller.activeAlerts.isNotEmpty) ...[
            BudgetBanner(alerts: controller.activeAlerts),
            const SizedBox(height: 12),
          ],
          _TotalBudgetCard(progress: controller.totalBudget),
          const SizedBox(height: 16),
          Text(
            '分类预算',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '只统计支出。没设预算的分类不会提醒。',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          for (final category in controller.categoriesOf(EntryType.expense))
            _CategoryBudgetTile(
              category: category,
              progress: byCategory[category.id],
            ),
        ],
      ),
    );
  }
}

class _TotalBudgetCard extends StatelessWidget {
  const _TotalBudgetCard({required this.progress});

  final BudgetProgress? progress;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('本月总预算', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
              TextButton(
                onPressed: () => _edit(context, current: progress?.budget.amountCents),
                child: Text(progress == null ? '设置' : '修改'),
              ),
            ],
          ),
          if (progress == null)
            const Text('设置一个总额后，支出接近或超出时会在这里提醒。')
          else ...[
            Text(
              '${Money.format(progress!.spentCents)} / ${Money.format(progress!.budget.amountCents)}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            _Bar(progress: progress!),
          ],
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, {int? current}) async {
    final result = await showBudgetAmountDialog(
      context,
      title: '本月总预算',
      currentCents: current,
    );
    if (result == null || !context.mounted) return;
    await context.read<AppController>().setBudget(
      categoryId: null,
      amountCents: result.cleared ? null : result.amountCents,
    );
  }
}

class _CategoryBudgetTile extends StatelessWidget {
  const _CategoryBudgetTile({required this.category, required this.progress});

  final Category category;
  final BudgetProgress? progress;

  @override
  Widget build(BuildContext context) {
    final color = Color(category.colorValue);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SurfaceCard(
        onTap: () async {
          final result = await showBudgetAmountDialog(
            context,
            title: category.name,
            currentCents: progress?.budget.amountCents,
          );
          if (result == null || !context.mounted) return;
          await context.read<AppController>().setBudget(
            categoryId: category.id,
            amountCents: result.cleared ? null : result.amountCents,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(categoryIcon(category.iconKey), color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                Text(
                  progress == null ? '未设置' : '${progress!.percent}%',
                  style: TextStyle(
                    color: progress == null
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : budgetLevelColor(progress!.level),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (progress != null) ...[
              const SizedBox(height: 8),
              _Bar(progress: progress!),
              const SizedBox(height: 6),
              Text(
                '${Money.format(progress!.spentCents)} / ${Money.format(progress!.budget.amountCents)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.progress});

  final BudgetProgress progress;

  @override
  Widget build(BuildContext context) {
    final color = budgetLevelColor(progress.level);
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: progress.barValue,
        minHeight: 8,
        color: color,
        backgroundColor: color.withValues(alpha: 0.15),
      ),
    );
  }
}

class BudgetAmountResult {
  const BudgetAmountResult.saved(this.amountCents) : cleared = false;
  const BudgetAmountResult.cleared() : amountCents = null, cleared = true;

  final int? amountCents;
  final bool cleared;
}

Future<BudgetAmountResult?> showBudgetAmountDialog(
  BuildContext context, {
  required String title,
  int? currentCents,
}) {
  return showDialog<BudgetAmountResult>(
    context: context,
    builder: (context) => _BudgetAmountDialog(title: title, currentCents: currentCents),
  );
}

class _BudgetAmountDialog extends StatefulWidget {
  const _BudgetAmountDialog({required this.title, this.currentCents});

  final String title;
  final int? currentCents;

  @override
  State<_BudgetAmountDialog> createState() => _BudgetAmountDialogState();
}

class _BudgetAmountDialogState extends State<_BudgetAmountDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentCents == null ? '' : Money.plain(widget.currentCents!),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final cents = Money.parseYuan(_controller.text);
    if (cents == null) {
      setState(() => _error = '请输入大于 0 的金额');
      return;
    }
    Navigator.pop(context, BudgetAmountResult.saved(cents));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        decoration: InputDecoration(
          prefixText: '¥ ',
          labelText: '预算金额',
          errorText: _error,
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        if (widget.currentCents != null)
          TextButton(
            onPressed: () => Navigator.pop(context, const BudgetAmountResult.cleared()),
            child: const Text('清除'),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(onPressed: _save, child: const Text('保存')),
      ],
    );
  }
}
