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
      body: Center(
        child: Text('Aquí se mostrarán las alertas y notificaciones'),
      ),
    );
  }
}
