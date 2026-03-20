import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:video_player/video_player.dart';
import 'package:virtual_tryon_app/core/router/app_router.dart';

@RoutePage()
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Video player
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;
  bool _videoStarted = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      _videoController = VideoPlayerController.asset('lib/assets/videos/demo.mp4');
      await _videoController!.initialize();
      _videoController!.setVolume(0); // muted
      _videoController!.setLooping(false);
      if (mounted) setState(() => _videoInitialized = true);
    } catch (_) {
      // Video not found or failed — handled gracefully in the UI
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _goToApp() async {
    _videoController?.pause();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    if (mounted) context.router.replace(const CatalogRoute());
  }

  void _startVideo() {
    if (_videoController == null || !_videoInitialized) return;
    setState(() => _videoStarted = true);
    _videoController!.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip button (top-right) ──────────────────────────────────────
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 20, 0),
                child: GestureDetector(
                  onTap: _goToApp,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),

            // ── PageView ─────────────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildPage1(),
                  _buildPage2(),
                ],
              ),
            ),

            // ── Page indicator + Next / Get Started button ───────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: 2,
                    effect: ExpandingDotsEffect(
                      activeDotColor: const Color(0xFF6B4CE6),
                      dotColor: Colors.grey[300]!,
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage == 0) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _goToApp();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B4CE6),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        _currentPage == 0 ? 'Next  →' : 'Start Shopping  🛍️',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Page 1: How to use the app ────────────────────────────────────────────

  Widget _buildPage1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B4CE6), Color(0xFF9D4EDD)],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.checkroom_rounded,
                  size: 44, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'Welcome to AuraTry',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Virtual Try-On · Pantaloons',
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  letterSpacing: 1),
            ),
          ),
          const SizedBox(height: 28),

          // Feature tiles
          _featureTile(
            icon: Icons.style_rounded,
            color: const Color(0xFF6B4CE6),
            title: 'Browse Dresses',
            desc:
                'Explore 21+ dresses for Men & Women across all categories — Casual, Formal, Party, Beach and more.',
          ),
          _featureTile(
            icon: Icons.filter_alt_rounded,
            color: const Color(0xFFE91E8C),
            title: 'Filter by Gender & Category',
            desc:
                'Use the Men / Women / All filter and category chips to quickly find exactly what you\'re looking for.',
          ),
          _featureTile(
            icon: Icons.camera_alt_rounded,
            color: const Color(0xFF00BCD4),
            title: 'Virtual Try-On with AI',
            desc:
                'Upload your photo or take a live selfie. Our AI (IDM-VTON) will show how the dress looks on you — before you buy.',
          ),
          _featureTile(
            icon: Icons.shopping_cart_rounded,
            color: const Color(0xFF4CAF50),
            title: 'Add to Cart & Checkout',
            desc:
                'Select your size (with live stock counts), add to cart, and pay securely via Stripe or UPI.',
          ),
        ],
      ),
    );
  }

  // ─── Page 2: More features + Demo video ────────────────────────────────────

  Widget _buildPage2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE91E8C), Color(0xFFFF6B9D)],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.play_circle_fill_rounded,
                  size: 44, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'See It In Action',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Watch how AuraTry works',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ),
          const SizedBox(height: 24),

          // More features
          _featureTile(
            icon: Icons.receipt_long_rounded,
            color: const Color(0xFFFFA000),
            title: 'PDF Receipts',
            desc:
                'Every order comes with a professional PDF receipt — download or share it instantly after payment.',
          ),
          _featureTile(
            icon: Icons.inventory_2_rounded,
            color: const Color(0xFFFF5722),
            title: 'Live Stock Counts',
            desc:
                'See exactly how many units are left per size. Low-stock sizes show urgent alerts so you never miss out.',
          ),
          _featureTile(
            icon: Icons.star_rounded,
            color: const Color(0xFF9C27B0),
            title: 'Suggestions',
            desc:
                'The ✨ Suggestion tab shows the most tried-on dresses — curated by real users just like you.',
          ),

          const SizedBox(height: 8),

          // ── Demo video section ──────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Video label
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE91E8C).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.play_circle_outline,
                            color: Color(0xFFE91E8C), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Demo Video',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            Text(
                              'See the full app walkthrough (muted)',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Video player or Start button
                if (_videoStarted && _videoInitialized)
                  _buildVideoPlayer()
                else
                  _buildStartVideoButton(),

                const SizedBox(height: 4),
              ],
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ─── Start video button ────────────────────────────────────────────────────

  Widget _buildStartVideoButton() {
    return GestureDetector(
      onTap: _startVideo,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 180,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6B4CE6), Color(0xFFE91E8C)],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(height: 14),
            const Text(
              '▶  Start Demo Video',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _videoInitialized
                  ? 'Tap to play · Muted'
                  : 'Loading video...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Inline video player ───────────────────────────────────────────────────

  Widget _buildVideoPlayer() {
    final ctrl = _videoController!;
    return Column(
      children: [
        // Video frame
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.black,
          ),
          clipBehavior: Clip.hardEdge,
          child: AspectRatio(
            aspectRatio: ctrl.value.aspectRatio,
            child: VideoPlayer(ctrl),
          ),
        ),
        const SizedBox(height: 10),
        // Controls row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // Play / Pause
              ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: ctrl,
                builder: (_, value, __) {
                  return GestureDetector(
                    onTap: () {
                      value.isPlaying ? ctrl.pause() : ctrl.play();
                      setState(() {});
                    },
                    child: Icon(
                      value.isPlaying
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_filled_rounded,
                      color: const Color(0xFF6B4CE6),
                      size: 32,
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              // Progress bar
              Expanded(
                child: ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: ctrl,
                  builder: (_, value, __) {
                    final total = value.duration.inMilliseconds.toDouble();
                    final pos   = value.position.inMilliseconds
                        .toDouble()
                        .clamp(0.0, total);
                    return SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 12),
                        trackHeight: 3,
                      ),
                      child: Slider(
                        value: total > 0 ? pos / total : 0.0,
                        activeColor: const Color(0xFF6B4CE6),
                        inactiveColor: Colors.grey[300],
                        onChanged: (v) {
                          ctrl.seekTo(
                            Duration(
                                milliseconds: (v * total).round()),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              // Muted badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.volume_off, size: 12, color: Colors.grey),
                    SizedBox(width: 3),
                    Text('Muted',
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ─── Feature tile ──────────────────────────────────────────────────────────

  Widget _featureTile({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 3),
                Text(desc,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B6B80),
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}