import '../../models/listing_model.dart';

class FilterByPriceService {
  static List<ListingModel> filterByPrice(
    List<ListingModel> listings,
    double minPrice,
    double maxPrice,
  ) {
    return listings
        .where(
          (listing) =>
              listing.monthlyRent >= minPrice &&
              listing.monthlyRent <= maxPrice,
        )
        .toList();
  }

  static List<ListingModel> sortListingByPrice(
    List<ListingModel> listings, {
    bool ascending = true,
  }) {
    final sorted = listings.toList();
    sorted.sort(
      (a, b) => ascending
          ? a.monthlyRent.compareTo(b.monthlyRent)
          : b.monthlyRent.compareTo(a.monthlyRent),
    );
    return sorted;
  }
}
