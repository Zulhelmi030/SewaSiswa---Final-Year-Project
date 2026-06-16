import "package:flutter/material.dart";
import "package:finalyearproject/models/listing_model.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:finalyearproject/core/styles/app_theme_extensions.dart';
//import '../../core/constants/app_text_styles.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _client = Supabase.instance.client;
  bool _isLoading = true;
  List<ListingModel> _listings = [];
  ListingModel? _selectedListing;

  @override
  void initState() {
    super.initState();
    _fetchListings();
  }

  Future<void> _fetchListings() async {
    try {
      final response = await _client
          .from('listings')
          .select(
            'id, owner_id, title, description, address, latitude, longitude, monthly_rent, post_type',
          )
          .eq('status', 'available');
      setState(() {
        _listings = (response as List)
            .map((x) => ListingModel.fromJson(x as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching map listings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load listings. Showing UTeM location.'),
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // --- Layer 1: The Map ---
          FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(2.3138, 102.3183), // UTeM coordinates
              initialZoom: 14.0,
              onTap: (_, _) => setState(() => _selectedListing = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.finalyearproject',
              ),
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),

          // --- Back Button ---
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: GestureDetector(
              onTap: () => context.go('/home'),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: context.appColors.textPrimary,
                ),
              ),
            ),
          ),

          // --- Loading Indicator ---
          if (_isLoading) const Center(child: CircularProgressIndicator()),

          // --- Popup Card ---
          if (_selectedListing != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: _buildPopupCard(_selectedListing!),
            ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // 1. UTeM marker — distinct university icon
    markers.add(
      Marker(
        point: const LatLng(2.3138, 102.3183),
        width: 60,
        height: 60,
        child: GestureDetector(
          onTap: () => setState(() => _selectedListing = null),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'UTeM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(Icons.school, color: Colors.indigo.shade700, size: 20),
            ],
          ),
        ),
      ),
    );

    // 2. Listing markers — price bubble like Airbnb
    for (final listing in _listings) {
      markers.add(
        Marker(
          point: LatLng(listing.latitude, listing.longitude),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => setState(() => _selectedListing = listing),
            child: Container(
              decoration: BoxDecoration(
                color: _selectedListing?.id == listing.id
                    ? context.appColors.primary
                    : Colors.white,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.home_rounded,
                size: 22,
                color: _selectedListing?.id == listing.id
                    ? Colors.white
                    : context.appColors.primary,
              ),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  Widget _buildPopupCard(ListingModel listing) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Image thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: listing.imageUrls.isNotEmpty
                  ? Image.network(
                      listing.imageUrls.first,
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 110,
                      height: 110,
                      color: context.appColors.surfaceVariant,
                      child: Icon(
                        Icons.home,
                        color: context.appColors.outlineVariant,
                        size: 40,
                      ),
                    ),
            ),

            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      listing.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${listing.city ?? ''}, ${listing.state ?? ''}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: context.appColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'RM${listing.monthlyRent.toStringAsFixed(0)}/mo',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: context.appColors.primary,
                          ),
                        ),
                        // See Details button
                        GestureDetector(
                          onTap: () => context.push(
                            '/home/listings/detail',
                            extra: listing,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: context.appColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'See Details',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
