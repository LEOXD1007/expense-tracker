List<Map<String, Object?>> defaultCategoryRows(int nowMs) {
  Map<String, Object?> row({
    required String id,
    required String name,
    required String type,
    required String icon,
    required int color,
    required int order,
  }) {
    return {
      'id': id,
      'name': name,
      'type': type,
      'icon_key': icon,
      'color_value': color,
      'is_builtin': 1,
      'sort_order': order,
      'created_at': nowMs,
      'updated_at': nowMs,
    };
  }

  return [
    row(id: 'exp_food', name: '餐饮', type: 'expense', icon: 'restaurant', color: 0xFFE25B45, order: 0),
    row(id: 'exp_transit', name: '交通', type: 'expense', icon: 'transit', color: 0xFF3D7A9A, order: 1),
    row(id: 'exp_shopping', name: '购物', type: 'expense', icon: 'shopping', color: 0xFFD9892B, order: 2),
    row(id: 'exp_fun', name: '娱乐', type: 'expense', icon: 'entertainment', color: 0xFF7A5AF5, order: 3),
    row(id: 'exp_home', name: '居住', type: 'expense', icon: 'housing', color: 0xFF2F8F6B, order: 4),
    row(id: 'exp_medical', name: '医疗', type: 'expense', icon: 'medical', color: 0xFFD4537E, order: 5),
    row(id: 'exp_edu', name: '教育', type: 'expense', icon: 'education', color: 0xFF3E6FD8, order: 6),
    row(id: 'exp_comm', name: '通讯', type: 'expense', icon: 'comms', color: 0xFF0E8A8A, order: 7),
    row(id: 'exp_daily', name: '日用', type: 'expense', icon: 'daily', color: 0xFF8A6A3D, order: 8),
    row(id: 'exp_other', name: '其他', type: 'expense', icon: 'other', color: 0xFF6B7280, order: 9),
    row(id: 'inc_salary', name: '工资', type: 'income', icon: 'salary', color: 0xFF1F9D55, order: 0),
    row(id: 'inc_bonus', name: '奖金', type: 'income', icon: 'bonus', color: 0xFFE0A100, order: 1),
    row(id: 'inc_invest', name: '理财', type: 'income', icon: 'invest', color: 0xFF3E6FD8, order: 2),
    row(id: 'inc_parttime', name: '兼职', type: 'income', icon: 'parttime', color: 0xFF0E8A8A, order: 3),
    row(id: 'inc_other', name: '其他收入', type: 'income', icon: 'other_income', color: 0xFF6B7280, order: 4),
  ];
}
