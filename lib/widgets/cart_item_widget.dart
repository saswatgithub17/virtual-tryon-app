// lib/widgets/cart_item_widget.dart
// Cart Item Widget

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:virtual_tryon_app/features/cart/data/models/cart_model.dart';
import 'package:virtual_tryon_app/core/network/api_config.dart';
import 'package:virtual_tryon_app/core/theme/app_theme.dart';
import 'package:virtual_tryon_app/core/utils/app_config.dart';

class CartItemWidget extends StatelessWidget {
  final CartItem item;
  final VoidCallback? onRemove;
  final VoidCallback? onIncrease;
  final VoidCallback? onDecrease;
  final Function(int)? onQuantityChanged;

  const CartItemWidget({
    super.key,
    required this.item,
    this.onRemove,
    this.onIncrease,
    this.onDecrease,
    this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            _buildImage(),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    item.dress.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Size
                  Text(
                    'Size: ${item.selectedSize}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Price
                  Text(
                    AppConfig.formatPrice(item.dress.price),
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Quantity Controls & Remove Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Quantity Controls
                      _buildQuantityControls(),

                      // Remove Button
                      if (onRemove != null)
                        IconButton(
                          onPressed: onRemove,
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppTheme.errorColor,
                          ),
                          tooltip: 'Remove from cart',
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

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: ApiConfig.getUploadUrl(item.dress.imageUrl),
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 80,
          height: 80,
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: 80,
          height: 80,
          color: Colors.grey[200],
          child: const Icon(Icons.error, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildQuantityControls() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrease Button
          _buildQuantityButton(
            icon: Icons.remove,
            onPressed: item.quantity > 1 ? onDecrease : null,
          ),

          // Quantity Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              item.quantity.toString(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Increase Button
          _buildQuantityButton(
            icon: Icons.add,
            onPressed:
                item.quantity < AppConfig.maxCartQuantity ? onIncrease : null,
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 20,
          color: onPressed != null ? AppTheme.primaryColor : Colors.grey,
        ),
      ),
    );
  }
}

// Compact version for smaller displays
class CartItemCompact extends StatelessWidget {
  final CartItem item;
  final VoidCallback? onRemove;

  const CartItemCompact({
    super.key,
    required this.item,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: ApiConfig.getUploadUrl(item.dress.imageUrl),
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        ),
      ),
      title: Text(
        item.dress.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text('Size: ${item.selectedSize} × ${item.quantity}'),
      trailing: onRemove != null
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: onRemove,
            )
          : Text(
              AppConfig.formatPriceShort(item.subtotal),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
