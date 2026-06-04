import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/data_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/product.dart';
import '../../domain/models/category.dart';
import '../../providers/db_provider.dart';

class ProductsTab extends ConsumerWidget {
  const ProductsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Erreur: $e')),
        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text('Aucun produit disponible.'));
          }
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.surface,
                    child: Icon(Icons.inventory, color: product.currentStock < product.minStockLevel ? AppColors.error : AppColors.secondary),
                  ),
                  title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Stock: ${product.currentStock} | Prix: ${product.price} DHS'),
                  trailing: Text(
                    product.currentStock < product.minStockLevel ? 'Faible' : 'OK',
                    style: TextStyle(color: product.currentStock < product.minStockLevel ? AppColors.error : AppColors.secondary),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductDialog(context, ref, categoriesAsync.value ?? []),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
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
              title: const Text('Ajouter un Produit'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nom du produit')),
                    const SizedBox(height: 8),
                    TextField(controller: stockCtrl, decoration: const InputDecoration(labelText: 'Stock initial'), keyboardType: TextInputType.number),
                    const SizedBox(height: 8),
                    TextField(controller: minStockCtrl, decoration: const InputDecoration(labelText: 'Stock minimum (Alerte)'), keyboardType: TextInputType.number),
                    const SizedBox(height: 8),
                    TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Prix'), keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                            value: selectedCategoryId,
                            hint: const Text('Catégorie'),
                            isExpanded: true,
                            items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                            onChanged: (val) => setState(() => selectedCategoryId = val),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: AppColors.secondary),
                          onPressed: () => _showAddCategoryDialog(context, ref),
                        )
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.isNotEmpty && selectedCategoryId != null) {
                      final product = Product(
                        id: '',
                        name: nameCtrl.text,
                        categoryId: selectedCategoryId!,
                        currentStock: int.tryParse(stockCtrl.text) ?? 0,
                        minStockLevel: int.tryParse(minStockCtrl.text) ?? 0,
                        price: double.tryParse(priceCtrl.text) ?? 0.0,
                      );
                      ref.read(dbServiceProvider)?.addProduct(product);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Ajouter'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle Catégorie'),
        content: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nom')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                ref.read(dbServiceProvider)?.addCategory(Category(id: '', name: nameCtrl.text));
                Navigator.pop(context);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }
}
