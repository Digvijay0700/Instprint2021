import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';

class OrderSuccessPage extends StatelessWidget {
  final String orderId;
  final String shopId;

  const OrderSuccessPage({super.key, required this.orderId, required this.shopId});

  Future<String> fetchShopName() async {
    final doc = await FirebaseFirestore.instance.collection('shopkeepers').doc(shopId).get();
    if (doc.exists && doc.data() != null && doc.data()!.containsKey('name')) {
      return doc['name'];
    }
    return 'Unknown Shop';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<String>(
          future: fetchShopName(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final shopName = snapshot.data ?? 'Unknown Shop';

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset('assets/lottie/success_tick.json', height: 200),
                    const SizedBox(height: 24),
                    const Text('Order Sent!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
                    const SizedBox(height: 16),
                    Text('Your order has been successfully sent to $shopName.',
                        textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 16),
                    Text('Order ID: $orderId',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.amber)),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                      child: const Text('Back to Home'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
