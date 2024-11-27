import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'professor_panel.dart';
import 'monitor_panel.dart';
import 'admin_page.dart';
import 'create_user_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool rememberMe = true; 
  bool _passwordVisible = false; 
  bool isLoading = false; 

  @override
  void initState() {
    super.initState();
    _passwordVisible = false;
    _checkSavedSession();
  }

  //Guarda las credeniales del usuario de manera local
  Future<void> _saveUserSession(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
    await prefs.setString('password', password);
  }

  //Verifica si hay una sesion guardada para iniciar sesion automaticamente
  Future<void> _checkSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('email');
    final savedPassword = prefs.getString('password');

    if (savedEmail != null && savedPassword != null) {
      try {
        await authService.signInWithEmailAndPassword(savedEmail, savedPassword);
        // Redirige a la pantalla principal
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminPage()), 
        );
      } catch (e) {
        // Maneja errores de inicio de sesión si es necesario
      }
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 238, 241, 246), 
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    'Iniciar Sesión',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Correo Electrónico',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: !_passwordVisible, 
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _passwordVisible = !_passwordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Checkbox(
                        value: rememberMe,
                        onChanged: (bool? value) {
                          setState(() {
                            rememberMe = value ?? false;
                          });
                        },
                      ),
                      const Text('Recordarme'),
                    ],
                  ),
                  if (errorMessage.isNotEmpty)
                    Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 20),
                  isLoading
                      ? const CircularProgressIndicator() 
                      : ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 5,
                          ),
                          onPressed: () async {
                            setState(() {
                              isLoading = true; 
                              errorMessage = ''; 
                            });

                            String email = emailController.text.trim();
                            String password = passwordController.text.trim();

                            try {
                              firebase_auth.User? user =
                                  await authService.signInWithEmailAndPassword(email, password);

                              if (user != null) {
                                if (email == "admin@example.com") {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (context) => const AdminPage()),
                                  );
                                } else {
                                  bool usuarioEnFirestore =
                                      await verificarRegistroFirestore(email);

                                  if (usuarioEnFirestore) {
                                    if (await esProfesor(email)) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => const ProfessorPanel()),
                                      );
                                    } else {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => const MonitorPanel()),
                                      );
                                    }
                                  } else {
                                    setState(() {
                                      errorMessage = 'Este usuario no existe.';
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
                            } finally {
                              setState(() {
                                isLoading = false; 
                              });
                            }
                          },
                          icon: const Icon(Icons.login, color: Colors.white),
                          label: const Text(
                            'Iniciar Sesión   ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CreateUserPage()),
                      );
                    },
                    child: const Text(
                      '¿No tienes una cuenta? Regístrate',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () async {
                    String email = ''; // Inicializa como una cadena vacía para evitar problemas de nulabilidad
                    final result = await showDialog<String>(
                    context: context,
                    builder: (context) => AlertDialog(
                    title: const Text('Restablecer contraseña'),
                    content: TextField(
                      decoration: const InputDecoration(labelText: 'Correo electrónico'),
                      onChanged: (value) {
                        email = value.trim(); 
                      },
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(), // Cierra el diálogo sin devolver valor
                        child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(email), // Devuelve el email ingresado
                          child: const Text('Enviar'),
                        ),
                      ],
                    ),
                    );
                    // Verifica el resultado del diálogo
                    if (result != null && result.isNotEmpty) {
                      try {
                        await firebase_auth.FirebaseAuth.instance.sendPasswordResetEmail(email: result);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Correo de restablecimiento enviado'),
                        ));
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Error: ${e.toString()}'),
                        ));
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Por favor, ingresa un correo válido'),
                      ));
                    }
                  },
                  child: const Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(
                      color: Colors.blueAccent,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),

                ],
              ),
            ),
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
