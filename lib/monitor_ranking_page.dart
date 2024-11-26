import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class MonitorRankingPage extends StatelessWidget {
  const MonitorRankingPage({super.key});

  // Método para obtener la lista de monitores desde Firestore
  Future<List<Map<String, dynamic>>> _fetchMonitors() async {
    QuerySnapshot monitorSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'Monitor') // Solo monitores
        .get();

    return monitorSnapshot.docs.map((doc) {
      var data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; // Incluir el ID del documento en los datos
      return data;
    }).toList();
  }

  // Formatear el tiempo promedio de respuesta si es numérico
  String _formatTime(dynamic responseTime) {
    if (responseTime == null) {
      return 'No disponible';
    } else if (responseTime is String) {
      // Si ya está en formato de texto, devolverlo directamente
      return responseTime;
    } else if (responseTime is int || responseTime is double) {
      int seconds = responseTime.toInt();
      int minutes = seconds ~/ 60;
      seconds %= 60;
      return '${minutes}m ${seconds}s';
    } else {
      return 'No disponible';
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Ranking de Monitores'),
      automaticallyImplyLeading: false, // Elimina el espacio del AppBar
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchMonitors(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No se encontraron monitores.'));
        }

        List<Map<String, dynamic>> monitors = snapshot.data!;

        // Ordenar monitores por promedio de estrellas, de mayor a menor
        monitors.sort((a, b) {
          double aStars = (a['averageStars'] ?? 0.0).toDouble();
          double bStars = (b['averageStars'] ?? 0.0).toDouble();
          return bStars.compareTo(aStars); // Orden descendente
        });

        return ListView.builder(
          itemCount: monitors.length,
          itemBuilder: (context, index) {
            var monitor = monitors[index];

            double averageStars = (monitor['averageStars'] ?? 0.0).toDouble();
            dynamic averageResponseTime = monitor['averageResponseTime'];
            int totalResponses = monitor['totalResponses'] ?? 0;
            String monitorId = monitor['id'] ?? 'Sin ID';

            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text('${index + 1}'),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                title: Text(monitor['name'] ?? 'Nombre desconocido'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ID: $monitorId'),
                    Text('Correo: ${monitor['email']}'),
                    Text(
                        'Tiempo promedio de respuesta: ${_formatTime(averageResponseTime)}'),
                    Text('Alertas finalizadas: $totalResponses'),
                    const SizedBox(height: 4),
                    const Text('Promedio de estrellas:'),
                    RatingBarIndicator(
                      rating: averageStars,
                      itemBuilder: (context, _) => const Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                      itemCount: 5,
                      itemSize: 20.0,
                      direction: Axis.horizontal,
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.info, color: Colors.blueAccent),
                  onPressed: () {
                    _showMonitorDetails(context, monitor);
                  },
                ),
              ),
            );
          },
        );
      },
    ),
  );
}

  // Mostrar detalles adicionales del monitor en un diálogo
  void _showMonitorDetails(
      BuildContext context, Map<String, dynamic> monitor) {
    double averageStars = (monitor['averageStars'] ?? 0.0).toDouble();
    dynamic averageResponseTime = monitor['averageResponseTime'];
    int totalResponses = monitor['totalResponses'] ?? 0;
    String monitorId = monitor['id'] ?? 'Sin ID';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Detalles de ${monitor['name'] ?? 'Monitor'}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ID: $monitorId'),
              Text('Correo: ${monitor['email']}'),
              Text(
                  'Tiempo promedio de respuesta: ${_formatTime(averageResponseTime)}'),
              Text('Alertas finalizadas: $totalResponses'),
              Text('Promedio de estrellas: $averageStars'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}
