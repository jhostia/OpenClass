import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'auth_service.dart';
import 'professor_panel.dart';
import 'monitor_panel.dart';
import 'admin_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService authService = AuthService();
  String errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Sesión'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Correo Electrónico'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ElevatedButton(
              onPressed: () async {
                String email = emailController.text;
                String password = passwordController.text;

                firebase_auth.User? user = await authService.signInWithEmailAndPassword(email, password);

                if (user != null) {
                  // Usuario autenticado con éxito, redirige según el rol
                  if (email == "admin@example.com") {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminPage()),
                    );
                  } else if (email.contains("profesor")) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfessorPanel()),
                    );
                  } else if (email.contains("monitor")) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const MonitorPanel()),
                    );
                  }
                } else {
                  // Usuario o contraseña incorrectos
                  setState(() {
                    errorMessage = 'Usuario o contraseña incorrectos';
                    emailController.clear();
                    passwordController.clear();
                  });
                }
              },
              child: const Text('Ingresar'),
            ),
          ],
        ),
      ),
    );
  }
}
