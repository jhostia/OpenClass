import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_page.dart';
import 'login_page.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'monitor_list_page.dart';
import 'chat_page.dart';

class ProfessorPanel extends StatefulWidget {
  const ProfessorPanel({super.key});

  @override
  _ProfessorPanelState createState() => _ProfessorPanelState();
}

class _ProfessorPanelState extends State<ProfessorPanel> {
  String userId = '';
  String name = 'Cargando...';
  String email = 'Cargando...';
  String phone = 'Sin teléfono'; 
  String address = 'Sin dirección'; 
  String gender = 'No especificado'; 
  TextEditingController commentsController = TextEditingController();
  String? selectedBlock;
  String? selectedFloor;
  String? selectedRoom;
  bool isUrgent = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      QuerySnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: user.email)
          .get();
      if (userDoc.docs.isNotEmpty) {
        setState(() {
          var data = userDoc.docs.first.data() as Map<String, dynamic>;
          userId = data['id'] ?? user.uid;
          name = data['name'] ?? 'Usuario';
          email = data['email'] ?? user.email!;
          phone = data['phone'] ?? 'Sin teléfono';
          address = data['address'] ?? 'Sin dirección';
          gender = data['gender'] ?? 'No especificado';
        });
      } else {
        print('No se encontró ningún documento para el usuario.');
        setState(() {
          name = 'Usuario no encontrado';
          email = 'Correo no disponible';
        });
      }
    } else {
      setState(() {
        name = 'Usuario no autenticado';
        email = 'No disponible';
      });
    }
  }

  Future<void> _sendAlert() async {
    if (selectedBlock != null && selectedFloor != null && selectedRoom != null) {
      try {
        await FirebaseFirestore.instance.collection('alerts').add({
          'block': selectedBlock,
          'floor': selectedFloor,
          'room': selectedRoom,
          'isUrgent': isUrgent,
          'comments': commentsController.text,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'Enviada',
          'professorId': userId,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alerta enviada exitosamente')),
        );

        // Limpiar los campos después de enviar la alerta
        setState(() {
          selectedBlock = null;
          selectedFloor = null;
          selectedRoom = null;
          isUrgent = false;
          commentsController.clear();
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar la alerta: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona bloque, piso y salón')),
      );
    }
  }

  Widget _buildHistory() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('alerts')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var allAlerts = snapshot.data!.docs;
        var filteredAlerts = allAlerts.where((alert) {
          var alertData = alert.data() as Map<String, dynamic>;
          return alertData['professorId'] == userId;
        }).toList();

        if (filteredAlerts.isEmpty) {
          return const Center(child: Text('No hay alertas en el historial.'));
        }

        return ListView.builder(
          itemCount: filteredAlerts.length,
          itemBuilder: (context, index) {
            var alert = filteredAlerts[index].data() as Map<String, dynamic>;
            DateTime timestamp = (alert['timestamp'] as Timestamp).toDate();
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text('Alerta en Bloque ${alert['block']} - Salón ${alert['room']}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fecha y hora: ${timestamp.toLocal()}'),
                    Text('Estado: ${alert['status']}'),
                    Text('Urgente: ${alert['isUrgent'] ? 'Sí' : 'No'}'),
                    Text('Comentarios: ${alert['comments']}'),
                    if (alert['handledBy'] != null)
                      Text('Atendida por: ${alert['handledBy']}'),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _finalizeAlert(String alertId, String monitorId) async {
  try {
    DateTime now = DateTime.now(); 

    // Obtener la alerta
    var alertDoc = await FirebaseFirestore.instance.collection('alerts').doc(alertId).get();
    if (alertDoc.exists) {
      Map<String, dynamic>? alertData = alertDoc.data();
      if (alertData != null) {
        // Verificar si `acceptedTime` existe y calcular `responseTime`
        if (alertData.containsKey('acceptedTime') && alertData['acceptedTime'] != null) {
          DateTime acceptedTime = (alertData['acceptedTime'] as Timestamp).toDate();
          Duration responseTime = now.difference(acceptedTime);

          // Formatear el tiempo de respuesta en horas, minutos y segundos
          String responseTimeFormatted =
              '${responseTime.inHours} h ${responseTime.inMinutes % 60} min ${responseTime.inSeconds % 60} sec';

          // Actualizar la alerta con el estado finalizado
          await FirebaseFirestore.instance.collection('alerts').doc(alertId).update({
            'status': 'Finalizada',
            'completedTime': Timestamp.fromDate(now),
            'responseTime': responseTimeFormatted,
          });

          // Obtener datos del monitor
          var monitorDoc = await FirebaseFirestore.instance.collection('users').doc(monitorId).get();
          if (monitorDoc.exists) {
            Map<String, dynamic>? monitorData = monitorDoc.data();
            if (monitorData != null) {
              // Inicializar campos si no existen
              int totalResponses = (monitorData['totalResponses'] ?? 0) as int;
              String totalResponseTimeStr = (monitorData['totalResponseTime'] ?? '0 h 0 min 0 sec') as String;
              double totalStars = (monitorData['totalStars'] ?? 0.0) as double;

              // Convertir `totalResponseTime` de formato legible a duración total en segundos
              int totalResponseTimeInSeconds = _convertReadableTimeToSeconds(totalResponseTimeStr);

              // Actualizar campos
              totalResponses += 1;
              totalResponseTimeInSeconds += responseTime.inSeconds;

              // Convertir `totalResponseTimeInSeconds` de nuevo a formato legible
              String updatedTotalResponseTime =
                  '${(totalResponseTimeInSeconds ~/ 3600)} h ${(totalResponseTimeInSeconds % 3600 ~/ 60)} min ${(totalResponseTimeInSeconds % 60)} sec';

              // Calcular `averageResponseTime` en segundos
              int averageResponseTimeInSeconds = (totalResponseTimeInSeconds / totalResponses).round();
              String averageResponseTimeFormatted =
                  '${(averageResponseTimeInSeconds ~/ 3600)} h ${(averageResponseTimeInSeconds % 3600 ~/ 60)} min ${(averageResponseTimeInSeconds % 60)} sec';

              // Mostrar el diálogo para calificar al monitor
              double rating = await _showRatingDialog();

              // Actualizar el total de estrellas y el promedio
              totalStars += rating;
              double averageStars = totalStars / totalResponses;

              // Actualizar los datos del monitor
              await FirebaseFirestore.instance.collection('users').doc(monitorId).update({
                'totalResponses': totalResponses,
                'totalResponseTime': updatedTotalResponseTime,
                'averageResponseTime': averageResponseTimeFormatted,
                'totalStars': totalStars,
                'averageStars': averageStars,
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Alerta finalizada, tiempo de respuesta y calificación registrados.')),
              );
            }
          } else {
            throw Exception('El documento del monitor no existe.');
          }
        } else {
          throw Exception('El campo "acceptedTime" no existe o es nulo en el documento de la alerta.');
        }
      } else {
        throw Exception('El documento de la alerta está vacío.');
      }
    } else {
      throw Exception('El documento de la alerta no existe.');
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al finalizar la alerta: $e')),
    );
  }
}

// Función para convertir tiempo de respuesta legible a segundos
int _convertReadableTimeToSeconds(String readableTime) {
  final regex = RegExp(r'(\d+) h (\d+) min (\d+) sec');
  final match = regex.firstMatch(readableTime);

  if (match != null) {
    int hours = int.parse(match.group(1)!);
    int minutes = int.parse(match.group(2)!);
    int seconds = int.parse(match.group(3)!);
    return (hours * 3600) + (minutes * 60) + seconds;
  }
  return 0;
}

  Future<double> _showRatingDialog() async {
    double rating = 3.0; // Calificación inicial por defecto

    return await showDialog<double>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Califica al monitor'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Selecciona una calificación:'),
              RatingBar.builder(
                initialRating: rating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (newRating) {
                  rating = newRating; // Actualiza el valor de la calificación
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(rating); // Retorna la calificación seleccionada
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    ) ?? 3.0; // Retorna 3.0 si el diálogo se cierra sin seleccionar una calificación
  }

 Widget _buildAlertsInProgress() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('alerts')
        .where('professorId', isEqualTo: userId)
        .where('status', isEqualTo: 'Aceptada')
        .snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      var alerts = snapshot.data!.docs;
      if (alerts.isEmpty) {
        return const Center(child: Text('No hay alertas en proceso.'));
      }

      return ListView.builder(
        itemCount: alerts.length,
        itemBuilder: (context, index) {
          var alert = alerts[index].data() as Map<String, dynamic>;
          String monitorId = alert['handledBy'];

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(monitorId).get(),
            builder: (context, monitorSnapshot) {
              if (!monitorSnapshot.hasData) {
                return const ListTile(
                  title: Text('Cargando...'),
                );
              }

              var monitorData = monitorSnapshot.data!.data() as Map<String, dynamic>;
              String monitorName = monitorData['name'] ?? 'Desconocido';

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text('Alerta en Bloque ${alert['block']} - Salón ${alert['room']}'),
                  subtitle: Text('Monitor: $monitorName\nEstado: ${alert['status']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.message, color: Colors.blueAccent),
                        tooltip: 'Abrir chat',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatPage(
                                alertId: alerts[index].id,
                                professorId: userId,
                                monitorId: monitorId,
                              ),
                            ),
                          );
                        },
                      ),
                      ElevatedButton(
                        onPressed: () => _finalizeAlert(alerts[index].id, monitorId),
                        child: const Text('Finalizar'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}

  List<String> _generateRooms(String floor, String block) {
    return List.generate(4, (index) {
      int roomNumber = index + 1;
      return '${floor}0$roomNumber$block';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profesor - Crear Alerta'),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              accountName: Text(name),
              accountEmail: Text(email),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 50),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Perfil'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(
                      id: userId,
                      name: name,
                      phone: phone,
                      email: email,
                      address: address,
                      gender: gender,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Historial'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      appBar: AppBar(title: const Text('Historial de Alertas')),
                      body: _buildHistory(),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.incomplete_circle),
              title: const Text('Alertas en proceso'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      appBar: AppBar(title: const Text('Alertas en proceso')),
                      body: _buildAlertsInProgress(),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Monitores'),
              onTap: () {
              Navigator.push(
                context,
                  MaterialPageRoute(
                    builder: (context) => const MonitorListPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () {
              _showLogoutConfirmationDialog(context);
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedBlock,
                  items: ['P', 'I']
                      .map((block) => DropdownMenuItem(
                            value: block,
                            child: Text('Bloque $block'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedBlock = value;
                      selectedFloor = null;
                      selectedRoom = null;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Seleccionar Bloque',
                    prefixIcon: const Icon(Icons.location_city),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                if (selectedBlock != null)
                  DropdownButtonFormField<String>(
                    value: selectedFloor,
                    items: ['1', '2', '3', '4']
                        .map((floor) => DropdownMenuItem(
                              value: floor,
                              child: Text('Piso $floor'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedFloor = value;
                        selectedRoom = null;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Seleccionar Piso',
                      prefixIcon: const Icon(Icons.layers),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                const SizedBox(height: 16),
                if (selectedFloor != null)
                  DropdownButtonFormField<String>(
                    value: selectedRoom,
                    items: _generateRooms(selectedFloor!, selectedBlock!)
                        .map((room) => DropdownMenuItem(
                              value: room,
                              child: Text('Salón $room'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedRoom = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Seleccionar Salón',
                      prefixIcon: const Icon(Icons.meeting_room),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentsController,
                  decoration: InputDecoration(
                    labelText: 'Comentarios',
                    prefixIcon: const Icon(Icons.comment),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('¿Es Urgente?'),
                  value: isUrgent,
                  onChanged: (value) {
                    setState(() {
                      isUrgent = value;
                    });
                  },
                  activeColor: Colors.red,
                ),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: _sendAlert,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Enviar Alerta', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Confirmar'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: <Widget>[
          TextButton(
            child: const Text('No'),
            onPressed: () {
              Navigator.of(context).pop(); 
            },
          ),
          TextButton(
            child: const Text('Sí'),
            onPressed: () {
              Navigator.of(context).pop(); 
              FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      );
    },
  );
}

}
