import '../utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';

class AdminBankDetailsView extends StatefulWidget {
  const AdminBankDetailsView({super.key});

  @override
  State<AdminBankDetailsView> createState() => _AdminBankDetailsViewState();
}

class _AdminBankDetailsViewState extends State<AdminBankDetailsView> {
  List _bankDetails = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBankDetails();
  }

  Future<void> _fetchBankDetails() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token;
      final response = await http.get(
        Uri.parse('${AppConstants.apiUrl}/bank-details'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        setState(() {
          _bankDetails = json.decode(response.body);
        });
      }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteBankDetail(int id) async {
    try {
      final token = context.read<AuthProvider>().token;
      final response = await http.delete(
        Uri.parse('${AppConstants.apiUrl}/bank-details/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        _fetchBankDetails();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bank detail deleted')));
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void _showForm([Map? detail]) {
    final nameController = TextEditingController(text: detail?['account_name'] ?? '');
    final numberController = TextEditingController(text: detail?['account_number'] ?? '');
    final bankController = TextEditingController(text: detail?['bank_name'] ?? '');
    final branchController = TextEditingController(text: detail?['branch_name'] ?? '');
    bool isActive = detail?['is_active'] ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(detail == null ? 'Add Bank Detail' : 'Edit Bank Detail'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: bankController, decoration: const InputDecoration(labelText: 'Bank Name')),
                TextField(controller: branchController, decoration: const InputDecoration(labelText: 'Branch Name')),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Account Name')),
                TextField(controller: numberController, decoration: const InputDecoration(labelText: 'Account Number')),
                SwitchListTile(
                  title: const Text('Active'),
                  value: isActive,
                  onChanged: (v) => setModalState(() => isActive = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  'account_name': nameController.text,
                  'account_number': numberController.text,
                  'bank_name': bankController.text,
                  'branch_name': branchController.text,
                  'is_active': isActive,
                };
                final token = context.read<AuthProvider>().token;
                final url = detail == null 
                  ? '${AppConstants.apiUrl}/bank-details'
                  : '${AppConstants.apiUrl}/bank-details/${detail['id']}';
                
                final response = await (detail == null 
                  ? http.post(Uri.parse(url), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: json.encode(data))
                  : http.put(Uri.parse(url), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: json.encode(data)));

                if (response.statusCode == 200 || response.statusCode == 201) {
                  Navigator.pop(context);
                  _fetchBankDetails();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Bank Details', style: Theme.of(context).textTheme.displaySmall),
            ElevatedButton.icon(onPressed: () => _showForm(), icon: const Icon(Icons.add), label: const Text('Add Account')),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _bankDetails.length,
                itemBuilder: (context, index) {
                  final detail = _bankDetails[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text('${detail['bank_name']} - ${detail['account_number']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Name: ${detail['account_name']} | Branch: ${detail['branch_name'] ?? 'N/A'}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(detail['is_active'] ? Icons.check_circle : Icons.cancel, color: detail['is_active'] ? Colors.green : Colors.red),
                          IconButton(icon: const Icon(Icons.edit, color: AppTheme.primaryBlue), onPressed: () => _showForm(detail)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteBankDetail(detail['id'])),
                        ],
                      ),
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }
}
