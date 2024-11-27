import 'package:flutter/material.dart';

class CustomStyles {
  static const Color primaryColor = Colors.blue;

  // Estilo de texto para etiquetas (labels)
  static const TextStyle labelTextStyle = TextStyle(
    fontSize: 16,
    color: Colors.grey,
  );

  // Estilo de texto para mostrar mensajes de error
  static const TextStyle errorTextStyle = TextStyle(
    fontSize: 14,
    color: Colors.red,
  );

  // Estilo personalizado para botones elevados (ElevatedButton)
  static ButtonStyle elevatedButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor, 
    foregroundColor: Colors.white, 
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20), 
    ),
    elevation: 5, 
  );

  // Estilo de texto para los botones
  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 18, 
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  // Decoración personalizada para los campos de texto (TextField)
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

