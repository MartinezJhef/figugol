import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/models/app_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/trade_notification.dart';

class NegotiationChatScreen extends StatefulWidget {
  const NegotiationChatScreen({
    super.key,
    required this.notification,
  });

  final TradeNotification notification;

  @override
  State<NegotiationChatScreen> createState() => _NegotiationChatScreenState();
}

class _NegotiationChatScreenState extends State<NegotiationChatScreen> {
  final _messageController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage(String currentUserId) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final ref = _firestore
        .collection('tradeProposals')
        .doc(widget.notification.proposalId)
        .collection('messages')
        .doc();

    final message = ChatMessage(
      id: ref.id,
      senderId: currentUserId,
      text: text,
      createdAt: DateTime.now(),
    );

    ref.set(message.toJson());
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthController>().user;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Inicia sesión')));
    }

    final otherUserId = widget.notification.fromUserId == currentUser.uid
        ? widget.notification.toUserId
        : widget.notification.fromUserId;

    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection('users').doc(otherUserId).snapshots(),
          builder: (context, snapshot) {
            String name = 'Cargando...';
            bool isOnline = false;

            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>?;
              if (data != null) {
                name = data['exchangeName'] ?? 'Usuario';
                isOnline = data['isOnline'] == true;
              }
            } else {
              name = widget.notification.fromUserName;
            }

            return Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  isOnline ? 'En línea' : 'Desconectado',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightText,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('tradeProposals')
                    .doc(widget.notification.proposalId)
                    .collection('messages')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No hay mensajes. ¡Escribe algo para acordar el intercambio!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.lightText),
                      ),
                    );
                  }

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      if (data['createdAt'] == null) {
                        data['createdAt'] = Timestamp.now();
                      }
                      final msg = ChatMessage.fromJson(data);
                      final isMe = msg.senderId == currentUser.uid;

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? AppTheme.primaryBrand : AppTheme.cardDark,
                            borderRadius: BorderRadius.circular(16).copyWith(
                              bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
                              bottomLeft: !isMe ? const Radius.circular(0) : const Radius.circular(16),
                            ),
                          ),
                          child: Text(
                            msg.text,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.cardDark,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: AppTheme.lightText),
                      decoration: InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        hintStyle: TextStyle(color: AppTheme.lightText.withValues(alpha: 0.5)),
                        filled: true,
                        fillColor: AppTheme.bgDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryBrand,
                    radius: 24,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      onPressed: () => _sendMessage(currentUser.uid),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      backgroundColor: AppTheme.bgDark,
    );
  }
}
