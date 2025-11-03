import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpsellMaterialSheet extends StatefulWidget {
  final String shopId;

  const UpsellMaterialSheet({Key? key, required this.shopId}) : super(key: key);

  @override
  _UpsellMaterialSheetState createState() => _UpsellMaterialSheetState();
}

class _UpsellMaterialSheetState extends State<UpsellMaterialSheet> {
  List<Map<String, dynamic>> allMaterials = [];
  List<Map<String, dynamic>> selectedMaterials = [];

  @override
  void initState() {
    super.initState();
    fetchMaterials();
  }

  Future<void> fetchMaterials() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('materials')
        .where('shopId', isEqualTo: widget.shopId)
        .get();

    final materials = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'],
        'price': data['price'],
        'imageUrl': data['imageUrl'],
      };
    }).toList();

    setState(() {
      allMaterials = materials;
    });
  }

  void toggleSelection(Map<String, dynamic> item) {
    setState(() {
      final exists = selectedMaterials.any((mat) => mat['id'] == item['id']);
      if (exists) {
        selectedMaterials.removeWhere((mat) => mat['id'] == item['id']);
      } else {
        selectedMaterials.add(item);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('You May Also Like'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.white,
      ),
      body: allMaterials.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: allMaterials.length,
        itemBuilder: (context, index) {
          final material = allMaterials[index];
          final isSelected = selectedMaterials.any((mat) => mat['id'] == material['id']);

          return GestureDetector(
            onTap: () => toggleSelection(material),
            child: Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.amber.shade100 : Colors.white,
                border: Border.all(
                  color: isSelected ? Colors.amber : Colors.grey.shade300,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      material['imageUrl'],
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          material['name'],
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text('₹${material['price']}', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  Icon(
                    isSelected ? Icons.check_circle : Icons.add_circle_outline,
                    color: isSelected ? Colors.green : Colors.grey,
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(12),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, []),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text("Skip", style: TextStyle(color: Colors.red)),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context, selectedMaterials),
                child: Text("Confirm (${selectedMaterials.length})"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
