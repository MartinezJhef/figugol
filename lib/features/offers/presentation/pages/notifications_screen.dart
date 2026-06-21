import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/models/trade_notification.dart';
import '../../data/repositories/trade_offers_repository.dart';
import 'negotiation_chat_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Inicia sesión')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: StreamBuilder<List<TradeNotification>>(
        stream: TradeOffersRepository().watchNotifications(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) {
            return const Center(
              child: Text(
                'No tienes notificaciones',
                style: TextStyle(color: AppTheme.lightText),
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final isUnread = notif.status == TradeNotificationStatus.unread;

              return ListTile(
                tileColor: isUnread ? AppTheme.cardDark : AppTheme.bgDark,
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryBrand.withValues(alpha: 0.2),
                  child: const Icon(Icons.handshake_rounded, color: AppTheme.primaryBrand),
                ),
                title: Text(
                  '${notif.fromUserName} te propuso un intercambio',
                  style: TextStyle(
                    fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                    color: AppTheme.lightText,
                  ),
                ),
                subtitle: const Text('Toca para ver el chat de negociación'),
                onTap: () {
                  if (isUnread) {
                    TradeOffersRepository().markNotificationAsRead(notif.id);
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => NegotiationChatScreen(
                        notification: notif,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
