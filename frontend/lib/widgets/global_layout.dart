import '../utils/constants.dart';
import '../utils/price_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import 'product_search_bar.dart';
import 'notification_bell.dart';

class GlobalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackButton;

  const GlobalAppBar({super.key, this.showBackButton = false});

  @override
  Widget build(BuildContext context) {
    final cartItemCount = context.watch<CartProvider>().itemCount;
    final isMobile = MediaQuery.of(context).size.width < 800;

    return AppBar(
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(SecondaryCategoryNavBar.desktopHeight),
        child: SecondaryCategoryNavBar(),
      ),
      automaticallyImplyLeading: showBackButton,
      titleSpacing: showBackButton ? null : (isMobile ? 12 : 16),
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            )
          : null,
      title: Row(
        children: [
          InkWell(
            onTap: () => context.go('/'),
            child: SvgPicture.asset(
              'assets/images/hello_homes_logo.svg',
              height: isMobile ? 40 : 52,
              fit: BoxFit.contain,
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 32),
            const Expanded(child: Center(child: ProductSearchBar())),
          ],
        ],
      ),
      actions: [
        if (isMobile)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Show search in a modal or expand it
              showSearch(context: context, delegate: ProductSearchDelegate());
            },
          ),

        const NotificationBell(),

        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () => context.go('/checkout'),
              tooltip: 'Checkout',
            ),
            if (cartItemCount > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.accentOrange,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    cartItemCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        Consumer<AuthProvider>(
          builder: (context, auth, _) => IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () =>
                context.go(auth.isAuthenticated ? '/profile' : '/login'),
            tooltip: auth.isAuthenticated ? 'My Account' : 'Login',
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(
        kToolbarHeight + SecondaryCategoryNavBar.desktopHeight,
      );
}

class SecondaryCategoryNavBar extends StatelessWidget {
  static const double desktopHeight = 44;
  static const double mobileHeight = 44;

  const SecondaryCategoryNavBar({super.key});

  static const List<String> _centerItems = [
    'Brands',
    'Deals',
    'New Arrivals',
    'Furniture',
    'Appliances',
    'Electronics',
  ];

  static const List<String> _rightItems = [
    'Track your order',
    'Contact',
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final height = isMobile ? mobileHeight : desktopHeight;

    return Container(
      height: height,
      width: double.infinity,
      color: const Color(0xFF0B74B8),
      child: isMobile
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  const _SecondaryCategoryNavItem(
                    label: 'All Categories',
                    showMenuIcon: true,
                  ),
                  for (final item in _centerItems)
                    _SecondaryCategoryNavItem(label: item),
                  for (final item in _rightItems)
                    _SecondaryCategoryNavItem(label: item),
                ],
              ),
            )
          : Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 36),
                  child: _SecondaryCategoryNavItem(
                    label: 'All Categories',
                    showMenuIcon: true,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final item in _centerItems)
                          _SecondaryCategoryNavItem(label: item),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 36),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      for (final item in _rightItems)
                        _SecondaryCategoryNavItem(label: item),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _SecondaryCategoryNavItem extends StatelessWidget {
  final String label;
  final bool showMenuIcon;

  const _SecondaryCategoryNavItem({
    required this.label,
    this.showMenuIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return InkWell(
      onTap: () {},
      child: Container(
        height: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 12),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showMenuIcon) ...[
              const Icon(Icons.menu, color: Colors.white, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GlobalDrawer extends StatelessWidget {
  const GlobalDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.primaryBlue),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Hello', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.accentOrange, fontWeight: FontWeight.bold)),
                  Text('Homes', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              context.pop();
              context.go('/');
            },
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('© 2026 Hello Homes', style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class GlobalFooter extends StatelessWidget {
  const GlobalFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    
    return Container(
      width: double.infinity,
      color: AppTheme.darkBlue,
      padding: EdgeInsets.all(isMobile ? 30 : 60),
      child: Column(
        children: [
          if (isMobile)
            _buildMobileFooter(context)
          else 
            _buildDesktopFooter(context),
          const SizedBox(height: 60),
          const Divider(color: Colors.white24),
          const SizedBox(height: 24),
          Text('© 2026 Hello Homes. All rights reserved.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildDesktopFooter(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Hello', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.accentOrange, fontWeight: FontWeight.bold)),
                  Text('Homes', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'The Expert Neighbor for all your premium home electronic and appliance needs.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(width: 60),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Shop Categories', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
              const SizedBox(height: 16),
              _footerLink('Electronics'),
              _footerLink('Appliances'),
              _footerLink('Furniture'),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Support', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
              const SizedBox(height: 16),
              _footerLink('Help Center'),
              _footerLink('Delivery Info'),
              _footerLink('Returns'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileFooter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Hello', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.accentOrange, fontWeight: FontWeight.bold)),
            Text('Homes', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'The Expert Neighbor for all your premium home electronic and appliance needs.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 40),
        Text('Shop Categories', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
        const SizedBox(height: 16),
        _footerLink('Electronics'),
        _footerLink('Appliances'),
        _footerLink('Furniture'),
        const SizedBox(height: 30),
        Text('Support', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
        const SizedBox(height: 16),
        _footerLink('Help Center'),
        _footerLink('Delivery Info'),
        _footerLink('Returns'),
      ],
    );
  }

  Widget _footerLink(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {},
        child: Text(title, style: const TextStyle(color: Colors.white70)),
      ),
    );
  }
}

class ProductSearchDelegate extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Center(
      child: Text('Search results for "$query"'),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Search for products'));
    }

    return FutureBuilder<http.Response>(
      future: http.get(Uri.parse('${AppConstants.apiUrl}/products?search=$query&per_page=10')),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.statusCode != 200) {
          return const Center(child: Text('Error loading results'));
        }

        final data = json.decode(snapshot.data!.body);
        final List<dynamic> products = data['data'] ?? [];

        if (products.isEmpty) {
          return const Center(child: Text('No products found'));
        }

        // Grouping logic
        Map<String, List<dynamic>> grouped = {};
        for (var p in products) {
          String categoryName = p['category']?['name'] ?? 'Other';
          if (!grouped.containsKey(categoryName)) {
            grouped[categoryName] = [];
          }
          grouped[categoryName]!.add(p);
        }

        List<dynamic> items = [];
        grouped.forEach((category, prods) {
          items.add(category);
          items.addAll(prods);
        });

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            if (item is String) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey[100],
                child: Text(
                  item.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              );
            }
            final product = item as Map<String, dynamic>;
            return ListTile(
              leading: Image.network(
                product['image_url'] ?? 'https://via.placeholder.com/50',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.image),
              ),
              title: Text(product['title'], maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Row(
                children: [
                  Text(
                    formatDynamicPrice(product['original_price'] ?? product['price']),
                    style: const TextStyle(color: AppTheme.textMuted, decoration: TextDecoration.lineThrough),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatDynamicPrice(product['price']),
                    style: const TextStyle(color: AppTheme.accentOrange, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              onTap: () {
                close(context, null);
                context.go('/product/${product['id']}');
              },
            );
          },
        );
      },
    );
  }
}
