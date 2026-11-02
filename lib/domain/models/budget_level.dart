import 'budget.dart';

enum BudgetLevel { ok, warning, exceeded }

class BudgetProgress {
  const BudgetProgress({
    required this.budget,
    required this.spentCents,
    required this.categoryName,
    required this.colorValue,
    required this.iconKey,
  });

  final Budget budget;
  final int spentCents;
  final String? categoryName;
  final int colorValue;
  final String iconKey;

  bool get isTotal => budget.isTotal;

  /// Floored percent while under budget, so 79.9% stays 79 and matches [level].
  /// Once the budget is reached, the value is at least 100.
  int get percent {
    final amount = budget.amountCents;
    if (amount <= 0) return 0;
    if (spentCents >= amount) {
      final rounded = ((spentCents * 100) / amount).round();
      return rounded < 100 ? 100 : rounded;
    }
    return (spentCents * 100) ~/ amount;
  }

  BudgetLevel get level {
    final amount = budget.amountCents;
    if (amount <= 0) return BudgetLevel.ok;
    if (spentCents >= amount) return BudgetLevel.exceeded;
    // Integer 80% threshold: spent / amount >= 4/5.
    if (spentCents * 5 >= amount * 4) return BudgetLevel.warning;
    return BudgetLevel.ok;
  }

  double get barValue {
    final amount = budget.amountCents;
    if (amount <= 0) return 0;
    final ratio = spentCents / amount;
    if (ratio < 0) return 0;
    if (ratio > 1) return 1;
    return ratio;
  }
}
