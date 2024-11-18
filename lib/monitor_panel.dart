import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_page.dart';
import 'login_page.dart';
import 'package:intl/intl.dart';


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

      // Si no hay resultados, asegúrate de que `filteredAlerts` esté vacía.
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
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.grey),
                onPressed: () {
                  _removeAlertFromList(index);
                },
                tooltip: 'Eliminar de la lista',
              ),
            ),
          );
        },
      );
    },
  );
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
        var acceptedAlerts = allAlerts.where((alert) {
          var alertData = alert.data() as Map<String, dynamic>;
          return alertData['handledBy'] == userId && alertData['status'] == 'Aceptada';
        }).toList();

        var rejectedAlerts = allAlerts.where((alert) {
          var alertData = alert.data() as Map<String, dynamic>;
          return alertData['handledBy'] == userId && alertData['status'] == 'Denegada';
        }).toList();

        var completedAlerts = allAlerts.where((alert) {
          var alertData = alert.data() as Map<String, dynamic>;
          return alertData['handledBy'] == userId && alertData['status'] == 'Finalizada';
        }).toList();

        return SingleChildScrollView(
          child: Column(
            children: [
              if (acceptedAlerts.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Alertas Aceptadas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
              if (rejectedAlerts.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Alertas Rechazadas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rejectedAlerts.length,
                  itemBuilder: (context, index) {
                    var alert = rejectedAlerts[index].data() as Map<String, dynamic>;
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
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
              if (completedAlerts.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Alertas Finalizadas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: completedAlerts.length,
                  itemBuilder: (context, index) {
                    var alert = completedAlerts[index].data() as Map<String, dynamic>;
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
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
              if (acceptedAlerts.isEmpty && rejectedAlerts.isEmpty && completedAlerts.isEmpty)
                const Center(child: Text('No hay alertas en el historial.')),
            ],
          ),
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
              onTap: _logout,
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
