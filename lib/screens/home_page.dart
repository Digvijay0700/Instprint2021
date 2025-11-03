import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'select_print_method_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'track_orders_page.dart'; // ✅ New import for orders tracking page
import 'profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      const MainShopTab(),
      const TrackOrdersPage(),
      ProfilePage(uid: FirebaseAuth.instance.currentUser!.uid), // ✅ Profile tab
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.amber.shade800,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Track Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'), // ✅ New Profile tab
        ],
      ),
    );
  }
}

class MainShopTab extends StatefulWidget {
  const MainShopTab({super.key});

  @override
  State<MainShopTab> createState() => _MainShopTabState();
}

class _MainShopTabState extends State<MainShopTab> {
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();

  Future<void> _refreshShops() async {
    setState(() {}); // Triggers rebuild & fetches fresh snapshot
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Color _badgeColor(String badge) {
    switch (badge) {
      case "Verified":
        return Colors.green;
      case "Trending":
        return Colors.orange;
      case "Fast Service":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: Colors.amber.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Instprint",
                    style: GoogleFonts.lobster(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: () => _refreshKey.currentState?.show(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search for a shop...',
                  suffixIcon: const Icon(Icons.filter_list),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: RefreshIndicator(
                key: _refreshKey,
                onRefresh: _refreshShops,
                child: _buildShopList(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('shopkeepers').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final shops = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'Available'; // ✅ filter only available shops
        }).toList();

        if (shops.isEmpty) {
          return const Center(
            child: Text("No shops available right now"),
          );
        }

        return ListView.builder(
          itemCount: shops.length,
          padding: const EdgeInsets.only(bottom: 16),
          itemBuilder: (context, index) {
            final shop = shops[index];
            final data = shop.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shop Name & Location Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            data['name'] ?? 'Unnamed Shop',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8B0000),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.location_on, color: Colors.red),
                          onPressed: () {
                            final lat = data['latitude'];
                            final lng = data['longitude'];
                            if (lat != null && lng != null) {
                              final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
                              launchUrl(Uri.parse(url));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Location not available")),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Location Text
                    Text(
                      data['location'] ?? 'Location not set',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),

                    // Badges
                    if (data['badges'] != null && data['badges'] is List)
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: (data['badges'] as List).map<Widget>((badge) {
                          return Chip(
                            label: Text(badge),
                            backgroundColor: _badgeColor(badge),
                            labelStyle: const TextStyle(color: Colors.white),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 12),

                    // Upload Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.upload_file, size: 18),
                        label: const Text("Select"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SelectPrintMethodPage(
                                shopId: shop.id,
                                shopName: data['name'] ?? 'Unnamed Shop',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
