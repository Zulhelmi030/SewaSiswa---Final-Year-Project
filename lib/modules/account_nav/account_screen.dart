import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/user_avatar.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String _email = '';
  String _displayName = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && user.email != null) {
      final email = user.email!;
      setState(() {
        _email = email;
        _displayName = email.split('@').first;
      });
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
      backgroundColor: AppColors.background,
      body: SafeArea(
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
                    const UserAvatar(radius: 60),
                    const SizedBox(height: 24),
                    Text(_displayName, style: AppTextStyles.headlineLarge),
                    const SizedBox(height: 4),
                    Text(
                      _email,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.outline,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Menu Sections
              Text(
                "PREFERENCES",
                style: AppTextStyles.labelMedium.copyWith(
                  letterSpacing: 2,
                  color: AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 16),
              _buildMenuItem(
                Icons.person_outline_rounded,
                "Personal Information",
              ),
              _buildMenuItem(Icons.notifications_none_rounded, "Notifications"),
              _buildMenuItem(Icons.security_rounded, "Security & Privacy"),

              const SizedBox(height: 32),
              Text(
                "HOSTING",
                style: AppTextStyles.labelMedium.copyWith(
                  letterSpacing: 2,
                  color: AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 16),
              _buildMenuItem(Icons.home_work_outlined, "Manage Listings"),
              _buildMenuItem(Icons.analytics_outlined, "Earnings Report"),

              const SizedBox(height: 48),
              CustomButton(text: "Edit Profile", onPressed: () {}),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _handleLogout,
                  child: Text(
                    "Logout",
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
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
          Icon(icon, size: 22, color: AppColors.primary),
          const SizedBox(width: 16),
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: AppColors.outlineVariant,
          ),
        ],
      ),
    );
  }
}
