import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/data_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/product.dart';

class StatsTab extends ConsumerWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    
    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Erreur: $e')),
      data: (products) {
        final lowStockProducts = products.where((p) => p.currentStock < p.minStockLevel).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (lowStockProducts.isNotEmpty)
              _buildAlertCard(context, lowStockProducts),
            const SizedBox(height: 24),
            Text('Aperçu du stock', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildStockChart(products),
          ],
        );
      },
    );
  }

  Widget _buildAlertCard(BuildContext context, List<Product> lowStockProducts) {
    return Card(
      color: AppColors.error.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.error, width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.error),
                const SizedBox(width: 8),
                Text('Alerte de Stock', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.error)),
              ],
            ),
            const SizedBox(height: 16),
            ...lowStockProducts.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text('• ${p.name} (Stock: ${p.currentStock} / Min: ${p.minStockLevel})', style: const TextStyle(color: AppColors.error)),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildStockChart(List<Product> products) {
    if (products.isEmpty) return const SizedBox();
    
    return AspectRatio(
      aspectRatio: 1.5,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: products.map((e) => e.currentStock).reduce((a, b) => a > b ? a : b).toDouble() * 1.2,
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < products.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(products[value.toInt()].name, style: const TextStyle(fontSize: 10)),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: products.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.currentStock.toDouble(),
                      color: entry.value.currentStock < entry.value.minStockLevel ? AppColors.error : AppColors.primary,
                      width: 16,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
