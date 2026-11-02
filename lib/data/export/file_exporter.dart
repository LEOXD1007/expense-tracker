import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

abstract interface class FileExporter {
  Future<void> share({
    required String filename,
    required List<int> bytes,
    required String mimeType,
  });
}

class ShareFileExporter implements FileExporter {
  const ShareFileExporter();

  @override
  Future<void> share({
    required String filename,
    required List<int> bytes,
    required String mimeType,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, filename));
    await file.writeAsBytes(bytes, flush: true);
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: mimeType, name: filename)],
          title: '导出记账',
          subject: filename,
        ),
      );
    } catch (error) {
      throw ExportException('无法打开系统分享，文件已保存：$error', file.path);
    }
  }
}

class ExportException implements Exception {
  const ExportException(this.message, [this.filePath]);

  final String message;
  final String? filePath;

  @override
  String toString() => message;
}

/// Keeps bytes in memory. Used by tests and as a stand-in when sharing
/// is unavailable.
class MemoryFileExporter implements FileExporter {
  final files = <String, List<int>>{};

  @override
  Future<void> share({
    required String filename,
    required List<int> bytes,
    required String mimeType,
  }) async {
    files[filename] = bytes;
  }
}
