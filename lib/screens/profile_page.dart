import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatelessWidget {
  final String uid;

  const ProfilePage({super.key, required this.uid});

  Future<Map<String, dynamic>?> fetchUserData() async {
    final snap = await FirebaseFirestore.instance.collection("users").doc(uid).get();
    if (snap.exists) return snap.data();
    return null;
  }

  Widget buildInfoRow(String title, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade400),
      ),
      child: Row(
        children: [
          Text("$title:", style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile"), backgroundColor: Colors.amber),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: fetchUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.amber));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("User data not found"));
          }

          final user = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(Icons.account_circle, size: 100, color: Colors.amber),
                const SizedBox(height: 20),
                buildInfoRow("Name", user["name"] ?? ""),
                buildInfoRow("Email", user["email"] ?? ""),
                buildInfoRow("Phone", user["phone"] ?? ""),
                buildInfoRow("Year", user["year"] ?? ""),
              ],
            ),
          );
        },
      ),
    );
  }
}
