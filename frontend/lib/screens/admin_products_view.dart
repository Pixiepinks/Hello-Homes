import '../utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_theme.dart';
import '../models/product.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AdminProductsView extends StatefulWidget {
  const AdminProductsView({super.key});

  @override
  State<AdminProductsView> createState() => _AdminProductsViewState();
}

class _AdminProductsViewState extends State<AdminProductsView> {
  bool _isAdding = false;
  Product? _editingProduct;
  bool _isLoading = true;
  List<Product> _products = [];
  
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _imagesController = TextEditingController();
  final _specificationsController = TextEditingController();
  final _easyPaymentController = TextEditingController();
  final _enquiryController = TextEditingController();
  
  bool _isNew = false;
  bool _isOnSale = false;
  int? _selectedDeliveryOptionId;
  int? _selectedCategoryId;
  final _weightController = TextEditingController(text: '1.0');
  List<dynamic> _deliveryOptions = [];
  bool _isLoadingOptions = true;
  bool _isSubmitting = false;
  
  // Search and Filter State
  final _searchController = TextEditingController();
  int? _filterCategoryId;
  bool? _filterOnSale;
  bool? _filterIsNew;
  
  // Pagination State
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalProducts = 0;
  final int _perPage = 10;
  
  List<dynamic> _categories = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _fetchDeliveryOptions();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(Uri.parse('${AppConstants.apiUrl}/categories'));
      if (response.statusCode == 200) {
        setState(() {
          _categories = json.decode(response.body);
        });
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  Future<void> _fetchDeliveryOptions() async {
    try {
      final token = context.read<AuthProvider>().token;
      final response = await http.get(
        Uri.parse('${AppConstants.apiUrl}/delivery-options'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          _deliveryOptions = json.decode(response.body);
          _isLoadingOptions = false;
          if (_deliveryOptions.isNotEmpty && _selectedDeliveryOptionId == null) {
             final standard = _deliveryOptions.firstWhere((o) => o['type'] == 'weight_based', orElse: () => _deliveryOptions.first);
             _selectedDeliveryOptionId = standard['id'];
          }
        });
      } else {
        debugPrint('Failed to load delivery options: ${response.statusCode}');
        setState(() => _isLoadingOptions = false);
      }
    } catch (e) {
      debugPrint('Error fetching delivery options: $e');
      setState(() => _isLoadingOptions = false);
    }
  }

  Future<void> _fetchProducts({int page = 1}) async {
    setState(() => _isLoading = true);
    try {
      String url = '${AppConstants.apiUrl}/products?page=$page&per_page=$_perPage';
      
      if (_searchController.text.isNotEmpty) {
        url += '&search=${Uri.encodeComponent(_searchController.text)}';
      }
      if (_filterCategoryId != null) {
        url += '&category_id=$_filterCategoryId';
      }
      if (_filterOnSale != null) {
        url += '&on_sale=$_filterOnSale';
      }
      if (_filterIsNew != null) {
        url += '&is_new=$_filterIsNew';
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _products = (data['data'] as List).map((item) => Product.fromJson(item)).toList();
            _currentPage = int.tryParse(data['current_page']?.toString() ?? '1') ?? 1;
            _lastPage = int.tryParse(data['last_page']?.toString() ?? '1') ?? 1;
            _totalProducts = int.tryParse(data['total']?.toString() ?? '0') ?? 0;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading products: $e')));
      }
    }
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      final List<String> imagesList = _imagesController.text.split(',')
          .map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
          
      final Map<String, String> specsMap = {};
      final List<String> specsLines = _specificationsController.text.split('\n');
      for (var line in specsLines) {
        if (line.contains(':')) {
          final parts = line.split(':');
          specsMap[parts[0].trim()] = parts.sublist(1).join(':').trim();
        }
      }

      final bodyData = json.encode({
        'title': _titleController.text,
        'subtitle': '',
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'original_price': double.tryParse(_originalPriceController.text) ?? 0.0,
        'image_url': _imageUrlController.text,
        'is_new': _isNew,
        'is_on_sale': _isOnSale,
        'images': imagesList,
        'specifications': specsMap,
        'easy_payment': _easyPaymentController.text,
        'enquiry': _enquiryController.text,
        'delivery_option_id': _selectedDeliveryOptionId,
        'weight': double.tryParse(_weightController.text) ?? 1.0,
        'category_id': _selectedCategoryId,
      });

      final token = context.read<AuthProvider>().token;
      http.Response response;
      if (_editingProduct != null) {
        response = await http.put(
          Uri.parse('${AppConstants.apiUrl}/products/${_editingProduct!.id}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: bodyData,
        );
      } else {
        response = await http.post(
          Uri.parse('${AppConstants.apiUrl}/products'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: bodyData,
        );
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_editingProduct != null ? 'Product updated successfully!' : 'Product added successfully!')),
        );
        _clearForm();
        _fetchProducts();
      } else {
        throw Exception('Failed to save product');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteProduct(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: const TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token;
      final response = await http.delete(
        Uri.parse('${AppConstants.apiUrl}/products/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted successfully!')));
        _fetchProducts();
      } else {
        throw Exception('Failed to delete product');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _clearForm() {
    setState(() {
      _isAdding = false;
      _editingProduct = null;
      _titleController.clear();
      _priceController.clear();
      _originalPriceController.clear();
      _imageUrlController.clear();
      _imagesController.clear();
      _specificationsController.clear();
      _easyPaymentController.clear();
      _enquiryController.clear();
      _isNew = false;
      _isOnSale = false;
      _selectedCategoryId = null;
      if (_deliveryOptions.isNotEmpty) {
        final standard = _deliveryOptions.firstWhere((o) => o['type'] == 'weight_based', orElse: () => _deliveryOptions.first);
        _selectedDeliveryOptionId = standard['id'];
      }
      _weightController.text = '1.0';
    });
  }

  void _populateForm(Product product) {
    _editingProduct = product;
    _titleController.text = product.title;
    _priceController.text = product.price.toString();
    _originalPriceController.text = product.originalPrice.toString();
    _imageUrlController.text = product.imageUrl;
    _imagesController.text = product.images.join(', ');
    _easyPaymentController.text = product.easyPayment;
    _enquiryController.text = product.enquiry;
    _isNew = product.isNew;
    _isOnSale = product.isOnSale;
    _selectedDeliveryOptionId = product.deliveryOptionId;
    _selectedCategoryId = product.categoryId;
    _weightController.text = product.weight.toString();

    String specsText = '';
    product.specifications.forEach((key, value) {
      specsText += '$key: $value\n';
    });
    _specificationsController.text = specsText.trim();
    
    setState(() => _isAdding = true);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (_isAdding) {
      return _buildAddProductForm(isMobile);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        isMobile 
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Manage Products', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _clearForm();
                      setState(() => _isAdding = true);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Product'),
                  ),
                ),
              ],
            )
          : Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: [
                Text('Manage Products', style: Theme.of(context).textTheme.headlineMedium),
                ElevatedButton.icon(
                  onPressed: () {
                    _clearForm();
                    setState(() => _isAdding = true);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Product'),
                ),
              ],
            ),
        const SizedBox(height: 16),
        // Search and Filter Bar
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: isMobile ? double.infinity : 400,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search products...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty 
                            ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); _fetchProducts(); })
                            : null,
                          border: const OutlineInputBorder(),
                        ),
                        onSubmitted: (v) => _fetchProducts(page: 1),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _fetchProducts(page: 1),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                      child: const Text('Search'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Category Filter
                        SizedBox(
                          width: 200,
                        child: DropdownButtonFormField<int>(
                          isExpanded: true,
                          value: _filterCategoryId,
                          decoration: const InputDecoration(labelText: 'Category', contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                          items: [
                            const DropdownMenuItem<int>(value: null, child: Text('All Categories', overflow: TextOverflow.ellipsis)),
                            ..._categories.map((c) => DropdownMenuItem<int>(value: c['id'], child: Text(c['title']?.toString() ?? 'Unnamed Category', overflow: TextOverflow.ellipsis))),
                          ],
                          onChanged: (v) {
                            setState(() => _filterCategoryId = v);
                            _fetchProducts(page: 1);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Sale Filter
                      FilterChip(
                        label: const Text('On Sale'),
                        selected: _filterOnSale == true,
                        onSelected: (v) {
                          setState(() => _filterOnSale = v ? true : null);
                          _fetchProducts(page: 1);
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('New Arrival'),
                        selected: _filterIsNew == true,
                        onSelected: (v) {
                          setState(() => _filterIsNew = v ? true : null);
                          _fetchProducts(page: 1);
                        },
                      ),
                      const SizedBox(width: 16),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _filterCategoryId = null;
                            _filterOnSale = null;
                            _filterIsNew = null;
                          });
                          _fetchProducts(page: 1);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset Filters'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _products.isEmpty
                ? const Center(child: Text('No products available.'))
                : Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          itemCount: _products.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final product = _products[index];
                            return ListTile(
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                  image: product.imageUrl.isNotEmpty
                                      ? DecorationImage(image: NetworkImage(product.imageUrl), fit: BoxFit.cover)
                                      : null,
                                ),
                                child: product.imageUrl.isEmpty ? const Icon(Icons.image, color: Colors.grey) : null,
                              ),
                              title: Text(product.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Rs.${product.price.toStringAsFixed(2)}'),
                                  if (product.categoryName.isNotEmpty)
                                    Text(product.categoryName, style: TextStyle(color: AppTheme.primaryBlue.withOpacity(0.7), fontSize: 12)),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: AppTheme.primaryBlue),
                                    onPressed: () => _populateForm(product),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteProduct(product.id),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      // Pagination Controls
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        child: isMobile 
                            ? Column(
                                children: [
                                  Text('Showing ${_products.length} of $_totalProducts products'),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.chevron_left),
                                        onPressed: _currentPage > 1 ? () => _fetchProducts(page: _currentPage - 1) : null,
                                      ),
                                      Text('Page $_currentPage of $_lastPage'),
                                      IconButton(
                                        icon: const Icon(Icons.chevron_right),
                                        onPressed: _currentPage < _lastPage ? () => _fetchProducts(page: _currentPage + 1) : null,
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Showing ${_products.length} of $_totalProducts products'),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.chevron_left),
                                        onPressed: _currentPage > 1 ? () => _fetchProducts(page: _currentPage - 1) : null,
                                      ),
                                      Text('Page $_currentPage of $_lastPage'),
                                      IconButton(
                                        icon: const Icon(Icons.chevron_right),
                                        onPressed: _currentPage < _lastPage ? () => _fetchProducts(page: _currentPage + 1) : null,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddProductForm(bool isMobile) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_editingProduct != null ? 'Edit Product' : 'Add New Product', style: Theme.of(context).textTheme.headlineMedium),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _clearForm,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Product Title'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              isMobile 
                ? Column(
                    children: [
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(labelText: 'Price'),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _originalPriceController,
                        decoration: const InputDecoration(labelText: 'Original Price'),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(labelText: 'Price'),
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _originalPriceController,
                          decoration: const InputDecoration(labelText: 'Original Price'),
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'Main Image URL'),
              ),
              const SizedBox(height: 16),
              // Category Selection
              DropdownButtonFormField<int>(
                isExpanded: true,
                value: _selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Product Category'),
                items: [
                  const DropdownMenuItem<int>(value: null, child: Text('No Category', overflow: TextOverflow.ellipsis)),
                  ..._categories.map((c) => DropdownMenuItem<int>(value: c['id'], child: Text(c['title']?.toString() ?? 'Unnamed Category', overflow: TextOverflow.ellipsis))),
                ],
                onChanged: (v) => setState(() => _selectedCategoryId = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imagesController,
                decoration: const InputDecoration(
                  labelText: 'Additional Image URLs (Comma separated)',
                  hintText: 'url1, url2, url3',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _specificationsController,
                decoration: const InputDecoration(
                  labelText: 'Specifications (Key: Value per line)',
                  hintText: 'Processor: M3 Max\nRAM: 32GB',
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _easyPaymentController,
                decoration: const InputDecoration(labelText: 'Easy Payment Details'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _enquiryController,
                decoration: const InputDecoration(labelText: 'Enquiry Details'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const Text('Delivery Configuration', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _selectedDeliveryOptionId,
                items: _deliveryOptions.map((opt) {
                  return DropdownMenuItem<int>(
                    value: opt['id'],
                    child: Text('${opt['name']} (Rs. ${opt['base_fee']})'),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedDeliveryOptionId = v),
                decoration: InputDecoration(
                  labelText: 'Delivery Option',
                  hintText: _isLoadingOptions ? 'Loading options...' : 'Select a delivery method',
                  prefixIcon: const Icon(Icons.local_shipping_outlined),
                ),
                validator: (v) => v == null ? 'Please select a delivery option' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(labelText: 'Product Weight (KG)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 24,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(value: _isNew, onChanged: (v) => setState(() => _isNew = v!)),
                      const Text('Is New Arrival'),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(value: _isOnSale, onChanged: (v) => setState(() => _isOnSale = v!)),
                      const Text('Is On Sale'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitProduct,
                  child: _isSubmitting 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_editingProduct != null ? 'Update Product' : 'Save Product'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
