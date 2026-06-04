import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      print("Erreur de récupération de l'utilisateur: $e");
    }
    return null;
  }

  Future<UserModel?> signInWithEmailPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (credential.user != null) {
        return await getUserData(credential.user!.uid);
      }
    } catch (e) {
      print("Erreur de connexion: $e");
      rethrow;
    }
    return null;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Pour le test uniquement, permet de créer un compte avec un clientId associé
  Future<UserModel?> registerWithEmailPassword(String email, String password, String clientId) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (credential.user != null) {
        final userModel = UserModel(id: credential.user!.uid, email: email, clientId: clientId);
        await _firestore.collection('users').doc(credential.user!.uid).set(userModel.toMap());
        return userModel;
      }
    } catch (e) {
      print("Erreur d'inscription: $e");
      rethrow;
    }
    return null;
  }
}
