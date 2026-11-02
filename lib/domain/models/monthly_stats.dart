class CategoryTotal {
  const CategoryTotal({
    required this.categoryId,
    required this.categoryName,
    required this.colorValue,
    required this.iconKey,
    required this.amountCents,
    required this.ratio,
  });

  final String categoryId;
  final String categoryName;
  final int colorValue;
  final String iconKey;
  final int amountCents;

  /// Share of this type's total, from 0 to 1.
  final double ratio;
}

class DailyAmount {
  const DailyAmount({
    required this.day,
    required this.incomeCents,
    required this.expenseCents,
  });

  final DateTime day;
  final int incomeCents;
  final int expenseCents;
}

class MonthlyStats {
  const MonthlyStats({
    required this.year,
    required this.month,
    required this.incomeCents,
    required this.expenseCents,
    required this.expenseByCategory,
    required this.incomeByCategory,
    required this.daily,
  });

  final int year;
  final int month;
  final int incomeCents;
  final int expenseCents;
  final List<CategoryTotal> expenseByCategory;
  final List<CategoryTotal> incomeByCategory;
  final List<DailyAmount> daily;

  int get balanceCents => incomeCents - expenseCents;

  static MonthlyStats empty(int year, int month) {
    return MonthlyStats(
      year: year,
      month: month,
      incomeCents: 0,
      expenseCents: 0,
      expenseByCategory: const [],
      incomeByCategory: const [],
      daily: const [],
    );
  }
}
