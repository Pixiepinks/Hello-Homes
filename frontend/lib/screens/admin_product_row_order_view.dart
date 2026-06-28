import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';

class AdminProductRowOrderView extends StatefulWidget {
  const AdminProductRowOrderView({super.key});

  @override
  State<AdminProductRowOrderView> createState() => _AdminProductRowOrderViewState();
}

class _HomepageRow {
  final String key;
  final String title;
  final String type;

  _HomepageRow({required this.key, required this.title, required this.type});

  factory _HomepageRow.fromJson(Map<String, dynamic> json) => _HomepageRow(
    key: json['key']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    type: json['type']?.toString() ?? '',
  );
}

class _AdminProductRowOrderViewState extends State<AdminProductRowOrderView> {
  List<_HomepageRow> _rows = [];
  List<Product> _products = [];
  _HomepageRow? _selectedRow;
  bool _loadingRows = true;
  bool _loadingProducts = false;
  bool _saving = false;
  bool _dirty = false;

  Map<String, String> get _headers {
    final token = context.read<AuthProvider>().token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  @override
  void initState() {
    super.initState();
    _loadRows();
  }

  Future<void> _loadRows() async {
    setState(() => _loadingRows = true);
    try {
      final response = await http.get(Uri.parse('${AppConstants.apiUrl}/admin/homepage-rows'), headers: _headers);
      if (response.statusCode == 200) {
        final rows = (json.decode(response.body) as List<dynamic>).map((item) => _HomepageRow.fromJson(item)).where((row) => row.key.isNotEmpty).toList();
        setState(() {
          _rows = rows;
          _selectedRow = rows.isNotEmpty ? rows.first : null;
          _loadingRows = false;
        });
        if (_selectedRow != null) await _loadProducts(_selectedRow!);
      } else {
        throw Exception('Failed to load rows (${response.statusCode})');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingRows = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading homepage rows: $e')));
      }
    }
  }

  Future<void> _loadProducts(_HomepageRow row) async {
    setState(() {
      _loadingProducts = true;
      _dirty = false;
    });
    try {
      final response = await http.get(Uri.parse('${AppConstants.apiUrl}/admin/homepage-rows/${Uri.encodeComponent(row.key)}/products'), headers: _headers);
      if (response.statusCode == 200) {
        final products = (json.decode(response.body) as List<dynamic>).map((item) => Product.fromJson(item)).toList();
        setState(() {
          _products = products;
          _loadingProducts = false;
        });
      } else {
        throw Exception('Failed to load products (${response.statusCode})');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingProducts = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading products: $e')));
      }
    }
  }

  Future<void> _saveOrder() async {
    final row = _selectedRow;
    if (row == null) return;
    setState(() => _saving = true);
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiUrl}/admin/homepage-rows/${Uri.encodeComponent(row.key)}/products/order'),
        headers: _headers,
        body: json.encode({'product_ids': _products.map((product) => int.tryParse(product.id) ?? product.id).toList()}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          _products = ((data['products'] ?? []) as List<dynamic>).map((item) => Product.fromJson(item)).toList();
          _dirty = false;
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product order saved')));
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving order: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _resetOrder() async {
    final row = _selectedRow;
    if (row == null) return;
    setState(() => _saving = true);
    try {
      final response = await http.post(Uri.parse('${AppConstants.apiUrl}/admin/homepage-rows/${Uri.encodeComponent(row.key)}/products/reset-order'), headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          _products = ((data['products'] ?? []) as List<dynamic>).map((item) => Product.fromJson(item)).toList();
          _dirty = false;
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Default order restored')));
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error resetting order: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Product Row Order', style: Theme.of(context).textTheme.displaySmall),
      const SizedBox(height: 8),
      const Text('Choose a homepage row/category and drag products into the order customers should see.'),
      const SizedBox(height: 24),
      if (_loadingRows) const Center(child: CircularProgressIndicator()) else Row(children: [
        Expanded(child: DropdownButtonFormField<_HomepageRow>(
          value: _selectedRow,
          decoration: const InputDecoration(labelText: 'Homepage row/category', border: OutlineInputBorder()),
          items: _rows.map((row) => DropdownMenuItem(value: row, child: Text('${row.title} (${row.type})', overflow: TextOverflow.ellipsis))).toList(),
          onChanged: _saving ? null : (row) { if (row != null) { setState(() => _selectedRow = row); _loadProducts(row); } },
        )),
        const SizedBox(width: 12),
        ElevatedButton.icon(onPressed: (!_dirty || _saving) ? null : _saveOrder, icon: const Icon(Icons.save), label: const Text('Save Order')),
        const SizedBox(width: 8),
        OutlinedButton.icon(onPressed: _saving ? null : _resetOrder, icon: const Icon(Icons.restart_alt), label: const Text('Reset Order')),
      ]),
      const SizedBox(height: 16),
      Expanded(child: Container(
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppTheme.borderLight), borderRadius: BorderRadius.circular(12)),
        child: _loadingProducts ? const Center(child: CircularProgressIndicator()) : _products.isEmpty ? const Center(child: Text('No products found for this row.')) : ReorderableListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _products.length,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final item = _products.removeAt(oldIndex);
              _products.insert(newIndex, item);
              _dirty = true;
            });
          },
          itemBuilder: (context, index) {
            final product = _products[index];
            return Card(key: ValueKey(product.id), child: ListTile(
              leading: CircleAvatar(backgroundImage: product.imageUrl.isNotEmpty ? NetworkImage(product.imageUrl) : null, child: product.imageUrl.isEmpty ? const Icon(Icons.image) : null),
              title: Text(product.title),
              subtitle: Text('#${index + 1}${product.categoryName.isNotEmpty ? ' • ${product.categoryName}' : ''}'),
              trailing: const Icon(Icons.drag_handle),
            ));
          },
        ),
      )),
    ]);
  }
}
