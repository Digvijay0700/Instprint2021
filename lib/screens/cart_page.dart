import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../providers/user_provider.dart';
import 'file_upload_page.dart';
import 'order_success_page.dart';
import 'upsell_material_sheet.dart';

class CartPage extends StatefulWidget {
  final List<Map<String, dynamic>> batches;
  final String shopId;

  const CartPage({super.key, required this.batches, required this.shopId});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Map<String, dynamic>> selectedMaterials = [];
  bool isLoading = false;
  bool isProcessingPayment = false;

  String? userId;
  String? userName;
  String? shopUpi;
  String? shopName;
  late Razorpay _razorpay;


  int get printTotal => widget.batches.fold(0, (sum, item) {
    final price = item['price'];
    final int parsedPrice =
    price is int ? price : int.tryParse(price.toString()) ?? 0;
    return sum + parsedPrice;
  });

  int get materialTotal =>
      selectedMaterials.fold(0, (sum, item) => sum + ((item['price'] ?? 0) as int));

  int get grandTotal => printTotal + materialTotal;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<UserProvider>(context, listen: false);
    userId = provider.uid;
    if (userId != null) _fetchUserName(userId!);
    _fetchShopDetails();

    // Razorpay setup
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // Razorpay Handlers
// ✅ Razorpay Handlers (Updated)
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() => isProcessingPayment = true);
    try {
      await _createOrderInFirestore(response.paymentId);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderSuccessPage(
              orderId: response.paymentId ?? '',
              shopId: widget.shopId,
            ),
          ),
        );
      }
    } catch (e) {
      print("Error handling payment success: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong while saving order.")),
      );
    } finally {
      setState(() => isProcessingPayment = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => isProcessingPayment = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Failed: ${response.message}")),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("External Wallet: ${response.walletName}")),
    );
  }

  Future<void> _fetchUserName(String uid) async {
    try {
      final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final name = userDoc.data()?['name'];
        if (name != null && name is String) {
          setState(() {
            userName = name.trim();
          });
        }
      }
    } catch (e) {
      print("Error fetching user name: $e");
    }
  }

  Future<void> _fetchShopDetails() async {
    try {
      final shopDoc = await FirebaseFirestore.instance
          .collection('shopkeepers')
          .doc(widget.shopId)
          .get();
      if (shopDoc.exists) {
        setState(() {
          shopUpi = shopDoc.data()?['upi_id'];
          shopName = shopDoc.data()?['name'] ?? 'Shopkeeper';
        });
      }
    } catch (e) {
      print("Error fetching shop details: $e");
    }
  }

  Future<void> _createOrderInFirestore(String? paymentId) async {
    setState(() => isLoading = true);
    try {
      final firestore = FirebaseFirestore.instance;
      final storage = FirebaseStorage.instance;
      final currentUser = FirebaseAuth.instance.currentUser;
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      if (currentUser == null) throw Exception("User not logged in");

      final userDoc =
      await firestore.collection('users').doc(currentUser.uid).get();
      final String name = userDoc.data()?['name'] ?? 'Unknown';

      final randomId = Random().nextInt(9000) + 1000;
      final requestId = "${name.replaceAll(' ', '')}-$randomId";

      final requestRef = firestore
          .collection('shopkeepers')
          .doc(widget.shopId)
          .collection('print_requests')
          .doc(requestId);

      final List<Map<String, dynamic>> batchDataList = [];

      for (var batch in widget.batches) {
        final file = File(batch['filePath']);
        final fileName = batch['fileName'] ?? 'uploaded_file.pdf';

        final ref = storage
            .ref()
            .child('print_files/${widget.shopId}/${requestRef.id}/$fileName');
        final uploadTask = await ref.putFile(file);
        final fileUrl = await uploadTask.ref.getDownloadURL();

        List<Map<String, dynamic>> manualPages = [];
        if (batch['manualPages'] != null && batch['manualColorSelection'] == true) {
          final manual = List<Map<String, dynamic>>.from(batch['manualPages']);
          manualPages = manual
              .map((entry) => {
            'page': entry['page'],
            'color': entry['color'],
            'count': entry['count'],
          })
              .toList();
        }

        batchDataList.add({
          'fileName': fileName,
          'fileUrl': fileUrl,
          'pages': batch['totalPages'],
          'copies': batch['copies'],
          'price': batch['price'],
          'binding': batch['binding'],
          'punch': batch['punch'],
          'staple': batch['staple'],
          'printType': batch['printType'],
          'color': batch['color'],
          'doubleSided': batch['doubleSided'],
          'manualColorSelection': batch['manualColorSelection'],
          'manualPages': manualPages,
        });
      }

      // Generate summary PDF
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('Print Request Summary', style: pw.TextStyle(fontSize: 24)),
                pw.SizedBox(height: 20),
                pw.Text('Request ID: ${requestRef.id}'),
                pw.Text('User Name: $name'),
                pw.SizedBox(height: 10),
                pw.Text('Total Batches: ${batchDataList.length}'),
              ],
            ),
          ),
        ),
      );

      final pdfFile =
      File('${Directory.systemTemp.path}/summary_${requestRef.id}.pdf');
      await pdfFile.writeAsBytes(await pdf.save());

      final summaryRef = storage
          .ref()
          .child('print_files/${widget.shopId}/${requestRef.id}/summary.pdf');
      final summaryUpload = await summaryRef.putFile(pdfFile);
      final summaryUrl = await summaryUpload.ref.getDownloadURL();

      await requestRef.set({
        'userUid': currentUser.uid,
        'userName': name,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'batches': batchDataList,
        'extraMaterials': selectedMaterials,
        'extraMaterialTotal': materialTotal,
        'totalPrice': grandTotal,
        'summaryUrl': summaryUrl,
        'requestId': requestId,
        'paymentId': paymentId ?? "NoPaymentID",
      });

      // Send Firestore message for SMS
      final phoneNumber = userProvider.phone;
      await firestore.collection('messages').add({
        'to': phoneNumber,
        'message':
        'Your order ($requestId) has been placed successfully at ${widget.shopId}. You will be notified when it is ready.',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Navigate to success page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderSuccessPage(
            orderId: requestRef.id,
            shopId: widget.shopId,
          ),
        ),
      );
    } catch (e) {
      print('Error creating order: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ✅ Razorpay Payment Flow
  Future<void> handleProceedToPayment() async {
    final materials = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UpsellMaterialSheet(shopId: widget.shopId),
      ),
    );

    if (materials != null && materials is List<Map<String, dynamic>>) {
      setState(() {
        selectedMaterials = materials;
      });
    }

    if (grandTotal <= 0) return;

    setState(() => isProcessingPayment = true);

    try {
      final url = Uri.parse('https://instprint-backend.fly.dev/create_order');

      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "amount": grandTotal,
          "userId": userId,
          "receipt": "order_${userId}_${DateTime.now().millisecondsSinceEpoch}"
        }),
      );

      if (res.statusCode != 200) throw Exception("Failed to create order");

      final data = jsonDecode(res.body);
      final orderId = data['order_id'];
      final key = data['key'];

      var options = {
        'key': key,
        'amount': grandTotal * 100,
        'name': shopName ?? 'InstPrint',
        'description': 'Printing Order',
        'order_id': orderId,
        'theme': {'color': '#FBBF24'}
      };

      // Open Razorpay quickly after a tiny delay
      await Future.delayed(const Duration(milliseconds: 500));
      _razorpay.open(options);
    } catch (e) {
      print("Payment initiation error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment initiation failed")),
      );
    } finally {
      setState(() => isProcessingPayment = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        foregroundColor: Colors.white,
        title: const Text('Cart', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/background.png', fit: BoxFit.cover),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white.withOpacity(0.85),
            child: Column(
              children: [
                Expanded(
                  child: widget.batches.isEmpty
                      ? Center(
                    child: Text('No batches added yet.',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                  )
                      : ListView.builder(
                    itemCount: widget.batches.length,
                    itemBuilder: (context, index) {
                      final batch = widget.batches[index];
                      final manualPages = batch['manualPages'] as List<dynamic>?;

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              batch['fileName'] ?? 'Unnamed',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (manualPages != null && manualPages.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Manual Page Settings:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  ...manualPages.map((entry) {
                                    final page = entry['page'];
                                    final color = entry['color'];
                                    final count = entry['count'];
                                    return Text(
                                        'Page $page → $color ($count copies)',
                                        style: TextStyle(fontSize: 13));
                                  }).toList(),
                                ],
                              )
                            else
                              Text('Manual Settings: Not Available',
                                  style:
                                  TextStyle(fontSize: 13, color: Colors.grey)),
                            const SizedBox(height: 8),
                            Text(
                              'Pages: ${batch['totalPages']}, Copies: ${batch['copies']}, Price: ₹${batch['price']}',
                              style: TextStyle(fontSize: 14),
                            ),
                            Text(
                              'Binding: ${batch['binding'] == true || batch['binding'] == 'Yes' ? "Yes" : "No"}, '
                                  'Punch: ${batch['punch']}, Staple: ${batch['staple']}',
                              style: TextStyle(fontSize: 14),
                            ),
                            Text(
                              'Print Type: ${batch['printType']}, Color: ${batch['color']}, Double Sided: ${batch['doubleSided']}',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (selectedMaterials.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Added Materials:",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        ...selectedMaterials
                            .map((item) => Text("- ${item['name']} (₹${item['price']})",
                            style: TextStyle(fontSize: 14))),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Final Total:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('₹$grandTotal',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Add Another Batch'),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UploadFilePage(
                                shopId: widget.shopId,
                                existingBatches: widget.batches,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                (isLoading || isProcessingPayment)
                    ? const Center(child: CircularProgressIndicator())
                    : Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        icon: const Icon(Icons.shopping_cart_checkout_rounded),
                        label: const Text('Proceed to Payment'),
                        onPressed: handleProceedToPayment,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
