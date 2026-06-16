import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/photo_url.dart';

class AvatarImage extends StatelessWidget {
  const AvatarImage({
    super.key,
    this.url,
    required this.size,
    this.borderColor = AppColors.cyan,
    this.borderWidth = 3,
  });

  final String? url;
  final double size;
  final Color borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = resolveAvatarUrl(url);
    final hasUrl = resolvedUrl.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.cyan,
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withOpacity(0.4),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: hasUrl
          ? Image.network(
              resolvedUrl,
              width: size,
              height: size,
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
    );
  }

  Widget _placeholder() {
    return Icon(
      Icons.person,
      size: size * 0.55,
      color: Colors.white,
    );
  }
}
