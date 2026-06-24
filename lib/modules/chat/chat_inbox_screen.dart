import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../routes/app_routes.dart';
import 'package:finalyearproject/core/styles/app_theme_extensions.dart';

class ChatInboxScreen extends StatefulWidget {
  const ChatInboxScreen({super.key});

  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen> {
  final _client = Supabase.instance.client;
  bool _isLoading = true;

  /// A list of conversation objects containing:
  /// - 'other_user_id'
  /// - 'other_user_name'
  /// - 'latest_message' (content)
  /// - 'sent_at'
  /// - 'unread_count'
  /// - 'listing_id'
  /// - 'listing_title'
  List<Map<String, dynamic>> _conversations = [];

  String? _currentUserId;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _currentUserId = _client.auth.currentUser?.id;
    _fetchInboxData().then((_) => _subscribeToInboxChanges());
  }

  @override
  void dispose() {
    if (_channel != null) {
      _client.removeChannel(_channel!);
    }
    super.dispose();
  }

  Future<void> _fetchInboxData() async {
    if (_currentUserId == null) return;

    try {
      // 1. Fetch all messages where current user is sender OR receiver
      final messagesResponse = await _client
          .from('messages')
          .select('*, listings(title)')
          .or('sender_id.eq.$_currentUserId,receiver_id.eq.$_currentUserId')
          .order('sent_at', ascending: false);

      final List<dynamic> messages = messagesResponse as List<dynamic>;

      // 2. Group by the OTHER user
      final Map<String, Map<String, dynamic>> grouped = {};

      for (var msg in messages) {
        final senderId = msg['sender_id'] as String;
        final receiverId = msg['receiver_id'] as String;

        // Determine who the other person is
        final otherUserId = senderId == _currentUserId ? receiverId : senderId;

        // Calculate unread (only counts if WE are the receiver and it's not read)
        final isUnread =
            (receiverId == _currentUserId) && (msg['is_read'] == false);

        if (!grouped.containsKey(otherUserId)) {
          // First time seeing this user (which is their latest message due to sorting)
          grouped[otherUserId] = {
            'other_user_id': otherUserId,
            'other_user_name': 'Loading...', // Will fetch next
            'latest_message': msg['content'],
            'sent_at': msg['sent_at'],
            'listing_id': msg['listing_id'],
            'listing_title': msg['listings']?['title'],
            'unread_count': isUnread ? 1 : 0,
          };
        } else {
          // Already have the latest message, just accumulate unread count
          if (isUnread) {
            grouped[otherUserId]!['unread_count'] =
                (grouped[otherUserId]!['unread_count'] as int) + 1;
          }
        }
      }

      // 3. Fetch names for the other users
      final userIds = grouped.keys.toList();
      if (userIds.isNotEmpty) {
        final usersResponse = await _client
            .from('users')
            .select('id, full_name')
            .inFilter('id', userIds);

        for (var user in (usersResponse as List<dynamic>)) {
          final id = user['id'] as String;
          final name = user['full_name'] as String? ?? id.substring(0, 8);
          if (grouped.containsKey(id)) {
            grouped[id]!['other_user_name'] = name;
          }
        }
      }

      // 4. Convert to list and sort by date descending
      final convos = grouped.values.toList();
      convos.sort((a, b) {
        final da = DateTime.parse(a['sent_at'] as String);
        final db = DateTime.parse(b['sent_at'] as String);
        return db.compareTo(da);
      });

      if (mounted) {
        setState(() {
          _conversations = convos;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching inbox: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeToInboxChanges() {
    if (_currentUserId == null) return;
    // Just listen to all inserts on messages. If it involves us, refresh inbox.
    // In a production app, we'd manually update the specific list item to save a network call.
    _channel = _client
        .channel('public:messages_inbox')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final newMsg = payload.newRecord;
            final sender = newMsg['sender_id'] as String?;
            final receiver = newMsg['receiver_id'] as String?;
            if (sender == _currentUserId || receiver == _currentUserId) {
              _fetchInboxData(); // Refresh the list
            }
          },
        )
        .subscribe();
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      if (dt.day == now.day - 1) return 'Yesterday';
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        backgroundColor: context.appColors.surfaceContainerLowest,
        title: Text(
          "Messages",
          style: context.appTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: context.appColors.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              "No messages yet",
              style: context.appTextStyles.titleMedium.copyWith(
                color: context.appColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "When you contact owners, your chats\nwill appear here.",
              textAlign: TextAlign.center,
              style: context.appTextStyles.bodyMedium.copyWith(
                color: context.appColors.outline,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchInboxData,
      color: context.appColors.primary,
      child: ListView.separated(
        itemCount: _conversations.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: context.appColors.surfaceContainerHigh,
          indent: 72,
        ),
        itemBuilder: (context, index) {
          final convo = _conversations[index];
          final hasUnread = (convo['unread_count'] as int) > 0;

          return InkWell(
            onTap: () async {
              await context.push(
                '/chat',
                extra: ChatArgs(
                  receiverId: convo['other_user_id'],
                  receiverName: convo['other_user_name'],
                  listingId: convo['listing_id'],
                  listingTitle: convo['listing_title'],
                ),
              );
              // Refresh when returning in case messages were read
              _fetchInboxData();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: context.appColors.primaryFixed,
                    child: Text(
                      (convo['other_user_name'] as String)
                          .substring(0, 1)
                          .toUpperCase(),
                      style: context.appTextStyles.titleMedium.copyWith(
                        color: context.appColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Chat info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                convo['other_user_name'],
                                style: context.appTextStyles.titleMedium
                                    .copyWith(
                                      fontWeight: hasUnread
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              _formatTime(convo['sent_at']),
                              style: context.appTextStyles.labelMedium.copyWith(
                                color: hasUnread
                                    ? context.appColors.primary
                                    : context.appColors.outline,
                                fontWeight: hasUnread
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                convo['latest_message'],
                                style: context.appTextStyles.bodyMedium
                                    .copyWith(
                                      color: hasUnread
                                          ? context.appColors.textPrimary
                                          : context.appColors.textSecondary,
                                      fontWeight: hasUnread
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasUnread) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: context.appColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  convo['unread_count'].toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
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
