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
                  const _HomepagePromoBanner(),
                  _buildSectionTitle(
                    context,
                    'Best Offers',
                    'Handpicked deals just for you',
                  ),
                  const SizedBox(height: 30),
                  _buildBestOffersSection(context),
                  const SizedBox(height: 60),
                  _buildSectionTitle(
                    context,
                    'Top Categories',
                    'Curated essentials for every room',
                  ),
                  const SizedBox(height: 30),
                  _buildCategoryGrid(context),
                  const SizedBox(height: 60),
                  _buildSectionTitle(
                    context,
                    'Trending Now',
                    'Most popular items this week',
                  ),
                  const SizedBox(height: 30),
                  _buildProductGrid(context),
                  const SizedBox(height: 80),
                  const GlobalFooter(),
                ],
              ),
            ),
    );
  }

  List<Product> get _bestOfferProducts {
    final offers = _products
        .where(
          (product) => product.isOnSale || product.price < product.originalPrice,
        )
        .toList();

    if (offers.isEmpty) {
      return [];
    }

    offers.sort((a, b) {
      final aDiscount = a.originalPrice > 0
          ? (a.originalPrice - a.price) / a.originalPrice
          : 0.0;
      final bDiscount = b.originalPrice > 0
          ? (b.originalPrice - b.price) / b.originalPrice
          : 0.0;
      return bDiscount.compareTo(aDiscount);
    });

    return offers.take(8).toList();
  }

  Widget _buildBestOffersSection(BuildContext context) {
    final bestOffers = _bestOfferProducts;
    if (bestOffers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 800;
          if (isMobile) {
            return SizedBox(
              height: 360,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: bestOffers.length,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final product = bestOffers[index];
                  return SizedBox(
                    width: 260,
                    child: HoverProductCard(
                      product: product,
                      onTap: () => context.go('/product/${product.id}'),
                    ),
                  );
                },
              ),
            );
          }

          final itemCount = bestOffers.length > 4 ? 4 : bestOffers.length;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: constraints.maxWidth > 1200 ? 4 : 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
            ),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              final product = bestOffers[index];
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
    return const _HeroAutoSlider();
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

class _HomepagePromoBanner extends StatelessWidget {
  const _HomepagePromoBanner();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => context.go('/products'),
          child: Image.asset(
            'assets/images/home-banner.png',
            width: double.infinity,
            fit: BoxFit.fitWidth,
            alignment: Alignment.center,
            errorBuilder: (context, error, stackTrace) {
              return const _PromoBannerPlaceholder();
            },
          ),
        ),
      ),
    );
  }
}

class _PromoBannerPlaceholder extends StatelessWidget {
  const _PromoBannerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 5,
      child: Container(
        width: double.infinity,
        color: AppTheme.backgroundLight,
        alignment: Alignment.center,
        child: Text(
          'Hello Homes Promotion Banner',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.textMuted,
              ),
        ),
      ),
    );
  }
}

// Auto Slider Widget
class _HeroAutoSlider extends StatefulWidget {
  const _HeroAutoSlider();

  static const List<String> _bannerImages = [
    'assets/images/hero/hero_01.png',
    'assets/images/hero/hero_02.png',
    'assets/images/hero/hero_03.png',
    'assets/images/hero/hero_04.png',
    'assets/images/hero/hero_05.png',
    'assets/images/hero/hero_06.png',
    'assets/images/hero/hero_07.png',
    'assets/images/hero/hero_08.png',
    'assets/images/hero/hero_09.png',
    'assets/images/hero/hero_10.png',
    'assets/images/hero/hero_11.png',
    'assets/images/hero/hero_12.png',
    'assets/images/hero/hero_13.png',
    'assets/images/hero/hero_14.png',
    'assets/images/hero/hero_15.png',
  ];

  @override
  State<_HeroAutoSlider> createState() => _HeroAutoSliderState();
}

class _HeroAutoSliderState extends State<_HeroAutoSlider> {
  static const int _initialPage = 15000;
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialPage);
    _currentPage = _initialPage % _HeroAutoSlider._bannerImages.length;
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
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
    final isMobile = MediaQuery.of(context).size.width < 800;
    final bannerHeight = isMobile ? 200.0 : 340.0;

    return SizedBox(
      width: double.infinity,
      height: bannerHeight,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index % _HeroAutoSlider._bannerImages.length;
              });
            },
            itemBuilder: (context, index) {
              final imagePath = _HeroAutoSlider
                  ._bannerImages[index % _HeroAutoSlider._bannerImages.length];
              return Image.asset(
                imagePath,
                width: double.infinity,
                height: bannerHeight,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _HeroPlaceholderBanner(imagePath: imagePath);
                },
              );
            },
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _HeroAutoSlider._bannerImages.length,
                (index) {
                  final isActive = _currentPage == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.accentOrange
                          : Colors.white.withAlpha(180),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPlaceholderBanner extends StatelessWidget {
  final String imagePath;

  const _HeroPlaceholderBanner({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.darkBlue],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image_outlined, color: Colors.white70, size: 44),
            const SizedBox(height: 12),
            Text(
              'Hero banner placeholder',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              imagePath,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white70),
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
