import '../utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../theme/app_theme.dart';
import '../models/product.dart';

class ProductSearchBar extends StatefulWidget {
  final bool isMobile;
  const ProductSearchBar({super.key, this.isMobile = false});

  @override
  State<ProductSearchBar> createState() => _ProductSearchBarState();
}

class _ProductSearchBarState extends State<ProductSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  bool _showDropdown = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _hideDropdown();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    _hideDropdown();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _performSearch(query);
      } else {
        setState(() {
          _searchResults = [];
          _showDropdown = false;
          _hideDropdown();
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _showDropdown = true;
    });
    _showOverlay();

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiUrl}/products?search=$query&per_page=5'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _searchResults = data['data'] ?? [];
          _isLoading = false;
        });
        _updateOverlay();
      }
    } catch (e) {
      debugPrint('Search error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _showDropdown = false);
  }

  void _updateOverlay() {
    _overlayEntry?.markNeedsBuild();
  }

  List<dynamic> _getGroupedResults() {
    if (_searchResults.isEmpty) return [];
    
    Map<String, List<dynamic>> grouped = {};
    for (var p in _searchResults) {
      String categoryName = p['category']?['name'] ?? 'Other';
      if (!grouped.containsKey(categoryName)) {
        grouped[categoryName] = [];
      }
      grouped[categoryName]!.add(p);
    }

    List<dynamic> items = [];
    grouped.forEach((category, products) {
      items.add(category);
      items.addAll(products);
    });
    return items;
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: widget.isMobile ? MediaQuery.of(context).size.width * 0.9 : 400,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 5.0),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 400),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.borderLight),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : _searchResults.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No products found', style: TextStyle(color: AppTheme.textMuted)),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: _getGroupedResults().length,
                          itemBuilder: (context, index) {
                            final item = _getGroupedResults()[index];
                            if (item is String) {
                              // Category Header
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                color: Colors.grey[50],
                                child: Text(
                                  item.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryBlue,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              );
                            }
                            final product = item as Map<String, dynamic>;
                            return ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  product['image_url'] ?? 'https://via.placeholder.com/50',
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], width: 40, height: 40, child: const Icon(Icons.image, size: 20)),
                                ),
                              ),
                              title: Text(product['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text('\$${product['price']}', style: const TextStyle(color: AppTheme.accentOrange, fontWeight: FontWeight.bold)),
                              onTap: () {
                                _hideDropdown();
                                _controller.clear();
                                context.go('/product/${product['id']}');
                              },
                            );
                          },
                        ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        width: widget.isMobile ? double.infinity : 300,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search products...',
            hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _controller.clear();
                      _onSearchChanged('');
                    },
                  )
                : null,
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              _hideDropdown();
              context.go('/products?search=$value');
            }
          },
        ),
      ),
    );
  }
}
