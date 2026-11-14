import 'package:flutter/material.dart';
import 'package:darom_app/theme/app_colors.dart';

import 'listing_photo_image.dart';

class ListingPhotoGallery extends StatefulWidget {
  const ListingPhotoGallery({
    super.key,
    required this.urls,
  });

  final List<String> urls;

  @override
  State<ListingPhotoGallery> createState() => _ListingPhotoGalleryState();
}

class _ListingPhotoGalleryState extends State<ListingPhotoGallery> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int next) {
    if (next < 0 || next >= widget.urls.length) return;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Widget _squareFrame({required Widget child}) {
    return AspectRatio(
      aspectRatio: 1,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.urls;

    if (urls.isEmpty) {
      return _squareFrame(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.accent, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image, size: 72, color: AppColors.accent.withOpacity(0.5)),
              const SizedBox(height: 8),
              Text(
                'Нет фото',
                style: TextStyle(color: AppColors.textPrimary.withOpacity(0.7)),
              ),
            ],
          ),
        ),
      );
    }

    if (urls.length == 1) {
      return _squareFrame(
        child: ListingPhotoImage(
          url: urls.first,
          width: double.infinity,
          height: double.infinity,
          borderRadius: 20,
        ),
      );
    }

    return Column(
      children: [
        _squareFrame(
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: PageView.builder(
                  controller: _controller,
                  itemCount: urls.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => ListingPhotoImage(
                    url: urls[i],
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: 0,
                  ),
                ),
              ),
              Positioned(
                left: 4,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _navButton(Icons.chevron_left, () => _goTo(_index - 1)),
                ),
              ),
              Positioned(
                right: 4,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _navButton(Icons.chevron_right, () => _goTo(_index + 1)),
                ),
              ),
              Positioned(
                bottom: 10,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accent, width: 1.5),
                  ),
                  child: Text(
                    '${_index + 1} / ${urls.length}',
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            urls.length,
            (i) => Container(
              width: i == _index ? 10 : 7,
              height: i == _index ? 10 : 7,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == _index
                    ? AppColors.accent
                    : AppColors.accent.withOpacity(0.35),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: AppColors.textPrimary.withOpacity(0.75),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, color: AppColors.accent, size: 28),
        ),
      ),
    );
  }
}
