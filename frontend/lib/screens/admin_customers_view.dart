import '../utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';

class Customer {
  final String id;
  final String name;
  final String email;

  Customer({
    required this.id,
    required this.name,
    required this.email,
  });
}

class AdminCustomersView extends StatefulWidget {
  const AdminCustomersView({super.key});

  @override
  State<AdminCustomersView> createState() => _AdminCustomersViewState();
}

class _AdminCustomersViewState extends State<AdminCustomersView> {
  bool _isAdding = false;
  Customer? _editingCustomer;
  bool _isLoading = true;
  List<Customer> _customers = [];
  
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _searchController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    try {
      final token = context.read<AuthProvider>().token;
      String url = '${AppConstants.apiUrl}/customers';
      if (_searchController.text.isNotEmpty) {
        url += '?search=${Uri.encodeComponent(_searchController.text)}';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _customers = data.map((item) => Customer(
              id: item['id'].toString(),
              name: item['name'] ?? '',
              email: item['email'] ?? '',
            )).toList();
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading customers: $e')));
      }
    }
  }

  Future<void> _submitCustomer() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      final bodyData = json.encode({
        'name': _nameController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
      });

      final token = context.read<AuthProvider>().token;
      http.Response response;
      if (_editingCustomer != null) {
        response = await http.put(
          Uri.parse('${AppConstants.apiUrl}/customers/${_editingCustomer!.id}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: bodyData,
        );
      } else {
        response = await http.post(
          Uri.parse('${AppConstants.apiUrl}/customers'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: bodyData,
        );
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_editingCustomer != null ? 'Customer updated successfully!' : 'Customer added successfully!')),
        );
        _clearForm();
        _fetchCustomers();
      } else {
        final err = json.decode(response.body);
        throw Exception(err['message'] ?? 'Failed to save customer');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteCustomer(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this customer?'),
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
        Uri.parse('${AppConstants.apiUrl}/customers/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer deleted successfully!')));
        _fetchCustomers();
      } else {
        throw Exception('Failed to delete customer');
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
      _editingCustomer = null;
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
    });
  }

  void _populateForm(Customer customer) {
    _editingCustomer = customer;
    _nameController.text = customer.name;
    _emailController.text = customer.email;
    _passwordController.clear(); // Don't populate password
    
    setState(() => _isAdding = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdding) {
      return _buildAddCustomerForm();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Manage Customers', style: Theme.of(context).textTheme.displaySmall),
            ElevatedButton.icon(
              onPressed: () {
                _clearForm();
                setState(() => _isAdding = true);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add New Customer'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Search Bar
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name or email...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty 
                        ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); _fetchCustomers(); })
                        : null,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (v) => _fetchCustomers(),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _fetchCustomers,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                  child: const Text('Search'),
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
              : _customers.isEmpty
                ? const Center(child: Text('No customers available. Add one!'))
                : ListView.separated(
                    itemCount: _customers.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final customer = _customers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryBlue,
                          child: Text(customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C', style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(customer.email),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: AppTheme.primaryBlue),
                              onPressed: () => _populateForm(customer),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteCustomer(customer.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddCustomerForm() {
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
                  Text(_editingCustomer != null ? 'Edit Customer' : 'Add New Customer', style: Theme.of(context).textTheme.headlineMedium),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _clearForm,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email Address'),
                validator: (v) => v!.isEmpty || !v.contains('@') ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: _editingCustomer != null ? 'New Password (leave blank to keep current)' : 'Password',
                ),
                obscureText: true,
                validator: (v) => _editingCustomer == null && v!.isEmpty ? 'Required for new customer' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitCustomer,
                  child: _isSubmitting 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_editingCustomer != null ? 'Update Customer' : 'Save Customer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
