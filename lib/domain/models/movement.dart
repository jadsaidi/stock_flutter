import 'package:cloud_firestore/cloud_firestore.dart';

enum MovementType { inStock, outStock }

class Movement {
  final String id;
  final String productId;
  final MovementType type;
  final int quantity;
  final DateTime date;
  final double? priceAtMovement; // Prix lors du mouvement, utile pour les stats de ventes

  Movement({
    required this.id,
    required this.productId,
    required this.type,
    required this.quantity,
    required this.date,
    this.priceAtMovement,
  });

  factory Movement.fromMap(Map<String, dynamic> map, String documentId) {
    return Movement(
      id: documentId,
      productId: map['productId'] ?? '',
      type: (map['type'] == 'IN') ? MovementType.inStock : MovementType.outStock,
      quantity: map['quantity']?.toInt() ?? 0,
      date: (map['date'] as Timestamp).toDate(),
      priceAtMovement: map['priceAtMovement']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'type': type == MovementType.inStock ? 'IN' : 'OUT',
      'quantity': quantity,
      'date': Timestamp.fromDate(date),
      'priceAtMovement': priceAtMovement,
    };
  }
}
