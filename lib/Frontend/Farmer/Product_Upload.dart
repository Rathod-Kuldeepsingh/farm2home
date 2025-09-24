// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:farm2home/Backend/Farmer_auth/authfile.dart';
import 'package:farm2home/Backend/Farmer_auth/login.dart';
import 'package:farm2home/Frontend/Farmer/Add_product.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  late Future<List<dynamic>> products;
  final String baseUrl = "https://api-farm2home.onrender.com/my-products";
  final userDetails = AuthService.getUserDetails();
  @override
  void initState() {
    super.initState();
    products = fetchMyProducts();
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

  Future<List<dynamic>> fetchMyProducts() async {
  try {
    // Get current Firebase user's ID token
    String? idToken = await FirebaseAuth.instance.currentUser!.getIdToken();

    final res = await http.get(
      Uri.parse("$baseUrl"),
      headers: {
        "id-token": ?idToken, // Important!
      },
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load products: ${res.body}");
    }
  } catch (e) {
    debugPrint("🔥 Error fetching products: $e");
    return [];
  }
}

  Future<void> deleteProduct(String productId) async {
    final user = FirebaseAuth.instance.currentUser;
    final firebaseToken = await user?.getIdToken();

    if (firebaseToken == null) {
      showSnackBar("User Not logged in", color: Colors.red);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: Colors.green)),
    );

    try {
      // Send the id_token as form data
      final res = await http.delete(
        Uri.parse("$baseUrl/$productId"),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"id_token": firebaseToken},
      );

      Navigator.of(context).pop(); // Close loader

      if (res.statusCode == 200 || res.statusCode == 204) {
        showSnackBar("Product Deleted", color: Colors.green);
        setState(() {
          products = fetchMyProducts();
        });
      } else {
        throw Exception("Failed to delete product: ${res.statusCode}");
      }
    } catch (e) {
      Navigator.of(context).pop();
      showSnackBar("Error deleting product $e", color: Colors.red);
    }
  }

  Future<void> _confirmUpdate(
    BuildContext context,
    Map<String, dynamic> product,
  ) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Confirm Update"),
        content: Text("Are you sure you want to update '${product["name"]}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Update", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddProductPage(
            productId: product["id"],
            initialData: {
              "name": product["name"],
              "price": product["price"].toString(),
              "quantity": product["quantity"].toString(),
              "farmer_name": product["farmer_name"],
              "farmer_id": product["farmer_id"] ?? "", // Include farmer_id
              "description": product["description"] ?? "",
              "image_url": product["image_url"] ?? "",
            },
          ),
        ),
      );

      if (result == true) {
        setState(() {
          products = fetchMyProducts();
        });
      }
    }
  }

  Widget buildProductCard(product) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Image section
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white10,
              ),
              child: product["image_url"] != null && product["image_url"] != ""
                  ? Image.network(
                      product["image_url"],
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.broken_image,
                          size: 40,
                          color: Colors.grey,
                        );
                      },
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.green,
                            backgroundColor: Colors.white,
                          ),
                        );
                      },
                    )
                  : const Icon(
                      Icons.image_not_supported,
                      size: 40,
                      color: Colors.grey,
                    ),
            ),
            const SizedBox(width: 16),

            // Text details + buttons
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product["name"],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "₹${product["price"]}",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Quantity: ${product["quantity"]}",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    "Farmer: ${product["farmer_name"]}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  if (product["description"] != null &&
                      product["description"].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "Description: ${product["description"]}",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          deleteProduct(product["id"]);
                        },
                        icon: const Icon(
                          Icons.delete,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text(
                          "Delete",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          minimumSize: const Size(80, 30),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          _confirmUpdate(context, product);
                        },
                        icon: const Icon(
                          Icons.edit,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text(
                          "Update",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(80, 30),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshProducts() async {
    setState(() {
      products = fetchMyProducts();
    });
    await products;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white, // Change color
          size: 30, // Change size
        ),
        title: Center(
          child: const Text(
            "Farm2Home",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: Colors.green,
        actions: [],
      ),
      drawer: Drawer(
        width: 280,
        backgroundColor: Colors.white,
        child: Column(
          children: [
            // Drawer Header
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  "K",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              accountName: FutureBuilder<Map<String, dynamic>?>(
                future: AuthService.getUserDetails(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text(
                      "Loading...",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    );
                  } else if (snapshot.hasError) {
                    return Text(
                      "Error",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    );
                  } else if (!snapshot.hasData) {
                    return Text(
                      "",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    );
                  } else {
                    final userDetails = snapshot.data!;
                    return Text(
                      userDetails['name'] ?? "",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    );
                  }
                },
              ),
              accountEmail: FutureBuilder<Map<String, dynamic>?>(
                future: AuthService.getUserDetails(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text("");
                  } else if (snapshot.hasData) {
                    final userDetails = snapshot.data!;
                    return Text(userDetails['email'] ?? "");
                  } else {
                    return Text("");
                  }
                },
              ),
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerTile(
                    icon: Icons.home,
                    title: 'Home',
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => ProductListPage()),
                      );
                    },
                  ),
                  DrawerTile(
                    icon: Icons.settings,
                    title: 'Settings',
                    onTap: () => Navigator.pop(context),
                  ),
                  DrawerTile(
                    icon: Icons.logout,
                    title: 'Logout',
                    onTap: () {
                      AuthService.logoutUser(context);
                    },
                  ),
                ],
              ),
            ),

            // Footer or version info
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "App Version 1.0.0",
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: products,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.green,
                backgroundColor: Colors.white,
              ),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No products found"));
          } else {
            final productList = snapshot.data!;
            return RefreshIndicator(
              color: Colors.green,
              backgroundColor: Colors.white,
              onRefresh: _refreshProducts,
              child: ListView.builder(
                itemCount: productList.length,
                itemBuilder: (context, index) {
                  return buildProductCard(productList[index]);
                },
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddProductPage()),
          );
          if (result == true) {
            setState(() {
              products = fetchMyProducts();
            });
          }
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const DrawerTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      hoverColor: Colors.green[50],
      onTap: onTap,
    );
  }
}
