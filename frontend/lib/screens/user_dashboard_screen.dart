import '../utils/constants.dart';
import '../utils/price_formatter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  int _selectedIndex = 0;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nicController = TextEditingController();
  final _addressController = TextEditingController();
  final _districtController = TextEditingController();
  final _postalController = TextEditingController();

  List<dynamic> _orders = [];
  bool _isLoadingOrders = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      context.go('/login');
      return;
    }

    if (auth.user != null) {
      _nameController.text = auth.user!['name'] ?? '';
      _phoneController.text = auth.user!['phone'] ?? '';
      _nicController.text = auth.user!['nic_number'] ?? '';
      _addressController.text = auth.user!['street_address'] ?? '';
      _districtController.text = auth.user!['district'] ?? '';
      _postalController.text = auth.user!['postal_code'] ?? '';
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiUrl}/user/orders'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _orders = json.decode(response.body);
            _isLoadingOrders = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      if (mounted) setState(() => _isLoadingOrders = false);
    }
  }

  Future<void> _saveDetails() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    final auth = context.read<AuthProvider>();

    try {
      final response = await http.put(
        Uri.parse('${AppConstants.apiUrl}/user/details'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${auth.token}'
        },
        body: json.encode({
          'name': _nameController.text,
          'phone': _phoneController.text,
          'nic_number': _nicController.text,
          'street_address': _addressController.text,
          'district': _districtController.text,
          'postal_code': _postalController.text,
        }),
      );
      
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Details updated successfully')));
          await auth.fetchUser();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update details')));
        }
      }
    } catch (e) {
      debugPrint('Error saving details: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order #${order['id']} Details'),
        content: SizedBox(
          width: isMobile ? MediaQuery.of(context).size.width * 0.9 : 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date: ${order['created_at'].toString().split('T').first}'),
              Text('Status: ${order['status'].toString().toUpperCase()}'),
              Text('Payment: ${order['payment_method']}'),
              const Divider(height: 32),
              const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (order['items'] != null)
                ...((order['items'] as List).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${item['quantity']}x ${item['product_title']}'),
                      Text(formatDynamicPrice(item['price'])),
                    ],
                  ),
                ))),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(formatDynamicPrice(order['total_amount']), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue, fontSize: 18)),
                ],
              ),
              if (order['payment_slip_path'] != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Payment Slip'),
                              content: Image.network(
                                '${AppConstants.baseUrl}${order['payment_slip_path']}',
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(child: CircularProgressIndicator());
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    padding: const EdgeInsets.all(20),
                                    color: Colors.grey[200],
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                                        const SizedBox(height: 8),
                                        Text('Could not load image\n$error', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.visibility),
                        label: const Text('View Slip'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final url = Uri.parse('${AppConstants.baseUrl}${order['payment_slip_path']}');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Download'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isMobile = MediaQuery.of(context).size.width < 1000;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account Portal'),
        leading: isMobile ? Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ) : IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => context.go('/'),
          tooltip: 'Back to Home',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              auth.logout();
              context.go('/');
            },
            tooltip: 'Logout',
          ),
          const SizedBox(width: 16),
        ],
      ),
      drawer: isMobile ? _buildSidebar(context, auth) : null,
      body: Row(
        children: [
          // Sidebar Layout for Desktop
          if (!isMobile) _buildSidebar(context, auth),
          // Main Content Area
          Expanded(
            child: Container(
              color: AppTheme.backgroundLight,
              padding: EdgeInsets.all(isMobile ? 16 : 32),
              child: _getContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, AuthProvider auth) {
    return Container(
      width: 250,
      color: AppTheme.darkBlue,
      child: Column(
        children: [
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.accentOrange,
            child: Text(
              auth.user?['name']?.substring(0, 1).toUpperCase() ?? 'U',
              style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            auth.user?['name'] ?? 'User',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            auth.user?['email'] ?? '',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 32),
          _buildSidebarItem(Icons.dashboard, 'Overview', 0),
          _buildSidebarItem(Icons.receipt_long, 'My Orders', 1),
          _buildSidebarItem(Icons.settings, 'Billing Details', 2),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              auth.logout();
              context.go('/');
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, int index) {
    final isActive = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: isActive ? AppTheme.accentOrange : Colors.white70),
      title: Text(title, style: TextStyle(color: isActive ? Colors.white : Colors.white70)),
      selected: isActive,
      onTap: () {
        setState(() => _selectedIndex = index);
      },
    );
  }

  Widget _getContent() {
    switch (_selectedIndex) {
      case 1:
        return _buildOrderHistory();
      case 2:
        return _buildBillingDetailsForm();
      case 0:
      default:
        return _buildOverview();
    }
  }

  Widget _buildOverview() {
    final isMobile = MediaQuery.of(context).size.width < 1000;
    int totalOrders = _orders.length;
    double totalSpent = _orders.fold(0, (sum, item) {
      // Ensure we parse to double safely
      var amount = item['total_amount'];
      if (amount is String) return sum + double.parse(amount);
      if (amount is num) return sum + amount.toDouble();
      return sum;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dashboard Overview', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 32),
        isMobile 
          ? Column(
              children: [
                _buildStatCard(
                  'Total Orders',
                  totalOrders.toString(),
                  Icons.shopping_bag,
                  AppTheme.primaryBlue,
                ),
                const SizedBox(height: 16),
                _buildStatCard(
                  'Total Spent',
                  formatPrice(totalSpent),
                  Icons.attach_money,
                  AppTheme.accentOrange,
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Orders',
                    totalOrders.toString(),
                    Icons.shopping_bag,
                    AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildStatCard(
                    'Total Spent',
                    formatPrice(totalSpent),
                    Icons.attach_money,
                    AppTheme.accentOrange,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(child: Container()), // Empty space placeholder
              ],
            ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppTheme.textMuted)),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillingDetailsForm() {
    final isMobile = MediaQuery.of(context).size.width < 1000;
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(32),
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
              Text('Billing Details', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text('Update your default billing details for faster checkout.', style: TextStyle(color: AppTheme.textMuted)),
              const SizedBox(height: 32),
              
              isMobile 
                ? Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Full Name'),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'Phone Number'),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Full Name'),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(labelText: 'Phone Number'),
                        ),
                      ),
                    ],
                  ),
              const SizedBox(height: 16),
              isMobile 
                ? Column(
                    children: [
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(labelText: 'Street Address'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nicController,
                        decoration: const InputDecoration(labelText: 'NIC Number'),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(labelText: 'Street Address'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _nicController,
                          decoration: const InputDecoration(labelText: 'NIC Number'),
                        ),
                      ),
                    ],
                  ),
              const SizedBox(height: 16),
              isMobile 
                ? Column(
                    children: [
                      TextFormField(
                        controller: _districtController,
                        decoration: const InputDecoration(labelText: 'District / City'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _postalController,
                        decoration: const InputDecoration(labelText: 'Postal Code'),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _districtController,
                          decoration: const InputDecoration(labelText: 'District / City'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _postalController,
                          decoration: const InputDecoration(labelText: 'Postal Code'),
                        ),
                      ),
                    ],
                  ),
              const SizedBox(height: 32),
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveDetails,
                  child: _isSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Order History', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 24),
        if (_isLoadingOrders)
          const Center(child: CircularProgressIndicator())
        else if (_orders.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: const Center(child: Text('You have no orders yet. Start shopping!')),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    onTap: () => _showOrderDetails(order),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Order #${order['id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              const SizedBox(height: 4),
                              Text('Date: ${order['created_at'].toString().split('T').first}', style: const TextStyle(color: AppTheme.textMuted)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: order['status'] == 'pending' ? Colors.orange.withAlpha(30) : Colors.green.withAlpha(30),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  order['status'].toString().toUpperCase(),
                                  style: TextStyle(
                                    color: order['status'] == 'pending' ? Colors.orange : Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                              )
                            ],
                          ),
                          Text(formatDynamicPrice(order['total_amount']), style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.primaryBlue)),
                        ],
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
}
