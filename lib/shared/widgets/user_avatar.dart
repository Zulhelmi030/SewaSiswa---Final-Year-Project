import 'package:flutter/material.dart';
import 'package:finalyearproject/core/styles/app_theme_extensions.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;

  const UserAvatar({super.key, this.imageUrl, this.radius = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: context.appColors.surfaceContainerLow,
        shape: BoxShape.circle,
        image: imageUrl != null
            ? DecorationImage(
                image: NetworkImage(imageUrl!.replaceAll(
                    'api.dicebear.com/7.x/avataaars/svg',
                    'api.dicebear.com/7.x/avataaars/png')),
                fit: BoxFit.cover)
            : null,
      ),
      child: imageUrl == null
          ? Icon(
              Icons.person_outline_rounded,
              color: context.appColors.outline,
              size: radius,
            )
          : null,
    );
  }
}
