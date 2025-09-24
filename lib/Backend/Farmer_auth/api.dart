import 'package:farm2home/Backend/Farmer_auth/shared.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://api-farm2home.onrender.com/products"; // Android emulator

  static Future<http.Response> fetchProducts() async {
    String? token = await SharedPrefHelper.getString("firebase_token");

    return await http.get(
      Uri.parse(baseUrl),
      headers: {
        "Authorization": "Bearer $token",
      },
    );
  }

  static Future<http.Response> deleteProduct(String productId) async {
    String? token = await SharedPrefHelper.getString("firebase_token");

    return await http.delete(
      Uri.parse("$baseUrl/$productId"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );
  }
}
