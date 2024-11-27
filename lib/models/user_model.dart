class User {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String username;
  final String? password; 
  final String role;
  final List<String> blocks;
  final List<String> floors;
  final List<String> rooms;
  final String? address;
  final String? gender;
  final int? age;

  User({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.username,
    this.password, 
    required this.role,
    this.blocks = const [],
    this.floors = const [],
    this.rooms = const [],
    this.address,
    this.gender,
    this.age,
  });

  // Método para convertir un objeto User a un mapa 
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
      'address': address,
      'gender': gender,
      'age': age,
    };
  }

  // Método estático para crear un objeto User a partir de un mapa
  static User fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      password: map['password'], // Puede ser null
      role: map['role'] ?? '',
      blocks: List<String>.from(map['blocks'] ?? []),
      floors: List<String>.from(map['floors'] ?? []),
      rooms: List<String>.from(map['rooms'] ?? []),
      address: map['address'],
      gender: map['gender'],
      age: map['age'],
    );
  }

  // Método para crear una copia modificada del objeto User
  User copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? username,
    String? password,
    String? role,
    List<String>? blocks,
    List<String>? floors,
    List<String>? rooms,
    String? address,
    String? gender,
    int? age,
  }) {
    // Retorna una nueva instancia de User con los valores modificados o los originales
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
      blocks: blocks ?? this.blocks,
      floors: floors ?? this.floors,
      rooms: rooms ?? this.rooms,
      address: address ?? this.address,
      gender: gender ?? this.gender,
      age: age ?? this.age,
    );
  }
}

