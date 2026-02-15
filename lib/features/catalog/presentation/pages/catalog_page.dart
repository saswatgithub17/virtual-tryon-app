import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_config.dart';
import 'package:virtual_tryon_app/features/catalog/data/models/dress_model.dart';
import '../controllers/catalog_controller.dart';
import '../../../cart/presentation/cart_controller.dart';
import '../../../../core/router/app_router.dart';

@RoutePage()
class CatalogPage extends ConsumerStatefulWidget {
  const CatalogPage({super.key});

  @override
  ConsumerState<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends ConsumerState<CatalogPage> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedNavIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryTabs(),
          Expanded(child: _buildDressGrid()),
        ],
      ),
      floatingActionButton: _buildTryOnFAB(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        AppConfig.appName,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        Consumer(
          builder: (context, ref, child) {
            final cartItems = ref.watch(cartControllerProvider);
            final itemCount = cartItems.length;
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  onPressed: () => context.router.push(const CartRoute()),
                ),
                if (itemCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.secondaryColor,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        itemCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search dresses...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    ref
                        .read(catalogControllerProvider.notifier)
                        .searchDresses('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (value) {
          // Debounce logic
          ref.read(catalogControllerProvider.notifier).searchDresses(value);
        },
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: AppConfig.categories.length,
        itemBuilder: (context, index) {
          final category = AppConfig.categories[index];
          final selectedCategory =
              ref.watch(catalogControllerProvider.notifier).selectedCategory;
          final isSelected = selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                ref
                    .read(catalogControllerProvider.notifier)
                    .setCategory(category);
              },
              selectedColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDressGrid() {
    final catalogAsync = ref.watch(catalogControllerProvider);

    return catalogAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(err.toString(), textAlign: TextAlign.center),
            ElevatedButton(
              onPressed: () => ref.refresh(catalogControllerProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (dresses) {
        if (dresses.isEmpty) {
          return const Center(
            child: Text(AppConfig.emptySearchMessage),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: dresses.length,
          itemBuilder: (context, index) => _buildDressCard(dresses[index]),
        );
      },
    );
  }

  Widget _buildDressCard(Dress dress) {
    return GestureDetector(
      onTap: () {
        // Navigate to detail
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: ApiConfig.getUploadUrl(dress.imageUrl),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dress.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 2),
                  const SizedBox(height: 4),
                  Text(AppConfig.formatPriceShort(dress.price),
                      style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTryOnFAB() {
    return FloatingActionButton.extended(
      onPressed: () => context.router.push(const TryOnRoute()),
      backgroundColor: AppTheme.secondaryColor,
      icon: const Icon(Icons.camera_alt),
      label: const Text('Try On'),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedNavIndex,
      onTap: (index) {
        setState(() => _selectedNavIndex = index);
        if (index == 1) context.router.push(const TryOnRoute());
        if (index == 2) context.router.push(const CartRoute());
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'Try On'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
      ],
      selectedItemColor: AppTheme.primaryColor,
    );
  }
}
