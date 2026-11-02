import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../state/app_controller.dart';
import 'shell/main_shell.dart';
import 'theme/app_theme.dart';

class JizhangApp extends StatelessWidget {
  const JizhangApp({super.key, required this.controller, this.fontFamily});

  final AppController controller;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: MaterialApp(
        title: '简记',
        debugShowCheckedModeBanner: false,
        locale: const Locale('zh', 'CN'),
        supportedLocales: const [Locale('zh', 'CN')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.light(fontFamily: fontFamily),
        darkTheme: AppTheme.dark(fontFamily: fontFamily),
        home: const MainShell(),
      ),
    );
  }
}
