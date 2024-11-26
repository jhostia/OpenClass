import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'splashscreen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBGrYR-kZm8HW3AcJA1uqRQlQZpsQZY2kk",
      authDomain: "openclass-e2614.firebaseapp.com",
      projectId: "openclass-e2614",
      storageBucket: "openclass-e2614.appspot.com", 
      messagingSenderId: "131931693412",
      appId: "1:131931693412:web:48a8cd641b16bd3f225a71",
      measurementId: "G-XLWFJZTF5J",
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenClass',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(), 
    );
  }
}
