import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _error = 'Not logged in';
      });
      return;
    }

    try {
      // Fetch notifications for the current user, newest first
      final data = await _client
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load notifications';
        });
      }
    }
  }

  Future<void> _markAsRead(String id, int index) async {
    if (_notifications[index]['is_read'] == true) return;

    try {
      // Optimistic update
      setState(() {
        _notifications[index]['is_read'] = true;
      });

      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
    } catch (e) {
      debugPrint('Error marking as read: $e');
      // Revert if failed
      if (mounted) {
        setState(() {
          _notifications[index]['is_read'] = false;
        });
      }
    }
  }

  Future<void> _markAllAsRead() async {
    final unreadList = _notifications
        .where((n) => n['is_read'] == false)
        .toList();
    if (unreadList.isEmpty) return;

    try {
      setState(() {
        for (var n in _notifications) {
          n['is_read'] = true;
        }
      });

      final user = _client.auth.currentUser;
      if (user != null) {
        await _client
            .from('notifications')
            .update({'is_read': true})
            .eq('user_id', user.id)
            .eq('is_read', false);
      }
    } catch (e) {
      debugPrint('Error marking all as read: $e');
      _loadNotifications(); // Reload from server to fix state
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'payment':
        return Icons.payment_rounded;
      case 'booking':
        return Icons.calendar_month_rounded;
      case 'match':
        return Icons.handshake_rounded;
      case 'system':
      default:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    // We use the theme's colors to adapt to the dark mode you just added!
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: bgColor,
        elevation: 0,
        actions: [
          if (_notifications.any((n) => n['is_read'] == false))
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Mark all read',
                style: AppTextStyles.labelMedium.copyWith(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(textColor, primaryColor),
    );
  }

  Widget _buildBody(Color textColor, Color primaryColor) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.error),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: textColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: AppTextStyles.headlineMedium.copyWith(color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              'When you get updates, they\'ll appear here.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: textColor.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: primaryColor,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _notifications.length,
        separatorBuilder: (context, index) =>
            Divider(color: textColor.withValues(alpha: 0.1), height: 1),
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          final bool isRead = notification['is_read'] == true;
          final DateTime createdAt = DateTime.parse(
            notification['created_at'],
          ).toLocal();

          return InkWell(
            onTap: () => _markAsRead(notification['id'], index),
            child: Container(
              color: isRead
                  ? Colors.transparent
                  : primaryColor.withValues(alpha: 0.05),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isRead
                          ? textColor.withValues(alpha: 0.05)
                          : primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIconForType(notification['type'] ?? 'system'),
                      color: isRead
                          ? textColor.withValues(alpha: 0.5)
                          : primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                notification['title'] ?? 'Notification',
                                style: AppTextStyles.labelMedium.copyWith(
                                  fontWeight: isRead
                                      ? FontWeight.w500
                                      : FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ),
                            Text(
                              timeago.format(createdAt),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isRead
                                    ? textColor.withValues(alpha: 0.5)
                                    : primaryColor,
                                fontWeight: isRead
                                    ? FontWeight.normal
                                    : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification['message'] ?? '',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isRead
                                ? textColor.withValues(alpha: 0.7)
                                : textColor.withValues(alpha: 0.9),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Unread Dot
                  if (!isRead)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 8),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
