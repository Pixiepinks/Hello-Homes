import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import '../widgets/global_layout.dart';
import '../providers/cart_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'checkout_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late TabController _tabController;
  
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
      body: SingleChildScrollView(
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
                      _buildImageGallery(context, isMobile),
                      const SizedBox(height: 32),
                      _buildProductInfo(context, isMobile),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _buildImageGallery(context, isMobile)),
                      const SizedBox(width: 60),
                      Expanded(flex: 4, child: _buildProductInfo(context, isMobile)),
                    ],
                  ),
            ),
        const SizedBox(height: 80),
        const GlobalFooter(),
      ],
    ),
  ),
);
}

  Widget _buildImageGallery(BuildContext context, bool isMobile) {
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
                    tag: 'product_image_${widget.product.id}',
                    child: Transform.scale(
                      scale: (!isMobile && _isHovering) ? 2.5 : 1.0,
                      alignment: FractionalOffset(_hoverPosition.dx, _hoverPosition.dy),
                      child: CachedNetworkImage(
                        imageUrl: widget.product.images.isNotEmpty 
                            ? widget.product.images[_selectedImageIndex] 
                            : widget.product.imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
        ),
        const SizedBox(height: 16),
        if (widget.product.images.isNotEmpty)
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.product.images.length,
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
                      child: CachedNetworkImage(
                        imageUrl: widget.product.images[index],
                        fit: BoxFit.cover,
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

  Widget _buildProductInfo(BuildContext context, bool isMobile) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.product.isNew)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
                child: const Text('NEW ARRIVAL', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            const SizedBox(height: 16),
            Text(widget.product.title, style: isMobile ? Theme.of(context).textTheme.headlineLarge : Theme.of(context).textTheme.displayMedium),
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
                      Text('\$${widget.product.price.toStringAsFixed(2)}', style: (isMobile ? Theme.of(context).textTheme.headlineMedium : Theme.of(context).textTheme.displaySmall)?.copyWith(color: AppTheme.primaryBlue)),
                      const SizedBox(width: 12),
                      if (widget.product.price < widget.product.originalPrice)
                        Text('\$${widget.product.originalPrice.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge?.copyWith(decoration: TextDecoration.lineThrough, color: AppTheme.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Or from \$299.99/mo. with 12 months special financing.', style: TextStyle(color: AppTheme.textMuted)),
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
                  widget.product.specifications.isEmpty 
                    ? const Text('No specifications available.')
                    : ListView(
                        children: widget.product.specifications.entries.map((e) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(width: isMobile ? 100 : 150, child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(child: Text(e.value)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  // Easy Payment Tab
                  SingleChildScrollView(
                    child: Text(widget.product.easyPayment.isNotEmpty ? widget.product.easyPayment : 'No payment options available.'),
                  ),
                  // Enquiry Tab
                  SingleChildScrollView(
                    child: Text(widget.product.enquiry.isNotEmpty ? widget.product.enquiry : 'For enquiries, please contact us.'),
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
                      context.read<CartProvider>().addItem(widget.product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${widget.product.title} added to cart')),
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
                            buyNowItem: CartItem(product: widget.product, quantity: 1),
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
