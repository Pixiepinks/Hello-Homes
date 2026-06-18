import '../utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'admin_products_view.dart';
import 'admin_categories_view.dart';
import 'admin_customers_view.dart';
import 'admin_orders_view.dart';
import 'admin_settings_view.dart';
import 'admin_bank_details_view.dart';
import '../widgets/notification_bell.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String? initialOrderId;
  const AdminDashboardScreen({super.key, this.initialOrderId});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  double _totalSales = 0;
  int _activeOrders = 0;
  int _totalProducts = 0;
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      if (!auth.isAuthenticated || !auth.isAdmin) {
        context.go('/login');
        return;
      }
      _fetchStats();
    });
    if (widget.initialOrderId != null) {
      _selectedIndex = 3; // Orders view
    }
  }

  Future<void> _fetchStats() async {
    try {
      final token = context.read<AuthProvider>().token;
      final response = await http.get(
        Uri.parse('${AppConstants.apiUrl}/dashboard/stats'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _totalSales = double.tryParse(data['totalSales']?.toString() ?? '0') ?? 0.0;
            _activeOrders = data['activeOrders'] ?? 0;
            _totalProducts = data['totalProducts'] ?? 0;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 1000;

    Widget _getContent() {
      if (_isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      switch (_selectedIndex) {
        case 1:
          return const AdminProductsView();
        case 2:
          return const AdminCategoriesView();
        case 3:
          return AdminOrdersView(initialSearch: widget.initialOrderId);
        case 4:
          return const AdminCustomersView();
        case 5:
          return const AdminSettingsView();
        case 6:
          return const AdminBankDetailsView();
        case 0:
        default:
          return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dashboard Overview', style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 32),
                  isMobile 
                    ? Column(
                        children: [
                          _buildStatCard(context, 'Total Sales', '\$${_totalSales.toStringAsFixed(2)}', Icons.attach_money, AppTheme.primaryBlue),
                          const SizedBox(height: 16),
                          _buildStatCard(context, 'Active Orders', '$_activeOrders', Icons.receipt, AppTheme.accentOrange),
                          const SizedBox(height: 16),
                          _buildStatCard(context, 'Total Products', '$_totalProducts', Icons.shopping_bag, Colors.green),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: _buildStatCard(context, 'Total Sales', '\$${_totalSales.toStringAsFixed(2)}', Icons.attach_money, AppTheme.primaryBlue)),
                          const SizedBox(width: 24),
                          Expanded(child: _buildStatCard(context, 'Active Orders', '$_activeOrders', Icons.receipt, AppTheme.accentOrange)),
                          const SizedBox(width: 24),
                          Expanded(child: _buildStatCard(context, 'Total Products', '$_totalProducts', Icons.shopping_bag, Colors.green)),
                        ],
                      ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: const Center(child: Text('API Connected: Real Database Stats Showing Above.')),
                    ),
                  ),
                ],
              );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        leading: isMobile ? Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ) : null,
        actions: [
          const NotificationBell(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchStats,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
              context.go('/login');
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: isMobile ? _buildSidebar(context) : null,
      body: Row(
        children: [
          // Sidebar for Desktop
          if (!isMobile) _buildSidebar(context),
          // Main Content
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

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 250,
      color: AppTheme.darkBlue,
      child: Column(
        children: [
          if (MediaQuery.of(context).size.width < 1000) // If in drawer
            DrawerHeader(
              decoration: const BoxDecoration(color: AppTheme.primaryBlue),
              child: Center(child: Text('Admin Panel', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white))),
            ),
          Expanded(
            child: ListView(
              children: [
                _buildSidebarItem(Icons.dashboard, 'Overview', 0),
                _buildSidebarItem(Icons.shopping_bag, 'Products', 1),
                _buildSidebarItem(Icons.category, 'Categories', 2),
                _buildSidebarItem(Icons.receipt, 'Orders', 3),
                 _buildSidebarItem(Icons.people, 'Customers', 4),
                _buildSidebarItem(Icons.settings, 'Settings', 5),
                _buildSidebarItem(Icons.account_balance, 'Bank Details', 6),
              ],
            ),
          ),
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

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
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
}
