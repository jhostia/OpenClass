class User {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String username;
  final String password;
  final String role;
  final List<String> blocks;
  final List<String> floors;
  final List<String> rooms;

  User({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.username,
    required this.password,
    required this.role,
    this.blocks = const [],
    this.floors = const [],
    this.rooms = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'username': username,
      'password': password,
      'role': role,
      'blocks': blocks,
      'floors': floors,
      'rooms': rooms,
    };
  }

  static User fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '', // Asignar valor por defecto si es null
      name: map['name'] ?? '', // Asignar valor por defecto si es null
      phone: map['phone'] ?? '', // Asignar valor por defecto si es null
      email: map['email'] ?? '', // Asignar valor por defecto si es null
      username: map['username'] ?? '', // Asignar valor por defecto si es null
      password: map['password'] ?? '', // Asignar valor por defecto si es null
      role: map['role'] ?? '', // Asignar valor por defecto si es null
      blocks: List<String>.from(map['blocks'] ?? []),
      floors: List<String>.from(map['floors'] ?? []),
      rooms: List<String>.from(map['rooms'] ?? []),
    );
  }
}

