import 'package:flutter/material.dart';
import 'models/user_model.dart';
import 'database/database.dart';

class EditUserPage extends StatefulWidget {
  final User user;

  const EditUserPage({super.key, required this.user});

  @override
  EditUserPageState createState() => EditUserPageState();
}

class EditUserPageState extends State<EditUserPage> {
  late TextEditingController idController;
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController usernameController;
  List<String> selectedRooms = [];

  @override
  void initState() {
    super.initState();
    idController = TextEditingController(text: widget.user.id);
    nameController = TextEditingController(text: widget.user.name);
    phoneController = TextEditingController(text: widget.user.phone);
    emailController = TextEditingController(text: widget.user.email);
    usernameController = TextEditingController(text: widget.user.username);
    selectedRooms = List.from(widget.user.rooms);
  }

  @override
  void dispose() {
    idController.dispose();
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    usernameController.dispose();
    super.dispose();
  }

  Future<void> updateUser() async {
    User updatedUser = User(
      id: widget.user.id, // Usamos el id como identificador de documento
      name: nameController.text,
      phone: phoneController.text,
      email: emailController.text,
      username: usernameController.text,
      password: widget.user.password, // No se muestra ni se edita la contraseña
      role: widget.user.role,
      rooms: widget.user.role == 'Monitor' ? selectedRooms : [],
    );

    try {
      await Database().updateUser(updatedUser);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario actualizado correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar usuario: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Usuario: ${widget.user.name}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: idController, decoration: const InputDecoration(labelText: 'ID'), readOnly: true),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nombre')),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Teléfono')),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Correo')),
              TextField(controller: usernameController, decoration: const InputDecoration(labelText: 'Usuario')),
              if (widget.user.role == 'Monitor') ...[
                const SizedBox(height: 20),
                const Text('Editar Salones Asignados'),
                Wrap(
                  children: selectedRooms.map((room) {
                    return Chip(label: Text(room));
                  }).toList(),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: updateUser,
                child: const Text('Actualizar Usuario'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
