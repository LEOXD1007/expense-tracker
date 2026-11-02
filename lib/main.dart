import 'package:flutter/widgets.dart';

import 'bootstrap.dart';
import 'ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = await bootstrap();
  runApp(JizhangApp(controller: controller));
}
