import 'package:flutter/material.dart';

class MonitorPanel extends StatelessWidget {
  const MonitorPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitor - Responder Alertas'),
      ),
      body: Column(
        children: [
          // Lista de alertas por responder
          ElevatedButton(
            onPressed: () {
              // Lógica para aceptar alerta
            },
            child: const Text('Aceptar Alerta'),
          ),
        ],
      ),
    );
  }
}
