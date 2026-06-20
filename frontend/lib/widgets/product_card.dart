import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import '../utils/price_formatter.dart';
import 'package:provider/provider.dart';
import '../providers/ui_settings_provider.dart';

class HoverProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;

  const HoverProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  State<HoverProductCard> createState() => _HoverProductCardState();
}

class _HoverProductCardState extends State<HoverProductCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final uiSettings = context.watch<UiSettingsProvider>().settings;
    final width = MediaQuery.of(context).size.width;
    final isCompactCard = width < 900;
    final badgeInset = isCompactCard ? 8.0 : 12.0;
    final badgeHorizontalPadding = isCompactCard ? 6.0 : 8.0;
    final badgeVerticalPadding = isCompactCard ? 3.0 : 4.0;
    final imagePadding = isCompactCard ? 8.0 : 10.0;
    final detailsPadding = isCompactCard
        ? const EdgeInsets.fromLTRB(10, 7, 10, 9)
        : const EdgeInsets.fromLTRB(12, 8, 12, 10);
    final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppTheme.textMuted,
          fontWeight: FontWeight.w600,
          fontSize: isCompactCard ? 10 : null,
          letterSpacing: isCompactCard ? 0.8 : 1.2,
        );
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: isCompactCard ? 13 : 14,
        );
    final originalPriceStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppTheme.textMuted,
          decoration: TextDecoration.lineThrough,
          fontSize: isCompactCard ? 11 : 13,
        );
    final sellingPriceStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          color: AppTheme.primaryBlue,
          fontWeight: FontWeight.bold,
          fontSize: isCompactCard ? 14 : 16,
        );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.borderLight,
              width: 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(26), // ~0.1 opacity
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              Expanded(
                flex: 7,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                      child: Container(
                        color: Colors.white,
                        padding: EdgeInsets.all(imagePadding),
                        child: CachedNetworkImage(
                          imageUrl: widget.product.imageUrl,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => Container(color: Colors.white),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
                      ),
                    ),
                    if (widget.product.isNew)
                      Positioned(
                        top: badgeInset,
                        left: badgeInset,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: badgeHorizontalPadding, vertical: badgeVerticalPadding),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'NEW ARRIVAL',
                            style: TextStyle(color: Colors.white, fontSize: isCompactCard ? 9 : 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    if (widget.product.isOnSale)
                      Positioned(
                        top: badgeInset,
                        left: badgeInset,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: badgeHorizontalPadding, vertical: badgeVerticalPadding),
                          decoration: BoxDecoration(
                            color: AppTheme.accentOrange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'SALE',
                            style: TextStyle(color: Colors.white, fontSize: isCompactCard ? 9 : 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    // Hover Action (Add to cart overlay)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: AnimatedOpacity(
                        opacity: _isHovered ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          color: Colors.white.withAlpha(230), // ~0.9 opacity
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.shopping_cart_checkout, size: 16, color: AppTheme.primaryBlue),
                              const SizedBox(width: 6),
                              Text(
                                'Add to Cart',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.primaryBlue,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Details Section
              Expanded(
                flex: 3,
                child: Padding(
                  padding: detailsPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.product.subtitle,
                        style: subtitleStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.product.title,
                        style: titleStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              formatPrice(widget.product.originalPrice, currencySymbol: uiSettings.currencySymbol),
                              style: originalPriceStyle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              formatPrice(widget.product.price, currencySymbol: uiSettings.currencySymbol),
                              style: sellingPriceStyle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
