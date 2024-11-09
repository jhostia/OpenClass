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
    foregroundColor: Colors.white, // Color del texto
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20), // Borde redondeado más pronunciado
    ),
    elevation: 5, // Elevación para dar un efecto de sombra
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 18, // Tamaño de texto más grande para mayor visibilidad
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static InputDecoration textFieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: labelTextStyle,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20), // Bordes redondeados para los campos de texto
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
    );
  }
}

