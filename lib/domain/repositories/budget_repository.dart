import '../models/budget.dart';

abstract interface class BudgetRepository {
  Future<List<Budget>> getForMonth(int year, int month);

  /// Inserts or replaces the budget for the same month and category.
  /// [Budget.categoryId] null is the monthly total.
  Future<void> upsert(Budget budget);

  Future<void> deleteFor({
    required int year,
    required int month,
    required String? categoryId,
  });
}
