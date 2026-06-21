import '../utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/product.dart';
import '../models/category.dart';
import '../widgets/product_card.dart';
import '../widgets/product_layout.dart';
import '../widgets/global_layout.dart';
import '../widgets/mobile_bottom_navigation.dart';
import '../theme/app_theme.dart';

class AllProductsScreen extends StatefulWidget {
  final bool offersOnly;

  const AllProductsScreen({super.key, this.offersOnly = false});

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen> {
  List<Product> _products = [];
  bool _isLoading = true;
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalItems = 0;
  final int _perPage = 12; // 12 products per page for a nice grid
  List<Brand> _brands = [];
  List<ChildCategory> _childCategories = [];
  int? _selectedBrandId;
  int? _selectedChildCategoryId;

  @override
  void initState() {
    super.initState();
    _fetchFilters();
    _fetchProducts();
  }

  Future<void> _fetchFilters() async {
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('${AppConstants.apiUrl}/brands?active=true')),
        http.get(Uri.parse('${AppConstants.apiUrl}/child-categories?active=true')),
      ]);
      if (mounted) {
        setState(() {
          _brands = responses[0].statusCode == 200 ? (json.decode(responses[0].body) as List).map((e) => Brand.fromJson(e)).toList() : [];
          _childCategories = responses[1].statusCode == 200 ? (json.decode(responses[1].body) as List).map((e) => ChildCategory.fromJson(e)).toList() : [];
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchProducts({int page = 1}) async {
    setState(() => _isLoading = true);
    try {
      final saleFilter = widget.offersOnly ? '&on_sale=true' : '';
      final brandFilter = _selectedBrandId == null ? '' : '&brand_id=$_selectedBrandId';
      final childFilter = _selectedChildCategoryId == null ? '' : '&child_category_id=$_selectedChildCategoryId';
      final response = await http.get(
        Uri.parse(
          '${AppConstants.apiUrl}/products?page=$page&per_page=$_perPage$saleFilter$brandFilter$childFilter',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            final List<dynamic> productList = data['data'];
            _products = productList.map((item) => Product.fromJson(item)).toList();
            _currentPage = data['current_page'];
            _lastPage = data['last_page'];
            _totalItems = data['total'];
            _isLoading = false;
          });
          // Scroll to top on page change
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlobalAppBar(showBackButton: true),
      drawer: const GlobalDrawer(),
      bottomNavigationBar: buildMobileBottomNavigationBar(context),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 40),
                  _buildFilters(),
                  const SizedBox(height: 24),
                  _buildProductGrid(context),
                  const SizedBox(height: 40),
                  if (_lastPage > 1) _buildPaginationControls(),
                  const SizedBox(height: 80),
                  const GlobalFooter(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 40 : 60,
        horizontal: 24,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withAlpha(10),
      ),
      child: Column(
        children: [
          Text(
            widget.offersOnly
                ? 'Latest Offers & Deals'
                : 'Explore All Products',
            style: Theme.of(context)
                .textTheme
                .displaySmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Wrap(spacing: 16, runSpacing: 12, alignment: WrapAlignment.center, children: [
        SizedBox(width: 240, child: DropdownButtonFormField<int>(isExpanded: true, value: _selectedBrandId, decoration: const InputDecoration(labelText: 'Filter by Brand'), items: [const DropdownMenuItem<int>(value: null, child: Text('All Brands')), ..._brands.map((b) => DropdownMenuItem<int>(value: int.tryParse(b.id), child: Text(b.name, overflow: TextOverflow.ellipsis)))], onChanged: (v) { setState(() => _selectedBrandId = v); _fetchProducts(page: 1); })),
        SizedBox(width: 280, child: DropdownButtonFormField<int>(isExpanded: true, value: _selectedChildCategoryId, decoration: const InputDecoration(labelText: 'Filter by Child Category'), items: [const DropdownMenuItem<int>(value: null, child: Text('All Child Categories')), ..._childCategories.map((c) => DropdownMenuItem<int>(value: int.tryParse(c.id), child: Text(c.name, overflow: TextOverflow.ellipsis)))], onChanged: (v) { setState(() => _selectedChildCategoryId = v); _fetchProducts(page: 1); })),
      ]),
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

  Widget _buildPaginationControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous Button
          OutlinedButton.icon(
            onPressed: _currentPage > 1 ? () => _fetchProducts(page: _currentPage - 1) : null,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Previous'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
          const SizedBox(width: 16),
          // Page Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Page $_currentPage of $_lastPage',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
            ),
          ),
          const SizedBox(width: 16),
          // Next Button
          ElevatedButton.icon(
            onPressed: _currentPage < _lastPage ? () => _fetchProducts(page: _currentPage + 1) : null,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Next'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
