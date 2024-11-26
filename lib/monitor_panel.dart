import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_page.dart';
import 'login_page.dart';
import 'package:intl/intl.dart';
import 'chat_page.dart';


class MonitorPanel extends StatefulWidget {
  const MonitorPanel({super.key});

  @override
  _MonitorPanelState createState() => _MonitorPanelState();
}

class _MonitorPanelState extends State<MonitorPanel> {
  String userId = '';
  String name = 'Cargando...';
  String email = 'Cargando...';
  String phone = 'Sin teléfono';
  String address = 'Sin dirección';
  String gender = 'No especificado';
  bool isActive = true;

  // Variables para el filtrado
  String? selectedFilterType;
  String? selectedFilterValue;
  DateTime? selectedDate;

  List<QueryDocumentSnapshot> filteredAlerts = [];
  List<QueryDocumentSnapshot> allAlerts = [];
  String? selectedStatus;
  bool? isUrgentFilter;
  String? selectedBlock;

  // Opciones de filtrado
  final List<String> filterTypes = ['Estado', 'Urgencia', 'Bloque', 'Fecha'];
  final List<String> statusOptions = ['Enviada', 'Aceptada', 'Denegada', 'Finalizada'];
  final List<String> blockOptions = ['I', 'P'];
  final List<String> urgencyOptions = ['Sí', 'No'];
  
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
          isActive = data['isActive'] ?? true;
        });
      }
    }
  }

  Future<void> _toggleActiveStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        isActive = !isActive;
      });
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isActive': isActive,
      });
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  // Método para eliminar una alerta de la lista en la interfaz
  void _removeAlertFromList(int index) {
    setState(() {
      filteredAlerts.removeAt(index);
    });
  }

  // Método para aplicar filtros a las alertas
  void _applyFilters() {
  setState(() {
    if (selectedFilterType == null) {
      // Si no se selecciona ningún filtro, mostrar todas las alertas.
      filteredAlerts = List.from(allAlerts);
    } else {
      filteredAlerts = allAlerts.where((alert) {
        var alertData = alert.data() as Map<String, dynamic>;

        bool matchesStatus = selectedFilterType == 'Estado' && (selectedFilterValue == null || alertData['status'] == selectedFilterValue);
        bool matchesUrgency = selectedFilterType == 'Urgencia' && (selectedFilterValue == null || (selectedFilterValue == 'Sí' ? alertData['isUrgent'] == true : alertData['isUrgent'] == false));
        bool matchesBlock = selectedFilterType == 'Bloque' && (selectedFilterValue == null || alertData['block'] == selectedFilterValue);
        bool matchesDate = selectedFilterType == 'Fecha' && (selectedDate == null || (alertData['timestamp'] as Timestamp).toDate().toLocal().day == selectedDate!.day && (alertData['timestamp'] as Timestamp).toDate().toLocal().month == selectedDate!.month && (alertData['timestamp'] as Timestamp).toDate().toLocal().year == selectedDate!.year);

        return matchesStatus || matchesUrgency || matchesBlock || matchesDate;
      }).toList();

     
      if (filteredAlerts.isEmpty) {
        filteredAlerts = [];
      }
    }
  });
}

  Widget _buildFilterOptions() {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Column(
      children: [
        DropdownButtonFormField<String>(
          value: selectedFilterType,
          items: ['Ninguno', ...filterTypes].map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type == 'Ninguno' ? 'Ver todos' : 'Filtrar por $type'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedFilterType = value;
              selectedFilterValue = null;
              selectedDate = null;
              if (selectedFilterType == 'Ninguno') {
                filteredAlerts = List.from(allAlerts); // Muestra todas las alertas si se selecciona "Ninguno".
              }
            });
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Seleccionar tipo de filtro',
          ),
        ),
        const SizedBox(height: 10),
        if (selectedFilterType == 'Estado')
          DropdownButtonFormField<String>(
            value: selectedFilterValue,
            items: statusOptions.map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(status),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedFilterValue = value;
              });
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Seleccionar estado',
            ),
          ),
        if (selectedFilterType == 'Urgencia')
          DropdownButtonFormField<String>(
            value: selectedFilterValue,
            items: urgencyOptions.map((urgency) {
              return DropdownMenuItem(
                value: urgency,
                child: Text(urgency),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedFilterValue = value;
              });
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Seleccionar urgencia',
            ),
          ),
        if (selectedFilterType == 'Bloque')
          DropdownButtonFormField<String>(
            value: selectedFilterValue,
            items: blockOptions.map((block) {
              return DropdownMenuItem(
                value: block,
                child: Text(block),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedFilterValue = value;
              });
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Seleccionar bloque',
            ),
          ),
        if (selectedFilterType == 'Fecha')
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2022),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        selectedDate = pickedDate;
                      });
                    }
                  },
                  child: Text(
                    selectedDate == null
                        ? 'Seleccionar fecha'
                        : DateFormat('dd/MM/yyyy').format(selectedDate!),
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            if (selectedFilterType == 'Ninguno') {
              setState(() {
                filteredAlerts = List.from(allAlerts);
              });
            } else {
              _applyFilters(); // Llama a la función para aplicar los filtros.
            }
          },
          child: const Text('Buscar'),
        ),
      ],
    ),
  );
}

  Widget _buildAlertList() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('alerts').orderBy('timestamp', descending: true).snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      allAlerts = snapshot.data!.docs;

      // Inicializa `filteredAlerts` con todas las alertas si está vacío y no hay filtro activo
      if (filteredAlerts.isEmpty && (selectedFilterType == null || selectedFilterType == 'Ninguno')) {
        filteredAlerts = List.from(allAlerts);
      }

      // Mostrar mensaje si no hay alertas después de aplicar el filtro
      if (filteredAlerts.isEmpty && selectedFilterType != null && selectedFilterType != 'Ninguno') {
        return const Center(child: Text('No existen alertas por ese filtrado.'));
      }

      return ListView.builder(
        itemCount: filteredAlerts.length,
        itemBuilder: (context, index) {
          var alert = filteredAlerts[index].data() as Map<String, dynamic>;
          String status = alert['status'] ?? 'Enviada';

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
            child: ListTile(
              title: Text(
                'Alerta en Bloque ${alert['block']} - Salón ${alert['room']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Urgente: ${alert['isUrgent'] ? 'Sí' : 'No'}',
                    style: TextStyle(
                      color: alert['isUrgent'] ? Colors.red : Colors.black,
                      fontWeight: alert['isUrgent'] ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  Text(
                    'Comentarios: ${alert['comments'].isNotEmpty ? alert['comments'] : 'Sin comentarios'}',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Estado: $status',
                    style: TextStyle(
                      color: status == 'Aceptada' ? Colors.green : status == 'Denegada' ? Colors.red : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              trailing: status == 'Enviada'
    ? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () {
              _updateAlertStatus(filteredAlerts[index].id, 'Aceptada');
            },
            tooltip: 'Aceptar alerta',
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () {
              _updateAlertStatus(filteredAlerts[index].id, 'Denegada');
            },
            tooltip: 'Denegar alerta',
          ),
        ],
      )
      : null,

            ),
          );
        },
      );
    },
  );
}

void _updateAlertStatus(String alertId, String newStatus) async {
  try {
    Map<String, dynamic> updateData = {
      'status': newStatus,
      'handledBy': userId, 
    };

    // Si el nuevo estado es "Aceptada", añadimos el campo `acceptedTime` y creamos un chat
    if (newStatus == 'Aceptada') {
      updateData['acceptedTime'] = Timestamp.now();

      // Obtener la información de la alerta para usar en el chat
      DocumentSnapshot alertSnapshot =
          await FirebaseFirestore.instance.collection('alerts').doc(alertId).get();

      if (alertSnapshot.exists) {
        var alertData = alertSnapshot.data() as Map<String, dynamic>;

        // Verificar si el campo `createdBy` (profesor que creó la alerta) está presente
        if (alertData.containsKey('professorId') && alertData['professorId'] != null) {
          await FirebaseFirestore.instance.collection('chats').doc(alertId).set({
            'alertId': alertId,
            'professorId': alertData['professorId'], 
            'monitorId': userId, 
            'messages': [], 
            'createdAt': Timestamp.now(),
          });
        } else {
          throw Exception('El campo "professorId" no está definido en la alerta.');
        }
      } else {
        throw Exception('No se encontró el documento de la alerta.');
      }
    }

    await FirebaseFirestore.instance.collection('alerts').doc(alertId).update(updateData);

    // Actualiza la interfaz eliminando la alerta del estado actual
    setState(() {
      filteredAlerts.removeWhere((alert) => alert.id == alertId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Alerta $newStatus correctamente')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al actualizar el estado de la alerta: $e')),
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

      // Filtrar alertas según el estado
      var acceptedAlerts = allAlerts.where((alert) {
        var alertData = alert.data() as Map<String, dynamic>;
        return alertData['handledBy'] == userId && alertData['status'] == 'Aceptada';
      }).toList();

      var declinedAlerts = allAlerts.where((alert) {
        var alertData = alert.data() as Map<String, dynamic>;
        return alertData['handledBy'] == userId && alertData['status'] == 'Denegada';
      }).toList();

      var finalizedAlerts = allAlerts.where((alert) {
        var alertData = alert.data() as Map<String, dynamic>;
        return alertData['handledBy'] == userId && alertData['status'] == 'Finalizada';
      }).toList();

      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (acceptedAlerts.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Alertas Aceptadas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: acceptedAlerts.length,
                itemBuilder: (context, index) {
                  var alert = acceptedAlerts[index].data() as Map<String, dynamic>;
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
                          Text('Comentarios: ${alert['comments']}'),
                          Text('Urgente: ${alert['isUrgent'] ? 'Sí' : 'No'}'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.chat, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatPage(
                                alertId: acceptedAlerts[index].id,
                                professorId: alert['professorId'],
                                monitorId: userId,
                              ),
                            ),
                          );
                        },
                        tooltip: 'Abrir chat',
                      ),
                      onTap: () => _showAlertDetails(context, acceptedAlerts[index].id, alert),
                    ),
                  );
                },
              ),
            ],
            if (declinedAlerts.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Alertas Denegadas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: declinedAlerts.length,
                itemBuilder: (context, index) {
                  var alert = declinedAlerts[index].data() as Map<String, dynamic>;
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
                          Text('Comentarios: ${alert['comments']}'),
                          Text('Urgente: ${alert['isUrgent'] ? 'Sí' : 'No'}'),
                        ],
                      ),
                      onTap: () => _showAlertDetails(context, declinedAlerts[index].id, alert),
                    ),
                  );
                },
              ),
            ],
            if (finalizedAlerts.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Alertas Finalizadas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: finalizedAlerts.length,
                itemBuilder: (context, index) {
                  var alert = finalizedAlerts[index].data() as Map<String, dynamic>;
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
                          Text('Comentarios: ${alert['comments']}'),
                          Text('Urgente: ${alert['isUrgent'] ? 'Sí' : 'No'}'),
                        ],
                      ),
                      onTap: () => _showAlertDetails(context, finalizedAlerts[index].id, alert),
                    ),
                  );
                },
              ),
            ],
            if (acceptedAlerts.isEmpty &&
                declinedAlerts.isEmpty &&
                finalizedAlerts.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No hay alertas en el historial.'),
                ),
              ),
          ],
        ),
      );
    },
  );
}

// Método para mostrar detalles de la alerta en un diálogo
void _showAlertDetails(BuildContext context, String alertId, Map<String, dynamic> alertData) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Detalles de la Alerta'),
        content: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(alertData['professorId']).get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            var professorData = snapshot.data!.data() as Map<String, dynamic>;
            String professorName = professorData['name'] ?? 'Desconocido';
            String responseTime = alertData['responseTime'] ?? 'No disponible';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Bloque: ${alertData['block']}'),
                Text('Salón: ${alertData['room']}'),
                Text('Urgente: ${alertData['isUrgent'] ? 'Sí' : 'No'}'),
                Text('Comentarios: ${alertData['comments']}'),
                Text('Profesor: $professorName'),
                Text('Tiempo de Respuesta: $responseTime'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      );
    },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitor - Responder Alertas'),
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
              leading: const Icon(Icons.notifications),
              title: const Text('Historial de Alertas'),
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
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () {
              _showLogoutConfirmationDialog(context);
              },
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Estado activo'),
              value: isActive,
              onChanged: (value) {
                _toggleActiveStatus();
              },
              activeColor: Colors.blue,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildFilterOptions(),
          Expanded(child: _buildAlertList()),
        ],
      ),
    );
  }
}
