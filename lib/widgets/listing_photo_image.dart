import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/photo_url.dart';

class ListingPhotoImage extends StatelessWidget {
  const ListingPhotoImage({
    super.key,
    this.url,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.iconColor = AppColors.cyan,
  });

  final String? url;
  final double? width;
  final double? height;
  final double borderRadius;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = resolvePhotoUrl(url);
    final hasUrl = resolvedUrl.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        height: height,
        color: AppColors.darkBlue.withOpacity(0.85),
        child: hasUrl
            ? Image.network(
                resolvedUrl,
                width: width,
                height: height,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.cyan,
                      ),
                    ),
                  );
                },
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Center(
      child: Icon(
        Icons.image_outlined,
        color: iconColor.withOpacity(0.7),
        size: (height != null && height! < 80) ? 28 : 48,
      ),
    );
  }
}
