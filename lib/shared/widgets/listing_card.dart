import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import '../../models/listing_model.dart';
import 'package:finalyearproject/core/styles/app_theme_extensions.dart';

class ListingCard extends StatelessWidget {
  final ListingModel listing;
  final VoidCallback? onTap;
  final bool isWishlisted;
  final VoidCallback? onWishlistToggle;

  const ListingCard({
    super.key,
    required this.listing,
    this.onTap,
    this.isWishlisted = false,
    this.onWishlistToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.appColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: context.appColors.glassOutline,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: context.appColors.primary.withValues(alpha: 0.12),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.2,
                  child: listing.imageUrls.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: listing.imageUrls[0],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: context.appColors.surfaceContainerLow,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: context.appColors.surfaceContainerLow,
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: context.appColors.outline,
                            ),
                          ),
                        )
                      : Container(
                          color: context.appColors.surfaceContainerLow,
                          child: Icon(
                            Icons.image_outlined,
                            color: context.appColors.outline,
                            size: 48,
                          ),
                        ),
                ),
                // Price Tag - Glassmorphism style
                Positioned(
                  top: 16,
                  left: 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9999),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        color: Colors.white.withValues(alpha: 0.85),
                        child: Text(
                          "RM ${listing.monthlyRent.toStringAsFixed(0)}/mo",
                          style: context.appTextStyles.labelMedium.copyWith(
                            color: context.appColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Wishlist Heart Button
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: onWishlistToggle,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isWishlisted
                            ? Colors.red.shade50
                            : Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                        child: Icon(
                          isWishlisted
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          key: ValueKey(isWishlisted),
                          color: isWishlisted ? Colors.red : context.appColors.outline,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Info Section (The "Shelf")
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    style: context.appTextStyles.headlineMedium.copyWith(
                      fontSize: 20,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: context.appColors.outline,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          listing.address,
                          style: context.appTextStyles.labelSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Available Now",
                        style: context.appTextStyles.labelSmall.copyWith(
                          color: context.appColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: context.appColors.outline,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
