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
      productNameOneLine: json['product_name_one_line'] == true || json['product_name_one_line'] == 1,
      productsPerRowDesktop: int.tryParse(json['products_per_row_desktop']?.toString() ?? '') ?? 6,
      currencySymbol: json['currency_symbol']?.toString() ?? 'Rs.',
      showCarouselArrows: json['show_carousel_arrows'] == true || json['show_carousel_arrows'] == 1,
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

  const HeroBanner({required this.id, this.title, required this.imageUrl, this.linkUrl, required this.sortOrder, required this.isActive});

  factory HeroBanner.fromJson(Map<String, dynamic> json) => HeroBanner(
        id: int.parse(json['id'].toString()),
        title: json['title']?.toString(),
        imageUrl: json['image_url']?.toString() ?? '',
        linkUrl: json['link_url']?.toString(),
        sortOrder: int.tryParse(json['sort_order']?.toString() ?? '') ?? 0,
        isActive: json['is_active'] == true || json['is_active'] == 1,
      );
}
