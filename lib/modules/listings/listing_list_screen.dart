import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/listing_model.dart';
import '../../shared/widgets/listing_card.dart';
import '../../core/services/filter_by_dist_service.dart';
import '../../core/services/filter_by_price_service.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/skeletons.dart';
import 'package:finalyearproject/core/styles/app_theme_extensions.dart';

class ListingListScreen extends StatefulWidget {
  final String? initialSearchQuery;

  const ListingListScreen({super.key, this.initialSearchQuery});

  @override
  State<ListingListScreen> createState() => _ListingListScreenState();
}

class _ListingListScreenState extends State<ListingListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedFilterIndex = 0;
  final Set<String> _wishlistIds = {};

  // Distance filter state
  double _maxDistanceKm = 5.0; // default radius shown in the slider
  bool _distanceFilterActive = false; // true once user confirms a distance

  // Price filter state
  double _minPrice = 100.0;
  double _maxPrice = 3000.0;
  bool _priceFilterActive = false;

  // Gender filter state
  String _selectedGender = 'Any';
  bool _genderFilterActive = false;

  // Slots filter state
  int _selectedTotalSlots = 1; // min slots
  bool _slotsFilterActive = false;

  List<ListingModel> _listings = [];
  bool _isLoading = true;
  String? _error;

  final List<String> _filters = ['All', 'Price', 'Gender', 'Distance', 'Slots'];

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchQuery != null) {
      _searchQuery = widget.initialSearchQuery!;
      _searchController.text = widget.initialSearchQuery!;
    }
    _fetchListings();
    _fetchWishlistStatus();
  }

  Future<void> _fetchListings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await Supabase.instance.client
          .from('listings')
          .select('*, listing_photos(photo_url)')
          .order('created_at', ascending: false);

      final fetched = (response as List<dynamic>)
          .map((json) => ListingModel.fromJson(json as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _listings = fetched;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching listings: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load listings. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  List<ListingModel> get _filteredListings {
    List<ListingModel> result = _listings.where((listing) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          listing.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          listing.address.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();

    // Apply price filter when the Price chip is active
    if (_selectedFilterIndex == 1 && _priceFilterActive) {
      result = FilterByPriceService.filterByPrice(result, _minPrice, _maxPrice);
      result = FilterByPriceService.sortListingByPrice(result);
    }

    // Apply gender filter when Gender chip is active
    if (_selectedFilterIndex == 2 && _genderFilterActive && _selectedGender != 'Any') {
      result = result.where((l) {
        return l.genderPreference == _selectedGender || 
               l.genderPreference == 'Any' || 
               l.genderPreference == null;
      }).toList();
    }

    // Apply distance filter when the Distance chip is active
    if (_selectedFilterIndex == 3 && _distanceFilterActive) {
      result = FilterByDistService.filterByDistance(result, _maxDistanceKm);
      result = FilterByDistService.sortByDistance(result);
    }

    // Apply slots filter when the Slots chip is active
    if (_selectedFilterIndex == 4 && _slotsFilterActive) {
      result = result.where((l) {
        final slots = l.totalSlots ?? 0;
        if (_selectedTotalSlots == 5) {
          return slots >= 5;
        }
        return slots == _selectedTotalSlots;
      }).toList();
    }

    return result;
  }

  /// Opens a bottom sheet that lets the user pick a max distance radius.
  void _showDistanceSheet() {
    // Temporarily hold the slider value inside the sheet
    double tempDistance = _maxDistanceKm;

    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                  // Title
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: context.appColors.primary.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.near_me_rounded,
                          color: context.appColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Distance from UTeM',
                            style: context.appTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Show listings within a radius',
                            style: context.appTextStyles.bodySmall.copyWith(
                              color: context.appColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Current value display
                  Center(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: tempDistance.toStringAsFixed(1),
                            style: context.appTextStyles.displayLarge.copyWith(
                              color: context.appColors.primary,
                              fontSize: 48,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(
                            text: ' km',
                            style: context.appTextStyles.titleMedium.copyWith(
                              color: context.appColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Slider
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: context.appColors.primary,
                      inactiveTrackColor: context.appColors.primary.withValues(
                        alpha: 0.15,
                      ),
                      thumbColor: context.appColors.primary,
                      overlayColor: context.appColors.primary.withValues(
                        alpha: 0.1,
                      ),
                      trackHeight: 6,
                    ),
                    child: Slider(
                      value: tempDistance,
                      min: 0.5,
                      max: 20.0,
                      divisions: 39, // 0.5 km steps
                      onChanged: (value) {
                        setSheetState(() => tempDistance = value);
                      },
                    ),
                  ),

                  // Min / Max labels
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '0.5 km',
                          style: context.appTextStyles.labelMedium.copyWith(
                            color: context.appColors.textSecondary,
                          ),
                        ),
                        Text(
                          '20 km',
                          style: context.appTextStyles.labelMedium.copyWith(
                            color: context.appColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Action buttons
                  Row(
                    children: [
                      // Reset
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _maxDistanceKm = 5.0;
                              _distanceFilterActive = false;
                              _selectedFilterIndex = 0;
                            });
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: context.appColors.outlineVariant,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Reset',
                            style: context.appTextStyles.labelMedium.copyWith(
                              color: context.appColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Apply
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              _maxDistanceKm = tempDistance;
                              _distanceFilterActive = true;
                              _selectedFilterIndex =
                                  3; // keep Distance selected
                            });
                            Navigator.pop(context);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: context.appColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Apply Filter',
                            style: context.appTextStyles.labelMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        );
      },
    );
  }

  void _showPriceSheet() {
    double tempMinPrice = _minPrice;
    double tempMaxPrice = _maxPrice;

    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                  // Title
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: context.appColors.primary.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.attach_money_rounded,
                          color: context.appColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Price Range',
                            style: context.appTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Filter by monthly rent',
                            style: context.appTextStyles.bodySmall.copyWith(
                              color: context.appColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Current value display
                  Center(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'RM ${tempMinPrice.toInt()} - RM ${tempMaxPrice.toInt()}',
                            style: context.appTextStyles.displayLarge.copyWith(
                              color: context.appColors.primary,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Range Slider
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: context.appColors.primary,
                      inactiveTrackColor: context.appColors.primary.withValues(
                        alpha: 0.15,
                      ),
                      thumbColor: context.appColors.primary,
                      overlayColor: context.appColors.primary.withValues(
                        alpha: 0.1,
                      ),
                      trackHeight: 6,
                    ),
                    child: RangeSlider(
                      values: RangeValues(tempMinPrice, tempMaxPrice),
                      min: 0,
                      max: 5000,
                      divisions: 100,
                      onChanged: (values) {
                        setSheetState(() {
                          tempMinPrice = values.start;
                          tempMaxPrice = values.end;
                        });
                      },
                    ),
                  ),

                  // Min / Max labels
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'RM 0',
                          style: context.appTextStyles.labelMedium.copyWith(
                            color: context.appColors.textSecondary,
                          ),
                        ),
                        Text(
                          'RM 5000+',
                          style: context.appTextStyles.labelMedium.copyWith(
                            color: context.appColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Action buttons
                  Row(
                    children: [
                      // Reset
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _minPrice = 100.0;
                              _maxPrice = 3000.0;
                              _priceFilterActive = false;
                              _selectedFilterIndex = 0;
                            });
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: context.appColors.outlineVariant,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Reset',
                            style: context.appTextStyles.labelMedium.copyWith(
                              color: context.appColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Apply
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              _minPrice = tempMinPrice;
                              _maxPrice = tempMaxPrice;
                              _priceFilterActive = true;
                              _selectedFilterIndex = 1;
                            });
                            Navigator.pop(context);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: context.appColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Apply Filter',
                            style: context.appTextStyles.labelMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        );
      },
    );
  }

  void _showGenderSheet() {
    String tempGender = _selectedGender;

    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                  // Title
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: context.appColors.primary.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.wc_rounded,
                          color: context.appColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gender Preference',
                            style: context.appTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Filter by allowed gender',
                            style: context.appTextStyles.bodySmall.copyWith(
                              color: context.appColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'Any', label: Text('Any')),
                        ButtonSegment(value: 'Male', label: Text('Male')),
                        ButtonSegment(value: 'Female', label: Text('Female')),
                      ],
                      selected: {tempGender},
                      onSelectionChanged: (Set<String> newSelection) {
                        setSheetState(() {
                          tempGender = newSelection.first;
                        });
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                          if (states.contains(WidgetState.selected)) {
                            return context.appColors.primary;
                          }
                          return context.appColors.surfaceContainerHigh;
                        }),
                        foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                          if (states.contains(WidgetState.selected)) {
                            return context.appColors.onPrimary;
                          }
                          return context.appColors.textPrimary;
                        }),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 28),

                  // Action buttons
                  Row(
                    children: [
                      // Reset
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedGender = 'Any';
                              _genderFilterActive = false;
                              _selectedFilterIndex = 0;
                            });
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: context.appColors.outlineVariant,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Reset',
                            style: context.appTextStyles.labelMedium.copyWith(
                              color: context.appColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Apply
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              _selectedGender = tempGender;
                              _genderFilterActive = tempGender != 'Any';
                              _selectedFilterIndex = 2;
                            });
                            Navigator.pop(context);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: context.appColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Apply Filter',
                            style: context.appTextStyles.labelMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        );
      },
    );
  }

  void _showSlotsSheet() {
    int tempSlots = _selectedTotalSlots;

    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: context.appColors.primary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.group_rounded,
                            color: context.appColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Slots',
                              style: context.appTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Number of slots per house/room',
                              style: context.appTextStyles.bodySmall.copyWith(
                                color: context.appColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Segments
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(
                            value: 1,
                            label: Text('1'),
                          ),
                          ButtonSegment(
                            value: 2,
                            label: Text('2'),
                          ),
                          ButtonSegment(
                            value: 3,
                            label: Text('3'),
                          ),
                          ButtonSegment(
                            value: 4,
                            label: Text('4'),
                          ),
                          ButtonSegment(
                            value: 5,
                            label: Text('5+'),
                          ),
                        ],
                        selected: {tempSlots},
                        onSelectionChanged: (Set<int> newSelection) {
                          setSheetState(() {
                            tempSlots = newSelection.first;
                          });
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return context.appColors.primary.withValues(alpha: 0.15);
                            }
                            return Colors.transparent;
                          }),
                          side: WidgetStateProperty.all(
                            BorderSide(
                              color: context.appColors.outlineVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _slotsFilterActive = false;
                                _selectedTotalSlots = 1; // reset
                              });
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                color: context.appColors.outlineVariant,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Clear',
                              style: context.appTextStyles.labelMedium.copyWith(
                                color: context.appColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              setState(() {
                                _slotsFilterActive = true;
                                _selectedTotalSlots = tempSlots;
                              });
                              Navigator.pop(context);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: context.appColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Apply Filter',
                              style: context.appTextStyles.labelMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
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
          _wishlistIds
            ..clear()
            ..addAll(
              (rows as List<dynamic>).map((r) => r['listing_id'] as String),
            );
        });
      }
    } catch (e) {
      debugPrint('Error fetching wishlist status: $e');
    }
  }

  Future<void> _toggleWishlist(String listingId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final isCurrentlyWishlisted = _wishlistIds.contains(listingId);
    // Optimistic update
    setState(() {
      if (isCurrentlyWishlisted) {
        _wishlistIds.remove(listingId);
      } else {
        _wishlistIds.add(listingId);
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
      // Rollback on failure
      if (mounted) {
        setState(() {
          if (isCurrentlyWishlisted) {
            _wishlistIds.add(listingId);
          } else {
            _wishlistIds.remove(listingId);
          }
        });
      }
    }
  }

  void _showWishlistSheet() {
    final wishlisted = _listings
        .where((l) => _wishlistIds.contains(l.id))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Stack(
        children: [
          // Tap outside to dismiss
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.92,
            builder: (context, scrollController) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.appColors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.favorite_rounded,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'My Wishlist',
                          style: context.appTextStyles.headlineMedium,
                        ),
                        const Spacer(),
                        Text(
                          '${wishlisted.length} saved',
                          style: context.appTextStyles.labelMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  Expanded(
                    child: wishlisted.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.favorite_border_rounded,
                                  size: 48,
                                  color: context.appColors.outline.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No saved properties yet',
                                  style: context.appTextStyles.bodyMedium
                                      .copyWith(
                                        color: context.appColors.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap ♡ on any listing to save it',
                                  style: context.appTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            itemCount: wishlisted.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final l = wishlisted[index];
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color:
                                      context.appColors.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: context.appColors.outlineVariant
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        width: 64,
                                        height: 64,
                                        color: context
                                            .appColors
                                            .surfaceContainerLow,
                                        child: Icon(
                                          Icons.home_rounded,
                                          color: context.appColors.outline,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l.title,
                                            style: context
                                                .appTextStyles
                                                .titleMedium
                                                .copyWith(fontSize: 15),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            l.address,
                                            style:
                                                context.appTextStyles.bodySmall,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'RM ${l.monthlyRent.toStringAsFixed(0)}/mo',
                                            style: context
                                                .appTextStyles
                                                .labelMedium
                                                .copyWith(
                                                  color:
                                                      context.appColors.primary,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.favorite_rounded,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      onPressed: () async {
                                        final nav = Navigator.of(context);
                                        await _toggleWishlist(l.id);
                                        nav.pop();
                                        if (_wishlistIds.isNotEmpty) {
                                          _showWishlistSheet();
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchListings,
          color: context.appColors.primary,
          child: CustomScrollView(
            slivers: [
              // ── Header ──────────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BROWSE & SEARCH',
                              style: context.appTextStyles.labelCaps.copyWith(
                                color: context.appColors.primary.withValues(
                                  alpha: 0.5,
                                ),
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Find Your\nPerfect Space',
                              style: context.appTextStyles.displayLarge
                                  .copyWith(fontSize: 36, height: 1.1),
                            ),
                          ],
                        ),
                      ),
                      // Wishlist Button
                      GestureDetector(
                        onTap: _showWishlistSheet,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _wishlistIds.isNotEmpty
                                ? Colors.red.shade50
                                : context.appColors.surfaceContainerLow,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.favorite_rounded,
                                color: _wishlistIds.isNotEmpty
                                    ? Colors.red
                                    : context.appColors.outline,
                                size: 22,
                              ),
                              if (_wishlistIds.isNotEmpty)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${_wishlistIds.length}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Search Bar ──────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                sliver: SliverToBoxAdapter(
                  child: _SearchBar(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
              ),

              // ── Filter Chips ────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 16, 0, 0),
                sliver: SliverToBoxAdapter(
                  child: SizedBox(
                    height: 52,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(right: 24),
                      itemCount: _filters.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final isSelected = _selectedFilterIndex == index;
                        final isPriceChip = index == 1;
                        final isGenderChip = index == 2;
                        final isDistanceChip = index == 3;
                        final isSlotsChip = index == 4;

                        String? badgeText;
                        if (isPriceChip && _priceFilterActive) {
                          badgeText = 'RM ${_minPrice.toInt()} - ${_maxPrice.toInt()}';
                        } else if (isGenderChip && _genderFilterActive) {
                          badgeText = _selectedGender;
                        } else if (isDistanceChip && _distanceFilterActive) {
                          badgeText = '≤ ${_maxDistanceKm.toStringAsFixed(1)} km';
                        } else if (isSlotsChip && _slotsFilterActive) {
                          badgeText = _selectedTotalSlots == 5 ? '5+ slots' : '$_selectedTotalSlots slots';
                        }

                        return _FilterChip(
                          label: _filters[index],
                          isSelected: isSelected,
                          badge: badgeText,
                          onTap: () {
                            if (isPriceChip) {
                              setState(() => _selectedFilterIndex = index);
                              _showPriceSheet();
                            } else if (isGenderChip) {
                              setState(() => _selectedFilterIndex = index);
                              _showGenderSheet();
                            } else if (isDistanceChip) {
                              setState(() => _selectedFilterIndex = index);
                              _showDistanceSheet();
                            } else if (isSlotsChip) {
                              setState(() => _selectedFilterIndex = index);
                              _showSlotsSheet();
                            } else {
                              setState(() {
                                _selectedFilterIndex = index;
                                _priceFilterActive = false;
                                _genderFilterActive = false;
                                _distanceFilterActive = false;
                                _slotsFilterActive = false;
                              });
                            }
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),

              // ── Body: Loading / Error / Listings ────────────────────────────
              if (_isLoading)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => const ListingCardSkeleton(),
                      childCount: 5,
                    ),
                  ),
                )
              else if (_error != null)
                SliverFillRemaining(child: _buildErrorState())
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Text(
                          '${_filteredListings.length} ',
                          style: context.appTextStyles.titleMedium.copyWith(
                            color: context.appColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          _filteredListings.length == 1
                              ? 'property found'
                              : 'properties found',
                          style: context.appTextStyles.bodyMedium.copyWith(
                            color: context.appColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: _filteredListings.isEmpty
                      ? SliverToBoxAdapter(child: _buildEmptyState())
                      : SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final listing = _filteredListings[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 24.0),
                              child: ListingCard(
                                listing: listing,
                                isWishlisted: _wishlistIds.contains(listing.id),
                                onWishlistToggle: () =>
                                    _toggleWishlist(listing.id),
                                onTap: () {
                                  context.push(
                                    '/home/listings/detail',
                                    extra: listing,
                                  );
                                },
                              ),
                            );
                          }, childCount: _filteredListings.length),
                        ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ],
          ), // CustomScrollView
        ), // RefreshIndicator
      ), // SafeArea
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: context.appColors.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: context.appTextStyles.titleMedium.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _error ?? '',
              style: context.appTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _fetchListings,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 56,
            color: context.appColors.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No properties found',
            style: context.appTextStyles.titleMedium.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a different search term or filter',
            style: context.appTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ── Search Bar Widget ──────────────────────────────────────────────────────────
class _SearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: context.appColors.surfaceContainerHigh,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        border: Border(
          bottom: BorderSide(
            color: _isFocused ? context.appColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Focus(
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        child: TextField(
          controller: widget.controller,
          onChanged: widget.onChanged,
          style: context.appTextStyles.bodyMedium.copyWith(
            color: context.appColors.onSurface,
          ),
          decoration: InputDecoration(
            hintText: 'Search by location, title...',
            hintStyle: context.appTextStyles.bodyMedium.copyWith(
              color: context.appColors.outline,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Icon(
                Icons.search_rounded,
                color: _isFocused
                    ? context.appColors.primary
                    : context.appColors.outline,
                size: 22,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 52,
              minHeight: 52,
            ),
            suffixIcon: widget.controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: context.appColors.outline,
                      size: 20,
                    ),
                    onPressed: () {
                      widget.controller.clear();
                      widget.onChanged('');
                    },
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Filter Chip Widget ─────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  /// Optional small badge text shown below the label (e.g. "≤ 3.0 km")
  final String? badge;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? context.appColors.primary
              : context.appColors.surfaceContainer,
          borderRadius: BorderRadius.circular(9999),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: context.appColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: context.appTextStyles.labelMedium.copyWith(
                color: isSelected
                    ? Colors.white
                    : context.appColors.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(height: 1),
              Text(
                badge!,
                style: context.appTextStyles.labelMedium.copyWith(
                  fontSize: 9,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.85)
                      : context.appColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
