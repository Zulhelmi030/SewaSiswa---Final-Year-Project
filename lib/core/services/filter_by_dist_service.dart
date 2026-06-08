import 'dart:math';
import '../../models/listing_model.dart';

/// Service that calculates distances and filters listings by proximity to UTeM.
class FilterByDistService {
  // UTeM campus coordinates (Universiti Teknikal Malaysia Melaka)
  static const double _utemLat = 2.3147;
  static const double _utemLon = 102.3185;

  /// Calculates the great-circle distance (in km) between two GPS coordinates
  /// using the Haversine formula.
  ///
  /// Parameters:
  ///   [lat1], [lon1] — origin latitude/longitude (degrees)
  ///   [lat2], [lon2] — destination latitude/longitude (degrees)
  ///
  /// Returns distance in kilometres.
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km

    // Convert degree difference to radians
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    // Haversine formula
    // a = sin²(Δlat/2) + cos(lat1)·cos(lat2)·sin²(Δlon/2)
    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    // c = 2·atan2(√a, √(1−a))   ← the central angle
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c; // arc length = radius × central angle
  }

  /// Calculates the distance (in km) from a listing to UTeM.
  static double distanceFromUtem(ListingModel listing) {
    return calculateDistance(
      listing.latitude,
      listing.longitude,
      _utemLat,
      _utemLon,
    );
  }

  /// Returns only listings whose GPS coordinates are within [maxDistanceKm]
  /// kilometres from UTeM.
  ///
  /// Listings with (0, 0) coordinates are excluded because that indicates
  /// missing location data.
  static List<ListingModel> filterByDistance(
    List<ListingModel> listings,
    double maxDistanceKm,
  ) {
    return listings.where((listing) {
      // Skip listings without real coordinates
      if (listing.latitude == 0.0 && listing.longitude == 0.0) return false;

      final double distance = distanceFromUtem(listing);
      return distance <= maxDistanceKm;
    }).toList();
  }

  /// Sorts listings by their distance from UTeM (nearest first).
  static List<ListingModel> sortByDistance(List<ListingModel> listings) {
    final sorted = List<ListingModel>.from(listings);
    sorted.sort(
      (a, b) => distanceFromUtem(a).compareTo(distanceFromUtem(b)),
    );
    return sorted;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static double _toRadians(double degrees) => degrees * pi / 180;
}
