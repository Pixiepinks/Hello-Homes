import '../utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/product.dart';
import '../models/category.dart';
import '../widgets/product_card.dart';
import '../widgets/global_layout.dart';
import '../theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  List<Product> _products = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _fetchCategories();
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await http.get(Uri.parse('${AppConstants.apiUrl}/products?all=1'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _products = data.map((item) => Product.fromJson(item)).toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(Uri.parse('${AppConstants.apiUrl}/categories'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _categories = data.map((item) => Category.fromJson(item)).toList();
            _isLoadingCategories = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlobalAppBar(),
      drawer: const GlobalDrawer(),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
        child: Column(
          children: [
            _buildAutoSlider(context),
            const SizedBox(height: 60),
            _buildSectionTitle(context, 'Top Categories', 'Curated essentials for every room'),
            const SizedBox(height: 30),
            _buildCategoryGrid(context),
            const SizedBox(height: 60),
            _buildSectionTitle(context, 'Trending Now', 'Most popular items this week'),
            const SizedBox(height: 30),
            _buildProductGrid(context),
            const SizedBox(height: 80),
            const GlobalFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 2 : 1);
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 0.75,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
            ),
            itemCount: _products.length,
            itemBuilder: (context, index) {
              final product = _products[index];
              return HoverProductCard(
                product: product,
                onTap: () => context.go('/product/${product.id}'),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAutoSlider(BuildContext context) {
    // Top 5 trending items for slider
    final sliderItems = _products.take(5).toList();
    return _HeroAutoSlider(items: sliderItems);
  }

  Widget _buildSectionTitle(BuildContext context, String title, String subtitle) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: isMobile 
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/categories'),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View All'),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios, size: 14),
                  ],
                ),
              )
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 8),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textMuted)),
                ],
              ),
              TextButton(
                onPressed: () => context.go('/products'),
                child: const Row(
                  children: [
                    Text('View All'),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios, size: 14),
                  ],
                ),
              )
            ],
          ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 2 : 1);
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 1.5,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              return _CategoryCard(category: _categories[index]);
            },
          );
        },
      ),
    );
  }
}

// Auto Slider Widget
class _HeroAutoSlider extends StatefulWidget {
  final List<Product> items;
  const _HeroAutoSlider({required this.items});

  @override
  State<_HeroAutoSlider> createState() => _HeroAutoSliderState();
}

class _HeroAutoSliderState extends State<_HeroAutoSlider> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (widget.items.isEmpty) return;
      int nextPage = (_currentPage + 1) % widget.items.length;
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox();
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Container(
      width: double.infinity,
      height: isMobile ? 400 : 500,
      margin: EdgeInsets.all(isMobile ? 12 : 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withAlpha(40),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final product = widget.items[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background Image
                    CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                    ),
                    // Gradient Overlay for text readability
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.darkBlue.withAlpha(220),
                            Colors.transparent,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: EdgeInsets.all(isMobile ? 24.0 : 60.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.accentOrange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('TRENDING', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            product.title,
                            style: (isMobile 
                              ? Theme.of(context).textTheme.headlineLarge 
                              : Theme.of(context).textTheme.displayLarge)?.copyWith(color: Colors.white, height: 1.1),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            product.subtitle,
                            style: (isMobile
                              ? Theme.of(context).textTheme.titleMedium
                              : Theme.of(context).textTheme.titleLarge)?.copyWith(color: Colors.white70),
                          ),
                          SizedBox(height: isMobile ? 24 : 40),
                          ElevatedButton(
                            onPressed: () => context.go('/product/${product.id}'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 24 : 32, 
                                vertical: isMobile ? 12 : 20
                              ),
                            ),
                            child: const Text('Shop Now'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            // Dots Indicator
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.items.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? AppTheme.accentOrange : Colors.white54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final Category category;
  const _CategoryCard({required this.category});

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/category/${widget.category.id}?title=${Uri.encodeComponent(widget.category.title)}'),
      child: MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppTheme.surfaceWhite,
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: _isHovered
              ? [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 20, offset: const Offset(0, 10))]
              : [],
        ),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              bottom: 0,
              width: 150,
              height: 150,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(bottomRight: Radius.circular(16)),
                child: AnimatedScale(
                  scale: _isHovered ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: CachedNetworkImage(
                    imageUrl: widget.category.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.category.title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(widget.category.subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted)),
                  const Spacer(),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isHovered ? AppTheme.primaryBlue : AppTheme.backgroundLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward,
                      color: _isHovered ? Colors.white : AppTheme.textDark,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
