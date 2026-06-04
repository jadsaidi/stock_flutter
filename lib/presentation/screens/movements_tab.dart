import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/data_provider.dart';
import '../../providers/db_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/movement.dart';
import '../../domain/models/product.dart';

class MovementsTab extends ConsumerWidget {
  const MovementsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movementsAsync = ref.watch(movementsProvider);
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      body: movementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Erreur: $e')),
        data: (movements) {
          if (movements.isEmpty) {
            return const Center(child: Text('Aucun mouvement.'));
          }
          return ListView.builder(
            itemCount: movements.length,
            itemBuilder: (context, index) {
              final movement = movements[index];
              final product = _getProduct(movement.productId, productsAsync.value);
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: movement.type == MovementType.inStock ? AppColors.secondary.withOpacity(0.2) : AppColors.error.withOpacity(0.2),
                    child: Icon(
                      movement.type == MovementType.inStock ? Icons.arrow_downward : Icons.arrow_upward,
                      color: movement.type == MovementType.inStock ? AppColors.secondary : AppColors.error,
                    ),
                  ),
                  title: Text(product?.name ?? 'Produit inconnu'),
                  subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(movement.date)),
                  trailing: Text(
                    '${movement.type == MovementType.inStock ? '+' : '-'}${movement.quantity}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: movement.type == MovementType.inStock ? AppColors.secondary : AppColors.error,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMovementDialog(context, ref, productsAsync.value ?? []),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.sync_alt, color: Colors.white),
        label: const Text('Nouveau Flux', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Product? _getProduct(String productId, List<Product>? products) {
    if (products == null) return null;
    try {
      return products.firstWhere((p) => p.id == productId);
    } catch (e) {
      return null;
    }
  }

  void _showAddMovementDialog(BuildContext context, WidgetRef ref, List<Product> products) {
    String? selectedProductId;
    MovementType selectedType = MovementType.inStock;
    final quantityCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Nouveau Mouvement'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<String>(
                      value: selectedProductId,
                      hint: const Text('Sélectionner un produit'),
                      isExpanded: true,
                      items: products.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.name} (Stock: ${p.currentStock})'))).toList(),
                      onChanged: (val) => setState(() => selectedProductId = val),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<MovementType>(
                            title: const Text('Entrée'),
                            value: MovementType.inStock,
                            groupValue: selectedType,
                            onChanged: (val) => setState(() => selectedType = val!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<MovementType>(
                            title: const Text('Sortie'),
                            value: MovementType.outStock,
                            groupValue: selectedType,
                            onChanged: (val) => setState(() => selectedType = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: quantityCtrl,
                      decoration: const InputDecoration(labelText: 'Quantité'),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                ElevatedButton(
                  onPressed: () {
                    if (selectedProductId != null && quantityCtrl.text.isNotEmpty) {
                      final product = _getProduct(selectedProductId!, products);
                      final movement = Movement(
                        id: '',
                        productId: selectedProductId!,
                        type: selectedType,
                        quantity: int.tryParse(quantityCtrl.text) ?? 0,
                        date: DateTime.now(),
                        priceAtMovement: product?.price,
                      );
                      ref.read(dbServiceProvider)?.addMovement(movement);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Valider'),
                ),
              ],
            );
          }
        );
      },
    );
  }
}
