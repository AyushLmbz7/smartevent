import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  String? get currentUserId => _auth.currentUser?.uid;

  Future<void> register(
    String name,
    String email,
    String password,
    String confirm,
    String role,
  ) async {
    final user = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await _db.collection('users').doc(user.user!.uid).set({
      'name': name.trim(),
      'email': email.trim(),
      'role': role,
    });
  }

  Future<User?> login(String email, String password) async {
    final user = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return user.user;
  }

  Future<String> getRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    // return doc['role'];
    if (doc.exists && doc.data()!.containsKey('role')) {
      return doc['role'];
    } else {
      return "participant"; // default fallback
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
