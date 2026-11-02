enum EntryType {
  expense,
  income;

  String get label => this == EntryType.expense ? '支出' : '收入';

  static EntryType fromDb(String value) {
    return EntryType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => throw FormatException('未知的收支类型：$value'),
    );
  }
}
