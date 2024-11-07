import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'professor_panel.dart';
import 'monitor_panel.dart';
import 'admin_page.dart';
import 'ui/styles/custom_styles.dart'; // Asegúrate de importar tu archivo de estilos

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
        backgroundColor: CustomStyles.primaryColor, // Usa tu estilo personalizado
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Correo Electrónico',
                    labelStyle: CustomStyles.labelTextStyle, // Aplica el estilo personalizado
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    labelStyle: CustomStyles.labelTextStyle, // Aplica el estilo personalizado
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                if (errorMessage.isNotEmpty)
                  Text(
                    errorMessage,
                    style: CustomStyles.errorTextStyle, // Aplica el estilo personalizado
                  ),
                ElevatedButton(
                  style: CustomStyles.elevatedButtonStyle, // Aplica el estilo personalizado
                  onPressed: () async {
                    String email = emailController.text;
                    String password = passwordController.text;

                    try {
                      firebase_auth.User? user = await authService.signInWithEmailAndPassword(email, password);

                      if (user != null) {
                        // Verifica si es el administrador
                        if (email == "admin@example.com") {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const AdminPage()),
                          );
                        } else {
                          bool usuarioEnFirestore = await verificarRegistroFirestore(email);

                          if (usuarioEnFirestore) {
                            // Verificar si es profesor o monitor
                            if (await esProfesor(email)) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const ProfessorPanel()),
                              );
                            } else {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const MonitorPanel()),
                              );
                            }
                          } else {
                            setState(() {
                              errorMessage = 'El usuario no tiene un registro en la base de datos.';
                            });
                          }
                        }
                      } else {
                        setState(() {
                          errorMessage = 'Usuario o contraseña incorrectos';
                        });
                      }
                    } catch (e) {
                      setState(() {
                        errorMessage = 'Error al iniciar sesión: $e';
                      });
                    }
                  },
                  child: Text('Ingresar', style: CustomStyles.buttonTextStyle), // Aplica el estilo personalizado
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> verificarRegistroFirestore(String email) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  Future<bool> esProfesor(String email) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .where('role', isEqualTo: 'Profesor')
        .get();

    return querySnapshot.docs.isNotEmpty;
  }
}
