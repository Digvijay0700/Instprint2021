// Same imports...
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'cart_page.dart';

class UploadFilePage extends StatefulWidget {
  final String shopId;
  final List<Map<String, dynamic>> existingBatches;
  final bool isFromCamera;

  const UploadFilePage({
    super.key,
    required this.shopId,
    this.existingBatches = const [],
    this.isFromCamera = false,
  });

  @override
  State<UploadFilePage> createState() => _UploadFilePageState();
}

class _UploadFilePageState extends State<UploadFilePage> {
  XFile? selectedFile;
  int numberOfPrints = 1;
  String? colorOption;
  String? stableOption;
  String? punchOption;
  String? bindingOption;
  String? printType = "Single";
  int totalPages = 0;
  int bwPrice = 0, colorPrice = 0, bindingPrice = 0, punchPrice = 0, staplePrice = 0, doubleSidedDiscount = 0;
  int totalPrice = 0;
  bool manualColorSelection = false;
  List<String> pageColorSettings = [];
  List<int> pagePrintCounts = [];


  Future<void> fetchPrices() async {
    final snap = await FirebaseFirestore.instance
        .collection("shopkeepers")
        .doc(widget.shopId)
        .get();

    if (snap.exists) {
      final rates = snap.data()!["rates"];
      setState(() {
        bwPrice = rates["bw_single_page_price"] ?? 0;
        colorPrice = rates["color_single_page_price"] ?? 0;
        bindingPrice = rates["binding_price"] ?? 0;
        doubleSidedDiscount = rates["double_sided_discount"] ?? 0;
        punchPrice = 0;
        staplePrice = 0;
      });
    }
  }

  Future<void> pickFile() async {
    const typeGroup = XTypeGroup(label: 'documents', extensions: ['pdf', 'doc', 'docx']);
    final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);

    if (file != null) {
      final fileSizeInBytes = await file.length();
      final fileSizeInMB = fileSizeInBytes / (1024 * 1024);

      if (fileSizeInMB > 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File too large! Max allowed size is 10MB.')),
        );
        return;
      }

      final isPdf = file.path.toLowerCase().endsWith('.pdf');

      selectedFile = file;

      if (isPdf) {
        await _loadPdfPageCount(file.path);
      } else {
        totalPages = 1;
      }
      pageColorSettings = List.generate(totalPages, (_) => 'B/W');
      pagePrintCounts = List.generate(totalPages, (_) => 1);

      await fetchPrices();
      setState(() {});
    }
  }

  Future<void> _loadPdfPageCount(String path) async {
    final bytes = await File(path).readAsBytes();
    final pdfDoc = PdfDocument(inputBytes: bytes);
    totalPages = pdfDoc.pages.count;
    pdfDoc.dispose();
  }

  int calculateTotalPrice() {
    int total = 0;

    if (manualColorSelection) {
      for (int i = 0; i < totalPages; i++) {
        int rate = pageColorSettings[i] == 'Color' ? colorPrice : bwPrice;
        total += rate * pagePrintCounts[i];
      }
    } else {
      int rate = colorOption == "Color" ? colorPrice : bwPrice;
      total += totalPages * rate;
      if (printType == "Double") total -= doubleSidedDiscount * totalPages;
    }

    total *= numberOfPrints;

    if (bindingOption == "Yes") total += bindingPrice;
    if (punchOption == "Yes") total += punchPrice;
    if (stableOption == "Yes") total += staplePrice;

    return total;
  }


  @override
  void initState() {
    super.initState();
    if (!widget.isFromCamera) {
      fetchPrices();
    }
  }

  Widget buildOption(String title, String? selected, List<String> opts, Function(String) onSelect) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.amber),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: opts.map((e) {
              bool isSel = selected == e;

              String priceLabel = "";
              if (title == "Color") {
                if (e == "Color") priceLabel = "₹$colorPrice pp";
                else if (e == "Black & White") priceLabel = "₹$bwPrice pp";
              } else if (title == "Binding") {
                priceLabel = e == "Yes" ? "₹$bindingPrice" : "";
              } else if (title == "Staple?" || title == "Punch?") {
                priceLabel = "";
              }

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => onSelect(e)),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSel ? Colors.amber.shade800 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "$e${priceLabel.isNotEmpty ? " ($priceLabel)" : ""}",
                      style: TextStyle(
                        color: isSel ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }).toList(),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    totalPrice = calculateTotalPrice();

    return Scaffold(
      appBar: AppBar(title: const Text("Upload File"), backgroundColor: Colors.amber),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (!widget.isFromCamera && selectedFile == null) ...[
              InkWell(
                onTap: pickFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.amber),
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.amber.shade50,
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.upload_file, size: 50, color: Colors.amber),
                      SizedBox(height: 10),
                      Text("Select File", style: TextStyle(fontSize: 18)),
                      SizedBox(height: 8),
                      Text(
                        "Allowed: PDF, DOC, DOCX\nMax size: 5MB",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Text("Total Pages: $totalPages", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              buildOption("Print Type", printType, ["Single", "Double"], (val) => printType = val),
              buildOption("Color", colorOption, ["Color", "Black & White", "Set Manually"], (val) {
                setState(() {
                  colorOption = val;
                  manualColorSelection = val == "Set Manually";
                });
              }),

              if (manualColorSelection)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(totalPages, (index) {
                    final isColor = pageColorSettings[index] == 'Color';

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isColor ? Colors.red.shade100 : Colors.grey.shade100,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Text("Page ${index + 1}", style: const TextStyle(fontWeight: FontWeight.w500)),
                          const Spacer(),

                          // Color dropdown
                          DropdownButton<String>(
                            value: pageColorSettings[index],
                            borderRadius: BorderRadius.circular(10),
                            dropdownColor: Colors.white,
                            items: ['Color', 'B/W'].map((val) {
                              return DropdownMenuItem(
                                value: val,
                                child: Text(val),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() => pageColorSettings[index] = val!);
                            },
                          ),

                          const SizedBox(width: 20),

                          // Quantity counter
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 20),
                                onPressed: () {
                                  if (pagePrintCounts[index] > 1) {
                                    setState(() => pagePrintCounts[index]--);
                                  }
                                },
                              ),
                              Text("${pagePrintCounts[index]}", style: const TextStyle(fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.add, size: 20),
                                onPressed: () {
                                  setState(() => pagePrintCounts[index]++);
                                },
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  }),
                ),


              buildOption("Binding", bindingOption, ["Yes", "No"], (val) => bindingOption = val),
              buildOption("Staple?", stableOption, ["Yes", "No"], (val) => stableOption = val),
              buildOption("Punch?", punchOption, ["Yes", "No"], (val) => punchOption = val),
              const SizedBox(height: 10),

              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.amber),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Copies", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            if (numberOfPrints > 1) {
                              setState(() => numberOfPrints--);
                            }
                          },
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade200,
                          ),
                          child: Text(
                            "$numberOfPrints",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            setState(() => numberOfPrints++);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Text("Total Price: ₹$totalPrice", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (!widget.isFromCamera && selectedFile == null) return;

                  final batch = {
                    'fileName': selectedFile?.name ?? "Captured.pdf",
                    'filePath': selectedFile?.path ?? "",
                    'totalPages': totalPages,
                    'copies': numberOfPrints,
                    'color': colorOption,
                    'manualColorSelection': manualColorSelection,
                    'manualPages': manualColorSelection
                        ? List.generate(totalPages, (i) => {
                      'page': i + 1,
                      'color': pageColorSettings[i],
                      'count': pagePrintCounts[i],
                    })
                        : [],
                    'punch': punchOption,
                    'staple': stableOption,
                    'binding': bindingOption,
                    'doubleSided': printType == "Double",
                    'price': totalPrice,
                    'timestamp': DateTime.now().millisecondsSinceEpoch,
                  };


                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartPage(
                        batches: [...widget.existingBatches, batch],
                        shopId: widget.shopId,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  child: Text("Confirm & Add to Cart", style: TextStyle(fontSize: 18)),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}