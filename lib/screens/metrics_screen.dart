import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sse_frontend_mobil/config/app_theme.dart';
import 'package:sse_frontend_mobil/providers/metrics_provider.dart';
import 'package:sse_frontend_mobil/widgets/skeleton.dart';

class MetricsScreen extends ConsumerWidget {
  const MetricsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(metricsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Metricas', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryDark,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(metricsProvider),
            icon: Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: metricsAsync.when(
        loading: () => const _MetricsSkeleton(),
        error: (e, _) => Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 48, color: Color(0xFFEF4444)),
                SizedBox(height: 12),
                Text('Error al cargar metricas',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark)),
                SizedBox(height: 4),
                Text('$e',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 13, color: AppTheme.textLight)),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(metricsProvider),
                  icon: Icon(Icons.refresh_rounded, size: 16),
                  label: Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        data: (metrics) => _buildContent(context, metrics),
      ),
    );
  }

  Widget _buildContent(BuildContext context, MetricsData m) {
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _sectionTitle('Resumen general'),
          SizedBox(height: 8),
          _kpiGrid(m.totals),
          SizedBox(height: 24),
          _sectionTitle('Tendencia mensual'),
          SizedBox(height: 8),
          _monthlyChart(m.byMonth),
          SizedBox(height: 24),
          _sectionTitle('Por industria'),
          SizedBox(height: 8),
          _industryBreakdown(m.byIndustry),
          SizedBox(height: 24),
          _sectionTitle('Top clientes'),
          SizedBox(height: 8),
          _topClients(m.topClients),
          SizedBox(height: 24),
          _sectionTitle('Blockchain'),
          SizedBox(height: 8),
          _blockchainStats(m.totals),
          SizedBox(height: 24),
          _sectionTitle('Tasa de completado'),
          SizedBox(height: 8),
          _completionBar(m.completionRate),
          SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Section title ──

  Widget _sectionTitle(String text) {
    return Text(text,
        style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark));
  }

  // ── KPI Grid (2x2) ──

  Widget _kpiGrid(Totals t) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: [
        _kpiCard(
            'Procesos', '${t.processes}', Icons.folder_open_rounded,
            Color(0xFF2563EB), Color(0xFFEFF6FF)),
        _kpiCard(
            'Abiertos', '${t.open}', Icons.play_circle_outline_rounded,
            Color(0xFFF59E0B), Color(0xFFFEF3C7)),
        _kpiCard(
            'Sellados', '${t.closed}', Icons.verified_rounded,
            Color(0xFF10B981), Color(0xFFECFDF5)),
        _kpiCard(
            'Vencidos', '${t.overdueSteps}', Icons.warning_amber_rounded,
            Color(0xFFEF4444), Color(0xFFFEF2F2)),
      ],
    );
  }

  Widget _kpiCard(
      String label, String value, IconData icon, Color accent, Color bg) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: accent),
          SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: accent)),
          SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textLight)),
        ],
      ),
    );
  }

  // ── Monthly Bar Chart ──

  Widget _monthlyChart(List<MonthMetric> data) {
    if (data.isEmpty) {
      return _emptyCard('Sin datos aun');
    }

    final maxVal = data
        .map((d) => d.created > d.closed ? d.created : d.closed)
        .fold<int>(0, (a, b) => a > b ? a : b)
        .toDouble();
    final maxY = maxVal < 1 ? 5.0 : (maxVal * 1.3).ceilToDouble();

    return Container(
      height: 220,
      padding: EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _legendDot(Color(0xFF2563EB), 'Creados'),
              SizedBox(width: 16),
              _legendDot(Color(0xFF10B981), 'Sellados'),
            ],
          ),
          SizedBox(height: 12),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: maxY,
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toInt()}',
                        TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= data.length) return SizedBox();
                        final parts = data[i].month.split('-');
                        final month = _monthShort(int.tryParse(parts[1]) ?? 0);
                        return Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(month,
                              style: TextStyle(
                                  fontSize: 10, color: AppTheme.textLight)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: maxY / 4,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return SizedBox();
                        return Text('${value.toInt()}',
                            style: TextStyle(
                                fontSize: 10, color: AppTheme.textLight));
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Color(0xFFE2E8F0),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: data.asMap().entries.map((e) {
                  final i = e.key;
                  final d = e.value;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: d.created.toDouble(),
                        color: Color(0xFF2563EB),
                        width: 12,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: d.closed.toDouble(),
                        color: Color(0xFF10B981),
                        width: 12,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Industry Breakdown ──

  Widget _industryBreakdown(List<IndustryMetric> data) {
    if (data.isEmpty) return _emptyCard('Sin industrias');
    return Container(
      padding: EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: data.map((ind) {
          final progress =
              ind.total > 0 ? ind.closed / ind.total : 0.0;
          return Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(ind.industry,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark)),
                    ),
                    Text('${ind.closed}/${ind.total}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textLight)),
                  ],
                ),
                SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Color(0xFFE2E8F0),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Top Clients ──

  Widget _topClients(List<ClientMetric> data) {
    if (data.isEmpty) return _emptyCard('Sin clientes');
    return Container(
      padding: EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: data.asMap().entries.map((e) {
          final i = e.key;
          final c = e.value;
          return Padding(
            padding: EdgeInsets.only(bottom: i < data.length - 1 ? 10 : 0),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Center(
                    child: Text('${i + 1}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2563EB))),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.clientName,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark)),
                      SizedBox(height: 2),
                      Text('${c.total} procesos',
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.textLight)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${c.closed} sellados',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981))),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Blockchain Stats ──

  Widget _blockchainStats(Totals t) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: _blockchainStat(
                'Confirmados', '${t.confirmedSteps}', Color(0xFF10B981)),
          ),
          Container(width: 1, height: 36, color: Color(0xFFE2E8F0)),
          Expanded(
            child: _blockchainStat(
                'Pendientes', '${t.pendingSteps}', Color(0xFFF59E0B)),
          ),
          Container(width: 1, height: 36, color: Color(0xFFE2E8F0)),
          Expanded(
            child: _blockchainStat(
                'Transacciones', '${t.txBlockchain}', Color(0xFF2563EB)),
          ),
        ],
      ),
    );
  }

  Widget _blockchainStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color)),
        SizedBox(height: 2),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppTheme.textLight)),
      ],
    );
  }

  // ── Completion Rate Bar ──

  Widget _completionBar(List<CompletionRate> data) {
    if (data.isEmpty) return _emptyCard('Sin datos');
    return Container(
      padding: EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: data.map((d) {
          final color =
              d.label == 'Abiertos' ? Color(0xFFF59E0B) : Color(0xFF10B981);
          return Expanded(
            child: Column(
              children: [
                Text('${d.value}%',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: color)),
                SizedBox(height: 2),
                Text(d.label,
                    style:
                        TextStyle(fontSize: 12, color: AppTheme.textLight)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Helpers ──

  Widget _emptyCard(String text) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Center(
        child: Text(text,
            style: TextStyle(fontSize: 13, color: AppTheme.textLight)),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 11, color: AppTheme.textLight)),
      ],
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: Offset(0, 2)),
        ],
      );

  String _monthShort(int m) {
    const months = [
      '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return m >= 1 && m <= 12 ? months[m] : '';
  }
}

class _MetricsSkeleton extends StatelessWidget {
  const _MetricsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        const SkeletonBox(width: 140, height: 18),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(child: SkeletonBox(height: 84)),
            const SizedBox(width: 12),
            const Expanded(child: SkeletonBox(height: 84)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Expanded(child: SkeletonBox(height: 84)),
            const SizedBox(width: 12),
            const Expanded(child: SkeletonBox(height: 84)),
          ],
        ),
        const SizedBox(height: 24),
        const SkeletonBox(width: 140, height: 18),
        const SizedBox(height: 16),
        const SkeletonBox(height: 180),
        const SizedBox(height: 24),
        const SkeletonBox(width: 140, height: 18),
        const SizedBox(height: 16),
        const SkeletonBox(height: 120),
        const SizedBox(height: 24),
        const SkeletonBox(width: 140, height: 18),
        const SizedBox(height: 16),
        const SkeletonBox(height: 120),
      ],
    );
  }
}
