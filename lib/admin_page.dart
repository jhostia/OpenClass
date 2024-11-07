import 'package:flutter/material.dart';
import 'create_user_page.dart';
import 'manage_users_page.dart';
import 'report_page.dart';
import 'login_page.dart'; // Asegúrate de tener esta línea para importar LoginPage

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrador - Gestión de Usuarios'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreateUserPage()),
                );
              },
              child: const Text('Crear Usuario'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ManageUsersPage()),
                );
              },
              child: const Text('Gestionar Usuarios'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReportPage()),
                );
              },
              child: const Text('Ver Informes'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (Route<dynamic> route) => false,
                );
              },
              child: const Text('Cerrar Sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
