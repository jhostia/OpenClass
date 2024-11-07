import 'package:flutter/material.dart';
import 'database/database.dart';
import 'models/user_model.dart';
import 'edit_user_page.dart';

class ManageUsersPage extends StatefulWidget {
  @override
  _ManageUsersPageState createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  List<User> users = [];
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
  try {
    List<User> fetchedUsers = await Database().getAllUsers();
    print("Usuarios obtenidos: ${fetchedUsers.length}"); // Verifica cuántos usuarios se obtienen
    setState(() {
      users = fetchedUsers;
    });
  } catch (e) {
    setState(() {
      errorMessage = 'Error al cargar usuarios: $e';
    });
    print("Error en loadUsers: $e"); // Imprime el error en caso de fallo
  }
}


  void showUserDetails(User user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(user.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
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
        users.removeWhere((user) => user.id == userId);
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
      ),
      body: errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage, style: const TextStyle(color: Colors.red)))
          : users.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      title: Text(user.name),
                      subtitle: Text(user.email),
                      onTap: () => showUserDetails(user), // Muestra detalles al hacer clic
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditUserPage(user: user),
                                ),
                              ).then((_) => loadUsers()); // Recarga los usuarios al regresar
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              deleteUser(user.id);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
