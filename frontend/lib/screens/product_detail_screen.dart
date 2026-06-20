import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../utils/constants.dart';
import '../theme/app_theme.dart';
import '../utils/price_formatter.dart';
import '../widgets/global_layout.dart';
import '../providers/cart_provider.dart';
import '../providers/ui_settings_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'checkout_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late TabController _tabController;
  
  Product? _product;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedImageIndex = 0;
  bool _isHovering = false;
  Offset _hoverPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
    _fetchProduct();
  }

  @override
  void didUpdateWidget(covariant ProductDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId) {
      _fetchProduct();
    }
  }

  Future<void> _fetchProduct() async {
    setState(() {
      _product = null;
      _isLoading = true;
      _errorMessage = null;
      _selectedImageIndex = 0;
      _isHovering = false;
    });

    try {
      final response = await http.get(Uri.parse('${AppConstants.apiUrl}/products/${Uri.encodeComponent(widget.productId)}'));
      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map) {
          setState(() {
            _product = Product.fromJson(Map<String, dynamic>.from(decoded));
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Product not found';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 404) {
        setState(() {
          _errorMessage = 'Product not found';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Unable to load product details.';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load product details.';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    return Scaffold(
      appBar: const GlobalAppBar(showBackButton: true),
      drawer: const GlobalDrawer(),
      body: _buildBody(context, isMobile),
    );
  }

  Widget _buildBody(BuildContext context, bool isMobile) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final product = _product;
    if (product == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inventory_2_outlined, size: 72, color: AppTheme.textMuted),
              const SizedBox(height: 16),
              Text(_errorMessage ?? 'Product not found', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              TextButton(onPressed: () => Navigator.of(context).maybePop(), child: const Text('Go back')),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 40, 
                vertical: 20
              ),
              child: isMobile 
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImageGallery(context, isMobile, product),
                      const SizedBox(height: 32),
                      _buildProductInfo(context, isMobile, product),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _buildImageGallery(context, isMobile, product)),
                      const SizedBox(width: 60),
                      Expanded(flex: 4, child: _buildProductInfo(context, isMobile, product)),
                    ],
                  ),
            ),
        const SizedBox(height: 80),
        const GlobalFooter(),
      ],
    ),
  );
}

  Widget _buildImageGallery(BuildContext context, bool isMobile, Product product) {
    final galleryImages = product.galleryImages;

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return MouseRegion(
              onEnter: (_) => setState(() => _isHovering = true),
              onExit: (_) => setState(() => _isHovering = false),
              onHover: (details) {
                if (!isMobile) {
                  setState(() {
                    _hoverPosition = Offset(
                      details.localPosition.dx / constraints.maxWidth,
                      details.localPosition.dy / (isMobile ? 400 : 600),
                    );
                  });
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  height: isMobile ? 400 : 600,
                  width: double.infinity,
                  child: Hero(
                    tag: 'product_image_${product.id}',
                    child: ColoredBox(
                      color: Colors.white,
                      child: Transform.scale(
                        scale: (!isMobile && _isHovering) ? 2.5 : 1.0,
                        alignment: FractionalOffset(_hoverPosition.dx, _hoverPosition.dy),
                        child: CachedNetworkImage(
                          imageUrl: galleryImages.isNotEmpty ? galleryImages[_selectedImageIndex] : product.imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
        ),
        const SizedBox(height: 16),
        if (galleryImages.isNotEmpty)
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: galleryImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedImageIndex = index),
                  child: Container(
                    width: 80,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedImageIndex == index ? AppTheme.primaryBlue : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: ColoredBox(
                        color: Colors.white,
                        child: CachedNetworkImage(
                          imageUrl: galleryImages[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildProductInfo(BuildContext context, bool isMobile, Product product) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.isNew)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
                child: const Text('NEW ARRIVAL', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            const SizedBox(height: 16),
            if (product.categoryName.isNotEmpty) ...[
              Text(
                product.categoryName.toUpperCase(),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
            ],
            Text(product.title, style: isMobile ? Theme.of(context).textTheme.headlineLarge : Theme.of(context).textTheme.displayMedium),
            if (product.subtitle.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(product.subtitle, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.textMuted)),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                ...List.generate(5, (index) => const Icon(Icons.star, color: Colors.amber, size: 20)),
                const SizedBox(width: 8),
                Text('(128 Reviews)', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted)),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(formatPrice(product.price, currencySymbol: context.watch<UiSettingsProvider>().settings.currencySymbol), style: (isMobile ? Theme.of(context).textTheme.headlineMedium : Theme.of(context).textTheme.displaySmall)?.copyWith(color: AppTheme.primaryBlue)),
                      const SizedBox(width: 12),
                      if (product.price < product.originalPrice)
                        Text(formatPrice(product.originalPrice, currencySymbol: context.watch<UiSettingsProvider>().settings.currencySymbol), style: Theme.of(context).textTheme.titleLarge?.copyWith(decoration: TextDecoration.lineThrough, color: AppTheme.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(product.easyPayment.isNotEmpty ? product.easyPayment : 'Easy payment options available.', style: const TextStyle(color: AppTheme.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryBlue,
              unselectedLabelColor: AppTheme.textMuted,
              indicatorColor: AppTheme.primaryBlue,
              tabs: const [
                Tab(text: 'Specs'),
                Tab(text: 'Payment'),
                Tab(text: 'Enquiry'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250, // fixed height for content
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Specs Tab
                  _buildSpecsTab(product, isMobile),
                  // Easy Payment Tab
                  SingleChildScrollView(
                    child: Text(product.easyPayment.isNotEmpty ? product.easyPayment : 'No payment options available.'),
                  ),
                  // Enquiry Tab
                  SingleChildScrollView(
                    child: Text(product.enquiry.isNotEmpty ? product.enquiry : 'For enquiries, please contact us.'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      context.read<CartProvider>().addItem(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${product.title} added to cart')),
                      );
                    },
                    child: const Text('ADD TO CART'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CheckoutScreen(
                            buyNowItem: CartItem(product: product, quantity: 1),
                          ),
                        ),
                      );
                    },
                    child: const Text('BUY NOW'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecsTab(Product product, bool isMobile) {
    final rows = <MapEntry<String, String>>[
      if (product.categoryName.isNotEmpty) MapEntry('Category', product.categoryName),
      ...product.specifications.entries,
    ];

    if (rows.isEmpty) {
      return const Text('No specifications available.');
    }

    return ListView(
      children: rows.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: isMobile ? 100 : 150,
                child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Expanded(child: Text(entry.value)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryBlue),
          const SizedBox(width: 16),
          Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
