import 'package:flutter/material.dart';

import '../models/listing.dart';
import '../services/chats_api.dart';
import '../services/listings_api.dart';
import '../widgets/favorite_button.dart';
import '../widgets/listing_photo_gallery.dart';
import '../widgets/midnight_glow_screen.dart';
import '../widgets/primary_action_button.dart';
import 'add_listing_screen.dart';
import 'chat_thread_screen.dart';
import '../widgets/pickup_pack_offer_dialog.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/super_donor_offer_dialog.dart';

class ListingScreen extends StatefulWidget {
  final Listing listing;
  final String phoneNumber;
  final String? currentUserId;
  final bool isFavorite;

  const ListingScreen({
    super.key,
    required this.listing,
    required this.phoneNumber,
    this.currentUserId,
    this.isFavorite = false,
  });

  @override
  State<ListingScreen> createState() => _ListingScreenState();
}

class _ListingScreenState extends State<ListingScreen> {
  final ListingsApi _api = ListingsApi();
  final ChatsApi _chatsApi = ChatsApi();
  late Listing _listing;
  bool _isBusy = false;
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _listing = widget.listing;
    _isFavorite = widget.isFavorite;
  }

  @override
  void dispose() {
    _api.dispose();
    _chatsApi.dispose();
    super.dispose();
  }

  bool get _isOwner =>
      widget.currentUserId != null && widget.currentUserId == _listing.ownerId;

  Future<void> _runAction(Future<Listing> Function() action, String success) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final updated = await action();
      if (!mounted) return;
      setState(() => _listing = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success), backgroundColor: const Color(0xFF00BFFF)),
      );
    } catch (error) {
      if (!mounted) return;
      if (error is ListingLimitException) {
        setState(() => _isBusy = false);
        final activated = await showSuperDonorOfferDialog(
          context,
          limitInfo: error.limitInfo,
          phoneNumber: widget.phoneNumber,
        );
        if (activated == true && mounted) {
          await _runAction(action, success);
        }
        return;
      }
      if (error is PickupLimitException) {
        setState(() => _isBusy = false);
        final activated = await showPickupPackOfferDialog(
          context,
          limitInfo: error.limitInfo,
          phoneNumber: widget.phoneNumber,
        );
        if (activated == true && mounted) {
          await _runAction(action, success);
        }
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'), backgroundColor: const Color(0xFFFF5722)),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _markGiven() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final result = await _api.markGivenWithDeal(
        listingId: _listing.id,
        phone: widget.phoneNumber,
      );
      if (!mounted) return;
      setState(() => _listing = result.listing);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Сделка завершена!'),
          backgroundColor: Color(0xFF00BFFF),
        ),
      );
      final deal = result.deal;
      if (deal != null && mounted) {
        await showRatingDialog(
          context,
          dealId: deal.id,
          counterpartyName: deal.counterpartyName,
          phoneNumber: widget.phoneNumber,
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'), backgroundColor: const Color(0xFFFF5722)),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _reportListing() async {
    if (_isBusy || _isOwner) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF001F3F),
        title: const Text('Пожаловаться?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Жалоба на объявление «${_listing.title}». После 3 жалоб оно будет скрыто.',
          style: TextStyle(color: Colors.white.withOpacity(0.85)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Пожаловаться', style: TextStyle(color: Color(0xFFFF5722))),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isBusy = true);
    try {
      final result = await _api.reportListing(
        listingId: _listing.id,
        phone: widget.phoneNumber,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: const Color(0xFF00BFFF)),
      );
      if (result.hidden) {
        Navigator.pop(context);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'), backgroundColor: const Color(0xFFFF5722)),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _deleteListing() async {
    if (_isBusy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF001F3F),
        title: const Text('Удалить объявление?', style: TextStyle(color: Colors.white)),
        content: Text(
          '«${_listing.title}» будет скрыто из ленты. Это действие нельзя отменить.',
          style: TextStyle(color: Colors.white.withOpacity(0.85)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить', style: TextStyle(color: Color(0xFFFF5722))),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isBusy = true);
    try {
      await _api.deleteListing(
        listingId: _listing.id,
        phone: widget.phoneNumber,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Объявление удалено'),
          backgroundColor: Color(0xFF00BFFF),
        ),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'), backgroundColor: const Color(0xFFFF5722)),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _editListing() async {
    final updated = await Navigator.push<Listing>(
      context,
      MaterialPageRoute(
        builder: (context) => AddListingScreen(
          phoneNumber: widget.phoneNumber,
          editingListing: _listing,
        ),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _listing = updated);
    }
  }

  Future<void> _writeToOwner() async {
    if (_isBusy || _isOwner) return;

    setState(() => _isBusy = true);
    try {
      final conversation = await _chatsApi.startConversation(
        phone: widget.phoneNumber,
        listingId: _listing.id,
      );
      if (!mounted) return;
      setState(() => _isBusy = false);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatThreadScreen(
            phoneNumber: widget.phoneNumber,
            currentUserId: widget.currentUserId,
            conversation: conversation,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error is ChatsApiException ? error.message : '$error'),
          backgroundColor: const Color(0xFFFF5722),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MidnightGlowScreen(
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Center(
              child: FractionallySizedBox(
                widthFactor: 0.8,
                child: ListingPhotoGallery(urls: _listing.photoUrls),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_listing.isReserved) _buildStatusBadge(),
                  Text(
                    _listing.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTags(),
                  const SizedBox(height: 20),
                  _buildDescription(),
                  const SizedBox(height: 20),
                  _buildAuthor(),
                  const SizedBox(height: 24),
                ],
              ),
            )),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context, _listing),
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: const Color(0xFF001F3F).withOpacity(0.85),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF00BFFF), width: 2),
              ),
              child: const Icon(Icons.arrow_back, color: Color(0xFF00BFFF)),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              _listing.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFFFFF),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!_isOwner && _listing.status != 'given' && _listing.status != 'hidden')
            GestureDetector(
              onTap: _reportListing,
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFF001F3F).withOpacity(0.85),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFF5722).withOpacity(0.7), width: 2),
                ),
                child: const Icon(Icons.flag_outlined, color: Color(0xFFFF5722), size: 22),
              ),
            ),
          if (!_isOwner)
            FavoriteButton(
              listingId: _listing.id,
              phoneNumber: widget.phoneNumber,
              isFavorite: _isFavorite,
              onChanged: (value) => setState(() => _isFavorite = value),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF9E9E9E).withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF9E9E9E)),
      ),
      child: Text(
        _listing.statusLabel,
        style: const TextStyle(
          color: Color(0xFF9E9E9E),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTags() {
    return Row(
      children: [
        _tag(_listing.category, const Color(0xFF00BFFF)),
        const SizedBox(width: 8),
        _tag(_listing.subcategory, const Color(0xFF008C8C)),
      ],
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildDescription() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF001F3F).withOpacity(0.85),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF00BFFF), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Описание',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00BFFF),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _listing.description,
            style: const TextStyle(fontSize: 15, color: Color(0xFFFFFFFF), height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthor() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF001F3F).withOpacity(0.85),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF008C8C), width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFF00BFFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _listing.authorName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
                Text(
                  '${_listing.authorLevel} • ${_listing.authorRating} ★',
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFFFFFFFF).withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF001F3F).withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        border: Border(top: BorderSide(color: const Color(0xFF00BFFF).withOpacity(0.3), width: 2)),
      ),
      child: _isBusy
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(color: Color(0xFF00BFFF)),
              ),
            )
          : _buildActionButtons(),
    );
  }

  Widget _buildActionButtons() {
    const ownerSecondaryButtonHeight = 44.0;
    const ownerSecondaryButtonFontSize = 14.0;
    const ownerSecondaryButtonRadius = 22.0;

    if (_isOwner && _listing.status == 'reserved') {
      return Column(
        children: [
          PrimaryActionButton(
            label: 'Отдал',
            height: 54,
            fontSize: 17,
            borderRadius: 27,
            gradientColors: PrimaryActionButton.successGradient,
            shadowColor: const Color(0xFF4CAF50),
            onPressed: _markGiven,
          ),
          const SizedBox(height: 10),
          PrimaryActionButton(
            label: 'Активировать повторно',
            height: 54,
            fontSize: 17,
            borderRadius: 27,
            gradientColors: PrimaryActionButton.warningGradient,
            shadowColor: const Color(0xFFFFC107),
            onPressed: () => _runAction(
              () => _api.reactivate(listingId: _listing.id, phone: widget.phoneNumber),
              'Объявление снова активно',
            ),
          ),
          const SizedBox(height: 10),
          PrimaryActionButton(
            label: 'Редактировать',
            height: ownerSecondaryButtonHeight,
            fontSize: ownerSecondaryButtonFontSize,
            borderRadius: ownerSecondaryButtonRadius,
            gradientColors: PrimaryActionButton.primaryShortGradient,
            onPressed: _editListing,
          ),
          const SizedBox(height: 10),
          PrimaryActionButton(
            label: 'Удалить объявление',
            height: ownerSecondaryButtonHeight,
            fontSize: ownerSecondaryButtonFontSize,
            borderRadius: ownerSecondaryButtonRadius,
            gradientColors: PrimaryActionButton.dangerGradient,
            onPressed: _deleteListing,
          ),
        ],
      );
    }

    if (_isOwner && _listing.isActive) {
      return Column(
        children: [
          PrimaryActionButton(
            label: 'Редактировать',
            height: ownerSecondaryButtonHeight,
            fontSize: ownerSecondaryButtonFontSize,
            borderRadius: ownerSecondaryButtonRadius,
            gradientColors: PrimaryActionButton.primaryShortGradient,
            onPressed: _editListing,
          ),
          const SizedBox(height: 10),
          PrimaryActionButton(
            label: 'Удалить объявление',
            height: ownerSecondaryButtonHeight,
            fontSize: ownerSecondaryButtonFontSize,
            borderRadius: ownerSecondaryButtonRadius,
            gradientColors: PrimaryActionButton.dangerGradient,
            onPressed: _deleteListing,
          ),
        ],
      );
    }

    if (!_isOwner && _listing.isActive) {
      return PrimaryActionButton(
        label: 'Написать владельцу',
        height: 54,
        fontSize: 17,
        borderRadius: 27,
        onPressed: _writeToOwner,
      );
    }

    if (!_isOwner && _listing.isReserved) {
      return PrimaryActionButton(
        label: 'Открыть чат',
        height: 54,
        fontSize: 17,
        borderRadius: 27,
        gradientColors: PrimaryActionButton.tealGradient,
        onPressed: _writeToOwner,
      );
    }

    return Text(
      _listing.isReserved ? 'Объявление забронировано' : 'Объявление недоступно',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: const Color(0xFFFFFFFF).withOpacity(0.7),
        fontSize: 16,
      ),
    );
  }
}
