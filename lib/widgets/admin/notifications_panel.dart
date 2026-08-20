import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/mock_data_service.dart';

/// Slides in a right-side notification center for the operator.
Future<void> showNotificationsPanel(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Notifiche',
    barrierColor: Colors.black45,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, _, __) => const SizedBox.shrink(),
    transitionBuilder: (context, anim, _, __) {
      return Align(
        alignment: Alignment.centerRight,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: const _NotificationsPanel(),
        ),
      );
    },
  );
}

class _NotificationsPanel extends StatelessWidget {
  const _NotificationsPanel();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SizedBox(
        width: 400,
        height: double.infinity,
        child: SafeArea(
          child: Consumer<MockDataService>(
            builder: (context, data, _) {
              final notifs = data.notifications;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text('Notifiche',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        if (notifs.isNotEmpty)
                          TextButton(
                            onPressed: data.markAllNotificationsRead,
                            child: const Text('Segna lette'),
                          ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: notifs.isEmpty
                        ? const Center(
                            child: Text('Nessuna notifica',
                                style: TextStyle(color: Colors.grey)))
                        : ListView.separated(
                            itemCount: notifs.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final n = notifs[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: n.color.withOpacity(0.15),
                                  child: Icon(n.icon, color: n.color, size: 20),
                                ),
                                title: Text(n.title,
                                    style: TextStyle(
                                        fontWeight: n.read
                                            ? FontWeight.normal
                                            : FontWeight.bold)),
                                subtitle: Text(n.body),
                                trailing: Text(
                                  DateFormat('HH:mm').format(n.createdAt),
                                  style: TextStyle(
                                      color: Colors.grey.shade500, fontSize: 12),
                                ),
                                tileColor:
                                    n.read ? null : Colors.blue.withOpacity(0.04),
                                onTap: () => data.markNotificationRead(n.id),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
