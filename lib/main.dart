// ignore_for_file: unused_import

import 'package:farm2home/Backend/Farmer_auth/login.dart';
import 'package:farm2home/Backend/Farmer_auth/registration.dart';
import 'package:farm2home/Backend/Farmer_auth/shared.dart';
import 'package:farm2home/Frontend/Farmer/Product_Upload.dart';
import 'package:farm2home/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Important!
  
  // Initialize Firebase with options from firebase_options.dart
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
   bool? loggedIn = await SharedPrefHelper.getBool("isLoggedIn");
  runApp(MyApp(initialRoute: loggedIn == true ? "/product" : "/login"));
}
class MyApp extends StatelessWidget {
   final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
       initialRoute: initialRoute,
      routes: {
        "/home":(context)=> HomePage(),
        "/login":(context) => LoginPage(),
        "/regist":(context)=> RegistrationPage(),
        "/product":(context)=> ProductListPage()
        
      },
    );  
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: const Center(child: Text("✅ Welcome! You are logged in")),
    );
  }
}