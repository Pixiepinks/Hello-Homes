List<ChildCategory> _parseChildCategories(Map<String, dynamic> json) {
  final rawChildren =
      json['child_categories'] ?? json['childCategories'] ?? json['children'];

  if (rawChildren is! List) {
    return const [];
  }

  return rawChildren
      .whereType<Map>()
      .map((item) => ChildCategory.fromJson(Map<String, dynamic>.from(item)))
      .toList();
}

class Brand {
  final String id;
  final String name;
  final String slug;
  final String logoUrl;
  final bool isActive;

  Brand({
    required this.id,
    required this.name,
    this.slug = '',
    this.logoUrl = '',
    this.isActive = true,
  });

  factory Brand.fromJson(Map<String, dynamic> json) => Brand(
    id: json['id'].toString(),
    name: json['name']?.toString() ?? '',
    slug: json['slug']?.toString() ?? '',
    logoUrl: json['logo_url']?.toString() ?? '',
    isActive: json['is_active'] == 1 || json['is_active'] == true,
  );
}

class ChildCategory {
  final String id;
  final int categoryId;
  final int subcategoryId;
  final String name;
  final String slug;
  final String imageUrl;
  final bool isActive;
  final int sortOrder;
  final List<ChildCategory> childCategories;

  ChildCategory({
    required this.id,
    required this.categoryId,
    required this.subcategoryId,
    required this.name,
    this.slug = '',
    this.imageUrl = '',
    this.isActive = true,
    this.sortOrder = 0,
    this.childCategories = const [],
  });

  factory ChildCategory.fromJson(Map<String, dynamic> json) => ChildCategory(
    id: json['id'].toString(),
    categoryId: int.tryParse(json['category_id']?.toString() ?? '') ?? 0,
    subcategoryId: int.tryParse(json['subcategory_id']?.toString() ?? '') ?? 0,
    name: json['name']?.toString() ?? '',
    slug: json['slug']?.toString() ?? '',
    imageUrl: json['image_url']?.toString() ?? '',
    isActive: json['is_active'] == 1 || json['is_active'] == true,
    sortOrder: int.tryParse(json['sort_order']?.toString() ?? '0') ?? 0,
    childCategories: _parseChildCategories(json),
  );
}

class Subcategory {
  final String id;
  final int categoryId;
  final String name;
  final String slug;
  final String imageUrl;
  final bool isActive;
  final int sortOrder;
  final List<ChildCategory> childCategories;

  Subcategory({
    required this.id,
    required this.categoryId,
    required this.name,
    this.slug = '',
    this.imageUrl = '',
    this.isActive = true,
    this.sortOrder = 0,
    this.childCategories = const [],
  });

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(
      id: json['id'].toString(),
      categoryId: int.tryParse(json['category_id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      sortOrder: int.tryParse(json['sort_order']?.toString() ?? '0') ?? 0,
      childCategories: _parseChildCategories(json),
    );
  }
}

class Category {
  final String id;
  final String title;
  final String slug;
  final String subtitle;
  final String imageUrl;
  final List<Subcategory> subcategories;
  final List<ChildCategory> childCategories;

  Category({
    required this.id,
    required this.title,
    this.slug = '',
    required this.subtitle,
    required this.imageUrl,
    this.subcategories = const [],
    this.childCategories = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'].toString(),
      title: (json['title'] ?? json['name'] ?? '').toString(),
      slug: json['slug']?.toString() ?? '',
      subtitle: json['subtitle'] ?? '',
      imageUrl: json['image_url'] ?? '',
      subcategories: json['subcategories'] is List
          ? (json['subcategories'] as List)
              .whereType<Map>()
              .map(
                (item) => Subcategory.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList()
          : const [],
      childCategories: _parseChildCategories(json),
    );
  }
}

final List<Category> dummyCategories = [
  Category(
    id: '1',
    title: 'Electronics',
    subtitle: 'High Performance',
    imageUrl: 'https://images.unsplash.com/photo-1498049794561-7780e7231661?q=80&w=800&auto=format&fit=crop',
  ),
  Category(
    id: '2',
    title: 'Large Appliances',
    subtitle: 'Smart living solutions',
    imageUrl: 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?q=80&w=800&auto=format&fit=crop',
  ),
  Category(
    id: '3',
    title: 'Kitchenware',
    subtitle: 'Culinary essentials',
    imageUrl: 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?q=80&w=800&auto=format&fit=crop',
  ),
  Category(
    id: '4',
    title: 'Furniture',
    subtitle: 'Modern comfort',
    imageUrl: 'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?q=80&w=800&auto=format&fit=crop',
  ),
];
