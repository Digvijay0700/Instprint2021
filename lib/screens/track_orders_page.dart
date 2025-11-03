import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TrackOrdersPage extends StatefulWidget {
  const TrackOrdersPage({super.key});

  @override
  State<TrackOrdersPage> createState() => _TrackOrdersPageState();
}

class _TrackOrdersPageState extends State<TrackOrdersPage> {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  List<Map<String, dynamic>> userOrders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserOrders();
  }

  Future<void> fetchUserOrders() async {
    if (userId == null) return;

    final shopkeepers = await FirebaseFirestore.instance.collection('shopkeepers').get();

    List<Map<String, dynamic>> fetchedOrders = [];

    for (var shopDoc in shopkeepers.docs) {
      final shopId = shopDoc.id;
      final shopName = shopDoc['name'] ?? 'Unknown Shop';

      final requests = await FirebaseFirestore.instance
          .collection('shopkeepers')
          .doc(shopId)
          .collection('print_requests')
          .where('userUid', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      for (var req in requests.docs) {
        var data = req.data();
        data['orderId'] = req.id;
        data['shopName'] = shopName;
        fetchedOrders.add(data);
      }
    }

    setState(() {
      userOrders = fetchedOrders;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Your Orders'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userOrders.isEmpty
          ? const Center(child: Text("No orders found."))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: userOrders.length,
        itemBuilder: (context, index) {
          final data = userOrders[index];
          final orderId = data['orderId'];
          final shopName = data['shopName'];
          final status = data['status'] ?? 'Pending';
          final timestamp = data['timestamp'] != null
              ? (data['timestamp'] as Timestamp).toDate()
              : null;

          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Order ID: $orderId",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Shop: $shopName",
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 8),
                  Text("Status: $status",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: status.toLowerCase() == 'completed'
                            ? Colors.green
                            : status.toLowerCase() == 'cancelled'
                            ? Colors.red
                            : Colors.orange,
                      )),
                  const SizedBox(height: 8),
                  if (timestamp != null)
                    Text("Placed: ${timestamp.toLocal()}",
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
