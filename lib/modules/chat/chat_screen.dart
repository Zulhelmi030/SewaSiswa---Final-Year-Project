import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:finalyearproject/core/styles/app_theme_extensions.dart';

/// A real-time chat screen backed by Supabase Realtime (WebSocket).
///
/// Parameters:
///   [receiverId]   — the Supabase user ID of the person being messaged
///   [receiverName] — display name shown in the AppBar
///   [listingId]    — optional listing context (shown as a banner)
///   [listingTitle] — optional listing title shown in the banner
class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String? listingId;
  final String? listingTitle;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    this.listingId,
    this.listingTitle,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // ── State ────────────────────────────────────────────────────────────────
  final _client = Supabase.instance.client;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _currentUserId;

  /// The active Supabase Realtime channel (WebSocket).
  RealtimeChannel? _channel;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _currentUserId = _client.auth.currentUser?.id;
    _loadHistory().then((_) => _subscribeToRealtime());
  }

  @override
  void dispose() {
    // ⚠️ Always unsubscribe to close the WebSocket connection cleanly.
    if (_channel != null) {
      _client.removeChannel(_channel!);
    }
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Data: Initial History Fetch ──────────────────────────────────────────

  Future<void> _loadHistory() async {
    if (_currentUserId == null) return;

    try {
      // Fetch all messages exchanged between the two users for this listing.
      final query = _client
          .from('messages')
          .select()
          .or(
            'and(sender_id.eq.$_currentUserId,receiver_id.eq.${widget.receiverId}),'
            'and(sender_id.eq.${widget.receiverId},receiver_id.eq.$_currentUserId)',
          )
          .order('sent_at', ascending: true);

      // If a listing context exists, filter by it.
      final response = widget.listingId != null
          ? await (query as dynamic).eq('listing_id', widget.listingId)
          : await query;

      if (mounted) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(response as List);
          _isLoading = false;
        });
        _scrollToBottom();
        _markMessagesAsRead();
      }
    } catch (e) {
      debugPrint('ChatScreen: history fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── WebSocket: Supabase Realtime Subscription ────────────────────────────

  /// Opens a WebSocket channel and listens for new INSERT events on the
  /// messages table. This is the core real-time / WebSocket functionality.
  /// handle incoming messages from other users.
  void _subscribeToRealtime() {
    if (_currentUserId == null) return;

    // Create a uniquely named channel for this conversation.
    final channelName =
        'chat:${_currentUserId}_${widget.receiverId}'
        '${widget.listingId != null ? '_${widget.listingId}' : ''}';

    _channel = _client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final newMsg = payload.newRecord;
            // Only handle messages that belong to this conversation.
            final sender = newMsg['sender_id'] as String?;
            final receiver = newMsg['receiver_id'] as String?;
            final isRelevant =
                (sender == _currentUserId && receiver == widget.receiverId) ||
                (sender == widget.receiverId && receiver == _currentUserId);

            if (!isRelevant || !mounted) return;

            setState(() => _messages.add(newMsg));
            _scrollToBottom();

            // Mark as read if received (not sent by us).
            if (sender != _currentUserId) {
              _markSingleAsRead(newMsg['id'] as String);
            }
          },
        )
        .subscribe((status, [error]) {
          debugPrint('ChatScreen WebSocket status: $status');
          if (error != null) debugPrint('ChatScreen WebSocket error: $error');
        });
  }

  // ── Data: Send Message ───────────────────────────────────────────────────

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending || _currentUserId == null) return;

    setState(() => _isSending = true);
    _messageController.clear();

    // Optimistic update — show message immediately before DB confirms.
    final optimisticMsg = {
      'id': 'optimistic_${DateTime.now().millisecondsSinceEpoch}',
      'sender_id': _currentUserId,
      'receiver_id': widget.receiverId,
      'listing_id': widget.listingId,
      'content': content,
      'is_read': false,
      'sent_at': DateTime.now().toIso8601String(),
      '_optimistic': true,
    };
    setState(() => _messages.add(optimisticMsg));
    _scrollToBottom();

    try {
      final payload = {
        'sender_id': _currentUserId,
        'receiver_id': widget.receiverId,
        'content': content,
        'is_read': false,
        if (widget.listingId != null) 'listing_id': widget.listingId,
      };

      await _client.from('messages').insert(payload);

      // Remove the optimistic message — the Realtime subscription will
      // receive the real row and add it automatically.
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m['_optimistic'] == true);
        });
      }
    } catch (e) {
      debugPrint('ChatScreen: send error: $e');
      // Rollback optimistic update on failure.
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m['_optimistic'] == true);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message. Please try again.'),
            backgroundColor: context.appColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _markMessagesAsRead() async {
    if (_currentUserId == null) return;
    try {
      await _client
          .from('messages')
          .update({'is_read': true})
          .eq('receiver_id', _currentUserId!)
          .eq('sender_id', widget.receiverId)
          .eq('is_read', false);
    } catch (_) {}
  }

  Future<void> _markSingleAsRead(String messageId) async {
    try {
      await _client
          .from('messages')
          .update({'is_read': true})
          .eq('id', messageId);
    } catch (_) {}
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (animated) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (widget.listingTitle != null) _buildListingBanner(),
          Expanded(child: _buildMessageList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: context.appColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: context.appColors.primaryFixed,
            child: Text(
              widget.receiverName.isNotEmpty
                  ? widget.receiverName[0].toUpperCase()
                  : '?',
              style: context.appTextStyles.labelMedium.copyWith(
                color: context.appColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.receiverName,
                style: context.appTextStyles.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // WebSocket connection indicator
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: context.appColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Connected',
                    style: context.appTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Listing Banner ────────────────────────────────────────────────────────

  Widget _buildListingBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: context.appColors.primaryFixed,
        border: Border(
          bottom: BorderSide(
            color: context.appColors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.home_outlined, size: 16, color: context.appColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Re: ${widget.listingTitle}',
              style: context.appTextStyles.labelMedium.copyWith(
                color: context.appColors.primary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Message List ──────────────────────────────────────────────────────────

  Widget _buildMessageList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 56,
              color: context.appColors.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: context.appTextStyles.titleMedium.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Say hello to ${widget.receiverName}!',
              style: context.appTextStyles.bodySmall,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isMine = msg['sender_id'] == _currentUserId;
        final isOptimistic = msg['_optimistic'] == true;

        // Show date separator if day changes
        final showDateSep =
            index == 0 ||
            _isDifferentDay(_messages[index - 1]['sent_at'], msg['sent_at']);

        return Column(
          children: [
            if (showDateSep) _buildDateSeparator(msg['sent_at'] as String?),
            _buildMessageBubble(msg, isMine, isOptimistic),
          ],
        );
      },
    );
  }

  bool _isDifferentDay(String? a, String? b) {
    if (a == null || b == null) return false;
    try {
      final da = DateTime.parse(a).toLocal();
      final db = DateTime.parse(b).toLocal();
      return da.day != db.day || da.month != db.month || da.year != db.year;
    } catch (_) {
      return false;
    }
  }

  Widget _buildDateSeparator(String? iso) {
    String label = '';
    if (iso != null) {
      try {
        final dt = DateTime.parse(iso).toLocal();
        final now = DateTime.now();
        if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
          label = 'Today';
        } else if (dt.day == now.day - 1) {
          label = 'Yesterday';
        } else {
          label = '${dt.day}/${dt.month}/${dt.year}';
        }
      } catch (_) {}
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: context.appColors.outlineVariant)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: context.appTextStyles.bodySmall.copyWith(
                color: context.appColors.outline,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(child: Divider(color: context.appColors.outlineVariant)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    Map<String, dynamic> msg,
    bool isMine,
    bool isOptimistic,
  ) {
    final content = msg['content'] as String? ?? '';
    final time = _formatTime(msg['sent_at'] as String?);
    final isRead = msg['is_read'] == true;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        child: Container(
          margin: EdgeInsets.only(
            bottom: 6,
            left: isMine ? 48 : 0,
            right: isMine ? 0 : 48,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isMine
                ? context.appColors.primary
                : context.appColors.surfaceContainerLowest,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isMine ? 20 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: isMine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              // Message text
              Text(
                content,
                style: context.appTextStyles.bodyMedium.copyWith(
                  color: isMine ? Colors.white : context.appColors.textPrimary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              // Time + read/sending status row
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: context.appTextStyles.bodySmall.copyWith(
                      fontSize: 10,
                      color: isMine
                          ? Colors.white.withValues(alpha: 0.65)
                          : context.appColors.outline,
                    ),
                  ),
                  if (isMine) ...[
                    const SizedBox(width: 4),
                    if (isOptimistic)
                      Icon(
                        Icons.schedule,
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.65),
                      )
                    else if (isRead)
                      Icon(
                        Icons.done_all,
                        size: 12,
                        color: context.appColors.success,
                      )
                    else
                      Icon(
                        Icons.done,
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Input Bar ─────────────────────────────────────────────────────────────

  Widget _buildInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surfaceContainerLowest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0
            ? 12
            : MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Row(
        children: [
          // Text field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: context.appColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: context.appColors.outlineVariant),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                style: context.appTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Message ${widget.receiverName}…',
                  hintStyle: context.appTextStyles.bodyMedium.copyWith(
                    color: context.appColors.outline,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: context.appColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: context.appColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: _isSending ? null : _sendMessage,
                child: Center(
                  child: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
