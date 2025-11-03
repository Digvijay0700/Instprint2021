import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String? _uid;
  String? _email;
  String? _name;
  String? _phone;

  // Getters
  String? get uid => _uid;
  String? get email => _email;
  String? get name => _name;
  String? get phone => _phone;

  // Set user from Firestore data
  void setUser(Map<String, dynamic> userData) {
    _uid = userData['uid'];
    _email = userData['email'];
    _name = userData['name'];
    _phone = userData['phone'];
    notifyListeners();
  }

  // Optional: Set UID separately if needed
  void setUid(String uid) {
    _uid = uid;
    notifyListeners();
  }
}
