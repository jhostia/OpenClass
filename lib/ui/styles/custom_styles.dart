import 'package:flutter/material.dart';

class CustomStyles {
  static const Color primaryColor = Colors.blue;

  static const TextStyle labelTextStyle = TextStyle(
    fontSize: 16,
    color: Colors.grey,
  );

  static const TextStyle errorTextStyle = TextStyle(
    fontSize: 14,
    color: Colors.red,
  );

  static ButtonStyle elevatedButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor, 
    foregroundColor: Colors.white, 
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20), 
    ),
    elevation: 5, 
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 18, 
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static InputDecoration textFieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: labelTextStyle,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20), 
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
    );
  }
}

