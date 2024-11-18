import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class MonitorListPage extends StatelessWidget {
  const MonitorListPage({super.key});

  Future<List<Map<String, dynamic>>> _fetchMonitors() async {
    QuerySnapshot monitorSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'Monitor')
        .get();

    return monitorSnapshot.docs.map((doc) {
      return doc.data() as Map<String, dynamic>;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitores'),
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

          return ListView.builder(
            itemCount: monitors.length,
            itemBuilder: (context, index) {
              var monitor = monitors[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(monitor['name'] ?? 'Nombre desconocido'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Correo: ${monitor['email']}'),
                      Text('Tiempo promedio de respuesta: ${monitor['averageResponseTime'] ?? 'No disponible'}'),
                      const Text('Promedio de estrellas:'),
                      RatingBarIndicator(
                        rating: (monitor['averageStars'] ?? 0.0).toDouble(),
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}
