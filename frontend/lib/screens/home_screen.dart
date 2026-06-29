import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/product.dart';
import '../models/ui_settings.dart';
import '../providers/ui_settings_provider.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/global_layout.dart';
import '../widgets/mobile_bottom_navigation.dart';
import '../widgets/product_card.dart';
import '../widgets/product_layout.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _coolingClimateTitle = 'Cooling & Climate';
  static const String _medicalHealthcareTitle = 'Medical & Healthcare';

  List<Product> _products = [];
  List<Product> _bestOfferRowProducts = [];
  List<Product> _newArrivalRowProducts = [];
  final Map<String, List<Product>> _categorySectionProducts = {};
  List<Category> _categories = [];
  final Map<String, Category> _homepageCategorySections = {};
  bool _isLoading = true;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _fetchHomepageSystemRowProducts('best_offers');
    _fetchHomepageSystemRowProducts('new_arrivals');
    _fetchCategories();
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiUrl}/products?all=1&homepage_row_key=featured_products'),
      );
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



  Future<void> _fetchHomepageSystemRowProducts(String rowKey) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiUrl}/products?all=1&homepage_row_key=$rowKey'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            final products = data.map((item) => Product.fromJson(item)).toList();
            if (rowKey == 'best_offers') {
              _bestOfferRowProducts = products;
            } else if (rowKey == 'new_arrivals') {
              _newArrivalRowProducts = products;
            }
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiUrl}/categories'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          final categories = data
              .map((item) => Category.fromJson(item))
              .toList();
          final homepageSections = _findHomepageCategorySections(categories);
          setState(() {
            _categories = categories;
            _homepageCategorySections
              ..clear()
              ..addAll(homepageSections);
            _isLoadingCategories = false;
          });
          for (final entry in homepageSections.entries) {
            _fetchHomepageCategoryProducts(entry.key, entry.value);
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  Map<String, Category> _findHomepageCategorySections(List<Category> categories) {
    const sectionTitles = [
      _coolingClimateTitle,
      _medicalHealthcareTitle,
    ];

    return {
      for (final title in sectionTitles)
        for (final category in categories)
          if (category.title == title) title: category,
    };
  }

  Future<void> _fetchHomepageCategoryProducts(
    String sectionTitle,
    Category category,
  ) async {
    final slug = category.slug.trim();
    final query = slug.isNotEmpty
        ? 'category_slug=${Uri.encodeQueryComponent(slug)}&homepage_row_key=category_${category.id}'
        : 'category_id=${Uri.encodeQueryComponent(category.id)}&homepage_row_key=category_${category.id}';

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiUrl}/products?all=1&$query'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _categorySectionProducts[sectionTitle] =
                data.map((item) => Product.fromJson(item)).toList();
          });
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlobalAppBar(),
      drawer: const GlobalDrawer(),
      bottomNavigationBar: buildMobileBottomNavigationBar(context),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildAutoSlider(context),
                  const _HomepagePromoBanner(),
                  const _ExistingHomepageBanner(),
                  if (_trendingProducts.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    _buildSectionTitle(context, 'Trending Now'),
                    const SizedBox(height: 16),
                    _buildTrendingNowSection(context),
                  ],
                  const SizedBox(height: 60),
                  _buildSectionTitle(context, 'Best Offers'),
                  const SizedBox(height: 16),
                  _buildBestOffersSection(context),
                  if (_newArrivalProducts.isNotEmpty) ...[
                    const SizedBox(height: 60),
                    _buildSectionTitle(context, 'New Arrivals'),
                    const SizedBox(height: 16),
                    _buildHorizontalProductSlider(context, _newArrivalProducts),
                  ],
                  const SizedBox(height: 60),
                  _buildSectionTitle(
                    context,
                    'Top Categories',
                    viewAllRoute: '/categories',
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryGrid(context),
                  const SizedBox(height: 60),
                  _buildSectionTitle(context, 'Featured Products'),
                  const SizedBox(height: 16),
                  _buildHorizontalProductSlider(context, _products),
                  ..._buildHomepageCategorySection(
                    context,
                    _coolingClimateTitle,
                  ),
                  ..._buildHomepageCategorySection(
                    context,
                    _medicalHealthcareTitle,
                  ),
                  const SizedBox(height: 80),
                  const GlobalFooter(),
                ],
              ),
            ),
    );
  }

  String _homepageCategoryRoute(String sectionTitle) {
    final category = _homepageCategorySections[sectionTitle];
    if (category == null) {
      return '/products';
    }

    final slug = category.slug.trim();
    if (slug.isNotEmpty) {
      return '/category/${Uri.encodeComponent(slug)}';
    }

    return '/category/${Uri.encodeComponent(category.id)}?title=${Uri.encodeQueryComponent(category.title)}';
  }

  List<Widget> _buildHomepageCategorySection(
    BuildContext context,
    String sectionTitle,
  ) {
    final products = _categorySectionProducts[sectionTitle] ?? const <Product>[];
    if (products.isEmpty) {
      return const [];
    }

    return [
      const SizedBox(height: 60),
      _buildSectionTitle(
        context,
        sectionTitle,
        viewAllRoute: _homepageCategoryRoute(sectionTitle),
      ),
      const SizedBox(height: 16),
      _buildHorizontalProductSlider(context, products),
    ];
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

  List<Product> get _newArrivalProducts {
    if (_newArrivalRowProducts.isNotEmpty) {
      return _newArrivalRowProducts.take(12).toList();
    }
    return _products.where((product) => product.isNew).take(12).toList();
  }

  List<Product> get _trendingProducts {
    return _products.where((product) => product.isActive).take(12).toList();
  }

  Widget _buildTrendingNowSection(BuildContext context) {
    if (_trendingProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: _TrendingProductMarquee(products: _trendingProducts),
    );
  }

  Widget _buildBestOffersSection(BuildContext context) {
    final bestOffers = _bestOfferRowProducts.isNotEmpty ? _bestOfferRowProducts : _bestOfferProducts;
    if (bestOffers.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildHorizontalProductSlider(context, bestOffers);
  }

  Widget _buildHorizontalProductSlider(
    BuildContext context,
    List<Product> products,
  ) {
    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: _ProductCarousel(products: products),
    );
  }

  Widget _buildProductGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: productGridDelegate(constraints.maxWidth, context: context),
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

  Widget _buildSectionTitle(
    BuildContext context,
    String title, {
    String viewAllRoute = '/products',
  }) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final titleStyle = isMobile
        ? Theme.of(context).textTheme.headlineMedium
        : Theme.of(context).textTheme.displaySmall;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: Text(title, style: titleStyle)),
          TextButton(
            onPressed: () => context.go(viewAllRoute),
            style: TextButton.styleFrom(
              padding: isMobile ? EdgeInsets.zero : null,
              minimumSize: isMobile ? Size.zero : null,
              tapTargetSize: isMobile ? MaterialTapTargetSize.shrinkWrap : null,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('View All'),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 1200
              ? 4
              : (constraints.maxWidth > 760 ? 2 : 1);
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 4 / 3,
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

class _TrendingProductMarquee extends StatefulWidget {
  final List<Product> products;

  const _TrendingProductMarquee({required this.products});

  @override
  State<_TrendingProductMarquee> createState() => _TrendingProductMarqueeState();
}

class _TrendingProductMarqueeState extends State<_TrendingProductMarquee>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _manualScrollOffset = 0;
  bool _isHovering = false;
  bool _isPointerDown = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _loopDuration());
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
  }

  @override
  void didUpdateWidget(covariant _TrendingProductMarquee oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.products.length != widget.products.length) {
      _controller
        ..duration = _loopDuration()
        ..reset();
      WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Duration _loopDuration() {
    final seconds = (widget.products.length * 9).clamp(60, 90).toInt();
    return Duration(seconds: seconds);
  }

  void _startAutoScroll() {
    if (!mounted || widget.products.isEmpty || _isHovering || _isPointerDown) {
      return;
    }

    if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  void _pause() {
    _controller.stop(canceled: false);
  }

  void _resumeIfIdle() {
    _startAutoScroll();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (widget.products.isEmpty) {
          return const SizedBox.shrink();
        }

        final width = constraints.maxWidth;
        final isMobile = width < 600;
        final isTablet = width >= 600 && width < 1000;
        final itemWidth = isMobile ? 142.0 : (isTablet ? 168.0 : 190.0);
        final spacing = isMobile ? 10.0 : 14.0;
        final height = isMobile ? 240.0 : (isTablet ? 270.0 : 300.0);
        final stride = itemWidth + spacing;
        final singleListWidth = widget.products.length * stride;
        final copyCount = singleListWidth > 0
            ? max(3, (width * 3 / singleListWidth).ceil())
            : 3;
        final repeatedProducts = [
          for (var i = 0; i < copyCount; i++) ...widget.products,
        ];

        return MouseRegion(
          onEnter: (_) {
            _isHovering = true;
            _pause();
          },
          onExit: (_) {
            _isHovering = false;
            _resumeIfIdle();
          },
          child: Listener(
            onPointerDown: (_) {
              _isPointerDown = true;
              _pause();
            },
            onPointerUp: (_) {
              _isPointerDown = false;
              _resumeIfIdle();
            },
            onPointerCancel: (_) {
              _isPointerDown = false;
              _resumeIfIdle();
            },
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragStart: (_) => _pause(),
              onHorizontalDragUpdate: (details) {
                if (singleListWidth <= 0) return;
                setState(() {
                  _manualScrollOffset =
                      (_manualScrollOffset - details.delta.dx) %
                          singleListWidth;
                });
              },
              onHorizontalDragEnd: (_) {
                _isPointerDown = false;
                _resumeIfIdle();
              },
              onHorizontalDragCancel: () {
                _isPointerDown = false;
                _resumeIfIdle();
              },
              child: ClipRect(
                child: SizedBox(
                  height: height,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final scrollDistance =
                          ((_controller.value * singleListWidth) +
                                  _manualScrollOffset) %
                              singleListWidth;
                      return Transform.translate(
                        offset: Offset(-scrollDistance, 0),
                        child: child,
                      );
                    },
                    child: Row(
                      children: [
                        for (final product in repeatedProducts) ...[
                          SizedBox(
                            width: itemWidth,
                            child: HoverProductCard(
                              product: product,
                              compact: true,
                              onTap: () => context.go('/product/${product.id}'),
                            ),
                          ),
                          SizedBox(width: spacing),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProductCarousel extends StatefulWidget {
  final List<Product> products;

  const _ProductCarousel({required this.products});

  @override
  State<_ProductCarousel> createState() => _ProductCarouselState();
}

class _ProductCarouselState extends State<_ProductCarousel> {
  final ScrollController _scrollController = ScrollController();
  bool _canScrollBack = false;
  bool _canScrollForward = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateArrowVisibility);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateArrowVisibility());
  }

  @override
  void didUpdateWidget(covariant _ProductCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateArrowVisibility());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_updateArrowVisibility)
      ..dispose();
    super.dispose();
  }

  void _updateArrowVisibility() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final canScrollBack = position.pixels > 4;
    final canScrollForward = position.pixels < position.maxScrollExtent - 4;
    if (canScrollBack != _canScrollBack || canScrollForward != _canScrollForward) {
      setState(() {
        _canScrollBack = canScrollBack;
        _canScrollForward = canScrollForward;
      });
    }
  }

  void _scrollBy(double distance) {
    if (!_scrollController.hasClients) return;
    final target = (_scrollController.offset + distance).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final uiSettings = context.watch<UiSettingsProvider>().settings;
        final showCarouselArrows =
            uiSettings.showCarouselArrows && constraints.maxWidth >= 800;
        final visibleItems = getProductCrossAxisCount(constraints.maxWidth, desktopCount: uiSettings.productsPerRowDesktop);
        final itemWidth = getProductCarouselItemWidth(constraints.maxWidth, desktopCount: uiSettings.productsPerRowDesktop);
        final spacing = visibleItems == 2 ? 12.0 : (constraints.maxWidth >= 900 ? 12.0 : 14.0);
        final scrollDistance =
            (itemWidth * visibleItems) + (spacing * visibleItems);

        return SizedBox(
          height: constraints.maxWidth < 600 ? 290 : 340,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                itemCount: widget.products.length,
                separatorBuilder: (context, index) => SizedBox(width: spacing),
                itemBuilder: (context, index) {
                  final product = widget.products[index];
                  return SizedBox(
                    width: itemWidth,
                    child: HoverProductCard(
                      product: product,
                      onTap: () => context.go('/product/${product.id}'),
                    ),
                  );
                },
              ),
              if (showCarouselArrows && _canScrollBack)
                _CarouselArrowButton(
                  alignment: Alignment.centerLeft,
                  icon: Icons.chevron_left,
                  onPressed: () => _scrollBy(-scrollDistance),
                ),
              if (showCarouselArrows && _canScrollForward)
                _CarouselArrowButton(
                  alignment: Alignment.centerRight,
                  icon: Icons.chevron_right,
                  onPressed: () => _scrollBy(scrollDistance),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CarouselArrowButton extends StatelessWidget {
  final Alignment alignment;
  final IconData icon;
  final VoidCallback onPressed;

  const _CarouselArrowButton({
    required this.alignment,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: alignment == Alignment.centerLeft ? 8 : null,
      right: alignment == Alignment.centerRight ? 8 : null,
      top: 0,
      bottom: 0,
      child: Center(
        child: Material(
          color: Colors.white,
          elevation: 8,
          shadowColor: Colors.black.withAlpha(31),
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            hoverColor: AppTheme.primaryBlue.withAlpha(20),
            child: SizedBox(
              width: 46,
              height: 46,
              child: Icon(
                icon,
                size: 30,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomepagePromoBanner extends StatefulWidget {
  const _HomepagePromoBanner();

  @override
  State<_HomepagePromoBanner> createState() => _HomepagePromoBannerState();
}

class _HomepagePromoBannerState extends State<_HomepagePromoBanner> {
  PromotionBanner? _banner;
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchActiveBanner();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchActiveBanner() async {
    final uri = Uri.parse('${AppConstants.apiUrl}/promotion-banners?active=1');
    debugPrint('[Home] loading promotion banner');
    debugPrint('[Home] promotion banner API URL: $uri');

    try {
      final response = await http.get(uri);
      debugPrint('[Home] promotion banner response status: ${response.statusCode}');
      debugPrint('[Home] raw response: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List<dynamic> && decoded.isNotEmpty && decoded.first is Map) {
          _banner = PromotionBanner.fromJson(Map<String, dynamic>.from(decoded.first as Map));
          debugPrint('[Home] parsed banner: ${_banner!.toJson()}');
          debugPrint('[Home] promotion banner image URL: ${_banner!.bannerImageUrl}');
          _updateRemaining();
          _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateRemaining());
        } else {
          debugPrint('[Home] parsed banner: null');
        }
      }
    } catch (e) {
      debugPrint('Error loading promotion banner: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _updateRemaining() {
    final banner = _banner;
    if (banner?.offerEndAt == null) return;
    final remaining = banner!.offerEndAt!.toUtc().difference(DateTime.now().toUtc());
    if (!mounted) return;
    setState(() {
      _remaining = remaining.isNegative ? Duration.zero : remaining;
      if (remaining.isNegative || remaining.inSeconds == 0) {
        _banner = null;
        _timer?.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final banner = _banner;
    final shouldShowPromotionBanner = !_loading &&
        banner != null &&
        banner.bannerImageUrl.trim().isNotEmpty &&
        banner.isCurrentlyActive;
    debugPrint('[Home] shouldShowPromotionBanner: $shouldShowPromotionBanner');
    if (!shouldShowPromotionBanner) return const SizedBox.shrink();
    debugPrint('[Home] promotion banner image URL: ${banner.bannerImageUrl}');
    final width = MediaQuery.of(context).size.width;
    final isMobile = width <= 768;
    final image = CachedNetworkImage(
      imageUrl: banner.bannerImageUrl,
      width: double.infinity,
      fit: BoxFit.cover,
      errorWidget: (context, url, error) {
        debugPrint('[Home] promotion banner image URL: $url');
        return _PromoBannerPlaceholder(imageUrl: url);
      },
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 18),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => context.go(banner.productUrl.isNotEmpty ? banner.productUrl : '/product/${banner.productId}'),
          child: AspectRatio(
            aspectRatio: 1920 / 400,
            child: Stack(
              fit: StackFit.expand,
              children: [
                image,
                Positioned(
                  left: isMobile ? 16 : 42,
                  bottom: isMobile ? 10 : 24,
                  child: _CountdownOverlay(remaining: _remaining, compact: isMobile),
                ),
                Positioned(
                  right: isMobile ? 16 : 42,
                  bottom: isMobile ? 10 : 24,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 8 : 20,
                      vertical: isMobile ? 3 : 11,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isMobile ? Colors.transparent : AppTheme.accentOrange,
                      borderRadius: BorderRadius.circular(isMobile ? 14 : 999),
                      border:
                          isMobile ? Border.all(color: Colors.white) : null,
                    ),
                    child: Text(
                      'Buy Now',
                      style: (isMobile
                              ? Theme.of(context).textTheme.labelSmall
                              : Theme.of(context).textTheme.labelLarge)
                          ?.copyWith(
                        color: Colors.white,
                        fontSize: isMobile ? 10 : null,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountdownOverlay extends StatelessWidget {
  const _CountdownOverlay({required this.remaining, required this.compact});
  final Duration remaining;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final days = remaining.inDays;
    final hours = remaining.inHours.remainder(24);
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 3 : 14,
        vertical: compact ? 2 : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(150),
        borderRadius: BorderRadius.circular(compact ? 8 : 16),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _timeBox(context, days, 'Days'),
          _timeBox(context, hours, 'Hours'),
          _timeBox(context, minutes, 'Mins'),
          _timeBox(context, seconds, 'Secs'),
        ],
      ),
    );
  }

  Widget _timeBox(BuildContext context, int value, String label) => Padding(
        padding: EdgeInsets.symmetric(horizontal: compact ? 1.5 : 7),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            value.toString().padLeft(2, '0'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontSize: compact ? 10 : null,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                  fontSize: compact ? 7 : null,
                ),
          ),
        ]),
      );
}

class _PromoBannerPlaceholder extends StatelessWidget {
  const _PromoBannerPlaceholder({required this.imageUrl});

  final String imageUrl;

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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.broken_image_outlined, color: Colors.white70, size: 44),
              const SizedBox(height: 12),
              Text(
                'Promotion banner image failed to load',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                imageUrl,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExistingHomepageBanner extends StatelessWidget {
  const _ExistingHomepageBanner();

  @override
  Widget build(BuildContext context) {
    final viewportWidth = MediaQuery.sizeOf(context).width;

    return SizedBox(
      width: viewportWidth,
      child: Image.asset(
        'assets/images/home-banner.png',
        width: viewportWidth,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: viewportWidth,
          color: AppTheme.backgroundLight,
          alignment: Alignment.center,
          child: Text(
            'Homepage banner unavailable',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }
}

// Auto Slider Widget
class _HeroAutoSlider extends StatefulWidget {
  const _HeroAutoSlider();

  @override
  State<_HeroAutoSlider> createState() => _HeroAutoSliderState();
}

class _HeroAutoSliderState extends State<_HeroAutoSlider> {
  static const int _initialPage = 0;
  final List<HeroBanner> _banners = [];
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialPage);
    _fetchBanners();
  }

  Future<void> _fetchBanners() async {
    try {
      final response = await http.get(Uri.parse('${AppConstants.apiUrl}/hero-banners?active=1'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        _banners
          ..clear()
          ..addAll(data.map((item) => HeroBanner.fromJson(item)));
        if (_banners.isNotEmpty) {
          _currentPage = _initialPage % _banners.length;
          _startAutoSlide();
        }
      }
    } catch (e) {
      debugPrint('Error loading hero banners: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startAutoSlide() {
    _timer?.cancel();
    if (_banners.length < 2) return;
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

    if (_isLoading) {
      return SizedBox(height: bannerHeight, child: const Center(child: CircularProgressIndicator()));
    }
    if (_banners.isEmpty) {
      return SizedBox(height: bannerHeight, child: const _HeroPlaceholderBanner(imagePath: 'No active hero banners'));
    }

    return SizedBox(
      width: double.infinity,
      height: bannerHeight,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index % _banners.length),
            itemBuilder: (context, index) {
              final banner = _banners[index % _banners.length];
              final isRemoteImage = banner.imageUrl.startsWith('http://') || banner.imageUrl.startsWith('https://');
              final image = isRemoteImage
                  ? CachedNetworkImage(
                      imageUrl: banner.imageUrl,
                      width: double.infinity,
                      height: bannerHeight,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => _HeroPlaceholderBanner(imagePath: banner.imageUrl),
                    )
                  : Image.asset(
                      banner.imageUrl,
                      width: double.infinity,
                      height: bannerHeight,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _HeroPlaceholderBanner(imagePath: banner.imageUrl),
                    );
              if (banner.linkUrl == null || banner.linkUrl!.isEmpty) return image;
              return GestureDetector(onTap: () => context.go(banner.linkUrl!), child: image);
            },
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_banners.length, (index) {
                final isActive = _currentPage == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.accentOrange : Colors.white.withAlpha(180),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1))],
                  ),
                );
              }),
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
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.darkBlue.withAlpha(_isHovered ? 42 : 22),
              blurRadius: _isHovered ? 30 : 18,
              offset: Offset(0, _isHovered ? 18 : 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.go(
              '/category/${widget.category.id}?title=${Uri.encodeComponent(widget.category.title)}',
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedScale(
                  scale: _isHovered ? 1.07 : 1.0,
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutCubic,
                  child: CachedNetworkImage(
                    imageUrl: widget.category.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppTheme.primaryBlue, AppTheme.accentOrange],
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppTheme.primaryBlue, AppTheme.accentOrange],
                        ),
                      ),
                      child: const Icon(
                        Icons.category_outlined,
                        color: Colors.white70,
                        size: 48,
                      ),
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.darkBlue.withAlpha(212),
                        AppTheme.primaryBlue.withAlpha(98),
                        Colors.white.withAlpha(18),
                        AppTheme.accentOrange.withAlpha(108),
                      ],
                      stops: const [0.0, 0.45, 0.72, 1.0],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 230),
                        child: Text(
                          widget.category.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                height: 1.05,
                                letterSpacing: -0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withAlpha(90),
                                    blurRadius: 14,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                        ),
                      ),

                      const Spacer(),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOutCubic,
                          transform: Matrix4.translationValues(
                            _isHovered ? 6 : 0,
                            0,
                            0,
                          ),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isHovered
                                ? AppTheme.accentOrange
                                : Colors.white.withAlpha(232),
                            border: Border.all(color: Colors.white.withAlpha(95)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(55),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: _isHovered ? Colors.white : AppTheme.primaryBlue,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
