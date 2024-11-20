import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildStatisticsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('alerts').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Procesar estadísticas
        int totalAlerts = 0;
        int acceptedAlerts = 0;
        int rejectedAlerts = 0;
        int completedAlerts = 0;
        int criticalAlerts = 0;
        int totalResponseTimeInSeconds = 0; // Para el cálculo del promedio
        int responseCount = 0;

        for (var alert in snapshot.data!.docs) {
          var data = alert.data() as Map<String, dynamic>;
          String status = data['status'] ?? 'Enviada';
          bool isUrgent = data['isUrgent'] ?? false;
          String responseTime = data['responseTime'] ?? "0 h 0 min 0 sec";

          totalAlerts++;
          if (status == 'Aceptada') acceptedAlerts++;
          if (status == 'Denegada') rejectedAlerts++;
          if (status == 'Finalizada') {
            completedAlerts++;
            if (responseTime.isNotEmpty) {
              // Convertir el tiempo de respuesta a segundos
              int responseTimeInSeconds = _convertResponseTimeToSeconds(responseTime);
              totalResponseTimeInSeconds += responseTimeInSeconds;
              responseCount++;
            }
          }
          if (isUrgent) criticalAlerts++;
        }

        double averageResponseTime = responseCount > 0
            ? totalResponseTimeInSeconds / responseCount
            : 0.0;

        // Construir la interfaz de estadísticas
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Resumen Estadístico",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildStatisticItem("Total de Alertas", totalAlerts),
              _buildStatisticItem("Alertas Aceptadas", acceptedAlerts),
              _buildStatisticItem("Alertas Rechazadas", rejectedAlerts),
              _buildStatisticItem("Alertas Finalizadas", completedAlerts),
              _buildStatisticItem("Alertas Críticas (Urgentes)", criticalAlerts),
              _buildStatisticItem(
                "Promedio de Tiempo de Respuesta",
                averageResponseTime > 0
                    ? "${_formatSecondsToReadableTime(averageResponseTime.toInt())}"
                    : "No disponible",
              ),
            ],
          ),
        );
      },
    );
  }

  // Método para convertir una cadena de tiempo a segundos
  int _convertResponseTimeToSeconds(String responseTime) {
    final regex = RegExp(r'(\d+) h (\d+) min (\d+) sec');
    final match = regex.firstMatch(responseTime);

    if (match != null) {
      int hours = int.parse(match.group(1)!);
      int minutes = int.parse(match.group(2)!);
      int seconds = int.parse(match.group(3)!);

      return (hours * 3600) + (minutes * 60) + seconds;
    }
    return 0; // Si el formato no coincide, retornar 0
  }

  // Método para convertir segundos a un formato legible
  String _formatSecondsToReadableTime(int seconds) {
    int hours = seconds ~/ 3600;
    seconds %= 3600;
    int minutes = seconds ~/ 60;
    seconds %= 60;

    return "$hours h $minutes min $seconds sec";
  }

  Widget _buildStatisticItem(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            value.toString(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.pie_chart), text: "Estadísticas"),
            Tab(icon: Icon(Icons.list), text: "Alertas"),
            Tab(icon: Icon(Icons.people), text: "Monitores"),
            Tab(icon: Icon(Icons.report), text: "Alertas Críticas"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatisticsTab(),
          const Center(child: Text("Gestión de Alertas (Próximamente)")),
          const Center(child: Text("Ranking de Monitores (Próximamente)")),
          const Center(child: Text("Alertas Críticas (Próximamente)")),
        ],
      ),
    );
  }
}
