import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:finalyearproject/core/styles/app_theme_extensions.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  // Privacy toggles — wire up to DB/provider later
  bool _showPhoneNumber = true;
  bool _showProfileToAll = true;

  final _client = Supabase.instance.client;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _client
          .from('users')
          .select('show_phone_number, show_profile_to_all')
          .eq('id', userId)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _showPhoneNumber = response['show_phone_number'] ?? true;
          _showProfileToAll = response['show_profile_to_all'] ?? true;
        });
      }
    } catch (e) {
      debugPrint('Error loading privacy settings: $e');
    }
  }

  Future<void> _deleteAccount() async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Deleting account...')));
      }
      await _client.rpc('delete_my_account');
      await _client.auth.signOut();
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      debugPrint('Error deleting account: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete account: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: context.appColors.textPrimary,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Security & Privacy',
          style: context.appTextStyles.headlineMedium,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── SECURITY Section ──────────────────────────────────────
              _buildSectionHeader(
                context,
                Icons.lock_outline_rounded,
                'SECURITY',
              ),
              const SizedBox(height: 16),

              _buildActionTile(
                context,
                icon: Icons.key_rounded,
                iconColor: context.appColors.primary,
                title: 'Change Password',
                subtitle: 'Update your account password',
                onTap: () => context.push('/change-password'),
              ),

              _buildActionTile(
                context,
                icon: Icons.devices_rounded,
                iconColor: context.appColors.primary,
                title: 'Active Sessions',
                subtitle: 'View devices currently logged in',
                onTap: () => _showActiveSessionsSheet(context),
              ),

              _buildActionTile(
                context,
                icon: Icons.verified_user_outlined,
                iconColor: context.appColors.primary,
                title: 'Two-Factor Authentication',
                subtitle: 'Add an extra layer of security',
                trailing: _buildComingSoonBadge(context),
                onTap: null, // coming soon
              ),

              const SizedBox(height: 32),

              // ── PRIVACY Section ───────────────────────────────────────
              _buildSectionHeader(context, Icons.shield_outlined, 'PRIVACY'),
              const SizedBox(height: 16),

              _buildToggleTile(
                context,
                icon: Icons.phone_outlined,
                title: 'Show Phone Number',
                subtitle: 'Allow other users to see your phone number',
                value: _showPhoneNumber,
                onChanged: (val) async {
                  setState(() => _showPhoneNumber = val);
                  try {
                    final userId = _client.auth.currentUser?.id;
                    if (userId != null) {
                      await _client
                          .from('users')
                          .update({'show_phone_number': val})
                          .eq('id', userId);
                    }
                  } catch (e) {
                    debugPrint('Error saving show_phone_number: $e');
                  }
                },
              ),

              _buildToggleTile(
                context,
                icon: Icons.public_rounded,
                title: 'Public Profile',
                subtitle: 'Make your profile visible to all users',
                value: _showProfileToAll,
                onChanged: (val) async {
                  setState(() => _showProfileToAll = val);
                  try {
                    final userId = _client.auth.currentUser?.id;
                    if (userId != null) {
                      await _client
                          .from('users')
                          .update({'show_profile_to_all': val})
                          .eq('id', userId);
                    }
                  } catch (e) {
                    debugPrint('Error saving show_profile_to_all: $e');
                  }
                },
              ),

              _buildActionTile(
                context,
                icon: Icons.block_rounded,
                iconColor: context.appColors.primary,
                title: 'Blocked Users',
                subtitle: 'Manage users you have blocked',
                onTap: () => context.push('/blocked-users'),
              ),

              const SizedBox(height: 32),

              // ── ACCOUNT Section ───────────────────────────────────────
              _buildSectionHeader(
                context,
                Icons.manage_accounts_outlined,
                'ACCOUNT',
              ),
              const SizedBox(height: 16),

              /* _buildActionTile(
                context,
                icon: Icons.download_outlined,
                iconColor: context.appColors.primary,
                title: 'Download My Data',
                subtitle: 'Export a copy of your personal data',
                onTap: () {
                  // TODO: implement data export
                },
              ),*/
              _buildActionTile(
                context,
                icon: Icons.delete_outline_rounded,
                iconColor: context.appColors.error,
                title: 'Delete Account',
                subtitle: 'Permanently remove your account and data',
                titleColor: context.appColors.error,
                onTap: () => _showDeleteAccountDialog(context),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── Active Sessions ──────────────────────────────────────────────────────

  /// Shows a bottom sheet with the current session details and an option
  /// to sign out all other active sessions using [SignOutScope.others].
  void _showActiveSessionsSheet(BuildContext context) {
    final session = _client.auth.currentSession;
    final user = _client.auth.currentUser;

    if (session == null || user == null) return;

    final signedInAt = user.lastSignInAt != null
        ? DateTime.tryParse(user.lastSignInAt!)?.toLocal()
        : null;
    final formattedDate = signedInAt != null
        ? '${signedInAt.day}/${signedInAt.month}/${signedInAt.year}  ${signedInAt.hour.toString().padLeft(2, '0')}:${signedInAt.minute.toString().padLeft(2, '0')}'
        : 'Unknown';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: BoxDecoration(
            color: context.appColors.surfaceContainerLowest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.appColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Active Sessions',
                style: context.appTextStyles.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Devices currently signed in to your account.',
                style: context.appTextStyles.bodySmall.copyWith(
                  color: context.appColors.outline,
                ),
              ),
              const SizedBox(height: 24),

              // Current session card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.appColors.primaryContainer.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: context.appColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: context.appColors.primary.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.smartphone_rounded,
                        color: context.appColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'This device',
                                style: context.appTextStyles.bodyMedium
                                    .copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: context.appColors.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Current',
                                  style: context.appTextStyles.labelMedium
                                      .copyWith(
                                        color: context.appColors.onPrimary,
                                        fontSize: 10,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email ?? '',
                            style: context.appTextStyles.bodySmall.copyWith(
                              color: context.appColors.outline,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Signed in $formattedDate',
                            style: context.appTextStyles.bodySmall.copyWith(
                              color: context.appColors.outline,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Sign out other devices button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: context.appColors.error.withValues(
                      alpha: 0.1,
                    ),
                    foregroundColor: context.appColors.error,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _isSigningOut
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.appColors.error,
                          ),
                        )
                      : const Icon(Icons.logout_rounded, size: 18),
                  label: Text(
                    _isSigningOut
                        ? 'Signing out...'
                        : 'Sign out all other devices',
                    style: context.appTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.appColors.error,
                    ),
                  ),
                  onPressed: _isSigningOut
                      ? null
                      : () async {
                          setSheetState(() => _isSigningOut = true);
                          try {
                            await _client.auth.signOut(
                              scope: SignOutScope.others,
                            );
                            if (!ctx.mounted) return;
                            {
                              Navigator.of(ctx).pop();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Signed out of all other devices.',
                                  ),
                                  backgroundColor: context.appColors.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            debugPrint('Error signing out other sessions: $e');
                            if (mounted) {
                              setSheetState(() => _isSigningOut = false);
                            }
                          }
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widgets ─────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(
    BuildContext context,
    IconData icon,
    String label,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: context.appColors.primary.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: context.appTextStyles.labelMedium.copyWith(
            letterSpacing: 2,
            color: context.appColors.primary.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Color? titleColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
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
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.appTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: titleColor ?? context.appColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: context.appTextStyles.bodySmall.copyWith(
                        color: context.appColors.outline,
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: onTap != null
                        ? context.appColors.outlineVariant
                        : context.appColors.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: context.appColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: context.appColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.appTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: context.appTextStyles.bodySmall.copyWith(
                      color: context.appColors.outline,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: context.appColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComingSoonBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.appColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Soon',
        style: context.appTextStyles.labelMedium.copyWith(
          color: context.appColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  // ── Dialogs ──────────────────────────────────────────────────────────────

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: context.appColors.error,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Delete Account',
              style: context.appTextStyles.headlineSmall.copyWith(
                color: context.appColors.error,
              ),
            ),
          ],
        ),
        content: Text(
          'This will permanently delete your account, all your listings, and your data. This action cannot be undone.',
          style: context.appTextStyles.bodySmall.copyWith(
            color: context.appColors.outline,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.appColors.outline),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.appColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteAccount();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
