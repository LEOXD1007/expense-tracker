import '../../core/money.dart';
import '../models/budget_level.dart';

class BudgetAlert {
  const BudgetAlert({required this.key, required this.message, required this.level});

  final String key;
  final String message;
  final BudgetLevel level;
}

class BudgetAlertPlanner {
  const BudgetAlertPlanner._();

  static List<BudgetAlert> plan({
    required List<BudgetProgress> progress,
    required int year,
    required int month,
  }) {
    final prefix = '$year-${month.toString().padLeft(2, '0')}';
    final alerts = <BudgetAlert>[];
    for (final item in progress) {
      if (item.level == BudgetLevel.ok) continue;
      final severity = item.level == BudgetLevel.exceeded ? 'exceeded' : 'warning';
      final scope = item.isTotal ? 'total' : item.budget.categoryId!;
      alerts.add(
        BudgetAlert(
          key: '$prefix-$scope-$severity',
          message: _message(item),
          level: item.level,
        ),
      );
    }
    alerts.sort((a, b) {
      if (a.level != b.level) {
        return a.level == BudgetLevel.exceeded ? -1 : 1;
      }
      return a.key.compareTo(b.key);
    });
    return alerts;
  }

  static String _message(BudgetProgress item) {
    final spent = Money.format(item.spentCents);
    final budget = Money.format(item.budget.amountCents);
    final percent = item.percent;
    if (item.isTotal) {
      if (item.level == BudgetLevel.exceeded) {
        return '本月支出已超出总预算（$spent / $budget）';
      }
      return '本月支出已达到预算的 $percent%（$spent / $budget）';
    }
    final name = item.categoryName ?? '未分类';
    if (item.level == BudgetLevel.exceeded) {
      return '「$name」已超出预算（$spent / $budget）';
    }
    return '「$name」支出已达到预算的 $percent%（$spent / $budget）';
  }
}
