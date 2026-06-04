import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/data_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/product.dart';
import '../../domain/models/movement.dart';
import '../../domain/models/category.dart';
import '../widgets/glass_card.dart';

class StatsTab extends ConsumerStatefulWidget {
  const StatsTab({super.key});

  @override
  ConsumerState<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends ConsumerState<StatsTab> {
  DateTimeRange? _selectedDateRange;

  void _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _selectedDateRange ?? DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.neonCyan,
              onPrimary: Colors.white,
              surface: Color(0xFF0A0A15),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  List<Movement> _filterMovementsByDate(List<Movement> movements) {
    if (_selectedDateRange == null) return movements;
    return movements.where((m) {
      return m.date.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
             m.date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
    }).toList();
  }

  @override
  Widget build(BuildContext context, ) {
    final productsAsync = ref.watch(productsProvider);
    final movementsAsync = ref.watch(movementsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
      error: (e, st) => Center(child: Text('Erreur: $e', style: const TextStyle(color: AppColors.neonPink))),
      data: (products) {
        final movements = movementsAsync.value ?? [];
        final categories = categoriesAsync.value ?? [];
        final filteredMovements = _filterMovementsByDate(movements);
        final lowStockProducts = products.where((p) => p.currentStock < p.minStockLevel).toList();
        final totalProducts = products.length;
        final totalStock = products.fold<int>(0, (sum, p) => sum + p.currentStock);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Date Range Picker
            _buildDateRangePicker(),
            const SizedBox(height: 16),

            // Summary Row
            Row(
              children: [
                Expanded(child: _buildStatCard(context, icon: Icons.inventory_2_rounded, label: 'Produits', value: '$totalProducts', color: AppColors.neonCyan)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard(context, icon: Icons.warehouse_rounded, label: 'Stock Total', value: '$totalStock', color: AppColors.neonPurple)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard(context, icon: Icons.warning_amber_rounded, label: 'Alertes', value: '${lowStockProducts.length}', color: AppColors.neonPink)),
              ],
            ),
            const SizedBox(height: 24),

            // Alerts
            if (lowStockProducts.isNotEmpty) _buildAlertCard(context, lowStockProducts),
            if (lowStockProducts.isNotEmpty) const SizedBox(height: 24),

            // 1. État de stock par plage de date (Stock Chart)
            _buildSectionTitle('📊 État du stock'),
            const SizedBox(height: 12),
            _buildStockChart(products),
            const SizedBox(height: 24),

            // 2. Produits les plus vendus par plage de date
            _buildSectionTitle('🏆 Produits les plus vendus'),
            const SizedBox(height: 12),
            _buildTopSellingProducts(filteredMovements, products),
            const SizedBox(height: 24),

            // 3. Ventes par catégorie
            _buildSectionTitle('📂 Ventes par catégorie'),
            const SizedBox(height: 12),
            _buildSalesByCategory(filteredMovements, products, categories),
            const SizedBox(height: 100),
          ],
        );
      },
    );
  }

  Widget _buildDateRangePicker() {
    final now = DateTime.now();
    final range = _selectedDateRange ?? DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now);
    final format = DateFormat('dd/MM/yyyy');

    return GestureDetector(
      onTap: _pickDateRange,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.quantumGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Plage de date', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(
                    '${format.format(range.start)}  →  ${format.format(range.end)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_calendar_rounded, color: AppColors.neonCyan, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return ShaderMask(
      shaderCallback: (bounds) => AppColors.quantumGradient.createShader(bounds),
      child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildStatCard(BuildContext context, {required IconData icon, required String label, required String value, required Color color}) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
                decoration: BoxDecoration(color: AppColors.neonPink.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.warning_amber_rounded, color: AppColors.neonPink, size: 20),
              ),
              const SizedBox(width: 12),
              Text('🔔 Alerte de Stock', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.neonPink, fontSize: 18)),
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
                Expanded(child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white))),
                Text('${p.currentStock}/${p.minStockLevel}', style: const TextStyle(color: AppColors.neonPink, fontWeight: FontWeight.w700)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildStockChart(List<Product> products) {
    if (products.isEmpty) {
      return const GlassCard(child: Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Aucune donnée', style: TextStyle(color: AppColors.textSecondary)))));
    }

    return GlassCard(
      child: AspectRatio(
        aspectRatio: 1.5,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: products.map((e) => e.currentStock).reduce((a, b) => a > b ? a : b).toDouble() * 1.3,
            barTouchData: BarTouchData(enabled: true, touchTooltipData: BarTouchTooltipData(getTooltipColor: (_) => Colors.black.withOpacity(0.8))),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < products.length) {
                  final name = products[value.toInt()].name;
                  return Padding(padding: const EdgeInsets.only(top: 8), child: Text(name.length > 6 ? '${name.substring(0, 6)}..' : name, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)));
                }
                return const SizedBox();
              })),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)))),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1)),
            borderData: FlBorderData(show: false),
            barGroups: products.asMap().entries.map((entry) {
              final isLow = entry.value.currentStock < entry.value.minStockLevel;
              return BarChartGroupData(x: entry.key, barRods: [
                BarChartRodData(
                  toY: entry.value.currentStock.toDouble(),
                  gradient: isLow ? const LinearGradient(colors: [AppColors.neonPink, Color(0xFFFF6B6B)], begin: Alignment.bottomCenter, end: Alignment.topCenter) : AppColors.quantumGradient,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  backDrawRodData: BackgroundBarChartRodData(show: true, toY: products.map((e) => e.currentStock).reduce((a, b) => a > b ? a : b).toDouble() * 1.3, color: Colors.white.withOpacity(0.03)),
                ),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  // 2. Produits les plus vendus par plage de date
  Widget _buildTopSellingProducts(List<Movement> movements, List<Product> products) {
    final salesMovements = movements.where((m) => m.type == MovementType.outStock).toList();

    if (salesMovements.isEmpty) {
      return const GlassCard(child: Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Aucune vente sur cette période', style: TextStyle(color: AppColors.textSecondary)))));
    }

    // Aggregate sales per product
    final Map<String, int> salesByProduct = {};
    for (final m in salesMovements) {
      salesByProduct[m.productId] = (salesByProduct[m.productId] ?? 0) + m.quantity;
    }

    // Sort by quantity desc
    final sortedSales = salesByProduct.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return GlassCard(
      child: Column(
        children: sortedSales.take(5).toList().asMap().entries.map((entry) {
          final rank = entry.key + 1;
          final productId = entry.value.key;
          final qty = entry.value.value;
          final product = products.where((p) => p.id == productId).firstOrNull;
          final maxQty = sortedSales.first.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    gradient: rank == 1 ? const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]) : rank == 2 ? const LinearGradient(colors: [Color(0xFFC0C0C0), Color(0xFF808080)]) : rank == 3 ? const LinearGradient(colors: [Color(0xFFCD7F32), Color(0xFF8B4513)]) : null,
                    color: rank > 3 ? Colors.white.withOpacity(0.1) : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Text('#$rank', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product?.name ?? 'Inconnu', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: maxQty > 0 ? qty / maxQty : 0,
                          backgroundColor: Colors.white.withOpacity(0.05),
                          valueColor: AlwaysStoppedAnimation<Color>(rank == 1 ? const Color(0xFFFFD700) : AppColors.neonCyan),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text('$qty', style: const TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.w800, fontSize: 18)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // 3. Ventes par catégorie
  Widget _buildSalesByCategory(List<Movement> movements, List<Product> products, List<Category> categories) {
    final salesMovements = movements.where((m) => m.type == MovementType.outStock).toList();

    if (salesMovements.isEmpty || categories.isEmpty) {
      return const GlassCard(child: Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Aucune vente sur cette période', style: TextStyle(color: AppColors.textSecondary)))));
    }

    // Aggregate sales per category
    final Map<String, double> revenueByCategory = {};
    final Map<String, int> qtyByCategory = {};
    for (final m in salesMovements) {
      final product = products.where((p) => p.id == m.productId).firstOrNull;
      if (product != null) {
        final catId = product.categoryId;
        revenueByCategory[catId] = (revenueByCategory[catId] ?? 0) + (m.priceAtMovement ?? product.price) * m.quantity;
        qtyByCategory[catId] = (qtyByCategory[catId] ?? 0) + m.quantity;
      }
    }

    final categoryColors = [AppColors.neonCyan, AppColors.neonPurple, AppColors.neonPink, const Color(0xFFFFD700), const Color(0xFF00FF88)];

    return GlassCard(
      child: Column(
        children: [
          // Pie Chart
          if (revenueByCategory.isNotEmpty)
            AspectRatio(
              aspectRatio: 1.4,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 40,
                  sections: revenueByCategory.entries.toList().asMap().entries.map((entry) {
                    final catId = entry.value.key;
                    final revenue = entry.value.value;
                    final cat = categories.where((c) => c.id == catId).firstOrNull;
                    final color = categoryColors[entry.key % categoryColors.length];
                    final totalRevenue = revenueByCategory.values.fold<double>(0, (a, b) => a + b);
                    final percentage = totalRevenue > 0 ? (revenue / totalRevenue * 100) : 0;

                    return PieChartSectionData(
                      color: color,
                      value: revenue,
                      title: '${percentage.toStringAsFixed(0)}%',
                      radius: 50,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                    );
                  }).toList(),
                ),
              ),
            ),
          const SizedBox(height: 16),
          // Legend
          ...revenueByCategory.entries.toList().asMap().entries.map((entry) {
            final catId = entry.value.key;
            final revenue = entry.value.value;
            final qty = qtyByCategory[catId] ?? 0;
            final cat = categories.where((c) => c.id == catId).firstOrNull;
            final color = categoryColors[entry.key % categoryColors.length];

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(width: 10),
                  Expanded(child: Text(cat?.name ?? 'Inconnu', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                  Text('$qty unités', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(width: 12),
                  Text('${revenue.toStringAsFixed(0)} DHS', style: TextStyle(color: color, fontWeight: FontWeight.w800)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
