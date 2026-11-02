import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/dates.dart';
import '../../core/money.dart';
import '../../domain/models/entry_type.dart';
import '../../domain/models/ledger_entry.dart';
import '../../state/app_controller.dart';
import '../icons/category_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class EntryEditorPage extends StatefulWidget {
  const EntryEditorPage({super.key, this.entryId});

  final String? entryId;

  @override
  State<EntryEditorPage> createState() => _EntryEditorPageState();
}

class _EntryEditorPageState extends State<EntryEditorPage> {
  static const _uuid = Uuid();

  final _amount = TextEditingController();
  final _note = TextEditingController();
  EntryType _type = EntryType.expense;
  DateTime? _date;
  String? _categoryId;
  LedgerEntry? _existing;
  bool _ready = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final controller = context.read<AppController>();
    LedgerEntry? existing;
    if (widget.entryId != null) {
      existing = await controller.entries.getById(widget.entryId!);
    }
    if (!mounted) return;
    final type = existing?.type ?? EntryType.expense;
    setState(() {
      _existing = existing;
      _type = type;
      _date = existing?.occurredOn ?? _defaultDate(controller);
      _categoryId = existing?.categoryId ?? _defaultCategory(controller, type);
      if (existing != null) {
        _amount.text = Money.plain(existing.amountCents);
        _note.text = existing.note ?? '';
      }
      _ready = true;
    });
  }

  DateTime _defaultDate(AppController controller) {
    final today = controller.clock();
    final month = controller.focusedMonth;
    final todayMonth = DateTime(today.year, today.month);
    final focused = DateTime(month.year, month.month);
    if (focused == todayMonth) {
      return DateTime(today.year, today.month, today.day);
    }
    if (focused.isBefore(todayMonth)) {
      return DateTime(month.year, month.month, daysInMonth(month.year, month.month));
    }
    return DateTime(month.year, month.month, 1);
  }

  String? _defaultCategory(AppController controller, EntryType type) {
    final remembered = type == EntryType.expense
        ? controller.lastExpenseCategoryId
        : controller.lastIncomeCategoryId;
    final options = controller.categoriesOf(type);
    if (remembered != null && options.any((category) => category.id == remembered)) {
      return remembered;
    }
    if (options.isEmpty) return null;
    return options.first.id;
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final controller = context.read<AppController>();
    final today = controller.clock();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? today,
      firstDate: DateTime(2000),
      lastDate: DateTime(today.year + 2, 12, 31),
    );
    if (picked != null) {
      setState(() => _date = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _voice() async {
    final controller = context.read<AppController>();
    final draft = await controller.parseVoice('');
    if (!mounted) return;
    if (draft == null) {
      showAppMessage(context, '语音记账将在后续版本提供，到时会自动填入金额、分类和备注');
      return;
    }
    setState(() {
      if (draft.type != null) _type = draft.type!;
      if (draft.amountCents != null) _amount.text = Money.plain(draft.amountCents!);
      if (draft.note != null) _note.text = draft.note!;
      if (draft.occurredOn != null) _date = draft.occurredOn;
      if (draft.categoryName != null) {
        final match = controller.categoriesOf(_type).where(
          (category) => category.name == draft.categoryName,
        );
        if (match.isNotEmpty) _categoryId = match.first.id;
      }
    });
  }

  Future<void> _save() async {
    final controller = context.read<AppController>();
    final cents = Money.parseYuan(_amount.text);
    if (cents == null) {
      showAppMessage(context, '请输入大于 0 的金额');
      return;
    }
    if (_categoryId == null) {
      showAppMessage(context, '请选择分类');
      return;
    }
    final note = _note.text.trim();
    if (note.length > 100) {
      showAppMessage(context, '备注最多 100 个字');
      return;
    }
    setState(() => _saving = true);
    final now = controller.clock();
    try {
      await controller.saveEntry(
        LedgerEntry(
          id: _existing?.id ?? _uuid.v4(),
          amountCents: cents,
          type: _type,
          categoryId: _categoryId!,
          occurredOn: _date ?? now,
          note: note.isEmpty ? null : note,
          createdAt: _existing?.createdAt ?? now,
          updatedAt: now,
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppMessage(context, '保存失败：$error');
    }
  }

  Future<void> _delete() async {
    final confirmed = await confirmDelete(
      context,
      title: '删除这条记录？',
      message: '删除后无法恢复。',
    );
    if (!confirmed || !mounted) return;
    await context.read<AppController>().deleteEntry(_existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  void _changeType(EntryType type) {
    final controller = context.read<AppController>();
    setState(() {
      _type = type;
      final options = controller.categoriesOf(type);
      if (!options.any((category) => category.id == _categoryId)) {
        _categoryId = _defaultCategory(controller, type);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final categories = controller.categoriesOf(_type);
    return Scaffold(
      appBar: AppBar(
        title: Text(_existing == null ? '记一笔' : '编辑记录'),
        actions: [
          IconButton(
            tooltip: '语音记账',
            onPressed: _voice,
            icon: const Icon(Icons.mic_none_rounded),
          ),
        ],
      ),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              key: const Key('editor-list'),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                SegmentedButton<EntryType>(
                  segments: const [
                    ButtonSegment(value: EntryType.expense, label: Text('支出')),
                    ButtonSegment(value: EntryType.income, label: Text('收入')),
                  ],
                  selected: {_type},
                  onSelectionChanged: (value) => _changeType(value.first),
                ),
                const SizedBox(height: 18),
                TextField(
                  key: const Key('amount-field'),
                  controller: _amount,
                  autofocus: _existing == null,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800),
                  decoration: const InputDecoration(
                    prefixText: '¥ ',
                    hintText: '0.00',
                    prefixStyle: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 18),
                Text('分类', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.86,
                  ),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final selected = category.id == _categoryId;
                    final color = Color(category.colorValue);
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => setState(() => _categoryId = category.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        decoration: BoxDecoration(
                          color: selected
                              ? color.withValues(alpha: 0.16)
                              : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected ? color : Colors.transparent,
                            width: 1.6,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(categoryIcon(category.iconKey), color: color),
                            const SizedBox(height: 6),
                            Text(
                              category.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_rounded),
                  title: const Text('日期'),
                  subtitle: Text(_date == null ? '选择日期' : formatFullDate(_date!)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _pickDate,
                ),
                TextField(
                  key: const Key('note-field'),
                  controller: _note,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: '备注（可选）',
                    hintText: '例如：午餐、地铁',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('save-entry'),
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(_saving ? '正在保存…' : '保存'),
                ),
                if (_existing != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _saving ? null : _delete,
                    style: TextButton.styleFrom(foregroundColor: AppColors.expense),
                    child: const Text('删除记录'),
                  ),
                ],
              ],
            ),
    );
  }
}
