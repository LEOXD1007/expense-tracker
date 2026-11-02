import 'dart:io';
import 'dart:ui' as ui;

import 'package:expense_tracker/bootstrap.dart';
import 'package:expense_tracker/data/notifications/budget_alert_service.dart';
import 'package:expense_tracker/state/app_controller.dart';
import 'package:expense_tracker/ui/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const capture = bool.fromEnvironment('CAPTURE_SCREENSHOTS');

  late Directory temp;
  late AppController controller;

  setUp(() async {
    if (!capture) return;
    temp = await Directory.systemTemp.createTemp('jizhang_shot_');
    controller = await bootstrap(
      databasePath: '${temp.path}/app.db',
      clock: () => DateTime(2026, 11, 18),
      notifier: const NoopNotifier(),
      initNotifications: false,
      seedDemo: true,
    );
  });

  tearDown(() async {
    if (!capture) return;
    await controller.database.close();
    if (temp.existsSync()) await temp.delete(recursive: true);
  });

  testWidgets('capture phone screenshots when requested', (tester) async {
    if (!capture) return;

    final fontFile = File('/tmp/wqy-microhei.ttf');
    expect(
      fontFile.existsSync(),
      isTrue,
      reason: '截图需要含中文和数字的 /tmp/wqy-microhei.ttf',
    );
    final loader = FontLoader('JizhangFallback')
      ..addFont(Future.value(ByteData.sublistView(fontFile.readAsBytesSync())));
    await loader.load();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('screenshot-root'),
        child: JizhangApp(
          controller: controller,
          fontFamily: 'JizhangFallback',
        ),
      ),
    );
    await tester.pump();

    final out = Directory('/opt/cursor/artifacts/screenshots');
    out.createSync(recursive: true);

    Future<void> shoot(String name) async {
      await tester.pump();
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('screenshot-root')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('${out.path}/$name.png').writeAsBytes(
          bytes!.buffer.asUint8List(),
        );
      });
    }

    await shoot('01-home');
    await tester.tap(find.text('统计'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await shoot('02-stats');
    await tester.drag(find.byType(Scrollable).hitTestable().first, const Offset(0, -520));
    await tester.pump();
    await shoot('02-trend');
    await tester.tap(find.text('预算'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await shoot('03-budget');
    await tester.tap(find.text('我的'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await shoot('04-settings');
    await tester.tap(find.text('明细'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('记一笔'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await shoot('05-editor');
    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('我的'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('分类管理'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await shoot('06-categories');
  });
}
