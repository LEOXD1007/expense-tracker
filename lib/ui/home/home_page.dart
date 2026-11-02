import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/dates.dart';
import '../../core/money.dart';
import '../../domain/models/category.dart';
import '../../domain/models/entry_type.dart';
import '../../domain/models/ledger_entry.dart';
import '../../state/app_controller.dart';
import '../editor/entry_editor_page.dart';
import '../widgets/common.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    return SafeArea(
      bottom: false,
      child: controller.loading && controller.categoryList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: controller.load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                children: [
                  Row(
                    children: [
                      Text(
                        '简记',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      MonthSwitcher(
                        month: controller.focusedMonth,
                        onShift: controller.shiftMonth,
                      ),
                    ],
                  ),
                  if (controller.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(controller.errorMessage!),
                    ),
                  const SizedBox(height: 8),
                  SummaryCard(
                    stats: controller.stats,
                    totalBudget: controller.totalBudget,
                  ),
                  if (controller.activeAlerts.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    BudgetBanner(alerts: controller.activeAlerts),
                  ],
                  const SizedBox(height: 18),
                  Text(
                    '收支明细',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (controller.monthEntries.isEmpty)
                    const EmptyHint(
                      icon: Icons.edit_note_rounded,
                      title: '这个月还没有记录',
                      subtitle: '点右下角「记一笔」，几秒钟就能记下收支。',
                    )
                  else
                    ..._groups(context, controller),
                ],
              ),
            ),
    );
  }

  List<Widget> _groups(BuildContext context, AppController controller) {
    final groups = <int, List<LedgerEntry>>{};
    for (final entry in controller.monthEntries) {
      groups.putIfAbsent(dateKey(entry.occurredOn), () => []).add(entry);
    }
    final keys = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    final widgets = <Widget>[];
    for (final key in keys) {
      final entries = groups[key]!;
      final day = dateFromKey(key);
      var expense = 0;
      var income = 0;
      for (final entry in entries) {
        if (entry.type == EntryType.expense) {
          expense += entry.amountCents;
        } else {
          income += entry.amountCents;
        }
      }
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
          child: Row(
            children: [
              Text(
                formatMonthDay(day),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (income > 0)
                Text(
                  '收入 ${Money.format(income)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              if (income > 0 && expense > 0) const SizedBox(width: 8),
              if (expense > 0)
                Text(
                  '支出 ${Money.format(expense)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      );
      widgets.add(
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            children: [
              for (var i = 0; i < entries.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _DismissibleEntry(
                  entry: entries[i],
                  category: controller.categoryMap[entries[i].categoryId],
                ),
              ],
            ],
          ),
        ),
      );
    }
    return widgets;
  }
}

class _DismissibleEntry extends StatelessWidget {
  const _DismissibleEntry({required this.entry, required this.category});

  final LedgerEntry entry;
  final Category? category;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => confirmDelete(
        context,
        title: '删除这条记录？',
        message: '删除后无法恢复。',
      ),
      onDismissed: (_) => context.read<AppController>().deleteEntry(entry.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: const Color(0xFFE15A45),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: EntryTile(
        entry: (
          categoryName: category?.name ?? '未分类',
          iconKey: category?.iconKey ?? 'other',
          colorValue: category?.colorValue ?? 0xFF6B7280,
          type: entry.type,
          amountCents: entry.amountCents,
          note: entry.note,
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => EntryEditorPage(entryId: entry.id)),
          );
        },
      ),
    );
  }
}
