import 'dart:io';

import 'package:expense_tracker/bootstrap.dart';
import 'package:expense_tracker/data/export/file_exporter.dart';
import 'package:expense_tracker/data/notifications/budget_alert_service.dart';
import 'package:expense_tracker/state/app_controller.dart';
import 'package:expense_tracker/ui/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late MemoryFileExporter exporter;
  late AppController controller;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('jizhang_widget_');
    exporter = MemoryFileExporter();
    controller = await bootstrap(
      databasePath: '${temp.path}/app.db',
      clock: () => DateTime(2026, 11, 18),
      exporter: exporter,
      notifier: const NoopNotifier(),
      initNotifications: false,
    );
  });

  tearDown(() async {
    await controller.database.close();
    if (temp.existsSync()) {
      await temp.delete(recursive: true);
    }
  });

  testWidgets('records an expense and shows it on the home month', (tester) async {
    await tester.pumpWidget(JizhangApp(controller: controller));
    await tester.pump();

    expect(find.text('这个月还没有记录'), findsOneWidget);
    expect(find.text('2026年11月'), findsOneWidget);

    await tester.tap(find.text('记一笔'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.enterText(find.byKey(const Key('amount-field')), '35.5');
    await _scrollTo(tester, find.byKey(const Key('note-field')));
    await tester.enterText(find.byKey(const Key('note-field')), '午餐');
    await _scrollTo(tester, find.byKey(const Key('save-entry')));
    await tester.tap(find.byKey(const Key('save-entry')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('餐饮'), findsWidgets);
    expect(find.text('-¥35.50'), findsWidgets);
    expect(find.text('午餐'), findsOneWidget);

    await tester.tap(find.text('统计'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('分类占比'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).hitTestable().first, const Offset(0, -700));
    await tester.pump();
    expect(find.text('每日趋势'), findsOneWidget);

    await tester.tap(find.text('预算'));
    await tester.pump();
    expect(find.text('本月总预算'), findsOneWidget);

    await tester.tap(find.text('我的'));
    await tester.pump();
    expect(find.text('分类管理'), findsOneWidget);

    await tester.tap(find.text('导出本月 CSV'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('已导出 1 条记录'), findsOneWidget);
    expect(exporter.files, isNotEmpty);
  });
}

Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  final scrollable = find
      .descendant(of: find.byKey(const Key('editor-list')), matching: find.byType(Scrollable))
      .first;
  for (var i = 0; i < 8 && target.evaluate().isEmpty; i++) {
    await tester.drag(scrollable, const Offset(0, -280));
    await tester.pump();
  }
  expect(target, findsOneWidget);
}
