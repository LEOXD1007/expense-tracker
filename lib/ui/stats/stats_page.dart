import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/money.dart';
import '../../domain/models/entry_type.dart';
import '../../domain/models/monthly_stats.dart';
import '../../state/app_controller.dart';
import '../widgets/common.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  EntryType _type = EntryType.expense;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final stats = controller.stats;
    final slices = _type == EntryType.expense
        ? stats.expenseByCategory
        : stats.incomeByCategory;
    final total = _type == EntryType.expense ? stats.expenseCents : stats.incomeCents;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            '统计',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          MonthSwitcher(month: controller.focusedMonth, onShift: controller.shiftMonth),
          const SizedBox(height: 8),
          Row(
            children: [
              _StatChip(label: '收入', value: Money.format(stats.incomeCents)),
              const SizedBox(width: 8),
              _StatChip(label: '支出', value: Money.format(stats.expenseCents)),
              const SizedBox(width: 8),
              _StatChip(label: '结余', value: Money.format(stats.balanceCents)),
            ],
          ),
          const SizedBox(height: 14),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '分类占比',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                SegmentedButton<EntryType>(
                  segments: const [
                    ButtonSegment(value: EntryType.expense, label: Text('支出')),
                    ButtonSegment(value: EntryType.income, label: Text('收入')),
                  ],
                  selected: {_type},
                  onSelectionChanged: (value) => setState(() => _type = value.first),
                ),
                const SizedBox(height: 12),
                if (slices.isEmpty)
                  const EmptyHint(
                    icon: Icons.pie_chart_outline_rounded,
                    title: '暂无数据',
                    subtitle: '这个月还没有对应的收支。',
                  )
                else ...[
                  SizedBox(
                    height: 220,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: slices.length == 1 ? 0 : 2,
                        centerSpaceRadius: 58,
                        sections: [
                          for (final slice in slices)
                            PieChartSectionData(
                              value: slice.amountCents.toDouble(),
                              color: Color(slice.colorValue),
                              radius: 48,
                              title: slice.ratio >= 0.08
                                  ? '${(slice.ratio * 100).round()}%'
                                  : '',
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    '${_type.label}合计 ${Money.format(total)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  for (final slice in slices) _LegendRow(slice: slice),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '每日趋势',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text('折线为每天的收入与支出'),
                const SizedBox(height: 12),
                if (stats.daily.isEmpty ||
                    stats.daily.every(
                      (day) => day.incomeCents == 0 && day.expenseCents == 0,
                    ))
                  const EmptyHint(
                    icon: Icons.show_chart_rounded,
                    title: '暂无趋势',
                    subtitle: '记几笔之后，这里会显示每天的变化。',
                  )
                else
                  SizedBox(height: 220, child: _TrendChart(daily: stats.daily)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SurfaceCard(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.slice});

  final CategoryTotal slice;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Color(slice.colorValue),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(slice.categoryName)),
          Text(Money.format(slice.amountCents), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          SizedBox(
            width: 42,
            child: Text(
              '${(slice.ratio * 100).round()}%',
              textAlign: TextAlign.end,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.daily});

  final List<DailyAmount> daily;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    var maxYuan = 1.0;
    for (final day in daily) {
      final income = day.incomeCents / 100;
      final expense = day.expenseCents / 100;
      if (income > maxYuan) maxYuan = income;
      if (expense > maxYuan) maxYuan = expense;
    }
    final maxY = maxYuan * 1.2;
    return LineChart(
      LineChartData(
        minX: 1,
        maxX: daily.length.toDouble(),
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: maxY / 4,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value >= maxY) return const SizedBox.shrink();
                return Text(
                  _compact(value),
                  style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final day = value.toInt();
                if (day < 1 || day > daily.length) return const SizedBox.shrink();
                if (day != 1 && day != daily.length && day % 5 != 0) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '$day',
                    style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) {
              return [
                for (final spot in spots)
                  LineTooltipItem(
                    '${spot.barIndex == 0 ? '支出' : '收入'} ${spot.y.toStringAsFixed(0)}元',
                    TextStyle(
                      color: spot.barIndex == 0
                          ? const Color(0xFFFFD0C8)
                          : const Color(0xFFD8FFE8),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ];
            },
          ),
        ),
        lineBarsData: [
          _bar(
            daily.map((day) => day.expenseCents / 100).toList(),
            const Color(0xFFE15A45),
          ),
          _bar(
            daily.map((day) => day.incomeCents / 100).toList(),
            const Color(0xFF1F9D55),
          ),
        ],
      ),
    );
  }

  LineChartBarData _bar(List<double> values, Color color) {
    return LineChartBarData(
      spots: [
        for (var i = 0; i < values.length; i++) FlSpot((i + 1).toDouble(), values[i]),
      ],
      isCurved: true,
      preventCurveOverShooting: true,
      color: color,
      barWidth: 2.6,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.12)),
    );
  }

  String _compact(double yuan) {
    if (yuan >= 10000) return '${(yuan / 10000).toStringAsFixed(1)}万';
    if (yuan >= 1000) return '${(yuan / 1000).toStringAsFixed(1)}千';
    return yuan.toStringAsFixed(0);
  }
}
