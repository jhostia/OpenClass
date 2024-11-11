import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_page.dart';
import 'login_page.dart';

class ProfessorPanel extends StatefulWidget {
  const ProfessorPanel({super.key});

  @override
  _ProfessorPanelState createState() => _ProfessorPanelState();
}

class _ProfessorPanelState extends State<ProfessorPanel> {
  String userId = '';
  String name = 'Cargando...';
  String email = 'Cargando...';
  String phone = 'Sin teléfono'; // Variable añadida
  String address = 'Sin dirección'; // Variable añadida
  String gender = 'No especificado'; // Variable añadida
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
        title: const Text('Profesor - Llamar Monitor'),
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
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
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
}

