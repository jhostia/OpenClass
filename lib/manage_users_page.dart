import 'package:flutter/material.dart';
import 'database/database.dart';
import 'models/user_model.dart';
import 'edit_user_page.dart';

class ManageUsersPage extends StatefulWidget {
  @override
  _ManageUsersPageState createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  List<User> monitors = [];
  List<User> professors = [];
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    try {
      List<User> fetchedUsers = await Database().getAllUsers();
      setState(() {
        monitors = fetchedUsers.where((user) => user.role == 'Monitor').toList();
        professors = fetchedUsers.where((user) => user.role == 'Profesor').toList();
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error al cargar usuarios: $e';
      });
    }
  }

  void showUserDetails(User user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            user.name,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Correo: ${user.email}'),
              Text('Teléfono: ${user.phone}'),
              Text('Identificación: ${user.id}'),
              Text('Rol: ${user.role}'),
              if (user.role == 'Monitor')
                Text('Salones asignados: ${user.rooms.join(', ')}'),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteUser(String userId) async {
    try {
      await Database().deleteUser(userId);
      setState(() {
        monitors.removeWhere((user) => user.id == userId);
        professors.removeWhere((user) => user.id == userId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario eliminado exitosamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar usuario: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Usuarios'),
        backgroundColor: Colors.blueAccent,
      ),
      body: errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage, style: const TextStyle(color: Colors.red)))
          : monitors.isEmpty && professors.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Monitores",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent),
                        ),
                        const SizedBox(height: 10),
                        ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: monitors.length,
                          itemBuilder: (context, index) {
                            final monitor = monitors[index];
                            return _buildUserCard(monitor);
                          },
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Profesores",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green),
                        ),
                        const SizedBox(height: 10),
                        ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: professors.length,
                          itemBuilder: (context, index) {
                            final professor = professors[index];
                            return _buildUserCard(professor);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildUserCard(User user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(
          user.name,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Correo: ${user.email}'),
            Text('Rol: ${user.role}'),
            if (user.role == 'Monitor')
              Text('Salones: ${user.rooms.join(', ')}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditUserPage(user: user),
                  ),
                ).then((_) => loadUsers());
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                deleteUser(user.id);
              },
            ),
          ],
        ),
        onTap: () => showUserDetails(user),
      ),
    );
  }
}
