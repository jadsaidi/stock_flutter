import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/data_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/product.dart';
import '../../domain/models/category.dart';
import '../../providers/db_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/neon_button.dart';

class ProductsTab extends ConsumerWidget {
  const ProductsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
        error: (e, st) => Center(child: Text('Erreur: $e', style: const TextStyle(color: AppColors.neonPink))),
        data: (products) {
          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => AppColors.quantumGradient.createShader(bounds),
                    child: const Icon(Icons.inventory_2_outlined, size: 80, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text('Aucun produit', style: TextStyle(color: AppColors.textSecondary, fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text('Appuyez sur + pour en ajouter un', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final isLow = product.currentStock < product.minStockLevel;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: isLow
                              ? const LinearGradient(colors: [AppColors.neonPink, Color(0xFFFF6B6B)])
                              : AppColors.quantumGradient,
                          boxShadow: [
                            BoxShadow(
                              color: (isLow ? AppColors.neonPink : AppColors.neonPurple).withOpacity(0.3),
                              blurRadius: 12,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          isLow ? Icons.warning_amber_rounded : Icons.inventory_2_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${product.price} DHS',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isLow ? AppColors.neonPink.withOpacity(0.15) : AppColors.neonCyan.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isLow ? AppColors.neonPink.withOpacity(0.3) : AppColors.neonCyan.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              '${product.currentStock}',
                              style: TextStyle(
                                color: isLow ? AppColors.neonPink : AppColors.neonCyan,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isLow ? 'Stock Faible' : 'En Stock',
                            style: TextStyle(
                              color: isLow ? AppColors.neonPink : AppColors.neonCyan,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppColors.quantumGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: AppColors.neonPurple.withOpacity(0.4), blurRadius: 15, spreadRadius: 0),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showAddProductDialog(context, ref, categoriesAsync.value ?? []),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  void _showAddProductDialog(BuildContext context, WidgetRef ref, List<Category> categories) {
    final nameCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    final minStockCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String? selectedCategoryId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0A0A15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              title: ShaderMask(
                shaderCallback: (bounds) => AppColors.quantumGradient.createShader(bounds),
                child: const Text('Ajouter un Produit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Nom du produit')),
                    const SizedBox(height: 12),
                    TextField(controller: stockCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Stock initial'), keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    TextField(controller: minStockCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Stock minimum (Alerte)'), keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    TextField(controller: priceCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Prix (DHS)'), keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                            value: selectedCategoryId,
                            hint: const Text('Catégorie', style: TextStyle(color: AppColors.textSecondary)),
                            isExpanded: true,
                            dropdownColor: const Color(0xFF0A0A15),
                            items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, style: const TextStyle(color: Colors.white)))).toList(),
                            onChanged: (val) => setState(() => selectedCategoryId = val),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.quantumGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.add, color: Colors.white),
                            onPressed: () => _showAddCategoryDialog(context, ref),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary))),
                Container(
                  decoration: BoxDecoration(gradient: AppColors.quantumGradient, borderRadius: BorderRadius.circular(12)),
                  child: TextButton(
                    onPressed: () {
                      if (nameCtrl.text.isNotEmpty && selectedCategoryId != null) {
                        final product = Product(id: '', name: nameCtrl.text, categoryId: selectedCategoryId!, currentStock: int.tryParse(stockCtrl.text) ?? 0, minStockLevel: int.tryParse(minStockCtrl.text) ?? 0, price: double.tryParse(priceCtrl.text) ?? 0.0);
                        ref.read(dbServiceProvider)?.addProduct(product);
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Ajouter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.white.withOpacity(0.1))),
        title: ShaderMask(
          shaderCallback: (bounds) => AppColors.quantumGradient.createShader(bounds),
          child: const Text('Nouvelle Catégorie', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
        content: TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Nom de la catégorie')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary))),
          Container(
            decoration: BoxDecoration(gradient: AppColors.quantumGradient, borderRadius: BorderRadius.circular(12)),
            child: TextButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  ref.read(dbServiceProvider)?.addCategory(Category(id: '', name: nameCtrl.text));
                  Navigator.pop(context);
                }
              },
              child: const Text('Créer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
