int dateKey(DateTime date) => date.year * 10000 + date.month * 100 + date.day;

DateTime dateFromKey(int key) =>
    DateTime(key ~/ 10000, (key ~/ 100) % 100, key % 100);

int monthStartKey(int year, int month) => year * 10000 + month * 100 + 1;

int nextMonthStartKey(int year, int month) => dateKey(DateTime(year, month + 1, 1));

int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

String formatYearMonth(DateTime date) => '${date.year}年${date.month}月';

String formatMonthDay(DateTime date) =>
    '${date.month}月${date.day}日 星期${_weekday(date)}';

String formatFullDate(DateTime date) =>
    '${date.year}年${date.month}月${date.day}日 星期${_weekday(date)}';

String formatIsoDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String _weekday(DateTime date) {
  const labels = ['一', '二', '三', '四', '五', '六', '日'];
  return labels[date.weekday - 1];
}
