import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/widgets/user_avatar.dart';
import '../../core/styles/app_theme_extensions.dart';
import 'package:go_router/go_router.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String _email = '';
  String _displayName = '';
  String? _avatarUrl;
  String? _globalRole;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user != null && user.email != null) {
      final email = user.email!;
      try {
        // Fetch the avatar URL from our public.users table
        final userData = await client
            .from('users')
            .select('avatar_url, global_role')
            .eq('id', user.id)
            .single();
        if (mounted) {
          setState(() {
            _email = email;
            if (user.userMetadata?['full_name'] != null) {
              _displayName = user.userMetadata!['full_name'] as String;
            } else {
              _displayName = email.split('@').first;
            }
            _avatarUrl = userData['avatar_url'] as String?;
            _globalRole = userData['global_role'] as String?;
          });
        }
      } catch (e) {
        debugPrint('AccountScreen _loadUser Error: $e');
        // Fallback if the database fetch fails
        if (mounted) {
          setState(() {
            _email = email;
            if (user.userMetadata?['full_name'] != null) {
              _displayName = user.userMetadata!['full_name'] as String;
            } else {
              _displayName = email.split('@').first;
            }
          });
        }
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      await Supabase.instance.client.auth.signOut();

      if (!mounted) return;

      // OPTIONAL: Clear navigation stack and go to login
      // context.go('/login');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Logged out successfully'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.appColors.background, // keeps it blending in
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout_rounded, color: context.appColors.error),
            onPressed: _handleLogout,
          ),
        ],
      ),
      backgroundColor: context.appColors.background,
      body: RefreshIndicator(
        onRefresh: _loadUser,
        color: context.appColors.primary,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                // Profile Header
                Center(
                  child: Column(
                    children: [
                      UserAvatar(imageUrl: _avatarUrl, radius: 60),
                      const SizedBox(height: 24),
                      Text(_displayName, style: context.appTextStyles.headlineLarge),
                      const SizedBox(height: 4),
                      Text(
                        _email,
                        style: context.appTextStyles.labelMedium.copyWith(
                          color: context.appColors.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Menu Sections
                Text(
                  "PREFERENCES",
                  style: context.appTextStyles.labelMedium.copyWith(
                    letterSpacing: 2,
                    color: context.appColors.primary.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 16),
                _buildMenuItem(
                  Icons.person_outline_rounded,
                  "Personal Information",
                  onTap: () async {
                    await context.push('/personal-info');
                    _loadUser(); // Refresh data when we come back!
                  },
                ),

                _buildMenuItem(
                  Icons.chat_bubble_outline_rounded,
                  "Messages",
                  onTap: () => context.push('/chat/inbox'),
                ),
                _buildMenuItem(
                  Icons.notifications_none_rounded,
                  "Notifications",
                  onTap: () => context.push('/notifications'),
                ),
                _buildMenuItem(
                  Icons.security_rounded,
                  "Security & Privacy",
                  onTap: () => context.push('/security'),
                ),

                if (_globalRole == 'owner' || _globalRole == 'landlord') ...[
                  const SizedBox(height: 32),
                  Text(
                    "HOSTING",
                    style: context.appTextStyles.labelMedium.copyWith(
                      letterSpacing: 2,
                      color: context.appColors.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMenuItem(
                    Icons.home_work_outlined,
                    "Manage Listings",
                    onTap: () => context.push('/manage-listings'),
                  ),
                  _buildMenuItem(
                    Icons.analytics_outlined,
                    "Earnings Report",
                    onTap: () => context.push('/earnings-report'),
                  ),
                ],

                const SizedBox(height: 100),
              ],
            ),
          ),
        ), // SafeArea
      ), // RefreshIndicator
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          20,
        ), // keeps the ripple inside the rounded corners
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.appColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: context.appColors.primary),
              const SizedBox(width: 16),
              Text(
                title,
                style: context.appTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: context.appColors.outlineVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
