import '../../core/dates.dart';
import '../models/category.dart';
import '../models/entry_type.dart';
import '../models/ledger_entry.dart';
import '../models/monthly_stats.dart';

class StatsCalculator {
  const StatsCalculator._();

  static MonthlyStats calculate({
    required int year,
    required int month,
    required List<LedgerEntry> entries,
    required Map<String, Category> categories,
    DateTime? today,
  }) {
    final start = monthStartKey(year, month);
    final end = nextMonthStartKey(year, month);
    final inMonth = entries.where((entry) {
      final key = dateKey(entry.occurredOn);
      return key >= start && key < end;
    });

    var income = 0;
    var expense = 0;
    final incomeById = <String, int>{};
    final expenseById = <String, int>{};
    final dailyIncome = <int, int>{};
    final dailyExpense = <int, int>{};

    for (final entry in inMonth) {
      final key = dateKey(entry.occurredOn);
      if (entry.type == EntryType.income) {
        income += entry.amountCents;
        incomeById[entry.categoryId] =
            (incomeById[entry.categoryId] ?? 0) + entry.amountCents;
        dailyIncome[key] = (dailyIncome[key] ?? 0) + entry.amountCents;
      } else {
        expense += entry.amountCents;
        expenseById[entry.categoryId] =
            (expenseById[entry.categoryId] ?? 0) + entry.amountCents;
        dailyExpense[key] = (dailyExpense[key] ?? 0) + entry.amountCents;
      }
    }

    final daily = <DailyAmount>[
      for (var day = 1; day <= _lastTrendDay(year, month, today); day++)
        DailyAmount(
          day: DateTime(year, month, day),
          incomeCents: dailyIncome[dateKey(DateTime(year, month, day))] ?? 0,
          expenseCents: dailyExpense[dateKey(DateTime(year, month, day))] ?? 0,
        ),
    ];

    return MonthlyStats(
      year: year,
      month: month,
      incomeCents: income,
      expenseCents: expense,
      incomeByCategory: _totals(incomeById, categories, income),
      expenseByCategory: _totals(expenseById, categories, expense),
      daily: daily,
    );
  }

  /// Past months include every day. The current month stops at [today] so the
  /// trend does not drop to zero for days that have not happened. Future
  /// months contribute no points.
  static int _lastTrendDay(int year, int month, DateTime? today) {
    final count = daysInMonth(year, month);
    if (today == null) return count;
    if (year > today.year || (year == today.year && month > today.month)) {
      return 0;
    }
    if (year == today.year && month == today.month) {
      return today.day.clamp(1, count);
    }
    return count;
  }

  static List<CategoryTotal> _totals(
    Map<String, int> amounts,
    Map<String, Category> categories,
    int total,
  ) {
    final rows = amounts.entries
        .where((entry) => entry.value > 0)
        .map((entry) {
          final category = categories[entry.key];
          return CategoryTotal(
            categoryId: entry.key,
            categoryName: category?.name ?? '未分类',
            colorValue: category?.colorValue ?? 0xFF6B7280,
            iconKey: category?.iconKey ?? 'other',
            amountCents: entry.value,
            ratio: total == 0 ? 0 : entry.value / total,
          );
        })
        .toList();
    rows.sort((a, b) => b.amountCents.compareTo(a.amountCents));
    return rows;
  }
}
