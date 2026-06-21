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

class CategoryProductsScreen extends StatefulWidget {
  final String categoryId;
  final String categoryTitle;

  const CategoryProductsScreen({
    super.key, 
    required this.categoryId,
    required this.categoryTitle,
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  List<Product> _products = [];
  List<Subcategory> _subcategories = [];
  String? _selectedSubcategoryId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSubcategories();
    _fetchCategoryProducts();
  }

  Future<void> _fetchCategoryProducts() async {
    try {
      var url = '${AppConstants.apiUrl}/products?category_id=${widget.categoryId}&all=1';
      if (_selectedSubcategoryId != null) {
        url += '&subcategory_id=$_selectedSubcategoryId';
      }
      final response = await http.get(Uri.parse(url));
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


  Future<void> _fetchSubcategories() async {
    try {
      final response = await http.get(Uri.parse('${AppConstants.apiUrl}/subcategories?category_id=${widget.categoryId}&active=1'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _subcategories = data.map((item) => Subcategory.fromJson(item)).toList();
          });
        }
      }
    } catch (_) {}
  }

  void _selectSubcategory(String? subcategoryId) {
    setState(() {
      _selectedSubcategoryId = subcategoryId;
      _isLoading = true;
    });
    _fetchCategoryProducts();
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
            const SizedBox(height: 24),
            _buildSubcategoryFilters(),
            const SizedBox(height: 40),
            _products.isEmpty
              ? _buildEmptyState()
              : _buildProductGrid(context),
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
      padding: EdgeInsets.symmetric(vertical: isMobile ? 40 : 60, horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withAlpha(10),
      ),
      child: Column(
        children: [
          Text(
            widget.categoryTitle,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }


  Widget _buildSubcategoryFilters() {
    if (_subcategories.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: _selectedSubcategoryId == null,
            onSelected: (_) => _selectSubcategory(null),
          ),
          ..._subcategories.map((subcategory) => ChoiceChip(
                label: Text(subcategory.name),
                selected: _selectedSubcategoryId == subcategory.id,
                onSelected: (_) => _selectSubcategory(subcategory.id),
              )),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: AppTheme.textMuted.withAlpha(100)),
          const SizedBox(height: 16),
          const Text('No products found in this category.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go('/'),
            child: const Text('Return to Home'),
          ),
        ],
      ),
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
}
