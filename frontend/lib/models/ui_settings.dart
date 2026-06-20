import 'package:flutter/foundation.dart';

bool parseApiBool(dynamic value) {
  if (value == true || value == 1) return true;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' ||
        normalized == '1' ||
        normalized == 'yes' ||
        normalized == 'on';
  }
  return false;
}

class UiSettings {
  final bool productNameOneLine;
  final int productsPerRowDesktop;
  final String currencySymbol;
  final bool showCarouselArrows;

  const UiSettings({
    this.productNameOneLine = true,
    this.productsPerRowDesktop = 6,
    this.currencySymbol = 'Rs.',
    this.showCarouselArrows = true,
  });

  factory UiSettings.fromJson(Map<String, dynamic> json) {
    return UiSettings(
      productNameOneLine: parseApiBool(json['product_name_one_line']),
      productsPerRowDesktop:
          int.tryParse(json['products_per_row_desktop']?.toString() ?? '') ?? 6,
      currencySymbol: json['currency_symbol']?.toString() ?? 'Rs.',
      showCarouselArrows: parseApiBool(json['show_carousel_arrows']),
    );
  }

  Map<String, dynamic> toJson() => {
        'product_name_one_line': productNameOneLine,
        'products_per_row_desktop': productsPerRowDesktop,
        'currency_symbol': currencySymbol,
        'show_carousel_arrows': showCarouselArrows,
      };
}

class HeroBanner {
  final int id;
  final String? title;
  final String imageUrl;
  final String? linkUrl;
  final int sortOrder;
  final bool isActive;

  const HeroBanner({
    required this.id,
    this.title,
    required this.imageUrl,
    this.linkUrl,
    required this.sortOrder,
    required this.isActive,
  });

  HeroBanner copyWith({
    String? title,
    String? imageUrl,
    String? linkUrl,
    int? sortOrder,
    bool? isActive,
  }) =>
      HeroBanner(
        id: id,
        title: title ?? this.title,
        imageUrl: imageUrl ?? this.imageUrl,
        linkUrl: linkUrl ?? this.linkUrl,
        sortOrder: sortOrder ?? this.sortOrder,
        isActive: isActive ?? this.isActive,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'image_url': imageUrl,
        'link_url': linkUrl,
        'sort_order': sortOrder,
        'is_active': isActive,
      };

  factory HeroBanner.fromJson(Map<String, dynamic> json) => HeroBanner(
        id: int.parse(json['id'].toString()),
        title: json['title']?.toString(),
        imageUrl: json['image_url']?.toString() ?? '',
        linkUrl: json['link_url']?.toString(),
        sortOrder: int.tryParse(json['sort_order']?.toString() ?? '') ?? 0,
        isActive: parseApiBool(json['is_active'] ?? json['enabled']),
      );
}

class PromotionBanner {
  final int id;
  final bool isActive;
  final String title;
  final String subtitle;
  final String bannerImageUrl;
  final String productId;
  final String? productSlug;
  final String productUrl;
  final int? discountPercentage;
  final double? originalPrice;
  final double? discountedPrice;
  final DateTime? offerStartAt;
  final DateTime? offerEndAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PromotionBanner({
    required this.id,
    required this.isActive,
    required this.title,
    required this.subtitle,
    required this.bannerImageUrl,
    required this.productId,
    this.productSlug,
    required this.productUrl,
    this.discountPercentage,
    this.originalPrice,
    this.discountedPrice,
    this.offerStartAt,
    this.offerEndAt,
    this.createdAt,
    this.updatedAt,
  });

  bool get isCurrentlyActive {
    final now = DateTime.now().toUtc();
    final startAt = offerStartAt?.toUtc();
    final endAt = offerEndAt?.toUtc();
    final computedIsActive = isActive &&
        (startAt == null || !now.isBefore(startAt)) &&
        (endAt == null || now.isBefore(endAt));

    debugPrint(
      'PromotionBanner.isCurrentlyActive id=$id '
      'now_utc=${now.toIso8601String()} '
      'offer_start_at_utc=${startAt?.toIso8601String()} '
      'offer_end_at_utc=${endAt?.toIso8601String()} '
      'enabled=$isActive computed_isActive=$computedIsActive',
    );

    return computedIsActive;
  }

  Map<String, dynamic> toJson() => {
        'is_active': isActive,
        'enabled': isActive,
        'title': title,
        'subtitle': subtitle,
        'banner_image_url': bannerImageUrl,
        'product_id': productId,
        'product_slug': productSlug,
        'product_url': productUrl,
        'discount_percentage': discountPercentage,
        'original_price': originalPrice,
        'discounted_price': discountedPrice,
        'offer_start_at': offerStartAt?.toUtc().toIso8601String(),
        'offer_end_at': offerEndAt?.toUtc().toIso8601String(),
      };

  factory PromotionBanner.fromJson(Map<String, dynamic> json) => PromotionBanner(
        id: int.parse(json['id'].toString()),
        isActive: parseApiBool(json['is_active'] ?? json['enabled']),
        title: json['title']?.toString() ?? '',
        subtitle: json['subtitle']?.toString() ?? '',
        bannerImageUrl: json['banner_image_url']?.toString() ?? '',
        productId: json['product_id']?.toString() ?? '',
        productSlug: json['product_slug']?.toString(),
        productUrl: _parseProductUrl(json),
        discountPercentage:
            int.tryParse(json['discount_percentage']?.toString() ?? ''),
        originalPrice: double.tryParse(json['original_price']?.toString() ?? ''),
        discountedPrice:
            double.tryParse(json['discounted_price']?.toString() ?? ''),
        offerStartAt: DateTime.tryParse(json['offer_start_at']?.toString() ?? ''),
        offerEndAt: DateTime.tryParse(json['offer_end_at']?.toString() ?? ''),
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
        updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
      );

  static String _parseProductUrl(Map<String, dynamic> json) {
    final productUrl = json['product_url']?.toString().trim() ?? '';
    if (productUrl.isNotEmpty) return productUrl;

    final productSlug = json['product_slug']?.toString().trim() ?? '';
    if (productSlug.isNotEmpty) return '/product/$productSlug';

    return '/product/${json['product_id']}';
  }
}
