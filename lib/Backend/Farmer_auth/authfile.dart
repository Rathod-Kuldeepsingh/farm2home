// lib/services/auth_service.dart
// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:farm2home/Backend/Farmer_auth/shared.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  static bool get isLoggedIn => _auth.currentUser != null;

  // Show SnackBar helper method
  static void showSnackBar(
    BuildContext context,
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

  // Login method
  static Future<bool> loginUser(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = userCredential.user;
      if (user != null) {
        final token = await user.getIdToken();
        await SharedPrefHelper.saveString("firebase_token", token!);
        await SharedPrefHelper.saveBool("isLoggedIn", true);
        return true;
      }
      return false;
    } catch (e) {
      throw e;
    }
  }

  // Logout method - can be called from anywhere
  static Future<void> logoutUser(BuildContext context) async {
    try {
      // Firebase sign-out
      await FirebaseAuth.instance.signOut();

      // Clear shared preferences
      await SharedPrefHelper.saveBool("isLoggedIn", false);
      await SharedPrefHelper.saveString("firebase_token", "");

      // Navigate back to login page
      Navigator.pushReplacementNamed(context, "/login");
      AuthService.showSnackBar(context, "Logout Succesfully");
    } catch (e) {
      AuthService.showSnackBar(
        context,
        "Logout Failed: $e",
        color: Colors.red,
        icon: Icons.error,
      );
    }
  }

  // Register method
  static Future<bool> registerUser(
    String email,
    String password,
    String name,
  ) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );

      final user = userCredential.user;
      if (user != null) {
        // Update display name in Firebase Auth
        await user.updateDisplayName(name);

        // Save token and login status locally
        final token = await user.getIdToken();
        await SharedPrefHelper.saveString("firebase_token", token!);
        await SharedPrefHelper.saveBool("isLoggedIn", true);

        // Save user details in Firestore

        try {
          final firestore = FirebaseFirestore.instance;
          await firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'name': name,
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
          });
          print("User data saved successfully");
        } catch (e) {
          print("Error saving user data: $e");
        }

        return true;
      }
      return false;
    } catch (e) {
      throw e;
    }
  }

  static Future<Map<String, dynamic>?> getUserDetails() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        return doc.data();
      }
    }
    return null;
  }

  // Check authentication status
  static Future<bool> checkAuthStatus() async {
    final isLoggedIn = await SharedPrefHelper.getBool("isLoggedIn") ?? false;
    return isLoggedIn && _auth.currentUser != null;
  }
}
