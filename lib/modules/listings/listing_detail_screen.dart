import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../routes/app_routes.dart';
import '../../models/listing_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../shared/widgets/skeletons.dart';
import 'dart:ui';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _ownerName = 'Loading...';

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
          .select('full_name')
          .eq('id', listing.ownerId)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _ownerName =
              row?['full_name'] as String? ?? listing.ownerId.substring(0, 8);
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
      backgroundColor: AppColors.background,
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
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceBright,
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
                      _buildLocationMap(currentListing.fullAddress),
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
                    style: AppTextStyles.labelCaps.copyWith(
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
                style: AppTextStyles.headlineLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "RM ${listing.monthlyRent.toStringAsFixed(0)}",
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
                Text(
                  "PER MONTH",
                  style: AppTextStyles.labelCaps.copyWith(
                    color: AppColors.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.location_on,
              size: 16,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                listing.fullAddress,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryFixed,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.school,
                size: 18,
                color: AppColors.onPrimaryFixed,
              ),
              const SizedBox(width: 8),
              Text(
                "0.8 km from UTeM Main Campus", // In a real app, calculate this
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.onPrimaryFixed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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
                  color: AppColors.surfaceContainer,
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.15),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      getIconFor(f),
                      color: AppColors.onSurfaceVariant,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      f,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textPrimary,
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
        Text("Description", style: AppTextStyles.titleLarge),
        const SizedBox(height: 16),
        Text(
          listing.description,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
            height: 1.6,
          ),
        ),

        if (rulesList.isNotEmpty) ...[
          const SizedBox(height: 32),
          Text("House Rules", style: AppTextStyles.titleLarge),
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
                  Icon(icon, color: AppColors.secondary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      rule.trim(),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.onSurfaceVariant,
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

  Widget _buildLandlordCard(String ratingDisplay, int reviewCount, String ownerId) {
    if (_isLoadingOwner) return const LandlordCardSkeleton();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
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
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    backgroundImage: const NetworkImage(
                      'https://images.unsplash.com/photo-1599566150163-29194dcaad36?w=150',
                    ), // dummy avatar
                  ),
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
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 16,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "$ratingDisplay ($reviewCount Reviews)",
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.outline,
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
            "Verified UTeM Member since 2019. Known for quick maintenance response.",
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.push('/home/owner-profile/$ownerId'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppColors.outlineVariant),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: Text(
                "View Profile",
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationMap(String address) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Location", style: AppTextStyles.titleLarge),
        const SizedBox(height: 16),
        Container(
          height: 256,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
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
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
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
                    Container(width: 2, height: 16, color: AppColors.primary),
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
                address,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              height: 200,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(
                    widget.listing!.latitude,
                    widget.listing!.longitude,
                  ),
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
                        point: LatLng(
                          widget.listing!.latitude,
                          widget.listing!.longitude,
                        ),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: AppColors.primary,
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
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
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
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "RM ${listing.monthlyRent.toStringAsFixed(2)} / Month",
                          style: AppTextStyles.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.chat, size: 20),
                    label: Text(
                      "Contact Owner",
                      style: AppTextStyles.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
