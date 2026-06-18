import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/listing.dart';
import '../services/listings_api.dart';
import '../widgets/midnight_glow_screen.dart';
import '../widgets/primary_action_button.dart';
import 'listing_screen.dart';

class MyListingsScreen extends StatefulWidget {
  final String phoneNumber;
  final String? currentUserId;

  const MyListingsScreen({
    super.key,
    required this.phoneNumber,
    this.currentUserId,
  });

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  final ListingsApi _api = ListingsApi();
  late Future<List<Listing>> _listingsFuture;

  @override
  void initState() {
    super.initState();
    _listingsFuture = _load();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<List<Listing>> _load() {
    return _api.fetchMine(phone: widget.phoneNumber);
  }

  void _retry() {
    setState(() {
      _listingsFuture = _load();
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'reserved':
        return const Color(0xFFFFC107);
      case 'given':
        return const Color(0xFF4CAF50);
      case 'hidden':
        return const Color(0xFF9E9E9E);
      default:
        return const Color(0xFF00BFFF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MidnightGlowScreen(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
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
                  const Expanded(
                    child: Text(
                      'Мои объявления',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Listing>>(
                future: _listingsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF00BFFF)),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_off, size: 48, color: Color(0xFF00BFFF)),
                            const SizedBox(height: 16),
                            Text(
                              snapshot.error.toString(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFFFFFFFF).withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 16),
                            PrimaryActionButton(
                              label: 'Повторить',
                              height: 48,
                              fontSize: 16,
                              borderRadius: 24,
                              gradientColors: PrimaryActionButton.primaryShortGradient,
                              onPressed: _retry,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final listings = (snapshot.data ?? [])
                      .where((listing) => listing.status != 'hidden')
                      .toList();

                  if (listings.isEmpty) {
                    return Center(
                      child: Text(
                        'У вас пока нет объявлений',
                        style: TextStyle(
                          fontSize: 16,
                          color: const Color(0xFFFFFFFF).withOpacity(0.7),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: listings.length,
                    itemBuilder: (context, index) {
                      final listing = listings[index];
                      final color = _statusColor(listing.status);

                      return GestureDetector(
                        onTap: () async {
                          final deleted = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ListingScreen(
                                listing: listing,
                                phoneNumber: widget.phoneNumber,
                                currentUserId: widget.currentUserId,
                              ),
                            ),
                          );
                          if (deleted == true && mounted) {
                            _retry();
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF001F3F).withOpacity(0.85),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: color, width: 2),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      listing.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFFFFFF),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${listing.category} · ${listing.subcategory}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: const Color(0xFFFFFFFF).withOpacity(0.6),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: color),
                                      ),
                                      child: Text(
                                        listing.statusLabel,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: color),
                            ],
                          ),
                        ),
                      )
                          .animate(delay: Duration(milliseconds: 80 * index))
                          .fadeIn(duration: 400.ms);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
