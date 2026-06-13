import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/notification_provider.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  void _showNotificationPanel(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset(0, button.size.height), ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      constraints: const BoxConstraints(maxWidth: 350, maxHeight: 500),
      items: [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryBlue)),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.read<NotificationProvider>().markAllAsRead();
                    },
                    child: const Text('Mark all as read', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const Divider(),
            ],
          ),
        ),
        ...context.read<NotificationProvider>().notifications.isEmpty
            ? [
                const PopupMenuItem(
                  enabled: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text('No notifications', style: TextStyle(color: AppTheme.textMuted)),
                    ),
                  ),
                )
              ]
            : context.read<NotificationProvider>().notifications.map((n) => PopupMenuItem(
                  onTap: () {
                    context.read<NotificationProvider>().markAsRead(n.id);
                    if (n.type == 'order' && n.referenceId != null) {
                      context.go('/admin?orderId=${n.referenceId}');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 6, right: 12),
                          decoration: BoxDecoration(
                            color: n.isRead ? Colors.transparent : AppTheme.accentOrange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(n.message, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM d, h:mm a').format(n.createdAt),
                                style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_outlined),
              onPressed: () => _showNotificationPanel(context),
              tooltip: 'Notifications',
            ),
            if (provider.unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    provider.unreadCount > 9 ? '9+' : provider.unreadCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
