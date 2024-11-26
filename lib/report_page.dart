import 'package:app_monitores/monitor_ranking_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'alerts_management.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:open_file/open_file.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late QuerySnapshot alertsSnapshot;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<String> _getUserName(String userId) async {
    if (userId.isEmpty) return 'N/A';

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      return userDoc.data()?['name'] ?? 'N/A';
    }
    return 'N/A';
  }

  Widget _buildStatisticsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('alerts').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        alertsSnapshot = snapshot.data!;

        int totalAlerts = 0;
        int acceptedAlerts = 0;
        int rejectedAlerts = 0;
        int completedAlerts = 0;
        int totalResponseTimeInSeconds = 0;
        int responseCount = 0;

        for (var alert in snapshot.data!.docs) {
          var data = alert.data() as Map<String, dynamic>;
          String status = data['status'] ?? 'Enviada';
          String responseTime = data['responseTime'] ?? "0 h 0 min 0 sec";

          totalAlerts++;
          if (status == 'Aceptada') acceptedAlerts++;
          if (status == 'Denegada') rejectedAlerts++;
          if (status == 'Finalizada') {
            completedAlerts++;
            if (responseTime.isNotEmpty) {
              int responseTimeInSeconds = _convertResponseTimeToSeconds(responseTime);
              totalResponseTimeInSeconds += responseTimeInSeconds;
              responseCount++;
            }
          }
        }

        double averageResponseTime = responseCount > 0
            ? totalResponseTimeInSeconds / responseCount
            : 0.0;

        return SingleChildScrollView(
          child: Padding(
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
                _buildStatisticItem(
                  "Promedio de Tiempo de Respuesta",
                  averageResponseTime > 0
                      ? "${_formatSecondsToReadableTime(averageResponseTime.toInt())}"
                      : "No disponible",
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text("Exportar a PDF"),
                  onPressed: _exportToPDF,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _convertResponseTimeToSeconds(String responseTime) {
    final regex = RegExp(r'(\d+) h (\d+) min (\d+) sec');
    final match = regex.firstMatch(responseTime);

    if (match != null) {
      int hours = int.parse(match.group(1)!);
      int minutes = int.parse(match.group(2)!);
      int seconds = int.parse(match.group(3)!);

      return (hours * 3600) + (minutes * 60) + seconds;
    }
    return 0;
  }

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
          Flexible(
            child: Text(
              value.toString(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToPDF() async {
    try {
      final pdf = pw.Document();

      List<List<String>> dataRows = [
        ["Salón", "Estado", "Urgente", "Monitor", "Profesor", "Tiempo Respuesta", "Fecha"]
      ];

      for (var doc in alertsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final monitorName = await _getUserName(data['handledBy'] ?? '');
        final professorName = await _getUserName(data['professorId'] ?? '');

        dataRows.add([
          data['room'] ?? 'Desconocido',
          data['status'] ?? 'Sin estado',
          data['isUrgent'] == true ? 'Sí' : 'No',
          monitorName,
          professorName,
          data['responseTime'] ?? 'N/A',
          data['timestamp']?.toDate().toString() ?? 'Sin fecha',
        ]);
      }

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "Informe de Alertas",
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(context: context, data: dataRows),
            ],
          ),
        ),
      );

      final downloadsDirectory = Directory("/storage/emulated/0/Download");
      if (!downloadsDirectory.existsSync()) {
        downloadsDirectory.createSync(recursive: true);
      }
      final file = File("${downloadsDirectory.path}/informe_alertas.pdf");
      await file.writeAsBytes(await pdf.save());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PDF exportado: ${file.path}")),
      );

      OpenFile.open(file.path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al exportar PDF: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Center(
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              tabs: const [
                Tab(icon: Icon(Icons.pie_chart), text: "Estadísticas"),
                Tab(icon: Icon(Icons.list), text: "Alertas"),
                Tab(icon: Icon(Icons.people), text: "Monitores"),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatisticsTab(),
          const AlertsManagement(),
          const MonitorRankingPage(),
        ],
      ),
    );
  }
}
