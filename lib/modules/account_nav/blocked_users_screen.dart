import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:finalyearproject/core/styles/app_theme_extensions.dart';
import 'package:finalyearproject/shared/widgets/user_avatar.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final _client = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _blockedUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchBlockedUsers();
  }

  Future<void> _fetchBlockedUsers() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;
      final response = await _client
          .from('blocked_users')
          .select(
            '*, users!blocked_users_blocked_id_fkey(id, full_name, avatar_url)',
          )
          .eq('blocker_id', userId);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _blockedUsers = response;
        });
      }
    } catch (e) {
      debugPrint('Error fetching blocked users: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _unblockUser(String blockId) async {
    try {
      await _client.from('blocked_users').delete().eq('id', blockId);

      if (mounted) {
        setState(() {
          _blockedUsers.removeWhere((item) => item['id'] == blockId);
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User unblocked')));
      }
    } catch (e) {
      debugPrint('Error unblocking user: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to unblock user: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        title: Text(
          'Blocked Users',
          style: context.appTextStyles.headlineMedium,
        ),
        // ...
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_blockedUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.block_rounded,
              size: 64,
              color: context.appColors.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text('No Blocked Users', style: context.appTextStyles.titleLarge),
            const SizedBox(height: 8),
            Text(
              'You haven\'t blocked anyone yet.',
              style: TextStyle(color: context.appColors.textSecondary),
            ),
          ],
        ),
      );
    }
    // Hint:
    // 1. Get the item: final item = _blockedUsers[index];
    // 2. Get the user data: final blockedUser = item['users'];
    // 3. Use a ListTile with your shared UserAvatar widget!
    // 4. For the trailing widget, use an TextButton or IconButton that calls _unblockUser(item['id'])
    return ListView.builder(
      itemCount: _blockedUsers.length,
      itemBuilder: (context, index) {
        final item = _blockedUsers[index];
        final blockedUser = item['users'];
        return ListTile(
          leading: UserAvatar(
            imageUrl: blockedUser['avatar_url'] as String?,
            radius: 20,
          ),
          title: Text(blockedUser['full_name']),
          trailing: TextButton(
            onPressed: () => _unblockUser(item['id']),
            child: Text('Unblock'),
          ),
        );
      },
    );
  }
}
