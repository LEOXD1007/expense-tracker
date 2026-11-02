import 'package:expense_tracker/core/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses yuan strings into cents', () {
    expect(Money.parseYuan('12.5'), 1250);
    expect(Money.parseYuan('12.50'), 1250);
    expect(Money.parseYuan('0.01'), 1);
    expect(Money.parseYuan('¥1,234.00'), 123400);
    expect(Money.parseYuan('1，234.5'), 123450);
    expect(Money.parseYuan('12.345'), 1235);
    expect(Money.parseYuan('  +8 '), 800);
  });

  test('rejects empty, zero, and negative amounts', () {
    expect(Money.parseYuan(''), isNull);
    expect(Money.parseYuan('0'), isNull);
    expect(Money.parseYuan('0.00'), isNull);
    expect(Money.parseYuan('-3'), isNull);
    expect(Money.parseYuan('abc'), isNull);
    expect(Money.parseYuan('1.2.3'), isNull);
  });

  test('formats grouped yuan and signed amounts', () {
    expect(Money.format(1234567), '¥12,345.67');
    expect(Money.format(0), '¥0.00');
    expect(Money.format(-50), '-¥0.50');
    expect(Money.format(100, withSymbol: false), '1.00');
    expect(Money.formatSigned(3550, income: false), '-¥35.50');
    expect(Money.formatSigned(3550, income: true), '+¥35.50');
    expect(Money.plain(3550), '35.50');
    expect(Money.plain(5), '0.05');
  });
}
