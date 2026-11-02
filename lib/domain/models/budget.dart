class Budget {
  const Budget({
    required this.id,
    required this.year,
    required this.month,
    required this.categoryId,
    required this.amountCents,
    required this.updatedAt,
  });

  final String id;
  final int year;
  final int month;

  /// Null means the monthly total budget.
  final String? categoryId;
  final int amountCents;
  final DateTime updatedAt;

  bool get isTotal => categoryId == null;
}
