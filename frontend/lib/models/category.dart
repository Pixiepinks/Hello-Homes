class Category {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;

  Category({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'].toString(),
      title: json['title'],
      subtitle: json['subtitle'] ?? '',
      imageUrl: json['image_url'] ?? '',
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
