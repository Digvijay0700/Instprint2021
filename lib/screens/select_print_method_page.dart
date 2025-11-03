import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class SelectPrintMethodPage extends StatelessWidget {
  final String shopId;
  final String shopName;

  const SelectPrintMethodPage({
    super.key,
    required this.shopId,
    required this.shopName,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          'Instprint',
          style: GoogleFonts.lobster(color: Colors.white, fontSize: 26),
        ),
        centerTitle: true,
        backgroundColor: Colors.amber.shade600,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Send to $shopName",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8B0000),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: Container(
                width: screenWidth * 0.95,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.shade100,
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      "Choose Print Method",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        childAspectRatio: 1.1,
                        padding: const EdgeInsets.only(top: 8),
                        children: [
                          _buildOptionCard(
                            context,
                            icon: Icons.upload_file,
                            title: "Upload File",
                            color: Colors.blueAccent,
                            isAvailable: true,
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/uploadFile',
                              arguments: {'shopId': shopId},
                            ),
                          ),
                          _buildOptionCard(
                            context,
                            icon: Icons.camera_alt,
                            title: "Capture & Send",
                            color: Colors.orangeAccent,
                            isAvailable: false, // make it clickable
                            onTap: () {

                            },
                          ),

                          _buildOptionCard(
                            context,
                            icon: Icons.folder_shared,
                            title: "From Wallet",
                            color: Colors.green,
                            isAvailable: false,
                          ),
                          _buildOptionCard(
                            context,
                            icon: Icons.group_add,
                            title: "Form / Join Group",
                            color: Colors.purple,
                            isAvailable: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.amber.shade800,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: "Track Orders"),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          } else if (index == 1) {
            Navigator.pushNamed(context, '/orders');
          }
        },
      ),
    );
  }

  Widget _buildOptionCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required Color color,
        bool isAvailable = false,
        VoidCallback? onTap,
      }) {
    return InkWell(
      onTap: () {
        if (isAvailable && onTap != null) {
          onTap();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "This feature will be added soon!",
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              backgroundColor: Colors.orange.shade300,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 2),
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
