import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AlertsManagement extends StatefulWidget {
  const AlertsManagement({Key? key}) : super(key: key);

  @override
  _AlertsManagementState createState() => _AlertsManagementState();
}

class _AlertsManagementState extends State<AlertsManagement> {
  String _selectedFilter = "Todas"; 

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilters(), 
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('alerts').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              // Obtener todas las alertas desde Firestore
              List<DocumentSnapshot> alerts = snapshot.data!.docs;

              // Filtrar las alertas según el estado seleccionado
              if (_selectedFilter != "Todas") {
                alerts = alerts.where((alert) {
                  var data = alert.data() as Map<String, dynamic>;
                  String status = data['status']?.toString().trim() ?? 'Enviada';

                  
                  if (_selectedFilter == "Finalizadas" && status == "Finalizada") {
                    return true;
                  } else if (_selectedFilter == "Aceptadas" && status == "Aceptada") {
                    return true;
                  } else if (_selectedFilter == "Denegadas" && status == "Denegada") {
                    return true;
                  } else if (_selectedFilter == "Enviadas" && status == "Enviada") {
                    return true;
                  }

                  return false;
                }).toList();
              }

              // Mostrar mensaje si no hay alertas en el filtro actual
              if (alerts.isEmpty) {
                return Center(
                  child: Text(
                    "No hay alertas en este estado",
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                );
              }

              // Mostrar las alertas filtradas en un ListView
              return ListView.builder(
                itemCount: alerts.length,
                itemBuilder: (context, index) {
                  var alertData = alerts[index].data() as Map<String, dynamic>;
                  return _buildAlertCard(alertData, alerts[index].id);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    final filters = ["Todas", "Enviadas", "Aceptadas", "Finalizadas", "Denegadas"];

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 8.0, 
        runSpacing: 8.0, 
        children: filters.map((filterName) => _buildFilterButton(filterName)).toList(),
      ),
    );
  }

  Widget _buildFilterButton(String filterName) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedFilter = filterName;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _selectedFilter == filterName ? Colors.blue : Colors.grey[300],
        foregroundColor: _selectedFilter == filterName ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), 
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(
        filterName,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alertData, String alertId) {
    // Validar y asignar valores predeterminados para los campos esperados
    String room = alertData['room'] ?? "Desconocido";
    String status = alertData['status'] ?? "Enviada";
    bool isUrgent = alertData['isUrgent'] ?? false;
    Timestamp timestamp = alertData['timestamp'] ?? Timestamp.now();
    String handledBy = alertData['handledBy'] ?? "Desconocido";
    String professorId = alertData['professorId'] ?? "Desconocido";

    return Card(
      child: ListTile(
        leading: Icon(
          isUrgent ? Icons.warning : Icons.info,
          color: isUrgent ? Colors.red : Colors.blue,
        ),
        title: Text("Salón: $room"),
        subtitle: FutureBuilder(
          future: _getUserNames(handledBy, professorId),
          builder: (context, AsyncSnapshot<Map<String, String>> snapshot) {
            if (!snapshot.hasData) return const Text("Cargando...");
            return Text(
              "Monitor: ${snapshot.data!['monitor']}\n"
              "Profesor: ${snapshot.data!['professor']}\n"
              "Estado: $status\n"
              "Fecha: ${timestamp.toDate().toLocal()}",
            );
          },
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            _deleteAlert(alertId);
          },
        ),
        onTap: () {
          _showAlertDetails(context, alertData);
        },
      ),
    );
  }

  void _showAlertDetails(BuildContext context, Map<String, dynamic> alertData) async {
    String room = alertData['room'] ?? "Desconocido";
    String status = alertData['status'] ?? "Enviada";
    bool isUrgent = alertData['isUrgent'] ?? false;
    String handledBy = alertData['handledBy'] ?? "Desconocido";
    String professorId = alertData['professorId'] ?? "Desconocido";
    String responseTime = alertData['responseTime'] ?? "No disponible";
    Timestamp timestamp = alertData['timestamp'] ?? Timestamp.now();

    // Obtener nombres de monitor y profesor
    Map<String, String> userNames = await _getUserNames(handledBy, professorId);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Detalles de la Alerta"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Salón: $room"),
              Text("Estado: $status"),
              Text("Es Urgente: ${isUrgent ? 'Sí' : 'No'}"),
              Text("Monitor: ${userNames['monitor']}"),
              Text("Profesor: ${userNames['professor']}"),
              Text("Fecha: ${timestamp.toDate().toLocal()}"),
              Text("Tiempo de Respuesta: $responseTime"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cerrar"),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, String>> _getUserNames(String monitorId, String professorId) async {
    String monitorName = "Desconocido";
    String professorName = "Desconocido";

    // Consultar Firestore para obtener los nombres
    if (monitorId != "Desconocido" && monitorId.isNotEmpty) {
      var monitorDoc =
          await FirebaseFirestore.instance.collection('users').doc(monitorId).get();
      if (monitorDoc.exists) monitorName = monitorDoc.data()?['name'] ?? "Desconocido";
    }

    if (professorId != "Desconocido" && professorId.isNotEmpty) {
      var professorDoc =
          await FirebaseFirestore.instance.collection('users').doc(professorId).get();
      if (professorDoc.exists) professorName = professorDoc.data()?['name'] ?? "Desconocido";
    }

    return {"monitor": monitorName, "professor": professorName};
  }

  void _deleteAlert(String alertId) {
    FirebaseFirestore.instance.collection('alerts').doc(alertId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Alerta eliminada")),
    );
  }
}
