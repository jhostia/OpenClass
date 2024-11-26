import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class ProfilePage extends StatefulWidget {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String gender;

  const ProfilePage({
    Key? key,
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.gender,
  }) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController idController;
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController addressController;
  String selectedGender = 'No especificado';

  @override
  void initState() {
    super.initState();
    idController = TextEditingController(text: widget.id);
    nameController = TextEditingController(text: widget.name);
    phoneController = TextEditingController(text: widget.phone);
    addressController = TextEditingController(text: widget.address);
    selectedGender = widget.gender;
  }

  Future<void> _saveProfileChanges() async {
    try {
      final updatedData = {
        'name': nameController.text,
        'phone': phoneController.text,
        'address': addressController.text,
        'gender': selectedGender,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.id)
          .update(updatedData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cambios guardados exitosamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar cambios: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTextField(
              controller: idController,
              label: 'Identificación',
              icon: Icons.badge,
              readOnly: true,
            ),
            _buildTextField(
              controller: nameController,
              label: 'Nombre',
              icon: Icons.person,
            ),
            _buildTextField(
              controller: phoneController,
              label: 'Teléfono',
              icon: Icons.phone,
            ),
            _buildTextField(
              controller: addressController,
              label: 'Dirección de residencia',
              icon: Icons.home,
            ),
            DropdownButtonFormField<String>(
              value: selectedGender,
              items: ['Hombre', 'Mujer', 'Otro', 'No especificado']
                  .map((gender) => DropdownMenuItem(
                        value: gender,
                        child: Text(gender),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedGender = value ?? 'No especificado';
                });
              },
              decoration: const InputDecoration(
                labelText: 'Género',
                prefixIcon: Icon(Icons.transgender),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveProfileChanges,
              child: const Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      readOnly: readOnly,
    );
  }
}
