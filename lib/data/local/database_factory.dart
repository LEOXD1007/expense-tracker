import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

bool _ready = false;

/// Mobile uses the sqflite plugin. Desktop tests and Linux use FFI so the
/// same repository code runs without a device.
void ensureDatabaseFactory() {
  if (_ready) return;
  _ready = true;
  if (kIsWeb) return;
  if (Platform.isAndroid || Platform.isIOS) return;
  sqfliteFfiInit();
  // The background-isolate factory deadlocks Flutter widget tests after the
  // first frame. Queries here are tiny, so desktop and tests run SQLite on
  // the calling isolate.
  databaseFactory = databaseFactoryFfiNoIsolate;
}
