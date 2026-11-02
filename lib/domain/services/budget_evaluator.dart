import '../models/budget.dart';
import '../models/budget_level.dart';
import '../models/category.dart';
import '../models/entry_type.dart';
import '../models/ledger_entry.dart';

class BudgetEvaluator {
  const BudgetEvaluator._();

  static List<BudgetProgress> evaluate({
    required List<Budget> budgets,
    required List<LedgerEntry> entries,
    required Map<String, Category> categories,
  }) {
    final spentByCategory = <String, int>{};
    var totalSpent = 0;
    for (final entry in entries) {
      if (entry.type != EntryType.expense) continue;
      totalSpent += entry.amountCents;
      spentByCategory[entry.categoryId] =
          (spentByCategory[entry.categoryId] ?? 0) + entry.amountCents;
    }

    final progress = <BudgetProgress>[];
    for (final budget in budgets) {
      if (budget.amountCents <= 0) continue;
      if (budget.isTotal) {
        progress.add(
          BudgetProgress(
            budget: budget,
            spentCents: totalSpent,
            categoryName: null,
            colorValue: 0xFF0E7C66,
            iconKey: 'bill',
          ),
        );
        continue;
      }
      final category = categories[budget.categoryId];
      progress.add(
        BudgetProgress(
          budget: budget,
          spentCents: spentByCategory[budget.categoryId] ?? 0,
          categoryName: category?.name ?? '未分类',
          colorValue: category?.colorValue ?? 0xFF6B7280,
          iconKey: category?.iconKey ?? 'other',
        ),
      );
    }

    progress.sort((a, b) {
      if (a.isTotal != b.isTotal) return a.isTotal ? -1 : 1;
      return b.barValue.compareTo(a.barValue);
    });
    return progress;
  }
}
