import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class ChatPage extends StatefulWidget {
  final String alertId;
  final String professorId;
  final String monitorId;

  const ChatPage({
    super.key,
    required this.alertId,
    required this.professorId,
    required this.monitorId,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Chat'),
      backgroundColor: Colors.blueAccent,
    ),
    body: Column(
      children: [
        // Mostrar mensajes del chat
        Expanded(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chats')
                .doc(widget.alertId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text('No hay mensajes en este chat.'));
              }

              var chatData = snapshot.data!.data() as Map<String, dynamic>;
              List<dynamic> messages = chatData['messages'] ?? [];

              // Obtener el ID del usuario actual autenticado
              String currentUserId = FirebaseAuth.instance.currentUser!.uid;

              return ListView.builder(
                controller: _scrollController,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  var message = messages[index];
                  bool isSentByCurrentUser = message['senderId'] == currentUserId;

                  return Align(
                    alignment: isSentByCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSentByCurrentUser ? Colors.blueAccent : Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: isSentByCurrentUser
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Text(
                            message['content'] ?? '',
                            style: TextStyle(
                              color: isSentByCurrentUser ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTimestamp(message['timestamp']),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        // Campo para escribir mensajes
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Escribe un mensaje...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.blueAccent),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

String _formatTimestamp(Timestamp? timestamp) {
  if (timestamp == null) return '';
  DateTime dateTime = timestamp.toDate();
  return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
}

  Future<void> _sendMessage() async {
  if (_messageController.text.trim().isEmpty) return;

  String messageContent = _messageController.text.trim();
  _messageController.clear();

  try {
    // Obtener el ID del usuario actual autenticado
    String senderId = FirebaseAuth.instance.currentUser!.uid;

    // Crear el mensaje
    final messageData = {
      'content': messageContent,
      'senderId': senderId,
      'timestamp': Timestamp.now(),
    };

    // Agregar el mensaje a Firestore
    DocumentReference chatDoc = FirebaseFirestore.instance.collection('chats').doc(widget.alertId);
    await chatDoc.update({
      'messages': FieldValue.arrayUnion([messageData]),
    });

    // Desplazar al último mensaje en la vista
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al enviar el mensaje: $e')),
    );
  }
}
}
