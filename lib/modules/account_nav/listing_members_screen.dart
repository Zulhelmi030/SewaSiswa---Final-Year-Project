import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:finalyearproject/models/listing_model.dart';
import 'package:finalyearproject/core/styles/app_theme_extensions.dart';

class ListingMembersScreen extends StatefulWidget {
  final ListingModel listing;
  const ListingMembersScreen({super.key, required this.listing});

  @override
  State<ListingMembersScreen> createState() => _ListingMembersScreenState();
}

class _ListingMembersScreenState extends State<ListingMembersScreen>
    with SingleTickerProviderStateMixin {
  final _client = Supabase.instance.client;
  late TabController _tabController;
  bool _isLoading = true;

  List<Map<String, dynamic>> _activeMembers = [];
  List<Map<String, dynamic>> _pendingRequests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final rows = await _client
          .from('rental_tenants')
          .select('''
            id,
            status,
            user_id,
            joined_at,
            users (
              id,
              full_name,
              email
            )
          ''')
          .eq('listing_id', widget.listing.id);

      final active = <Map<String, dynamic>>[];
      final pending = <Map<String, dynamic>>[];

      for (var row in rows) {
        if (row['status'] == 'active') {
          active.add(row);
        } else if (row['status'] == 'pending') {
          pending.add(row);
        }
      }

      if (mounted) {
        setState(() {
          _activeMembers = active;
          _pendingRequests = pending;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching members: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load members: $e'),
            backgroundColor: context.appColors.error,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleRequest(String id, String action, String userId) async {
    try {
      if (action == 'accept') {
        await _client
            .from('rental_tenants')
            .update({'status': 'active'})
            .eq('id', id);

        // Notify user they were accepted
        await _client.from('notifications').insert({
          'user_id': userId,
          'title': 'Booking Request Accepted',
          'body': 'Your request to join ${widget.listing.title} was accepted!',
          'type': 'system',
          'related_id': widget.listing.id,
        });
      } else if (action == 'reject') {
        await _client.from('rental_tenants').delete().eq('id', id);

        // Notify user they were rejected
        await _client.from('notifications').insert({
          'user_id': userId,
          'title': 'Booking Request Rejected',
          'body': 'Your request to join ${widget.listing.title} was declined.',
          'type': 'system',
          'related_id': widget.listing.id,
        });
      }

      _fetchData(); // refresh lists
    } catch (e) {
      debugPrint('Error handling request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to $action request: $e'),
            backgroundColor: context.appColors.error,
          ),
        );
      }
    }
  }

  Future<void> _removeMember(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member'),
        content: const Text('Are you sure you want to remove this member?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: context.appColors.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _client.from('rental_tenants').delete().eq('id', id);
      _fetchData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove member: $e'),
            backgroundColor: context.appColors.error,
          ),
        );
      }
    }
  }

  Future<void> _inviteMember() async {
    String email = '';
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invite Member'),
        content: TextField(
          decoration: const InputDecoration(
            labelText: 'User Email Address',
            hintText: 'Enter exact email',
          ),
          keyboardType: TextInputType.emailAddress,
          onChanged: (val) => email = val.trim(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, email),
            child: const Text('Invite'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    try {
      // Find user by email
      final userRow = await _client
          .from('users')
          .select('id, full_name')
          .eq('email', result)
          .maybeSingle();

      if (userRow == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No user found with that email address.'),
              backgroundColor: context.appColors.error,
            ),
          );
        }
        return;
      }

      final targetUserId = userRow['id'];

      // Add to rental tenants
      await _client.from('rental_tenants').insert({
        'listing_id': widget.listing.id,
        'user_id': targetUserId,
        'status': 'active', // or 'invited' if you prefer an invite-accept flow
      });

      // Notify the user
      await _client.from('notifications').insert({
        'user_id': targetUserId,
        'title': 'You were added to a house!',
        'body': 'You have been added to ${widget.listing.title} as a member.',
        'type': 'system',
        'related_id': widget.listing.id,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Member added successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _fetchData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to invite member: $e'),
            backgroundColor: context.appColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        backgroundColor: context.appColors.background,
        elevation: 0,
        title: Text(
          'Manage Members',
          style: context.appTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: context.appColors.primary,
          unselectedLabelColor: context.appColors.onSurfaceVariant,
          indicatorColor: context.appColors.primary,
          tabs: const [
            Tab(text: 'Active Members'),
            Tab(text: 'Booking Requests'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildActiveMembersTab(), _buildRequestsTab()],
            ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _inviteMember,
              backgroundColor: context.appColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add),
              label: const Text('Invite Member'),
            )
          : null,
    );
  }

  Widget _buildActiveMembersTab() {
    if (_activeMembers.isEmpty) {
      return Center(
        child: Text(
          'No active members yet.',
          style: context.appTextStyles.bodyLarge.copyWith(
            color: context.appColors.outline,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _activeMembers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final row = _activeMembers[index];
        final user = row['users'] as Map<String, dynamic>?;
        final name = user?['full_name'] ?? 'Unknown User';
        final email = user?['email'] ?? '';
        final isOwner = row['user_id'] == widget.listing.ownerId;

        return ListTile(
          tileColor: context.appColors.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          leading: CircleAvatar(
            backgroundColor: context.appColors.primaryFixed,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(color: context.appColors.onPrimaryFixed),
            ),
          ),
          title: Text(
            name,
            style: context.appTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(email, style: context.appTextStyles.bodySmall),
          trailing: isOwner
              ? Chip(
                  label: const Text('Owner'),
                  backgroundColor: context.appColors.primary.withValues(
                    alpha: 0.1,
                  ),
                  labelStyle: TextStyle(
                    color: context.appColors.primary,
                    fontSize: 12,
                  ),
                )
              : IconButton(
                  icon: Icon(
                    Icons.remove_circle_outline,
                    color: context.appColors.error,
                  ),
                  onPressed: () => _removeMember(row['id']),
                  tooltip: 'Remove Member',
                ),
        );
      },
    );
  }

  Widget _buildRequestsTab() {
    if (_pendingRequests.isEmpty) {
      return Center(
        child: Text(
          'No pending requests.',
          style: context.appTextStyles.bodyLarge.copyWith(
            color: context.appColors.outline,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingRequests.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final row = _pendingRequests[index];
        final user = row['users'] as Map<String, dynamic>?;
        final name = user?['full_name'] ?? 'Unknown User';
        final email = user?['email'] ?? '';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.appColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.appColors.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: context.appColors.secondaryContainer,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: context.appColors.onSecondaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: context.appTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(email, style: context.appTextStyles.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          _handleRequest(row['id'], 'reject', row['user_id']),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.appColors.error,
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          _handleRequest(row['id'], 'accept', row['user_id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.appColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
