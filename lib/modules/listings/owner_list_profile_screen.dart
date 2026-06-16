import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:finalyearproject/core/styles/app_theme_extensions.dart';

class OwnerProfileScreen extends StatefulWidget {
  final String ownerId;
  const OwnerProfileScreen({super.key, required this.ownerId});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  final _client = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _listings = [];

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final row = await _client
          .from('users')
          .select('full_name, global_role, phone_number, created_at')
          .eq('id', widget.ownerId)
          .maybeSingle();

      final listingsRes = await _client
          .from('listings')
          .select('id, title, monthly_rent, city, state, image_urls')
          .eq('owner_id', widget.ownerId)
          .eq('status', 'available')
          .limit(3);

      if (mounted) {
        setState(() {
          _profile = row;
          _listings = List<Map<String, dynamic>>.from(listingsRes);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching owner profile: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getInitials() {
    final name = _profile?['full_name'] as String? ?? '';
    final parts = name.trim().split(' ');
    if (parts.isEmpty || name.isEmpty) return '?';
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  String _getMemberSince() {
    final raw = _profile?['created_at'] as String?;
    if (raw == null) return 'Unknown';
    final date = DateTime.tryParse(raw);
    if (date == null) return 'Unknown';
    return '${_monthName(date.month)} ${date.year}';
  }

  String _monthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.appColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_profile == null) {
      return Scaffold(
        backgroundColor: context.appColors.background,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off_outlined,
                size: 64,
                color: context.appColors.outlineVariant,
              ),
              const SizedBox(height: 16),
              Text('Profile not found', style: context.appTextStyles.titleMedium),
            ],
          ),
        ),
      );
    }

    final name = _profile!['full_name'] as String? ?? 'Unknown User';
    final role = _profile!['global_role'] as String?;
    final phone = _profile!['phone_number'] as String?;

    return Scaffold(
      backgroundColor: context.appColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero Header ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: context.appColors.primary,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: context.appColors.primaryGradient,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    // Avatar with initials
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: context.appColors.secondaryContainer,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(),
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Member since ${_getMemberSince()}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Verification badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (role != null)
                        _buildBadge(
                          Icons.verified_rounded,
                          role == 'landlord' ? 'Landlord' : 'Tenant',
                          context.appColors.primary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Info card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: context.appColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: context.appColors.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      children: [
                        if (phone != null)
                          _buildInfoRow(Icons.phone_rounded, 'Phone', phone)
                        else
                          Center(
                            child: Text(
                              'No additional information available.',
                              style: context.appTextStyles.bodySmall.copyWith(
                                color: context.appColors.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Active Listings section
                  if (_listings.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Text(
                      'Active Listings',
                      style: context.appTextStyles.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    ..._listings.map((l) => _buildListingTile(l)),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: context.appColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: context.appColors.primary),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: context.appTextStyles.labelSmall.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: context.appTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildListingTile(Map<String, dynamic> listing) {
    final imageUrls = listing['image_urls'] as List<dynamic>? ?? [];
    final title = listing['title'] as String? ?? 'Listing';
    final rent = (listing['monthly_rent'] as num?)?.toStringAsFixed(0) ?? '-';
    final city = listing['city'] as String? ?? '';
    final state = listing['state'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.appColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrls.isNotEmpty
                ? Image.network(
                    imageUrls.first as String,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 72,
                    height: 72,
                    color: context.appColors.surfaceVariant,
                    child: Icon(
                      Icons.home_rounded,
                      color: context.appColors.outlineVariant,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.appTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$city, $state',
                  style: context.appTextStyles.labelSmall.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'RM $rent / mo',
                  style: context.appTextStyles.labelMedium.copyWith(
                    color: context.appColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
