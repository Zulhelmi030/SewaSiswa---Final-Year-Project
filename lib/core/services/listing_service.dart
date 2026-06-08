import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/listing_model.dart';

class ListingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch all available listings, joined with their first photo
  Future<List<ListingModel>> getListings({String? searchQuery}) async {
    var query = _supabase
        .from('listings')
        .select('*, listing_photos(photo_url)')
        .eq('status', 'available')
        .order('created_at', ascending: false);

    final response = await query;

    List<ListingModel> listings = (response as List)
        .map((json) => ListingModel.fromJson(json as Map<String, dynamic>))
        .toList();

    // Client-side search filter
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      listings = listings
          .where((l) =>
              l.title.toLowerCase().contains(q) ||
              l.address.toLowerCase().contains(q) ||
              (l.city?.toLowerCase().contains(q) ?? false) ||
              (l.state?.toLowerCase().contains(q) ?? false))
          .toList();
    }

    return listings;
  }

  /// Fetch listings by a specific owner
  Future<List<ListingModel>> getMyListings() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('listings')
        .select('*, listing_photos(photo_url)')
        .eq('owner_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => ListingModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a single listing by ID
  Future<ListingModel?> getListingById(String id) async {
    final response = await _supabase
        .from('listings')
        .select('*, listing_photos(photo_url)')
        .eq('id', id)
        .single();

    return ListingModel.fromJson(response);
  }

  /// Sort listings by price (ascending or descending)
  Future<List<ListingModel>> getListingsSortedByPrice({
    bool ascending = true,
  }) async {
    final response = await _supabase
        .from('listings')
        .select('*, listing_photos(photo_url)')
        .eq('status', 'available')
        .order('monthly_rent', ascending: ascending);

    return (response as List)
        .map((json) => ListingModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
