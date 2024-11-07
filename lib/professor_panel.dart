import 'package:flutter/material.dart';

class ProfessorPanel extends StatelessWidget {
  const ProfessorPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profesor - Llamar Monitor'),
      ),
      body: Column(
        children: [
          // Dropdowns para seleccionar bloque, piso, salón...
          ElevatedButton(
            onPressed: () {
              // Lógica para enviar alerta
            },
            child: const Text('Enviar Alerta'),
          ),
        ],
      ),
    );
  }
}
