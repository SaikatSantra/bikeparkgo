import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/pandal.dart';
import '../services/location_service.dart';

class PandalSlider extends StatefulWidget {
  final List<Pandal> pandals;
  final Function(Pandal) onSelectPandal;

  const PandalSlider({
    super.key,
    required this.pandals,
    required this.onSelectPandal,
  });

  @override
  State<PandalSlider> createState() => _PandalSliderState();
}

class _PandalSliderState extends State<PandalSlider> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (widget.pandals.length <= 1) return;

    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % widget.pandals.length;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pandals.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🎪', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text(
                    'Famous Pandals (জনপ্রিয় মণ্ডপ)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB91C1C),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF15803D).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF15803D), width: 0.8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_done, size: 12, color: Color(0xFF16A34A)),
                    SizedBox(width: 4),
                    Text(
                      'Drive Managed',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Carousel Slider
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.pandals.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final pandal = widget.pandals[index];
              return _buildPandalCard(pandal, isDark);
            },
          ),
        ),

        const SizedBox(height: 8),

        // Dot Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.pandals.length, (index) {
            final isActive = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: isActive
                    ? const Color(0xFFF59E0B)
                    : (isDark ? Colors.white24 : Colors.black12),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPandalCard(Pandal pandal, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0x50F59E0B) : const Color(0xFFFDE68A),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.network(
                pandal.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF450A0A), const Color(0xFF1E1B4B)]
                          : [const Color(0xFF991B1B), const Color(0xFFD97706)],
                    ),
                  ),
                  child: const Center(
                    child: Text('🔱', style: TextStyle(fontSize: 48)),
                  ),
                ),
              ),
            ),

            // Gradient Tint Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.85),
                    ],
                  ),
                ),
              ),
            ),

            // Top Badges
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFF59E0B), width: 0.8),
                    ),
                    child: Text(
                      pandal.zone,
                      style: const TextStyle(fontSize: 10, color: Color(0xFFFDE68A), fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB91C1C).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      pandal.crowd,
                      style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // Card Bottom Details & Action Buttons
            Positioned(
              bottom: 10,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    pandal.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${pandal.nameEn} • ${pandal.tag}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Color(0xFFE2E8F0)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Navigate to Pandal
                      Expanded(
                        child: SizedBox(
                          height: 32,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final ok = await LocationService.launchWalkingNavigation(
                                LatLng(pandal.latitude, pandal.longitude),
                              );
                              if (!ok && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Could not open Google Maps. Please install Google Maps or a browser.'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.navigation, size: 14),
                            label: const Text('Walk Here', style: TextStyle(fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // View on OpenStreetMap
                      Expanded(
                        child: SizedBox(
                          height: 32,
                          child: OutlinedButton.icon(
                            onPressed: () => widget.onSelectPandal(pandal),
                            icon: const Icon(Icons.map, size: 14, color: Color(0xFFF59E0B)),
                            label: const Text('Show Map', style: TextStyle(fontSize: 11, color: Colors.white)),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.black.withOpacity(0.4),
                              side: const BorderSide(color: Color(0xFFF59E0B), width: 1),
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
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
