import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/export/file_exporter.dart';
import '../../state/app_controller.dart';
import '../categories/categories_page.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            '我的',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [AppColors.jadeDeep, Color(0xFF15956F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '简记',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 6),
                Text(
                  '记账数据只保存在这台设备上，默认货币为人民币。',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _Tile(
                  icon: Icons.category_outlined,
                  title: '分类管理',
                  subtitle: '内置分类可以改名，也可以新建自己的分类',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CategoriesPage()),
                    );
                  },
                ),
                const Divider(height: 1),
                _Tile(
                  icon: Icons.cloud_outlined,
                  title: '云同步',
                  subtitle: '即将推出',
                  onTap: () async {
                    final message = await controller.syncMessage();
                    if (context.mounted) showAppMessage(context, message);
                  },
                ),
                const Divider(height: 1),
                _Tile(
                  icon: Icons.mic_none_rounded,
                  title: '语音记账',
                  subtitle: '即将推出，会自动识别金额和分类',
                  onTap: () async {
                    final draft = await controller.parseVoice('');
                    if (!context.mounted) return;
                    showAppMessage(
                      context,
                      draft == null
                          ? '语音记账将在后续版本提供'
                          : '已识别一笔记账，请在记一笔里使用',
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '导出',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _ExportTile(
                  title: '导出本月 CSV',
                  enabled: !controller.exporting,
                  onTap: () => _export(context, ExportFormat.csv, ExportScope.month),
                ),
                const Divider(height: 1),
                _ExportTile(
                  title: '导出本月 Excel',
                  enabled: !controller.exporting,
                  onTap: () => _export(context, ExportFormat.xlsx, ExportScope.month),
                ),
                const Divider(height: 1),
                _ExportTile(
                  title: '导出全部 CSV',
                  enabled: !controller.exporting,
                  onTap: () => _export(context, ExportFormat.csv, ExportScope.all),
                ),
                const Divider(height: 1),
                _ExportTile(
                  title: '导出全部 Excel',
                  enabled: !controller.exporting,
                  onTap: () => _export(context, ExportFormat.xlsx, ExportScope.all),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '关于',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('版本 1.0.0', style: TextStyle(fontWeight: FontWeight.w700)),
                SizedBox(height: 6),
                Text('v1 在本地完成记账、分类、月度统计、预算提醒和导出。'),
                SizedBox(height: 4),
                Text('v2 预留了云同步和语音记账的接口，当前不会上传任何数据。'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _export(
    BuildContext context,
    ExportFormat format,
    ExportScope scope,
  ) async {
    final controller = context.read<AppController>();
    try {
      final count = await controller.export(format: format, scope: scope);
      if (context.mounted) showAppMessage(context, '已导出 $count 条记录');
    } on ExportException catch (error) {
      if (!context.mounted) return;
      final path = error.filePath == null ? '' : '\n${error.filePath}';
      showAppMessage(context, '${error.message}$path');
    } catch (error) {
      if (context.mounted) showAppMessage(context, '导出失败：$error');
    }
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _ExportTile extends StatelessWidget {
  const _ExportTile({
    required this.title,
    required this.onTap,
    required this.enabled,
  });

  final String title;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.ios_share_rounded),
      title: Text(title),
      enabled: enabled,
      onTap: enabled ? onTap : null,
    );
  }
}
