import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_page.dart';
import 'login_page.dart';

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

  Widget _buildAlertList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('alerts').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var alerts = snapshot.data!.docs;
        if (alerts.isEmpty) {
          return const Center(child: Text('No hay alertas disponibles.'));
        }

        return ListView.builder(
          itemCount: alerts.length,
          itemBuilder: (context, index) {
            var alert = alerts[index].data() as Map<String, dynamic>;
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
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            onPressed: () {
                              _handleAlertResponse(alerts[index].id, true);
                            },
                            tooltip: 'Aceptar',
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () {
                              _handleAlertResponse(alerts[index].id, false);
                            },
                            tooltip: 'Rechazar',
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

  Future<void> _handleAlertResponse(String alertId, bool accepted) async {
    try {
      await FirebaseFirestore.instance.collection('alerts').doc(alertId).update({
        'status': accepted ? 'Aceptada' : 'Denegada',
        'handledBy': userId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accepted ? 'Alerta aceptada' : 'Alerta denegada'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al responder la alerta: $e'),
        ),
      );
    }
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
              leading: const Icon(Icons.meeting_room),
              title: const Text('Salones'),
              onTap: () {
                // Implementar navegación a la gestión de salones
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Alertas'),
              onTap: () {
                // Implementar navegación a la gestión de alertas
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
      body: _buildAlertList(),
    );
  }
}
