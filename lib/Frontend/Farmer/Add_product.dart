// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddProductPage extends StatefulWidget {
  final String? productId;
  final Map<String, dynamic>? initialData;

  const AddProductPage({super.key, this.productId, this.initialData});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  File? _image;
  bool isLoading = false;
  final picker = ImagePicker();
  final String baseUrl = "https://api-farm2home.onrender.com/products"; // FastAPI endpoint

  late TextEditingController nameCtrl;
  late TextEditingController priceCtrl;
  late TextEditingController qtyCtrl;
  late TextEditingController descCtrl;
  late TextEditingController farmernameCtrl;

  User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    // Initialize controllers
    nameCtrl = TextEditingController(text: widget.initialData?['name'] ?? "");
    priceCtrl = TextEditingController(text: widget.initialData?['price']?.toString() ?? "");
    qtyCtrl = TextEditingController(text: widget.initialData?['quantity']?.toString() ?? "");
    descCtrl = TextEditingController(text: widget.initialData?['description'] ?? "");
    farmernameCtrl = TextEditingController(text: user?.displayName ?? "User Name");
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    priceCtrl.dispose();
    qtyCtrl.dispose();
    descCtrl.dispose();
    farmernameCtrl.dispose();
    super.dispose();
  }

  void showSnackBar(
    String message, {
    Color color = Colors.green,
    IconData? icon,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white),
              SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 3),
      ),
    );
  }





  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
      });
    }
  }

  Future<void> saveProduct() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() {
    isLoading = true;
  });

  try {
    // 1️⃣ Get Firebase current user and ID token
    final user = FirebaseAuth.instance.currentUser;
    final firebaseToken = await user?.getIdToken();

    if (firebaseToken == null) {
      throw Exception("User not logged in or token unavailable");
    }

    // 2️⃣ Prepare image if any
    String? imageBase64;
    if (_image != null) {
      final bytes = await _image!.readAsBytes();
      imageBase64 = base64Encode(bytes);
    }

    // 3️⃣ Prepare request body
    final body = {
      "id_token": firebaseToken, // send token instead of farmer_id
      "farmer_name": farmernameCtrl.text,
      "name": nameCtrl.text,
      "price": priceCtrl.text,
      "quantity": qtyCtrl.text,
      "description": descCtrl.text,
      "image_base64": imageBase64 ?? "",
    };

    late http.Response response;

    if (widget.productId == null) {
      response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: body,
      );
    } else {
      response = await http.put(
        Uri.parse("$baseUrl/${widget.productId}"),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: body,
      );
    }

    if (response.statusCode == 200) {
      
          showSnackBar(widget.productId == null
              ? " Product added"
              : " Product updated",color: Colors.green);
      Navigator.pop(context, true);
    } else {
      showSnackBar(" ${response.statusCode}"
      );
    }
  } catch (e) {
    showSnackBar("Error: $e",
    );
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}

  InputDecoration customInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          widget.productId == null ? "Add Product" : "Edit Product",
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Card(
                color: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: customInputDecoration("Product Name", Icons.fastfood),
                        validator: (value) => value!.isEmpty ? "Enter product name" : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: priceCtrl,
                        decoration: customInputDecoration("Price (₹)", Icons.price_check),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? "Enter price" : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: qtyCtrl,
                        decoration: customInputDecoration("Quantity", Icons.production_quantity_limits),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? "Enter quantity" : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descCtrl,
                        decoration: customInputDecoration("Description", Icons.description),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: farmernameCtrl,
                        decoration: customInputDecoration("Farmer Name", Icons.person),
                        readOnly: true,
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: pickImage,
                        child: _image != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _image!,
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                height: 150,
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Icon(Icons.add_a_photo, color: Colors.green, size: 50),
                                ),
                              ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : saveProduct,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  widget.productId == null ? "Save Product" : "Update Product",
                                  style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
