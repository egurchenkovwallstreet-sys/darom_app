import 'package:flutter/material.dart';
import 'package:darom_app/theme/app_colors.dart';
import 'package:darom_app/theme/darom_decorations.dart';

import '../models/listing.dart';
import '../services/listings_api.dart';
import '../utils/founder_listing_style.dart';
import '../widgets/keyboard_inset_padding.dart';
import '../widgets/listing_photo_image.dart';
import '../widgets/midnight_glow_screen.dart';
import 'listing_screen.dart';

class SearchScreen extends StatefulWidget {
  final String phoneNumber;
  final String? currentUserId;
  final double lat;
  final double lng;
  final bool inShell;

  const SearchScreen({
    super.key,
    required this.phoneNumber,
    this.currentUserId,
    required this.lat,
    required this.lng,
    this.inShell = false,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ListingsApi _api = ListingsApi();
  final TextEditingController _queryController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<Listing> _results = [];
  bool _isSearching = false;
  String? _error;
  String? _lastQuery;

  static const _fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(14)),
    borderSide: BorderSide.none,
  );

  @override
  void initState() {
    super.initState();
    if (!widget.inShell) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    _focusNode.dispose();
    _api.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final query = _queryController.text.trim();
    if (query.length < 2) {
      setState(() {
        _error = 'Введите минимум 2 символа';
        _results = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
      _lastQuery = query;
    });

    try {
      final items = await _api.search(
        query: query,
        lat: widget.lat,
        lng: widget.lng,
      );
      if (!mounted) return;
      setState(() {
        _results = items;
        _isSearching = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _results = [];
        _error = error is ListingsApiException
            ? error.message
            : 'Ошибка поиска — проверьте backend';
      });
    }
  }

  void _clearQuery() {
    _queryController.clear();
    setState(() {
      _results = [];
      _error = null;
      _lastQuery = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = KeyboardInsetPadding(child: SafeArea(child: _buildContent()));
    if (widget.inShell) return content;
    return MidnightGlowScreen(child: content);
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, widget.inShell ? 12 : 16, 20, 0),
          child: Row(
            children: [
              if (!widget.inShell) ...[
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.92),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: AppColors.accent),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              const Expanded(
                child: Text(
                  'Поиск',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
          child: TextField(
            controller: _queryController,
            focusNode: _focusNode,
            style: DaromDecorations.fieldText.copyWith(height: 1.25),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _runSearch(),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface.withOpacity(0.92),
              hintText: 'Название или описание...',
              hintStyle: TextStyle(
                color: AppColors.textPrimary.withOpacity(0.45),
                fontSize: 16,
              ),
              prefixIcon: const Icon(Icons.search, color: AppColors.accent),
              suffixIcon: _queryController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                      onPressed: _clearQuery,
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              enabledBorder: _fieldBorder,
              focusedBorder: _fieldBorder.copyWith(
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GestureDetector(
            onTap: _isSearching ? null : _runSearch,
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(DaromDecorations.buttonRadius),
                color: AppColors.primary,
              ),
              child: Center(
                child: _isSearching
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textPrimary,
                        ),
                      )
                    : const Text(
                        'Найти',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ),
        if (_lastQuery != null && !_isSearching && _error == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _results.isEmpty
                    ? 'По запросу «$_lastQuery» ничего не найдено'
                    : 'Найдено: ${_results.length}',
                style: TextStyle(
                  color: AppColors.accent.withOpacity(0.95),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final listing = _results[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ListingScreen(
                          listing: listing,
                          phoneNumber: widget.phoneNumber,
                          currentUserId: widget.currentUserId,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: FounderListingStyle.cardDecoration(
                      listing,
                      AppColors.accent,
                    ),
                    child: Row(
                      children: [
                        ListingPhotoImage(
                          url: listing.photoUrls.isNotEmpty
                              ? listing.photoUrls.first
                              : null,
                          width: 56,
                          height: 56,
                          borderRadius: 10,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                listing.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${listing.category} · ${listing.distanceKm} км',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textPrimary.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
