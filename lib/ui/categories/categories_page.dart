import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/category.dart';
import '../../domain/models/entry_type.dart';
import '../../domain/repositories/category_repository.dart';
import '../../state/app_controller.dart';
import '../icons/category_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  EntryType _type = EntryType.expense;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final items = controller.categoriesOf(_type);
    return Scaffold(
      appBar: AppBar(title: const Text('分类')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, type: _type),
        icon: const Icon(Icons.add_rounded),
        label: const Text('新建分类'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SegmentedButton<EntryType>(
              segments: const [
                ButtonSegment(value: EntryType.expense, label: Text('支出')),
                ButtonSegment(value: EntryType.income, label: Text('收入')),
              ],
              selected: {_type},
              onSelectionChanged: (value) => setState(() => _type = value.first),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final category = items[index];
                final color = Color(category.colorValue);
                return SurfaceCard(
                  onTap: () => _edit(context, existing: category),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(categoryIcon(category.iconKey), color: color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(category.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(
                              category.isBuiltin ? '内置分类' : '自定义分类',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(
    BuildContext context, {
    Category? existing,
    EntryType? type,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _CategoryEditor(existing: existing, initialType: type ?? _type),
    );
    if (saved == true && context.mounted) {
      showAppMessage(context, existing == null ? '已添加分类' : '已更新分类');
    }
  }
}

class _CategoryEditor extends StatefulWidget {
  const _CategoryEditor({required this.initialType, this.existing});

  final Category? existing;
  final EntryType initialType;

  @override
  State<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<_CategoryEditor> {
  late final TextEditingController _name;
  late EntryType _type;
  late String _iconKey;
  late int _color;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _type = existing?.type ?? widget.initialType;
    _iconKey = existing?.iconKey ?? 'other';
    _color = existing?.colorValue ?? AppColors.palette.first;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final controller = context.read<AppController>();
    final name = _name.text.trim();
    if (name.isEmpty || name.length > 12) {
      showAppMessage(context, '分类名称需要 1 到 12 个字');
      return;
    }
    setState(() => _saving = true);
    try {
      final existing = widget.existing;
      if (existing == null) {
        await controller.addCategory(
          name: name,
          type: _type,
          iconKey: _iconKey,
          colorValue: _color,
        );
      } else {
        await controller.updateCategory(
          existing.copyWith(name: name, iconKey: _iconKey, colorValue: _color),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppMessage(context, '保存失败：$error');
    }
  }

  Future<void> _delete() async {
    final confirmed = await confirmDelete(
      context,
      title: '删除分类？',
      message: '只删除分类本身，已有记录需要先处理。',
    );
    if (!confirmed || !mounted) return;
    try {
      await context.read<AppController>().deleteCategory(widget.existing!.id);
      if (mounted) Navigator.pop(context, true);
    } on CategoryDeleteException catch (error) {
      if (!mounted) return;
      final message = switch (error.failure) {
        CategoryDeleteFailure.builtin => '内置分类不能删除，可以改名',
        CategoryDeleteFailure.inUse => '这个分类下还有记录，无法删除',
      };
      showAppMessage(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final existing = widget.existing;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            existing == null ? '新建分类' : '编辑分类',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            autofocus: existing == null,
            decoration: const InputDecoration(labelText: '名称'),
          ),
          const SizedBox(height: 12),
          if (existing == null)
            SegmentedButton<EntryType>(
              segments: const [
                ButtonSegment(value: EntryType.expense, label: Text('支出')),
                ButtonSegment(value: EntryType.income, label: Text('收入')),
              ],
              selected: {_type},
              onSelectionChanged: (value) => setState(() => _type = value.first),
            )
          else
            Text('类型：${existing.type.label}（创建后不能修改）'),
          const SizedBox(height: 12),
          const Text('图标'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in categoryIconChoices.entries)
                InkWell(
                  onTap: () => setState(() => _iconKey = entry.key),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _iconKey == entry.key
                          ? Color(_color).withValues(alpha: 0.18)
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _iconKey == entry.key ? Color(_color) : Colors.transparent,
                      ),
                    ),
                    child: Icon(entry.value, color: Color(_color), size: 20),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('颜色'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final color in AppColors.palette)
                InkWell(
                  onTap: () => setState(() => _color = color),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(color),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _color == color ? Colors.black : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: const Text('保存'),
          ),
          if (existing != null && !existing.isBuiltin)
            TextButton(
              onPressed: _saving ? null : _delete,
              style: TextButton.styleFrom(foregroundColor: AppColors.expense),
              child: const Text('删除分类'),
            ),
        ],
      ),
    );
  }
}
