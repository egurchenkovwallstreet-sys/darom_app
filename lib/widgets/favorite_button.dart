import 'package:flutter/material.dart';

import '../services/favorites_api.dart';

class FavoriteButton extends StatefulWidget {
  const FavoriteButton({
    super.key,
    required this.listingId,
    required this.phoneNumber,
    this.isFavorite = false,
    this.size = 28,
    this.onChanged,
  });

  final String listingId;
  final String phoneNumber;
  final bool isFavorite;
  final double size;
  final ValueChanged<bool>? onChanged;

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  final FavoritesApi _api = FavoritesApi();
  late bool _isFavorite;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
  }

  @override
  void didUpdateWidget(covariant FavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorite != widget.isFavorite) {
      _isFavorite = widget.isFavorite;
    }
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_busy) return;

    setState(() => _busy = true);
    final next = !_isFavorite;

    try {
      if (next) {
        await _api.addFavorite(
          phone: widget.phoneNumber,
          listingId: widget.listingId,
        );
      } else {
        await _api.removeFavorite(
          phone: widget.phoneNumber,
          listingId: widget.listingId,
        );
      }
      if (!mounted) return;
      setState(() {
        _isFavorite = next;
        _busy = false;
      });
      widget.onChanged?.call(next);
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error is FavoritesApiException ? error.message : '$error'),
          backgroundColor: const Color(0xFFFF5722),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _busy ? null : _toggle,
      icon: _busy
          ? SizedBox(
              width: widget.size,
              height: widget.size,
              child: const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00BFFF)),
            )
          : Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? const Color(0xFFFF5722) : const Color(0xFF80DEEA),
              size: widget.size,
            ),
    );
  }
}
