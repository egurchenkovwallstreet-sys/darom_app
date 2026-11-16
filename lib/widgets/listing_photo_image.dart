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
    this.detailView = false,
  });

  final String? url;
  final double? width;
  final double? height;
  final double borderRadius;
  final Color iconColor;
  /// Для карточки объявления — миниатюра; для экрана объявления — крупнее.
  final bool detailView;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final layoutWidth = _layoutWidth(context);
    final pixelWidth = _targetPixelWidth(layoutWidth, dpr, detailView);
    final pixelHeight = height != null && height!.isFinite
        ? (height! * dpr).ceil().clamp(64, 1600)
        : null;

    final resolvedUrl = resolvePhotoUrl(url, maxPixelWidth: pixelWidth);
    final hasUrl = resolvedUrl.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        height: height,
        color: AppColors.background.withOpacity(0.65),
        child: hasUrl
            ? Image.network(
                resolvedUrl,
                width: width,
                height: height,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                filterQuality: detailView ? FilterQuality.medium : FilterQuality.low,
                cacheWidth: pixelWidth,
                cacheHeight: pixelHeight,
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

  double? _layoutWidth(BuildContext context) {
    if (width == null) return null;
    if (width!.isFinite) return width;
    return MediaQuery.sizeOf(context).width;
  }

  int? _targetPixelWidth(double? layoutWidth, double dpr, bool detail) {
    if (layoutWidth == null) return detail ? 960 : 320;
    final px = (layoutWidth * dpr).ceil();
    if (detail) return px.clamp(320, 1200);
    return px.clamp(96, 480);
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
