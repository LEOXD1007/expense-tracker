import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' hide Category;
import 'package:uuid/uuid.dart';

import '../core/dates.dart';
import '../data/demo/demo_seed.dart';
import '../data/export/file_exporter.dart';
import '../data/export/ledger_export.dart';
import '../data/local/app_database.dart';
import '../data/notifications/budget_alert_service.dart';
import '../domain/models/budget.dart';
import '../domain/models/budget_level.dart';
import '../domain/models/category.dart';
import '../domain/models/entry_type.dart';
import '../domain/models/ledger_entry.dart';
import '../domain/models/monthly_stats.dart';
import '../domain/repositories/budget_repository.dart';
import '../domain/repositories/category_repository.dart';
import '../domain/repositories/entry_repository.dart';
import '../domain/services/budget_alert_planner.dart';
import '../domain/services/budget_evaluator.dart';
import '../domain/services/stats_calculator.dart';
import '../domain/sync/sync_service.dart';
import '../domain/voice/voice_entry_parser.dart';

typedef Clock = DateTime Function();

enum ExportFormat { csv, xlsx }

enum ExportScope { month, all }

class AppController extends ChangeNotifier {
  AppController({
    required this.database,
    required this.entries,
    required this.categories,
    required this.budgets,
    required this.alerts,
    required this.exporter,
    this.syncService = const DisabledSyncService(),
    this.voiceParser = const UnsupportedVoiceEntryParser(),
    Clock? clock,
  }) : clock = clock ?? DateTime.now {
    final today = this.clock();
    focusedMonth = DateTime(today.year, today.month);
  }

  static const _uuid = Uuid();

  final AppDatabase database;
  final EntryRepository entries;
  final CategoryRepository categories;
  final BudgetRepository budgets;
  final BudgetAlertService alerts;
  final FileExporter exporter;
  final SyncService syncService;
  final VoiceEntryParser voiceParser;
  final Clock clock;

  late DateTime focusedMonth;
  bool loading = true;
  bool exporting = false;
  String? errorMessage;
  List<Category> categoryList = [];
  List<LedgerEntry> monthEntries = [];
  List<Budget> monthBudgets = [];
  String? lastExpenseCategoryId;
  String? lastIncomeCategoryId;

  int _generation = 0;

  Map<String, Category> get categoryMap => {
    for (final category in categoryList) category.id: category,
  };

  MonthlyStats get stats => StatsCalculator.calculate(
    year: focusedMonth.year,
    month: focusedMonth.month,
    entries: monthEntries,
    categories: categoryMap,
    today: clock(),
  );

  List<BudgetProgress> get budgetProgress => BudgetEvaluator.evaluate(
    budgets: monthBudgets,
    entries: monthEntries,
    categories: categoryMap,
  );

  List<BudgetAlert> get activeAlerts => BudgetAlertPlanner.plan(
    progress: budgetProgress,
    year: focusedMonth.year,
    month: focusedMonth.month,
  );

  BudgetProgress? get totalBudget {
    for (final item in budgetProgress) {
      if (item.isTotal) return item;
    }
    return null;
  }

  List<Category> categoriesOf(EntryType type) {
    return categoryList.where((category) => category.type == type).toList();
  }

  Future<void> load() async {
    final generation = ++_generation;
    try {
      final loadedCategories = await categories.getAll();
      final loadedEntries = await entries.getByMonth(
        focusedMonth.year,
        focusedMonth.month,
      );
      final loadedBudgets = await budgets.getForMonth(
        focusedMonth.year,
        focusedMonth.month,
      );
      if (generation != _generation) return;
      categoryList = loadedCategories;
      monthEntries = loadedEntries;
      monthBudgets = loadedBudgets;
      errorMessage = null;
      loading = false;
      await alerts.sync(
        year: focusedMonth.year,
        month: focusedMonth.month,
        alerts: activeAlerts,
      );
      if (generation != _generation) return;
      notifyListeners();
    } catch (_) {
      if (generation != _generation) return;
      errorMessage = '读取数据失败，请重试';
      loading = false;
      notifyListeners();
    }
  }

  Future<void> shiftMonth(int delta) async {
    focusedMonth = DateTime(focusedMonth.year, focusedMonth.month + delta);
    await load();
  }

  Future<void> saveEntry(LedgerEntry entry) async {
    await entries.upsert(entry);
    if (entry.type == EntryType.expense) {
      lastExpenseCategoryId = entry.categoryId;
    } else {
      lastIncomeCategoryId = entry.categoryId;
    }
    focusedMonth = DateTime(entry.occurredOn.year, entry.occurredOn.month);
    await load();
  }

  Future<void> deleteEntry(String id) async {
    await entries.delete(id);
    await load();
  }

  Future<void> addCategory({
    required String name,
    required EntryType type,
    required String iconKey,
    required int colorValue,
  }) async {
    final now = clock();
    await categories.add(
      Category(
        id: _uuid.v4(),
        name: name,
        type: type,
        iconKey: iconKey,
        colorValue: colorValue,
        isBuiltin: false,
        sortOrder: -1,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await load();
  }

  Future<void> updateCategory(Category category) async {
    await categories.update(category.copyWith(updatedAt: clock()));
    await load();
  }

  Future<void> deleteCategory(String id) async {
    await categories.delete(id);
    await load();
  }

  Future<void> setBudget({String? categoryId, required int? amountCents}) async {
    if (amountCents == null) {
      await budgets.deleteFor(
        year: focusedMonth.year,
        month: focusedMonth.month,
        categoryId: categoryId,
      );
    } else {
      await budgets.upsert(
        Budget(
          id: _uuid.v4(),
          year: focusedMonth.year,
          month: focusedMonth.month,
          categoryId: categoryId,
          amountCents: amountCents,
          updatedAt: clock(),
        ),
      );
    }
    await load();
  }

  Future<int> export({
    required ExportFormat format,
    required ExportScope scope,
  }) async {
    exporting = true;
    notifyListeners();
    try {
      final source = scope == ExportScope.month
          ? monthEntries
          : await entries.getAll();
      final sorted = [...source]..sort((a, b) {
        final byDate = a.occurredOn.compareTo(b.occurredOn);
        if (byDate != 0) return byDate;
        return a.createdAt.compareTo(b.createdAt);
      });
      final table = LedgerTable.rows(sorted, categoryMap);
      final stamp = formatIsoDate(clock()).replaceAll('-', '');
      final label = scope == ExportScope.month
          ? '${focusedMonth.year}${focusedMonth.month.toString().padLeft(2, '0')}'
          : 'all';
      final isCsv = format == ExportFormat.csv;
      await exporter.share(
        filename: 'jizhang_${label}_$stamp.${isCsv ? 'csv' : 'xlsx'}',
        bytes: isCsv
            ? utf8.encode(CsvExporter.build(table))
            : XlsxExporter.build(table),
        mimeType: isCsv
            ? 'text/csv'
            : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      return sorted.length;
    } finally {
      exporting = false;
      notifyListeners();
    }
  }

  Future<String> syncMessage() async {
    final status = await syncService.sync();
    return switch (status) {
      SyncStatus.disabled => '云同步将在后续版本提供',
      SyncStatus.success => '同步完成',
      SyncStatus.failed => '同步失败，请稍后再试',
    };
  }

  Future<VoiceDraft?> parseVoice(String utterance) {
    return voiceParser.parse(utterance);
  }

  Future<void> loadDemo() {
    return seedDemoData(entries: entries, budgets: budgets, now: clock());
  }

  @override
  void dispose() {
    unawaited(database.close());
    super.dispose();
  }
}
