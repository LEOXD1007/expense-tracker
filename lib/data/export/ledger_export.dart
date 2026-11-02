import 'package:excel/excel.dart';

import '../../core/dates.dart';
import '../../core/money.dart';
import '../../domain/models/category.dart';
import '../../domain/models/ledger_entry.dart';

class LedgerTable {
  const LedgerTable._();

  static const headers = ['日期', '类型', '分类', '金额', '备注'];

  static List<List<String>> rows(
    List<LedgerEntry> entries,
    Map<String, Category> categories,
  ) {
    return [
      headers,
      for (final entry in entries)
        [
          formatIsoDate(entry.occurredOn),
          entry.type.label,
          categories[entry.categoryId]?.name ?? '未分类',
          Money.plain(entry.amountCents),
          entry.note ?? '',
        ],
    ];
  }
}

class CsvExporter {
  const CsvExporter._();

  static String build(List<List<String>> rows) {
    final buffer = StringBuffer('\uFEFF');
    for (final row in rows) {
      buffer.write(row.map(_escape).join(','));
      buffer.write('\r\n');
    }
    return buffer.toString();
  }

  static String _escape(String value) {
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}

class XlsxExporter {
  const XlsxExporter._();

  static const sheetName = '账单';

  static List<int> build(List<List<String>> rows) {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    final sheet = excel[sheetName];
    for (final row in rows) {
      sheet.appendRow([for (final cell in row) TextCellValue(cell)]);
    }
    if (defaultSheet != null && defaultSheet != sheetName) {
      excel.delete(defaultSheet);
    }
    final bytes = excel.encode();
    if (bytes == null) {
      throw const FormatException('无法生成 Excel 文件');
    }
    return bytes;
  }
}
