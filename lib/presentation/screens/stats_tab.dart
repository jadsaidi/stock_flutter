import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/data_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/product.dart';
import '../widgets/glass_card.dart';

class StatsTab extends ConsumerWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return productsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.neonCyan),
      ),
      error: (e, st) => Center(
        child: Text('Erreur: $e', style: const TextStyle(color: AppColors.neonPink)),
      ),
      data: (products) {
        final lowStockProducts = products.where((p) => p.currentStock < p.minStockLevel).toList();
        final totalProducts = products.length;
        final totalStock = products.fold<int>(0, (sum, p) => sum + p.currentStock);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.inventory_2_rounded,
                    label: 'Produits',
                    value: '$totalProducts',
                    color: AppColors.neonCyan,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.warehouse_rounded,
                    label: 'Stock Total',
                    value: '$totalStock',
                    color: AppColors.neonPurple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.warning_amber_rounded,
                    label: 'Alertes',
                    value: '${lowStockProducts.length}',
                    color: AppColors.neonPink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Alert Section
            if (lowStockProducts.isNotEmpty)
              _buildAlertCard(context, lowStockProducts),
            if (lowStockProducts.isNotEmpty) const SizedBox(height: 24),

            // Chart Section
            ShaderMask(
              shaderCallback: (bounds) => AppColors.quantumGradient.createShader(bounds),
              child: Text(
                'Aperçu du Stock',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            _buildStockChart(products),
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, List<Product> lowStockProducts) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.neonPink.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: AppColors.neonPink, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Alerte de Stock',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.neonPink,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...lowStockProducts.map((p) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.neonPink.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.neonPink.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.trending_down, color: AppColors.neonPink, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    p.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
                Text(
                  '${p.currentStock}/${p.minStockLevel}',
                  style: const TextStyle(color: AppColors.neonPink, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildStockChart(List<Product> products) {
    if (products.isEmpty) {
      return const GlassCard(
        child: Center(
          child: Text('Aucune donnée à afficher', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    return GlassCard(
      child: AspectRatio(
        aspectRatio: 1.5,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: products.map((e) => e.currentStock).reduce((a, b) => a > b ? a : b).toDouble() * 1.3,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => Colors.black.withOpacity(0.8),
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 && value.toInt() < products.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          products[value.toInt()].name.length > 6
                              ? '${products[value.toInt()].name.substring(0, 6)}...'
                              : products[value.toInt()].name,
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.white.withOpacity(0.05),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: products.asMap().entries.map((entry) {
              final isLow = entry.value.currentStock < entry.value.minStockLevel;
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value.currentStock.toDouble(),
                    gradient: isLow
                        ? const LinearGradient(colors: [AppColors.neonPink, Color(0xFFFF6B6B)], begin: Alignment.bottomCenter, end: Alignment.topCenter)
                        : AppColors.quantumGradient,
                    width: 20,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: products.map((e) => e.currentStock).reduce((a, b) => a > b ? a : b).toDouble() * 1.3,
                      color: Colors.white.withOpacity(0.03),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
