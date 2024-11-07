import 'package:flutter/material.dart';
import 'database/database.dart';
import 'models/user_model.dart';

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

  @override
  void initState() {
    super.initState();
    idController = TextEditingController(text: widget.user.id);
    nameController = TextEditingController(text: widget.user.name);
    phoneController = TextEditingController(text: widget.user.phone);
    emailController = TextEditingController(text: widget.user.email);
    selectedRooms = List.from(widget.user.rooms);

    if (widget.user.role == 'Monitor') {
      // Obtener bloques y pisos de los salones asignados
      selectedBlocks = selectedRooms.map((room) => room.substring(room.length - 1)).toSet().toList();
      selectedFloors = selectedRooms.map((room) => room.substring(0, 1)).toSet().toList();
    }
  }

  @override
  void dispose() {
    idController.dispose();
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  void toggleRoomSelection(String room) {
    setState(() {
      if (selectedRooms.contains(room)) {
        selectedRooms.remove(room);
      } else {
        selectedRooms.add(room);
      }
    });
  }

  Widget buildRoomSelection() {
  return Wrap(
    children: selectedBlocks.expand<Widget>((block) {
      return selectedFloors.expand<Widget>((floor) {
        return (roomsByFloor[floor]?.map<Widget>((room) {
          final formattedRoom = '$room${block.toLowerCase()}';
          return FilterChip(
            label: Text(formattedRoom),
            selected: selectedRooms.contains(formattedRoom),
            onSelected: (isSelected) {
              toggleRoomSelection(formattedRoom);
            },
          );
        }).toList() ?? []);
      }).toList();
    }).toList(),
  );
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
              TextField(controller: idController, decoration: const InputDecoration(labelText: 'ID')),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nombre')),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Teléfono')),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Correo')),
              if (widget.user.role == 'Monitor') ...[
                const SizedBox(height: 20),
                const Text('Seleccionar Bloques'),
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
                const Text('Seleccionar Pisos'),
                Wrap(
                  children: floors.map((floor) {
                    return FilterChip(
                      label: Text('Piso $floor'),
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
                const Text('Seleccionar Salones'),
                buildRoomSelection(),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  User updatedUser = User(
                    id: idController.text,
                    name: nameController.text,
                    phone: phoneController.text,
                    email: emailController.text,
                    username: widget.user.username,
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
                },
                child: const Text('Actualizar Usuario'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
