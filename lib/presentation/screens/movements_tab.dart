import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/data_provider.dart';
import '../../providers/db_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/movement.dart';
import '../../domain/models/product.dart';
import '../widgets/glass_card.dart';

class MovementsTab extends ConsumerWidget {
  const MovementsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movementsAsync = ref.watch(movementsProvider);
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: movementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
        error: (e, st) => Center(child: Text('Erreur: $e', style: const TextStyle(color: AppColors.neonPink))),
        data: (movements) {
          if (movements.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => AppColors.quantumGradient.createShader(bounds),
                    child: const Icon(Icons.swap_horiz_rounded, size: 80, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text('Aucun mouvement', style: TextStyle(color: AppColors.textSecondary, fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text('Effectuez une entrée ou sortie de stock', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: movements.length,
            itemBuilder: (context, index) {
              final movement = movements[index];
              final product = _getProduct(movement.productId, productsAsync.value);
              final isIn = movement.type == MovementType.inStock;

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
                          color: isIn ? AppColors.neonCyan.withOpacity(0.15) : AppColors.neonPink.withOpacity(0.15),
                          border: Border.all(
                            color: isIn ? AppColors.neonCyan.withOpacity(0.3) : AppColors.neonPink.withOpacity(0.3),
                          ),
                        ),
                        child: Icon(
                          isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                          color: isIn ? AppColors.neonCyan : AppColors.neonPink,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product?.name ?? 'Produit inconnu',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isIn ? AppColors.neonCyan.withOpacity(0.1) : AppColors.neonPink.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isIn ? 'ENTRÉE' : 'SORTIE',
                                    style: TextStyle(
                                      color: isIn ? AppColors.neonCyan : AppColors.neonPink,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('dd/MM/yyyy HH:mm').format(movement.date),
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${isIn ? '+' : '-'}${movement.quantity}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          color: isIn ? AppColors.neonCyan : AppColors.neonPink,
                        ),
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
        child: FloatingActionButton.extended(
          onPressed: () => _showAddMovementDialog(context, ref, productsAsync.value ?? []),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.sync_alt, color: Colors.white),
          label: const Text('Nouveau Flux', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
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
              backgroundColor: const Color(0xFF0A0A15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              title: ShaderMask(
                shaderCallback: (bounds) => AppColors.quantumGradient.createShader(bounds),
                child: const Text('Nouveau Mouvement', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<String>(
                      value: selectedProductId,
                      hint: const Text('Sélectionner un produit', style: TextStyle(color: AppColors.textSecondary)),
                      isExpanded: true,
                      dropdownColor: const Color(0xFF0A0A15),
                      items: products.map((p) => DropdownMenuItem(
                        value: p.id,
                        child: Text('${p.name} (Stock: ${p.currentStock})', style: const TextStyle(color: Colors.white)),
                      )).toList(),
                      onChanged: (val) => setState(() => selectedProductId = val),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => selectedType = MovementType.inStock),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: selectedType == MovementType.inStock
                                    ? AppColors.neonCyan.withOpacity(0.2)
                                    : Colors.white.withOpacity(0.05),
                                border: Border.all(
                                  color: selectedType == MovementType.inStock
                                      ? AppColors.neonCyan
                                      : Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.arrow_downward, color: selectedType == MovementType.inStock ? AppColors.neonCyan : AppColors.textSecondary),
                                  const SizedBox(height: 4),
                                  Text('Entrée', style: TextStyle(color: selectedType == MovementType.inStock ? AppColors.neonCyan : AppColors.textSecondary, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => selectedType = MovementType.outStock),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: selectedType == MovementType.outStock
                                    ? AppColors.neonPink.withOpacity(0.2)
                                    : Colors.white.withOpacity(0.05),
                                border: Border.all(
                                  color: selectedType == MovementType.outStock
                                      ? AppColors.neonPink
                                      : Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.arrow_upward, color: selectedType == MovementType.outStock ? AppColors.neonPink : AppColors.textSecondary),
                                  const SizedBox(height: 4),
                                  Text('Sortie', style: TextStyle(color: selectedType == MovementType.outStock ? AppColors.neonPink : AppColors.textSecondary, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: quantityCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Quantité'),
                      keyboardType: TextInputType.number,
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
                      if (selectedProductId != null && quantityCtrl.text.isNotEmpty) {
                        final product = _getProduct(selectedProductId!, products);
                        final movement = Movement(id: '', productId: selectedProductId!, type: selectedType, quantity: int.tryParse(quantityCtrl.text) ?? 0, date: DateTime.now(), priceAtMovement: product?.price);
                        ref.read(dbServiceProvider)?.addMovement(movement);
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Valider', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
