import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_config.dart';
import '../../data/models/dress_model.dart';
import '../controllers/catalog_controller.dart';
import '../../../../core/router/app_router.dart';
import '../../../../widgets/bottom_nav_bar.dart';

@RoutePage()
class CatalogPage extends ConsumerStatefulWidget {
  const CatalogPage({super.key});

  @override
  ConsumerState<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends ConsumerState<CatalogPage> {
  final TextEditingController _searchController = TextEditingController();

  // 5-tap admin secret on Home tab
  int _homeTapCount = 0;
  DateTime? _lastHomeTap;

  void _handleBottomNavTap(int index) {
    if (index == 0) {
      final now = DateTime.now();
      if (_lastHomeTap != null &&
          now.difference(_lastHomeTap!).inMilliseconds > 800) {
        _homeTapCount = 0;
      }
      _lastHomeTap = now;
      _homeTapCount++;
      if (_homeTapCount >= 5) {
        _homeTapCount = 0;
        _showAdminDialog();
      }
    } else if (index == 1) {
      context.router.push(const TryOnRoute());
    } else if (index == 2) {
      context.router.push(const CartRoute());
    }
  }

  void _showAdminDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Admin Access'),
          ],
        ),
        content: const Text('Open the Admin Dashboard?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.router.push(const AdminLoginRoute());
            },
            child: const Text('Go to Admin',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildGenderFilter(),
          _buildCategoryChips(),
          Expanded(child: _buildDressGrid()),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 0,
        onTap: _handleBottomNavTap,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'AuraTry : Pantaloons',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: AppTheme.primaryColor,
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search dresses, brands...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                    ref
                        .read(catalogControllerProvider.notifier)
                        .searchDresses('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        onChanged: (value) {
          setState(() {});
          ref.read(catalogControllerProvider.notifier).searchDresses(value);
        },
      ),
    );
  }

  // ─── Gender Filter Row ─────────────────────────────────────────────────────
  Widget _buildGenderFilter() {
    final selectedGender =
        ref.watch(catalogControllerProvider.notifier).selectedGender;

    final filters = [
      ('all', '✨  All', false),
      ('men', '👔  Men', false),
      ('women', '👗  Women', true),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: filters.map((f) {
          final isSelected = selectedGender == f.$1;
          final isWomen = f.$3;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () {
                  ref.read(catalogControllerProvider.notifier).setGender(f.$1);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: isWomen
                                ? [
                                    const Color(0xFFE91E8C),
                                    const Color(0xFFFF6B9D)
                                  ]
                                : [
                                    AppTheme.primaryColor,
                                    AppTheme.secondaryColor
                                  ],
                          )
                        : null,
                    color: isSelected ? null : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? null
                        : Border.all(color: Colors.grey[300]!),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: (isWomen
                                      ? Colors.pink
                                      : AppTheme.primaryColor)
                                  .withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      f.$2,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Category Chips ────────────────────────────────────────────────────────
  Widget _buildCategoryChips() {
    final selectedCategory =
        ref.watch(catalogControllerProvider.notifier).selectedCategory;

    final baseCategories =
        AppConfig.categories.where((c) => c != 'All').toList();
    final chips = <String>['All', 'Suggestion', ...baseCategories];

    return Container(
      color: Colors.white,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        itemBuilder: (context, index) {
          final category = chips[index];
          final isSelected = selectedCategory == category;
          final label = category == 'Suggestion' ? '✨ Suggestion' : category;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => ref
                  .read(catalogControllerProvider.notifier)
                  .setCategory(category),
              selectedColor: AppTheme.primaryColor,
              backgroundColor: Colors.grey[100],
              side: BorderSide(
                color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
              ),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          );
        },
      ),
    );
  }

  // ─── Dress Grid ────────────────────────────────────────────────────────────
  Widget _buildDressGrid() {
    final catalogAsync = ref.watch(catalogControllerProvider);
    return catalogAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text('Could not load dresses',
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => ref.refresh(catalogControllerProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (dresses) {
        if (dresses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 72, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('No dresses found',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600])),
                const SizedBox(height: 8),
                Text('Try a different filter',
                    style: TextStyle(color: Colors.grey[400])),
              ],
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.68,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: dresses.length,
          itemBuilder: (_, i) => _buildDressCard(dresses[i]),
        );
      },
    );
  }

  Widget _buildDressCard(Dress dress) {
    return GestureDetector(
      onTap: () => context.router.push(DressDetailRoute(dress: dress)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: CachedNetworkImage(
                      imageUrl: ApiConfig.getUploadUrl(dress.imageUrl),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (_, __) => Container(
                        color: Colors.grey[100],
                        child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey[100],
                        child: Icon(Icons.image_not_supported,
                            color: Colors.grey[400], size: 40),
                      ),
                    ),
                  ),
                  // Gender badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: (dress.gender == 'women'
                                ? const Color(0xFFE91E8C)
                                : AppTheme.primaryColor)
                            .withOpacity(0.88),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        dress.gender == 'women' ? '👗 Women' : '👔 Men',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  // Rating
                  if ((dress.averageRating ?? 0) > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 10),
                            const SizedBox(width: 2),
                            Text(
                              dress.averageRating!.toStringAsFixed(1),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dress.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF1A1A2E)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${dress.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (dress.category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            dress.category!,
                            style: const TextStyle(
                              fontSize: 8,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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