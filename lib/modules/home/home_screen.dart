import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../shared/widgets/listing_card.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/skeletons.dart';
import '../../models/listing_model.dart';
import 'package:finalyearproject/shared/widgets/anim_search_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ListingModel> _hotListings = [];
  bool _isLoadingListings = true;

  @override
  void initState() {
    super.initState();
    _fetchHotListings();
  }

  Future<void> _fetchHotListings() async {
    if (mounted) setState(() => _isLoadingListings = true);
    try {
      final response = await Supabase.instance.client
          .from('listings')
          .select('*, listing_photos(photo_url)')
          .eq('status', 'available')
          .order('created_at', ascending: false)
          .limit(10);
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
        color: AppColors.primary,
        child: CustomScrollView(
        slivers: [
          // 1. Hero Header & Search Section
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.surfaceContainerLow,
              padding: const EdgeInsets.fromLTRB(24, 80, 24, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Find Your\n',
                          style: AppTextStyles.displayLarge.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextSpan(
                          text: 'Next Space.',
                          style: AppTextStyles.displayLarge.copyWith(
                            color: AppColors.primary,
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
                    color: AppColors.surfaceContainerHighest,
                    textFieldColor: AppColors.surfaceContainerHighest,
                    searchIconColor: AppColors.outline,
                    textFieldIconColor: AppColors.outline,
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
              color: AppColors.surface,
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
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Hot Listings',
                              style: AppTextStyles.headlineLarge,
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
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.primary,
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
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: 3,
                            itemBuilder: (_, _) =>
                                const HorizontalListingCardSkeleton(),
                          )
                        : _hotListings.isEmpty
                        ? const Center(child: Text('No listings available'))
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
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

          // 3. Categories Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              delegate: SliverChildListDelegate([
                _buildCategoryCard('Private Studios', Icons.business_rounded),
                _buildCategoryCard('Shared Houses', Icons.groups_rounded),
                _buildCategoryCard('Campus Nearby', Icons.school_rounded),
                _buildCategoryCard('Eco-Energy', Icons.bolt_rounded),
              ]),
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
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.forum_outlined,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Need Roommates?',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Find students with similar vibes and courses to share your space.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 160,
                      child: CustomButton(
                        text: 'Join Community',
                        onPressed: () {},
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
                    color: AppColors.surfaceContainerLow,
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
                            const Icon(
                              Icons.map_outlined,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Map View',
                              style: AppTextStyles.headlineMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Explore rentals around your campus.',
                              style: AppTextStyles.bodySmall,
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

  Widget _buildCategoryCard(String title, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
