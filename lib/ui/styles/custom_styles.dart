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
    backgroundColor: primaryColor, // Color de fondo actualizado
    foregroundColor: Colors.white, // Color del texto (antes `onPrimary`)
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
}
