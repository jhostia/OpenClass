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
      username: '',
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario registrado exitosamente')),
      );

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
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Datos del Usuario',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: emailController,
                    label: 'Correo Electrónico',
                    icon: Icons.email,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: passwordController,
                    label: 'Contraseña',
                    icon: Icons.lock,
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: nameController,
                    label: 'Nombre Completo',
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: idController,
                    label: 'Identificación',
                    icon: Icons.badge,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: phoneController,
                    label: 'Teléfono',
                    icon: Icons.phone,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
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
                    decoration: InputDecoration(
                      labelText: 'Rol',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  if (selectedRole == 'Monitor') ...[
                    const SizedBox(height: 20),
                    _buildSelectionSection('Seleccione Bloques', blocks, selectedBlocks),
                    const SizedBox(height: 20),
                    _buildSelectionSection('Seleccione Pisos', floors, selectedFloors),
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
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: registerUser,
                      icon: const Icon(Icons.save),
                      label: const Text('Registrar Usuario'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      obscureText: obscureText,
    );
  }

  Widget _buildSelectionSection(String title, List<String> options, List<String> selectedList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          children: options.map((option) {
            return FilterChip(
              label: Text(option.toUpperCase()),
              selected: selectedList.contains(option),
              onSelected: (isSelected) {
                setState(() {
                  isSelected ? selectedList.add(option) : selectedList.remove(option);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
