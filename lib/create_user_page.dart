import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'database/database.dart';
import 'models/user_model.dart';

class CreateUserPage extends StatefulWidget {
  @override
  _CreateUserPageState createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  final AuthService _authService = AuthService();

  String selectedRole = 'Profesor';
  List<String> selectedBlocks = [];
  List<String> selectedFloors = [];
  List<String> selectedRooms = [];

  final List<String> blocks = ['i', 'p'];
  final List<String> floors = ['1', '2', '3', '4'];

  Map<String, List<String>> roomsByFloor = {
    '1': ['101', '102', '103', '104'],
    '2': ['201', '202', '203', '204'],
    '3': ['301', '302', '303', '304'],
    '4': ['401', '402', '403', '404'],
  };

  String errorMessage = '';

  void registerUser() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String name = nameController.text.trim();
    String id = idController.text.trim();
    String phone = phoneController.text.trim();

    // Verificar si los campos están vacíos
    if (email.isEmpty || password.isEmpty || name.isEmpty || id.isEmpty || phone.isEmpty) {
      setState(() {
        errorMessage = 'Por favor complete todos los campos';
      });
      return;
    }

    if (selectedRole == 'Monitor' && selectedRooms.isEmpty) {
      setState(() {
        errorMessage = 'Debe seleccionar al menos un salón para el monitor.';
      });
      return;
    }

    User newUser = User(
      id: id,
      name: name,
      phone: phone,
      email: email,
      username: '', // Asigna el valor necesario
      password: password,
      role: selectedRole,
      rooms: selectedRole == 'Monitor' ? selectedRooms : [],
    );

    try {
      await _authService.createUserWithEmailAndPassword(email, password);
      await Database().saveUserData(newUser);
      setState(() {
        errorMessage = '';
      });

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario registrado exitosamente')),
      );

      // Regresar a la pantalla anterior
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        errorMessage = 'Error al registrar usuario: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Usuario'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Correo Electrónico'),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
              ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: idController,
                decoration: const InputDecoration(labelText: 'Identificación'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Teléfono'),
              ),
              DropdownButton<String>(
                value: selectedRole,
                items: ['Profesor', 'Monitor']
                    .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedRole = value!;
                    if (selectedRole != 'Monitor') {
                      selectedRooms.clear();
                      selectedBlocks.clear();
                      selectedFloors.clear();
                    }
                  });
                },
              ),
              if (selectedRole == 'Monitor') ...[
                const SizedBox(height: 20),
                const Text('Seleccione Bloques'),
                Wrap(
                  children: blocks.map((block) {
                    return FilterChip(
                      label: Text(block.toUpperCase()),
                      selected: selectedBlocks.contains(block),
                      onSelected: (isSelected) {
                        setState(() {
                          isSelected ? selectedBlocks.add(block) : selectedBlocks.remove(block);
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const Text('Seleccione Pisos'),
                Wrap(
                  children: floors.map((floor) {
                    return FilterChip(
                      label: Text(floor),
                      selected: selectedFloors.contains(floor),
                      onSelected: (isSelected) {
                        setState(() {
                          isSelected ? selectedFloors.add(floor) : selectedFloors.remove(floor);
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const Text('Seleccione Salones'),
                Wrap(
                  children: selectedFloors.expand((floor) {
                    return roomsByFloor[floor]?.map((room) {
                      final formattedRoom = selectedBlocks.isNotEmpty
                          ? '$room${selectedBlocks[0].toLowerCase()}'
                          : room;
                      return FilterChip(
                        label: Text(formattedRoom),
                        selected: selectedRooms.contains(formattedRoom),
                        onSelected: (isSelected) {
                          setState(() {
                            isSelected
                                ? selectedRooms.add(formattedRoom)
                                : selectedRooms.remove(formattedRoom);
                          });
                        },
                      );
                    }).toList() ?? [];
                  }).cast<Widget>().toList(),
                ),
              ],
              if (errorMessage.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: registerUser,
                child: const Text('Registrar Usuario'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
