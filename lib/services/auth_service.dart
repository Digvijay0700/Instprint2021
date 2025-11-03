import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(userCred.user!.uid).set({
        'name': name,
        'phone': phone,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return userCred.user;
    } catch (e) {
      print("Registration Error: $e");
      rethrow;
    }
  }

  Future<User?> login(String email, String password) async {
    try {
      UserCredential userCred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCred.user;
    } catch (e) {
      print("Login Error: $e");
      rethrow;
    }
  }
}
