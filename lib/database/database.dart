import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class Database {
  final CollectionReference userCollection = FirebaseFirestore.instance.collection('users');

  Future<void> saveUserData(User user) async {
    try {
      // Usa la identificación del usuario como documentId
      await userCollection.doc(user.id).set(user.toMap());
      print("Usuario guardado exitosamente en Firestore.");
    } catch (e) {
      print("Error al guardar el usuario: $e");
      throw e; 
    }
  }

  Future<void> updateUser(User user) async {
    try {
      await userCollection.doc(user.id).update(user.toMap());
      print("Usuario actualizado exitosamente en Firestore.");
    } catch (e) {
      print("Error al actualizar el usuario: $e");
      throw e; 
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      await userCollection.doc(id).delete();
      print("Usuario eliminado exitosamente.");
    } catch (e) {
      print("Error al eliminar el usuario: $e");
      throw e; 
    }
  }

  Future<List<User>> getAllUsers() async {
    try {
      QuerySnapshot snapshot = await userCollection.get();
      return snapshot.docs.map((doc) {
        return User.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print("Error al obtener usuarios: $e");
      throw e; 
    }
  }

  Future<User?> getUserByEmail(String email) async {
  try {
    QuerySnapshot snapshot = await userCollection.where('email', isEqualTo: email).get();
    if (snapshot.docs.isNotEmpty) {
      return User.fromMap(snapshot.docs.first.data() as Map<String, dynamic>);
    }
    return null; // Si no se encuentra un usuario con ese correo
  } catch (e) {
    print("Error al obtener usuario por correo: $e");
    return null;
  }
}
}

