import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../shared/widgets/listing_card.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/skeletons.dart';
import '../../models/listing_model.dart';
import 'package:finalyearproject/shared/widgets/anim_search_widget.dart';
import 'package:finalyearproject/core/styles/app_theme_extensions.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ListingModel> _hotListings = [];
  Set<String> _wishlistedIds = {};
  bool _isLoadingListings = true;

  @override
  void initState() {
    super.initState();
    _fetchHotListings();
    _fetchWishlistStatus();
  }

  Future<void> _fetchHotListings() async {
    if (mounted) setState(() => _isLoadingListings = true);
    try {
      final response = await Supabase.instance.client
          .from('listings')
          .select('*, listing_photos(photo_url)')
          .eq('status', 'available')
          .order('created_at', ascending: false)
          .limit(3);
      final fetched = (response as List<dynamic>)
          .map((json) => ListingModel.fromJson(json as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() {
          _hotListings = fetched;
          _isLoadingListings = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingListings = false);
    }
  }

  Future<void> _fetchWishlistStatus() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final rows = await Supabase.instance.client
          .from('wishlists')
          .select('listing_id')
          .eq('user_id', userId);
      if (mounted) {
        setState(() {
          _wishlistedIds = (rows as List<dynamic>)
              .map((r) => r['listing_id'] as String)
              .toSet();
        });
      }
    } catch (e) {
      debugPrint('Error fetching wishlist status: $e');
    }
  }

  Future<void> _toggleWishlist(String listingId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final isCurrentlyWishlisted = _wishlistedIds.contains(listingId);
    // Optimistic update
    setState(() {
      if (isCurrentlyWishlisted) {
        _wishlistedIds.remove(listingId);
      } else {
        _wishlistedIds.add(listingId);
      }
    });
    try {
      if (isCurrentlyWishlisted) {
        await Supabase.instance.client
            .from('wishlists')
            .delete()
            .eq('user_id', userId)
            .eq('listing_id', listingId);
      } else {
        await Supabase.instance.client.from('wishlists').insert({
          'user_id': userId,
          'listing_id': listingId,
        });
      }
    } catch (e) {
      debugPrint('Error toggling wishlist: $e');
      // Revert optimistic update on error
      if (mounted) {
        setState(() {
          if (isCurrentlyWishlisted) {
            _wishlistedIds.add(listingId);
          } else {
            _wishlistedIds.remove(listingId);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchHotListings,
        color: context.appColors.primary,
        child: CustomScrollView(
          slivers: [
            // 1. Hero Header & Search Section
            SliverToBoxAdapter(
              child: Container(
                color: context.appColors.surfaceContainerLow,
                padding: const EdgeInsets.fromLTRB(24, 80, 24, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Find Your\n',
                            style: context.appTextStyles.displayLarge.copyWith(
                              color: context.appColors.textPrimary,
                            ),
                          ),
                          TextSpan(
                            text: 'Next Space.',
                            style: context.appTextStyles.displayLarge.copyWith(
                              color: context.appColors.primary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Search Bar
                    AnimSearchBar(
                      height: 55,
                      width: (MediaQuery.of(context).size.width - 48).clamp(
                        0.0,
                        double.infinity,
                      ),
                      textController: _searchController,
                      helpText: 'Where are you staying?',
                      color: context.appColors.surfaceContainerHighest,
                      textFieldColor: context.appColors.surfaceContainerHighest,
                      searchIconColor: context.appColors.outline,
                      textFieldIconColor: context.appColors.outline,
                      boxShadow: false,
                      rtl: true, // icon on the right
                      closeSearchOnSuffixTap: true,
                      onSuffixTap: () {
                        _searchController.clear(); // clear on X tap
                      },
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          context.go('/listings', extra: value);
                        }
                      },
                      searchBarOpen: (state) {},
                    ),
                  ],
                ),
              ),
            ),

            // 2. Hot Listings Section
            SliverToBoxAdapter(
              child: Container(
                color: context.appColors.surface,
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: context.appColors.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Hot Listings',
                                style: context.appTextStyles.headlineLarge,
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              final user =
                                  Supabase.instance.client.auth.currentUser;
                              if (user == null) {
                                context.push('/login');
                                return;
                              }
                              context.go('/listings');
                            },
                            child: Text(
                              'View all →',
                              style: context.appTextStyles.labelMedium.copyWith(
                                color: context.appColors.primary,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                                decorationColor: context.appColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 380,
                      child: _isLoadingListings
                          ? ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: 3,
                              itemBuilder: (_, _) =>
                                  const HorizontalListingCardSkeleton(),
                            )
                          : _hotListings.isEmpty
                          ? const Center(child: Text('No listings available'))
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: _hotListings.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: SizedBox(
                                    width: 280,
                                    child: ListingCard(
                                      listing: _hotListings[index],
                                      isWishlisted: _wishlistedIds.contains(
                                        _hotListings[index].id,
                                      ),
                                      onWishlistToggle: () => _toggleWishlist(
                                        _hotListings[index].id,
                                      ),
                                      onTap: () => context.push(
                                        '/home/listings/detail',
                                        extra: _hotListings[index],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),

            // 4. Promotional Banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: context.appColors.primaryContainer,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.forum_outlined,
                        color: context.appColors.onPrimaryContainer,
                        size: 32,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Need Roommates?',
                        style: context.appTextStyles.headlineMedium.copyWith(
                          color: context.appColors.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Find students with similar vibes and courses to share your space.',
                        style: context.appTextStyles.bodySmall.copyWith(
                          color: context.appColors.onPrimaryContainer
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: 160,
                        child: CustomButton(
                          text: 'Join Community',
                          onPressed: () async {
                            final uri = Uri.parse(
                              'https://t.me/+LNeT0QRTlV83OGI9',
                            );
                            if (!await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            )) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Could not open Telegram. Please install Telegram and try again.',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          isOutlined: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),

            // 5. Map View Preview
            SliverToBoxAdapter(
              child: GestureDetector(
                onTap: () => context.go('/map'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: context.appColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(32),
                      image: const DecorationImage(
                        image: NetworkImage(
                          'https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?q=80&w=1000',
                        ),
                        fit: BoxFit.cover,
                        opacity: 0.3,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.map_outlined,
                                color: context.appColors.primary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Map View',
                                style: context.appTextStyles.headlineMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Explore rentals around your campus.',
                                style: context.appTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  /*Widget _buildCategoryCard(String title, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: context.appColors.primary),
          const SizedBox(height: 16),
          Text(
            title,
            style: context.appTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: context.appColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
*/
}
