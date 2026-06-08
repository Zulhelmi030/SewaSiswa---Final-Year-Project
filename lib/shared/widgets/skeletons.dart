import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../core/constants/app_colors.dart';

/// A shimmer placeholder shaped like a listing card used in the vertical list.
class ListingCardSkeleton extends StatelessWidget {
  const ListingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              child: Container(
                height: 200,
                width: double.infinity,
                color: AppColors.surfaceContainerHigh,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Bone.text(words: 3),
                  const SizedBox(height: 8),
                  // Address
                  Bone.text(words: 5),
                  const SizedBox(height: 12),
                  // Price row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Bone.text(words: 2),
                      Bone.text(words: 2),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Distance badge
                  Bone(
                    height: 28,
                    width: 160,
                    borderRadius: BorderRadius.circular(100),
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

/// A shimmer placeholder shaped like a horizontal listing card used in Home Screen.
class HorizontalListingCardSkeleton extends StatelessWidget {
  const HorizontalListingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              child: Container(
                height: 200,
                width: double.infinity,
                color: AppColors.surfaceContainerHigh,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Bone.text(words: 3),
                  const SizedBox(height: 8),
                  Bone.text(words: 4),
                  const SizedBox(height: 12),
                  Bone.text(words: 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A shimmer placeholder shaped like the landlord card in ListingDetailScreen.
class LandlordCardSkeleton extends StatelessWidget {
  const LandlordCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            const Bone.circle(size: 64),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Bone.text(words: 2),
                  const SizedBox(height: 8),
                  Bone.text(words: 3),
                ],
              ),
            ),
            Bone(
              height: 40,
              width: 90,
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
      ),
    );
  }
}

/// A shimmer placeholder for the manage listing card.
class ManageListingCardSkeleton extends StatelessWidget {
  const ManageListingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Container(
                height: 160,
                width: double.infinity,
                color: AppColors.surfaceContainerHigh,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Bone.text(words: 3)),
                      const SizedBox(width: 8),
                      Bone(
                        height: 24,
                        width: 70,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Bone.text(words: 4),
                  const SizedBox(height: 8),
                  Bone.text(words: 2),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Bone(
                          height: 44,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Bone(
                          height: 44,
                          borderRadius: BorderRadius.circular(12),
                        ),
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
