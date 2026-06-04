import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/category.dart';
import '../domain/models/product.dart';
import '../domain/models/movement.dart';
import 'db_provider.dart';

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final dbService = ref.watch(dbServiceProvider);
  if (dbService != null) {
    return dbService.getCategories();
  }
  return const Stream.empty();
});

final productsProvider = StreamProvider<List<Product>>((ref) {
  final dbService = ref.watch(dbServiceProvider);
  if (dbService != null) {
    return dbService.getProducts();
  }
  return const Stream.empty();
});

final movementsProvider = StreamProvider<List<Movement>>((ref) {
  final dbService = ref.watch(dbServiceProvider);
  if (dbService != null) {
    return dbService.getMovements();
  }
  return const Stream.empty();
});
