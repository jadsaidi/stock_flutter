class Product {
  final String id;
  final String name;
  final String categoryId;
  final int currentStock;
  final int minStockLevel;
  final double price;

  Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.currentStock,
    required this.minStockLevel,
    required this.price,
  });

  factory Product.fromMap(Map<String, dynamic> map, String documentId) {
    return Product(
      id: documentId,
      name: map['name'] ?? '',
      categoryId: map['categoryId'] ?? '',
      currentStock: map['currentStock']?.toInt() ?? 0,
      minStockLevel: map['minStockLevel']?.toInt() ?? 0,
      price: map['price']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'categoryId': categoryId,
      'currentStock': currentStock,
      'minStockLevel': minStockLevel,
      'price': price,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? categoryId,
    int? currentStock,
    int? minStockLevel,
    double? price,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      currentStock: currentStock ?? this.currentStock,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      price: price ?? this.price,
    );
  }
}
