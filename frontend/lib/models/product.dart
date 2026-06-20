import 'dart:convert';

class Product {
  final String id;
  final String title;
  final String subtitle;
  final double price;
  final double originalPrice;
  final String imageUrl;
  final bool isNew;
  final bool isOnSale;
  final List<String> images;
  final Map<String, String> specifications;
  final String easyPayment;
  final String enquiry;
  final int? deliveryOptionId;
  final double weight;
  final int? categoryId;
  final String categoryName;

  Product({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.originalPrice,
    required this.imageUrl,
    this.isNew = false,
    this.isOnSale = false,
    this.images = const [],
    this.specifications = const {},
    this.easyPayment = '',
    this.enquiry = '',
    this.deliveryOptionId,
    this.weight = 1.0,
    this.categoryId,
    this.categoryName = '',
  });

  List<String> get galleryImages {
    final urls = <String>[];
    for (final url in [imageUrl, ...images]) {
      final trimmed = url.trim();
      if (trimmed.isNotEmpty && !urls.contains(trimmed)) {
        urls.add(trimmed);
      }
    }
    return urls;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    // Handle cases where PHP might return an empty array [] instead of an empty object {}
    Map<String, String> parsedSpecs = {};
    if (json['specifications'] is Map) {
      (json['specifications'] as Map).forEach((key, value) {
        parsedSpecs[key.toString()] = value?.toString() ?? '';
      });
    } else if (json['specifications'] is String) {
       try {
         final decoded = jsonDecode(json['specifications']);
         if (decoded is Map) {
           decoded.forEach((key, value) {
             parsedSpecs[key.toString()] = value?.toString() ?? '';
           });
         }
       } catch (_) {}
    }

    List<String> parsedImages = [];
    if (json['images'] is List) {
      parsedImages = (json['images'] as List).map((e) => e?.toString().trim() ?? '').where((url) => url.isNotEmpty).toList();
    } else if (json['images'] is String) {
       try {
         final decoded = jsonDecode(json['images']);
         if (decoded is List) {
           parsedImages = decoded.map((e) => e?.toString().trim() ?? '').where((url) => url.isNotEmpty).toList();
         }
       } catch (_) {}
    }

    return Product(
      id: json['id'].toString(),
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      originalPrice: double.tryParse(json['original_price'].toString()) ?? 0.0,
      imageUrl: json['image_url']?.toString().trim() ?? '',
      isNew: json['is_new'] == 1 || json['is_new'] == true,
      isOnSale: json['is_on_sale'] == 1 || json['is_on_sale'] == true,
      images: parsedImages,
      specifications: parsedSpecs,
      easyPayment: json['easy_payment']?.toString() ?? '',
      enquiry: json['enquiry']?.toString() ?? '',
      deliveryOptionId: json['delivery_option_id'] != null ? int.tryParse(json['delivery_option_id'].toString()) : null,
      weight: double.tryParse(json['weight'].toString()) ?? 1.0,
      categoryId: json['category_id'] != null ? int.tryParse(json['category_id'].toString()) : null,
      categoryName: (json['category'] != null && json['category'] is Map) 
          ? (json['category']['title']?.toString() ?? '') 
          : '',
    );
  }
}

final List<Product> dummyProducts = [
  Product(
    id: '1',
    title: 'Hyperion Z-Fold Ultra',
    subtitle: 'SMARTPHONE',
    price: 1299.0,
    originalPrice: 1499.0,
    imageUrl: 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?q=80&w=800&auto=format&fit=crop',
    isNew: true,
    images: [
      'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?q=80&w=800&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1598327105666-5b89351cb315?q=80&w=800&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1525598912003-663126343e1f?q=80&w=800&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1601784551446-20c9e07cdbc0?q=80&w=800&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1592899677977-9c10ca588bb3?q=80&w=800&auto=format&fit=crop',
    ],
    specifications: {
      'Type': 'Foldable Smartphone',
      'Processor': 'Snapdragon 8 Gen 3',
      'RAM': '12GB LPDDR5X',
      'Storage': '512GB UFS 4.0',
      'Display (Main)': '7.6" AMOLED, 120Hz',
      'Display (Cover)': '6.2" AMOLED, 120Hz',
      'Camera': '50MP + 12MP + 10MP',
      'Battery': '4400 mAh',
    },
    easyPayment: 'Pay in 12 monthly installments with 0% interest using selected credit cards.',
    enquiry: 'For bulk orders and corporate enquiries, please contact our B2B sales team at sales@hellohomes.com or call 1-800-555-0199.',
  ),
  Product(
    id: '2',
    title: 'TitanBook Pro 16"',
    subtitle: 'LAPTOP',
    price: 2499.0,
    originalPrice: 2499.0,
    imageUrl: 'https://images.unsplash.com/photo-1611186871348-b1ce696e52c9?q=80&w=800&auto=format&fit=crop',
    images: [
      'https://images.unsplash.com/photo-1611186871348-b1ce696e52c9?q=80&w=800&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?q=80&w=800&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1531297172868-9f1d1b53e8fc?q=80&w=800&auto=format&fit=crop',
    ],
    specifications: {
      'Processor': 'M3 Max 16-core CPU',
      'RAM': '32GB Unified Memory',
      'Storage': '1TB SSD',
      'Display': '16.2" Liquid Retina XDR',
    },
  ),
  Product(
    id: '3',
    title: 'OLED Cinema Pro Max',
    subtitle: 'SMART TV',
    price: 3199.0,
    originalPrice: 3500.0,
    imageUrl: 'https://images.unsplash.com/photo-1593359677879-a4bb92f829d1?q=80&w=800&auto=format&fit=crop',
    isOnSale: true,
  ),
  Product(
    id: '4',
    title: 'SonicSphere Wireless',
    subtitle: 'AUDIO',
    price: 349.0,
    originalPrice: 349.0,
    imageUrl: 'https://images.unsplash.com/photo-1618366712010-f4ae9c647dcb?q=80&w=800&auto=format&fit=crop',
  ),
];
