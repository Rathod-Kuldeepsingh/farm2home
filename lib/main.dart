import 'package:farm2home/Backend/Farmer_auth/login.dart';
import 'package:farm2home/Backend/Farmer_auth/registration.dart';
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
  
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ProductListPage(),
      routes: {
        "/login":(context) => LoginPage(),
        "/regist":(context)=> RegistrationPage()
      },
    );  
  }
}

