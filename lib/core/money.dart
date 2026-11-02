/// Yuan amounts stored as integer cents to avoid binary floating point.
class Money {
  const Money._();

  static const symbol = '¥';

  /// 99,999,999.99 yuan.
  static const maxCents = 9999999999;

  /// Parses a yuan string such as `12.50`, `¥1,234.00`, or `12.345` (rounded).
  /// Returns null for empty, zero, negative, or unreadable input.
  static int? parseYuan(String raw) {
    var text = raw.trim();
    if (text.isEmpty) return null;
    text = text
        .replaceAll('¥', '')
        .replaceAll(',', '')
        .replaceAll('，', '')
        .replaceAll(' ', '');
    if (text.startsWith('+')) text = text.substring(1);
    if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(text)) return null;
    final value = double.tryParse(text);
    if (value == null || value <= 0) return null;
    final cents = (value * 100).round();
    if (cents <= 0 || cents > maxCents) return null;
    return cents;
  }

  static String format(int cents, {bool withSymbol = true}) {
    final negative = cents < 0;
    final abs = cents.abs();
    final yuan = abs ~/ 100;
    final frac = (abs % 100).toString().padLeft(2, '0');
    final body = '${_group(yuan)}.$frac';
    final withYuan = withSymbol ? '$symbol$body' : body;
    return negative ? '-$withYuan' : withYuan;
  }

  /// `+¥12.00` for income and `-¥12.00` for expense.
  static String formatSigned(int cents, {required bool income}) {
    final body = format(cents.abs());
    return income ? '+$body' : '-$body';
  }

  /// Plain decimal without grouping or symbol, for CSV and Excel.
  static String plain(int cents) {
    final negative = cents < 0;
    final abs = cents.abs();
    final yuan = abs ~/ 100;
    final frac = (abs % 100).toString().padLeft(2, '0');
    return '${negative ? '-' : ''}$yuan.$frac';
  }

  static String _group(int yuan) {
    final digits = yuan.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
