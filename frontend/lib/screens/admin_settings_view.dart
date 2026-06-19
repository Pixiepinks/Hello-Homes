import '../utils/constants.dart';
import '../utils/price_formatter.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class AdminSettingsView extends StatefulWidget {
  const AdminSettingsView({super.key});

  @override
  State<AdminSettingsView> createState() => _AdminSettingsViewState();
}

class _AdminSettingsViewState extends State<AdminSettingsView> {
  bool _isLoading = true;
  List<dynamic> _deliveryOptions = [];
  List<dynamic> _products = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token;
      final headers = {'Authorization': 'Bearer $token'};
      
      final optionsRes = await http.get(Uri.parse('${AppConstants.apiUrl}/delivery-options'), headers: headers);
      final productsRes = await http.get(Uri.parse('${AppConstants.apiUrl}/products?all=1'), headers: headers);

      if (optionsRes.statusCode == 200 && productsRes.statusCode == 200) {
        setState(() {
          _deliveryOptions = json.decode(optionsRes.body);
          _products = json.decode(productsRes.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showOptionDialog([Map<String, dynamic>? option]) async {
    final isEditing = option != null;
    final nameController = TextEditingController(text: option?['name'] ?? '');
    final baseFeeController = TextEditingController(text: option?['base_fee']?.toString() ?? '0');
    final additionalFeeController = TextEditingController(text: option?['additional_fee_per_unit']?.toString() ?? '0');
    String type = option?['type'] ?? 'weight_based';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Delivery Option' : 'Add Delivery Option'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                DropdownButtonFormField<String>(
                  value: type,
                  items: const [
                    DropdownMenuItem(value: 'weight_based', child: Text('Weight Based')),
                    DropdownMenuItem(value: 'flat_rate', child: Text('Flat Rate')),
                    DropdownMenuItem(value: 'free', child: Text('Free')),
                  ],
                  onChanged: (v) => setDialogState(() => type = v!),
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
                TextField(controller: baseFeeController, decoration: const InputDecoration(labelText: 'Base Fee / Minimum Fee'), keyboardType: TextInputType.number),
                if (type == 'weight_based')
                  TextField(controller: additionalFeeController, decoration: const InputDecoration(labelText: 'Additional Fee (per KG)'), keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final token = context.read<AuthProvider>().token;
                final data = {
                  'name': nameController.text,
                  'type': type,
                  'base_fee': double.parse(baseFeeController.text),
                  'additional_fee_per_unit': double.parse(additionalFeeController.text),
                };
                
                http.Response res;
                if (isEditing) {
                  res = await http.put(Uri.parse('${AppConstants.apiUrl}/delivery-options/${option['id']}'), 
                    headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
                    body: json.encode(data));
                } else {
                  res = await http.post(Uri.parse('${AppConstants.apiUrl}/delivery-options'), 
                    headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
                    body: json.encode(data));
                }

                if (res.statusCode == 200 || res.statusCode == 201) {
                  Navigator.pop(context);
                  _fetchData();
                }
              }, 
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateAllProducts(int optionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Bulk Update'),
        content: const Text('This will set this delivery option for ALL products. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);
    try {
      final token = context.read<AuthProvider>().token;
      final res = await http.post(
        Uri.parse('${AppConstants.apiUrl}/delivery-options/update-all-products'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({'delivery_option_id': optionId}),
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All products updated successfully')));
        _fetchData();
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Delivery Settings', style: Theme.of(context).textTheme.displaySmall),
              ElevatedButton.icon(
                onPressed: () => _showOptionDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Option'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Delivery Options List
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _deliveryOptions.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final opt = _deliveryOptions[index];
                return ListTile(
                  title: Text(opt['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Type: ${opt['type']} | Base: ${formatDynamicPrice(opt['base_fee'])}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.all_inclusive, color: AppTheme.primaryBlue),
                        tooltip: 'Apply to all products',
                        onPressed: () => _updateAllProducts(opt['id']),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.grey),
                        onPressed: () => _showOptionDialog(opt),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 48),
          Text('Bulk Product Delivery Update', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          const Text('To update individual products, please go to the Products tab and edit the product directly.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
