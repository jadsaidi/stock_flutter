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
            colorScheme: const ColorScheme.dark(primary: AppColors.neonCyan, onPrimary: Colors.white, surface: Color(0xFF0A0A15), onSurface: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDateRange = picked);
  }

  List<Movement> _filterMovementsByDate(List<Movement> movements) {
    if (_selectedDateRange == null) return movements;
    return movements.where((m) => m.date.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) && m.date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)))).toList();
  }

  @override
  Widget build(BuildContext context) {
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
        final totalStock = products.fold<int>(0, (sum, p) => sum + p.currentStock);

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // Header with Compact Date Picker
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => AppColors.quantumGradient.createShader(bounds),
                  child: const Text('Vue Générale', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                ),
                GestureDetector(
                  onTap: _pickDateRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.neonCyan.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.neonCyan.withOpacity(0.3))),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_rounded, color: AppColors.neonCyan, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          _selectedDateRange == null ? '30 Derniers Jours' : '${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}',
                          style: const TextStyle(color: AppColors.neonCyan, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Compact Stats Row
            Row(
              children: [
                Expanded(child: _buildCompactStatCard(icon: Icons.inventory_2, label: 'Produits', value: '${products.length}', color: AppColors.neonCyan)),
                const SizedBox(width: 8),
                Expanded(child: _buildCompactStatCard(icon: Icons.warehouse, label: 'Total Stock', value: '$totalStock', color: AppColors.neonPurple)),
                const SizedBox(width: 8),
                Expanded(child: _buildCompactStatCard(icon: Icons.warning_amber, label: 'Alertes', value: '${lowStockProducts.length}', color: AppColors.neonPink)),
              ],
            ),
            const SizedBox(height: 16),

            // Compact Alert Banner (only if alerts exist)
            if (lowStockProducts.isNotEmpty) _buildCompactAlertBanner(lowStockProducts),
            if (lowStockProducts.isNotEmpty) const SizedBox(height: 16),

            // Stock Chart (More compact aspect ratio)
            const Text('📊 État du stock', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _buildStockChart(products),
            const SizedBox(height: 16),

            // Two columns layout for wide screens, or stacked for mobile
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildTopSellingSection(filteredMovements, products)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildSalesCategorySection(filteredMovements, products, categories)),
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopSellingSection(filteredMovements, products),
                      const SizedBox(height: 16),
                      _buildSalesCategorySection(filteredMovements, products, categories),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 100),
          ],
        );
      },
    );
  }

  Widget _buildCompactStatCard({required IconData icon, required String label, required String value, required Color color}) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      borderRadius: 16,
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildCompactAlertBanner(List<Product> lowStockProducts) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: AppColors.neonPink.withOpacity(0.15), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.neonPink.withOpacity(0.3))),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: AppColors.neonPink, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Stock critique', style: TextStyle(color: AppColors.neonPink, fontWeight: FontWeight.w700, fontSize: 14)),
                Text('${lowStockProducts.length} produit(s) à réapprovisionner', style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockChart(List<Product> products) {
    if (products.isEmpty) return const GlassCard(child: SizedBox(height: 100, child: Center(child: Text('Aucune donnée', style: TextStyle(color: AppColors.textSecondary)))));
    
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: AspectRatio(
        aspectRatio: 2.2, // Plus compact en hauteur
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: products.map((e) => e.currentStock).reduce((a, b) => a > b ? a : b).toDouble() * 1.3,
            barTouchData: BarTouchData(enabled: true, touchTooltipData: BarTouchTooltipData(getTooltipColor: (_) => Colors.black.withOpacity(0.8))),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 22, getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < products.length) {
                  final name = products[value.toInt()].name;
                  return Padding(padding: const EdgeInsets.only(top: 4), child: Text(name.length > 5 ? '${name.substring(0, 5)}.' : name, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)));
                }
                return const SizedBox();
              })),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)))),
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
                  width: 12, // Barres plus fines
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  backDrawRodData: BackgroundBarChartRodData(show: true, toY: products.map((e) => e.currentStock).reduce((a, b) => a > b ? a : b).toDouble() * 1.3, color: Colors.white.withOpacity(0.03)),
                ),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTopSellingSection(List<Movement> movements, List<Product> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🏆 Top Ventes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _buildTopSellingProducts(movements, products),
      ],
    );
  }

  Widget _buildTopSellingProducts(List<Movement> movements, List<Product> products) {
    final sales = movements.where((m) => m.type == MovementType.outStock).toList();
    if (sales.isEmpty) return const GlassCard(child: SizedBox(height: 80, child: Center(child: Text('Aucune vente', style: TextStyle(color: AppColors.textSecondary)))));

    final Map<String, int> salesMap = {};
    for (final m in sales) salesMap[m.productId] = (salesMap[m.productId] ?? 0) + m.quantity;
    final sortedSales = salesMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: sortedSales.take(3).toList().asMap().entries.map((entry) {
          final rank = entry.key + 1;
          final qty = entry.value.value;
          final product = products.where((p) => p.id == entry.value.key).firstOrNull;
          final maxQty = sortedSales.first.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text('#$rank', style: TextStyle(color: rank == 1 ? const Color(0xFFFFD700) : AppColors.textSecondary, fontWeight: FontWeight.w800, fontSize: 12)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product?.name ?? 'Inconnu', style: const TextStyle(color: Colors.white, fontSize: 12)),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(value: maxQty > 0 ? qty / maxQty : 0, backgroundColor: Colors.white.withOpacity(0.05), valueColor: AlwaysStoppedAnimation<Color>(rank == 1 ? const Color(0xFFFFD700) : AppColors.neonCyan), minHeight: 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text('$qty', style: const TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.w700, fontSize: 14)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSalesCategorySection(List<Movement> movements, List<Product> products, List<Category> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('📂 Répartition Ventes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _buildSalesByCategory(movements, products, categories),
      ],
    );
  }

  Widget _buildSalesByCategory(List<Movement> movements, List<Product> products, List<Category> categories) {
    final sales = movements.where((m) => m.type == MovementType.outStock).toList();
    if (sales.isEmpty || categories.isEmpty) return const GlassCard(child: SizedBox(height: 80, child: Center(child: Text('Aucune vente', style: TextStyle(color: AppColors.textSecondary)))));

    final Map<String, double> revMap = {};
    for (final m in sales) {
      final product = products.where((p) => p.id == m.productId).firstOrNull;
      if (product != null) revMap[product.categoryId] = (revMap[product.categoryId] ?? 0) + (m.priceAtMovement ?? product.price) * m.quantity;
    }

    final colors = [AppColors.neonCyan, AppColors.neonPurple, AppColors.neonPink, const Color(0xFFFFD700)];

    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: AspectRatio(
              aspectRatio: 1.0,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 20, // Plus petit
                  sections: revMap.entries.toList().asMap().entries.map((entry) {
                    final total = revMap.values.fold<double>(0, (a, b) => a + b);
                    return PieChartSectionData(
                      color: colors[entry.key % colors.length],
                      value: entry.value.value,
                      title: '${(entry.value.value / total * 100).toStringAsFixed(0)}%',
                      radius: 30,
                      titleStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: revMap.entries.toList().asMap().entries.map((entry) {
                final cat = categories.where((c) => c.id == entry.value.key).firstOrNull;
                final color = colors[entry.key % colors.length];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Expanded(child: Text(cat?.name ?? 'Inc', style: const TextStyle(color: Colors.white, fontSize: 10), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

