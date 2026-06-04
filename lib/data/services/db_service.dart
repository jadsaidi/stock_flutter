import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/product.dart';
import '../../domain/models/category.dart';
import '../../domain/models/movement.dart';

class DBService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String clientId;

  DBService({required this.clientId});

  DocumentReference get clientDoc => _firestore.collection('clients').doc(clientId);

  // CATEGORIES
  Stream<List<Category>> getCategories() {
    return clientDoc.collection('categories').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Category.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> addCategory(Category category) async {
    await clientDoc.collection('categories').add(category.toMap());
  }

  // PRODUCTS
  Stream<List<Product>> getProducts() {
    return clientDoc.collection('products').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> addProduct(Product product) async {
    await clientDoc.collection('products').add(product.toMap());
  }

  Future<void> updateProductStock(String productId, int newStock) async {
    await clientDoc.collection('products').doc(productId).update({'currentStock': newStock});
  }

  // MOVEMENTS
  Stream<List<Movement>> getMovements() {
    return clientDoc.collection('movements').orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Movement.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> addMovement(Movement movement) async {
    final batch = _firestore.batch();
    
    // Add movement
    final movementRef = clientDoc.collection('movements').doc();
    batch.set(movementRef, movement.toMap());

    // Update product stock
    final productRef = clientDoc.collection('products').doc(movement.productId);
    final productDoc = await productRef.get();
    
    if (productDoc.exists) {
      final product = Product.fromMap(productDoc.data()!, productDoc.id);
      final int quantityChange = movement.type == MovementType.inStock ? movement.quantity : -movement.quantity;
      final int newStock = product.currentStock + quantityChange;
      batch.update(productRef, {'currentStock': newStock});
    }

    await batch.commit();
  }
}
