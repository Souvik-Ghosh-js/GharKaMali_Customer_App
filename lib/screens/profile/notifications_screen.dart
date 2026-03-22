import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List _notifs = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try {
      final res = await context.read<ApiService>().getNotifications();
      setState(() => _notifs = res['data'] ?? []);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notifications')),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
        : _notifs.isEmpty
            ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('🔔', style: TextStyle(fontSize: 48)),
                SizedBox(height: 12),
                Text('No notifications yet', style: TextStyle(color: AppTheme.textSecondary)),
              ]))
            : RefreshIndicator(
                color: AppTheme.primary,
                onRefresh: _load,
                child: ListView.builder(
                  itemCount: _notifs.length,
                  itemBuilder: (_, i) {
                    final n = _notifs[i];
                    final isRead = n['is_read'] == true;
                    return ListTile(
                      leading: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: isRead ? AppTheme.border : AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.notifications, color: isRead ? AppTheme.textSecondary : AppTheme.primary),
                      ),
                      title: Text(n['title'] ?? '', style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold, fontSize: 14)),
                      subtitle: Text(n['body'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      trailing: isRead ? null : Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle)),
                      onTap: () async {
                        if (!isRead) {
                          await context.read<ApiService>().markNotificationRead(n['id']);
                          _load();
                        }
                      },
                    );
                  },
                ),
              ),
  );
}
