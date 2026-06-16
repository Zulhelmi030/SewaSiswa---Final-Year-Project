import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../routes/app_routes.dart';
import '../../models/listing_model.dart';
import '../../shared/widgets/skeletons.dart';
import 'dart:ui';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:finalyearproject/core/styles/app_theme_extensions.dart';
import '../../shared/widgets/user_avatar.dart';

class ListingDetailScreen extends StatefulWidget {
  final ListingModel? listing;

  const ListingDetailScreen({super.key, this.listing});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  final _client = Supabase.instance.client;
  bool _isLoadingOwner = true;
  bool _isFavourited = false;
  bool _isTogglingFav = false;
  bool _isApplying = false;
  String? _applicationStatus;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _ownerName = 'Loading...';
  String? _ownerAvatarUrl;
  int? _ownerMemberSinceYear;
  String? _ownerBio;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchOwner();
    _fetchWishlistStatus();
    _fetchApplicationStatus();
  }

  Future<void> _fetchOwner() async {
    final listing = widget.listing;
    if (listing == null) {
      setState(() => _isLoadingOwner = false);
      return;
    }
    try {
      final row = await Supabase.instance.client
          .from('users')
          .select('full_name, avatar_url, created_at, bio')
          .eq('id', listing.ownerId)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _ownerName =
              row?['full_name'] as String? ?? listing.ownerId.substring(0, 8);
          _ownerAvatarUrl = row?['avatar_url'] as String?;
          _ownerBio = row?['bio'] as String?;
          if (row?['created_at'] != null) {
            _ownerMemberSinceYear = DateTime.tryParse(row!['created_at'])?.year;
          }
          _isLoadingOwner = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingOwner = false);
    }
  }

  Future<void> _fetchWishlistStatus() async {
    final listingId = widget.listing?.id;
    final userId = _client.auth.currentUser?.id;
    if (listingId == null || userId == null) return;
    try {
      final row = await _client
          .from('wishlists')
          .select('id')
          .eq('user_id', userId)
          .eq('listing_id', listingId)
          .maybeSingle();
      if (mounted) setState(() => _isFavourited = row != null);
    } catch (e) {
      debugPrint('Error fetching wishlist status: $e');
    }
  }

  Future<void> _toggleFavourite() async {
    final listingId = widget.listing?.id;
    final userId = _client.auth.currentUser?.id;
    if (listingId == null || userId == null || _isTogglingFav) return;
    setState(() => _isTogglingFav = true);
    try {
      if (_isFavourited) {
        await _client
            .from('wishlists')
            .delete()
            .eq('user_id', userId)
            .eq('listing_id', listingId);
      } else {
        await _client.from('wishlists').insert({
          'user_id': userId,
          'listing_id': listingId,
        });
      }
      if (mounted) setState(() => _isFavourited = !_isFavourited);
    } catch (e) {
      debugPrint('Error toggling wishlist: $e');
    } finally {
      if (mounted) setState(() => _isTogglingFav = false);
    }
  }

  Future<void> _fetchApplicationStatus() async {
    final listingId = widget.listing?.id;
    final userId = _client.auth.currentUser?.id;
    if (listingId == null || userId == null) return;
    try {
      final row = await _client
          .from('rental_tenants')
          .select('status')
          .eq('user_id', userId)
          .eq('listing_id', listingId)
          .maybeSingle();
      if (mounted) {
        setState(() => _applicationStatus = row?['status'] as String?);
      }
    } catch (e) {
      debugPrint('Error fetching application status: $e');
    }
  }

  Future<void> _applyForListing() async {
    final listingId = widget.listing?.id;
    final userId = _client.auth.currentUser?.id;
    if (listingId == null || userId == null || _isApplying) return;

    setState(() => _isApplying = true);
    try {
      // 1. Insert into rental_tenants as 'pending'
      await _client.from('rental_tenants').insert({
        'listing_id': listingId,
        'user_id': userId,
        'tenant_role': 'house_member',
        'status': 'pending',
      });

      // 2. Fetch current user info for the notification body
      final userRow = await _client
          .from('users')
          .select('full_name')
          .eq('id', userId)
          .maybeSingle();
      final userName = userRow?['full_name'] as String? ?? 'A user';

      // 3. Notify the owner
      if (widget.listing?.ownerId != null) {
        await _client.from('notifications').insert({
          'user_id': widget.listing!.ownerId,
          'title': 'New Booking Request',
          'body': '$userName has requested to join ${widget.listing!.title}',
          'type': 'booking',
          'related_id': listingId,
        });
      }

      if (mounted) {
        setState(() => _applicationStatus = 'pending');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking request sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error applying for listing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to apply: $e'),
            backgroundColor: context.appColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dummy model for prototype preview if no listing is passed
    final currentListing =
        widget.listing ??
        ListingModel(
          id: '1',
          ownerId: 'owner_1',
          title: 'Emerald Residency Suites',
          description:
              'A premium studio unit designed specifically for UTeM students. Features include a dedicated study desk, ergonomic chair, and high-speed fibre internet. The residency is located within a 10-minute walk to the engineering faculty entrance.',
          address: 'Jalan Hang Tuah, Durian Tunggal, Melaka',
          latitude: 2.3082,
          longitude: 102.3211,
          monthlyRent: 450,
          deposit: 900,
          genderPreference: 'Any',
          facilities: ['Free WiFi', 'Parking', 'AC', 'Water Heater'],
          houseRule:
              'No smoking inside the unit.|No pets allowed in the residency.|Quiet hours after 11:00 PM.',
          rating: 4.9,
          reviewCount: 124,
          imageUrls: [
            'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800',
          ],
        );

    return Scaffold(
      backgroundColor: context.appColors.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              bottom: 140,
            ), // Space for bottom action bar
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCarousel(context, currentListing.imageUrls),

                // Main Content Card
                Container(
                  transform: Matrix4.translationValues(0, -32, 0),
                  decoration: BoxDecoration(
                    color: context.appColors.surfaceBright,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderInfo(currentListing),
                      const SizedBox(height: 24),
                      _buildFacilityChips(currentListing.facilities ?? []),
                      const SizedBox(height: 32),
                      _buildDescriptionAndRules(currentListing),
                      const SizedBox(height: 32),
                      _buildLandlordCard(
                        currentListing.ratingDisplay,
                        currentListing.reviewCount ?? 0,
                        currentListing.ownerId,
                      ),
                      const SizedBox(height: 40),
                      _buildLocationMap(currentListing),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Action Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomActionBar(currentListing),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCarousel(BuildContext context, List<String> imageUrls) {
    return SizedBox(
      height: 397,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          imageUrls.isNotEmpty
              ? PageView.builder(
                  controller: _pageController, // ← wires _pageController
                  itemCount: imageUrls.length,
                  onPageChanged: (index) => setState(
                    () => _currentPage = index,
                  ), // ← wires _currentPage
                  itemBuilder: (context, index) =>
                      Image.network(imageUrls[index], fit: BoxFit.cover),
                )
              : Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.image, size: 50, color: Colors.grey),
                ),

          // Top Bar Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildGlassButton(
                      icon: Icons.arrow_back,
                      onTap: () => context.pop(),
                    ),
                    Row(
                      children: [
                        _buildGlassButton(icon: Icons.share, onTap: () {}),
                        const SizedBox(width: 12),
                        _buildGlassButton(
                          icon: _isFavourited
                              ? Icons.favorite
                              : Icons.favorite_border,
                          iconColor: _isFavourited ? Colors.red : Colors.white,
                          onTap: _toggleFavourite,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Image Indicator
          Positioned(
            bottom: 56, // Account for the -32 overlap
            right: 24,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  color: Colors.black.withValues(alpha: 0.3),
                  child: Text(
                    "${_currentPage + 1} / ${imageUrls.length}",
                    style: context.appTextStyles.labelCaps.copyWith(
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.white.withValues(alpha: 0.2),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(icon, color: iconColor ?? Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(ListingModel listing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                listing.title,
                style: context.appTextStyles.headlineLarge.copyWith(
                  color: context.appColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "RM ${listing.monthlyRent.toStringAsFixed(0)}",
                  style: context.appTextStyles.headlineMedium.copyWith(
                    color: context.appColors.secondary,
                  ),
                ),
                Text(
                  "PER MONTH",
                  style: context.appTextStyles.labelCaps.copyWith(
                    color: context.appColors.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.location_on,
              size: 16,
              color: context.appColors.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                listing.fullAddress,
                style: context.appTextStyles.bodyMedium.copyWith(
                  color: context.appColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // UTeM Distance Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: context.appColors.primaryFixed,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.school,
                    size: 18,
                    color: context.appColors.onPrimaryFixed,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "0.8 km from UTeM Main Campus", // In a real app, calculate this
                    style: context.appTextStyles.labelMedium.copyWith(
                      color: context.appColors.onPrimaryFixed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Post Type Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: listing.postType == 'housemate'
                    ? Colors.orange.withValues(alpha: 0.15)
                    : Colors.teal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    listing.postType == 'housemate' ? Icons.group : Icons.home,
                    size: 18,
                    color: listing.postType == 'housemate'
                        ? Colors.orange.shade800
                        : Colors.teal.shade800,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    listing.postType == 'housemate'
                        ? 'Housemate Wanted'
                        : 'Full Property',
                    style: context.appTextStyles.labelMedium.copyWith(
                      color: listing.postType == 'housemate'
                          ? Colors.orange.shade800
                          : Colors.teal.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Available Slots Badge (only for housemate)
            if (listing.postType == 'housemate' &&
                listing.availableSlots != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: listing.availableSlots! > 0
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      listing.availableSlots! > 0
                          ? Icons.check_circle
                          : Icons.cancel,
                      size: 18,
                      color: listing.availableSlots! > 0
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      listing.availableSlots! > 0
                          ? '${listing.availableSlots} slots left (of ${listing.totalSlots})'
                          : 'Fully Occupied',
                      style: context.appTextStyles.labelMedium.copyWith(
                        color: listing.availableSlots! > 0
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFacilityChips(List<String> facilities) {
    if (facilities.isEmpty) return const SizedBox.shrink();

    // Map text to icons
    IconData getIconFor(String facility) {
      final f = facility.toLowerCase();
      if (f.contains('wifi')) return Icons.wifi;
      if (f.contains('parking')) return Icons.local_parking;
      if (f.contains('ac') || f.contains('aircond')) return Icons.ac_unit;
      if (f.contains('water heater')) return Icons.water_drop;
      return Icons.check_circle_outline;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: facilities
            .map(
              (f) => Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: context.appColors.surfaceContainer,
                  border: Border.all(
                    color: context.appColors.outlineVariant.withValues(
                      alpha: 0.15,
                    ),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      getIconFor(f),
                      color: context.appColors.onSurfaceVariant,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      f,
                      style: context.appTextStyles.labelMedium.copyWith(
                        color: context.appColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildDescriptionAndRules(ListingModel listing) {
    final rulesList = listing.houseRule?.split('|') ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Description", style: context.appTextStyles.titleLarge),
        const SizedBox(height: 16),
        Text(
          listing.description,
          style: context.appTextStyles.bodyMedium.copyWith(
            color: context.appColors.onSurfaceVariant,
            height: 1.6,
          ),
        ),

        if (rulesList.isNotEmpty) ...[
          const SizedBox(height: 32),
          Text("House Rules", style: context.appTextStyles.titleLarge),
          const SizedBox(height: 16),
          ...rulesList.map((rule) {
            if (rule.trim().isEmpty) return const SizedBox.shrink();

            // Map rule string to icon heuristically for the prototype
            IconData icon = Icons.info_outline;
            final r = rule.toLowerCase();
            if (r.contains('smok')) icon = Icons.smoke_free;
            if (r.contains('pet')) icon = Icons.pets;
            if (r.contains('quiet') || r.contains('time')) {
              icon = Icons.schedule;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: context.appColors.secondary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      rule.trim(),
                      style: context.appTextStyles.bodyMedium.copyWith(
                        color: context.appColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildLandlordCard(
    String ratingDisplay,
    int reviewCount,
    String ownerId,
  ) {
    if (_isLoadingOwner) return const LandlordCardSkeleton();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.appColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  UserAvatar(radius: 32, imageUrl: _ownerAvatarUrl),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _ownerName,
                    style: context.appTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: context.appColors.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "$ratingDisplay ($reviewCount Reviews)",
                        style: context.appTextStyles.labelMedium.copyWith(
                          color: context.appColors.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "${_ownerBio ?? 'Known for quick maintenance response.'} since ${_ownerMemberSinceYear ?? DateTime.now().year}",
            style: context.appTextStyles.bodySmall.copyWith(
              color: context.appColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.push('/home/owner-profile/$ownerId'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: context.appColors.outlineVariant),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: Text(
                "View Profile",
                style: context.appTextStyles.labelMedium.copyWith(
                  color: context.appColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationMap(ListingModel listing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Location", style: context.appTextStyles.titleLarge),
        const SizedBox(height: 16),
        Container(
          height: 256,
          decoration: BoxDecoration(
            color: context.appColors.surfaceContainer,
            borderRadius: BorderRadius.circular(24),
            image: const DecorationImage(
              image: NetworkImage(
                'https://images.unsplash.com/photo-1524661135-423995f22d0b?w=800',
              ), // map placeholder
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(Colors.grey, BlendMode.saturation),
            ),
          ),
          child: Stack(
            children: [
              // Map markers overlay logic could go here
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.appColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 8),
                        ],
                      ),
                      child: const Icon(
                        Icons.home,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 16,
                      color: context.appColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                listing.fullAddress,
                style: context.appTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              height: 200,
              width: 140, // Needs bounded width in Row
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.appColors.outlineVariant),
              ),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(listing.latitude, listing.longitude),
                  initialZoom: 15.0, // Adjust zoom level to your liking
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag
                        .none, // Optional: disables panning so it doesn't mess with screen scrolling
                  ),
                ),
                children: [
                  TileLayer(
                    // This is the free OpenStreetMap tile URL
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.finalyearproject',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(listing.latitude, listing.longitude),
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.location_on,
                          color: context.appColors.primary,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomActionBar(ListingModel listing) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.appColors.surfaceContainerLowest.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: context.appColors.glassOutline,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: context.appColors.primary.withValues(alpha: 0.12),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "RM ${listing.monthlyRent.toStringAsFixed(2)} / Month",
                            style: context.appTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      // Chat Button
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.appColors.surfaceContainerHigh,
                        ),
                        child: IconButton(
                          onPressed: () {
                            final listing = widget.listing;
                            if (listing == null) return;
                            context.push(
                              '/chat',
                              extra: ChatArgs(
                                receiverId: listing.ownerId,
                                receiverName: _ownerName,
                                listingId: listing.id,
                                listingTitle: listing.title,
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.chat,
                            color: context.appColors.primary,
                          ),
                          tooltip: 'Chat with Owner',
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Apply Button
                      ElevatedButton(
                        onPressed:
                            (_applicationStatus == null &&
                                !_isApplying &&
                                _client.auth.currentUser?.id != listing.ownerId)
                            ? _applyForListing
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _applicationStatus == 'pending'
                              ? Colors.orange
                              : _applicationStatus == 'active'
                              ? Colors.green
                              : context.appColors.primaryContainer,
                          foregroundColor: _applicationStatus == 'pending' || _applicationStatus == 'active' 
                              ? Colors.white 
                              : context.appColors.onPrimaryContainer,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                          elevation: 0,
                          disabledBackgroundColor:
                              context.appColors.surfaceContainerHigh,
                        ),
                        child: _isApplying
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _applicationStatus == 'pending'
                                    ? 'Requested'
                                    : _applicationStatus == 'active'
                                    ? 'Joined'
                                    : 'Apply Now',
                                style: context.appTextStyles.labelMedium
                                    .copyWith(
                                      color:
                                          (_applicationStatus == null &&
                                              _client.auth.currentUser?.id !=
                                                  listing.ownerId)
                                          ? Colors.white
                                          : context.appColors.outline,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
