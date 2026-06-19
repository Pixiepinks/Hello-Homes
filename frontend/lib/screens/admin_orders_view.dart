import '../utils/constants.dart';
import '../utils/price_formatter.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';

class AdminOrdersView extends StatefulWidget {
  final String? initialSearch;
  const AdminOrdersView({super.key, this.initialSearch});

  @override
  State<AdminOrdersView> createState() => _AdminOrdersViewState();
}

class _AdminOrdersViewState extends State<AdminOrdersView> {
  List _orders = [];
  bool _isLoading = true;
  int _currentPage = 1;
  int _lastPage = 1;
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _paymentMethodFilter = 'all';
  
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialSearch != null) {
      _searchQuery = widget.initialSearch!;
      _searchController.text = widget.initialSearch!;
    }
    _fetchOrders();
  }

  Future<void> _fetchOrders({int page = 1}) async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token;
      final url = '${AppConstants.apiUrl}/orders?page=$page&search=$_searchQuery&status=$_statusFilter&payment_method=$_paymentMethodFilter';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _orders = data['data'];
          _currentPage = data['current_page'];
          _lastPage = data['last_page'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error fetching orders: $e');
    }
  }

  Future<void> _updateStatus(int id, String status) async {
    try {
      final token = context.read<AuthProvider>().token;
      final response = await http.put(
        Uri.parse('${AppConstants.apiUrl}/orders/$id/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'status': status}),
      );
      if (response.statusCode == 200) {
        _fetchOrders(page: _currentPage);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order #$id status updated to $status')));
      }
    } catch (e) {
      debugPrint('Error updating status: $e');
    }
  }

  Future<void> _deleteSlip(int id) async {
    try {
      final token = context.read<AuthProvider>().token;
      final response = await http.delete(
        Uri.parse('${AppConstants.apiUrl}/orders/$id/slip'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        Navigator.pop(context); // Close dialog
        _fetchOrders(page: _currentPage);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment slip deleted successfully')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete payment slip')));
      }
    } catch (e) {
      debugPrint('Error deleting slip: $e');
    }
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order #${order['id']} Details'),
        content: SizedBox(
          width: isMobile ? MediaQuery.of(context).size.width * 0.9 : 600,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                isMobile 
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoColumn('Customer', order['full_name']),
                        const SizedBox(height: 8),
                        _buildInfoColumn('Email', order['email']),
                        const SizedBox(height: 8),
                        _buildInfoColumn('Phone', order['phone']),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoColumn('Customer', order['full_name']),
                        _buildInfoColumn('Email', order['email']),
                        _buildInfoColumn('Phone', order['phone']),
                      ],
                    ),
                const SizedBox(height: 16),
                _buildInfoColumn('Shipping Address', '${order['street_address']}, ${order['district']}, ${order['postal_code']}'),
                const Divider(height: 40),
                const Text('Ordered Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                if (order['items'] != null)
                  ...((order['items'] as List).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${item['quantity']}x ${item['product_title']}'),
                        Text(formatPrice((double.tryParse(item['price'].toString()) ?? 0) * (int.tryParse(item['quantity'].toString()) ?? 1)), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ))),
                const Divider(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Delivery Fee:', style: TextStyle(color: Colors.grey)),
                    Text(formatDynamicPrice(order['delivery_fee'] ?? '0'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(formatDynamicPrice(order['total_amount']), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
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
                          label: const Text('View'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
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
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Slip'),
                                content: const Text('Are you sure you want to delete this payment slip?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _deleteSlip(order['id']);
                                    }, 
                                    child: const Text('Delete', style: TextStyle(color: Colors.red))
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.delete),
                          label: const Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, dynamic value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value?.toString() ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Manage Orders', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 24),
        
        // Search and Filter Bar
        isMobile 
          ? Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _searchQuery = '';
                        _fetchOrders();
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (value) {
                    _searchQuery = value;
                    _fetchOrders();
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _statusFilter,
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All Status')),
                              DropdownMenuItem(value: 'pending', child: Text('Pending')),
                              DropdownMenuItem(value: 'confirmed', child: Text('Confirmed')),
                              DropdownMenuItem(value: 'delivered', child: Text('Delivered')),
                              DropdownMenuItem(value: 'refunded', child: Text('Refunded')),
                            ],
                            onChanged: (val) {
                              setState(() => _statusFilter = val!);
                              _fetchOrders();
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _paymentMethodFilter,
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All Payments')),
                              DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                              DropdownMenuItem(value: 'Card', child: Text('Card')),
                              DropdownMenuItem(value: 'Cash on Delivery', child: Text('COD')),
                            ],
                            onChanged: (val) {
                              setState(() => _paymentMethodFilter = val!);
                              _fetchOrders();
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _fetchOrders(page: _currentPage),
                      icon: const Icon(Icons.refresh),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by Name, Email, or Order ID...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchQuery = '';
                          _fetchOrders();
                        },
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    onSubmitted: (value) {
                      _searchQuery = value;
                      _fetchOrders();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _statusFilter,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Status')),
                        DropdownMenuItem(value: 'pending', child: Text('Pending')),
                        DropdownMenuItem(value: 'confirmed', child: Text('Confirmed')),
                        DropdownMenuItem(value: 'delivered', child: Text('Delivered')),
                        DropdownMenuItem(value: 'refunded', child: Text('Refunded')),
                      ],
                      onChanged: (val) {
                        setState(() => _statusFilter = val!);
                        _fetchOrders();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _paymentMethodFilter,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Payments')),
                        DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                        DropdownMenuItem(value: 'Card', child: Text('Card')),
                        DropdownMenuItem(value: 'Cash on Delivery', child: Text('COD')),
                      ],
                      onChanged: (val) {
                        setState(() => _paymentMethodFilter = val!);
                        _fetchOrders();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () => _fetchOrders(page: _currentPage),
                  icon: const Icon(Icons.refresh),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
        const SizedBox(height: 24),

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
              : _orders.isEmpty 
                ? const Center(child: Text('No orders found matching your criteria.'))
                : Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 40,
                            columns: const [
                              DataColumn(label: Text('ID')),
                              DataColumn(label: Text('Customer')),
                              DataColumn(label: Text('Total')),
                              DataColumn(label: Text('Date')),
                              DataColumn(label: Text('Payment')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: _orders.map((order) {
                              return DataRow(cells: [
                                DataCell(Text('#${order['id']}')),
                                DataCell(InkWell(
                                  onTap: () {
                                    setState(() {
                                      _searchQuery = order['email'];
                                      _searchController.text = order['email'];
                                    });
                                    _fetchOrders();
                                  },
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(order['full_name'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                                      Text(order['email'], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                    ],
                                  ),
                                )),
                                DataCell(Text(formatDynamicPrice(order['total_amount']))),
                                DataCell(Text(order['created_at'].toString().split('T').first)),
                                DataCell(Text(order['payment_method'] ?? 'N/A')),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(order['status']).withAlpha(30),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      order['status'].toString().toUpperCase(),
                                      style: TextStyle(color: _getStatusColor(order['status']), fontWeight: FontWeight.bold, fontSize: 11),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.visibility, color: AppTheme.primaryBlue, size: 20),
                                        onPressed: () => _showOrderDetails(order),
                                        tooltip: 'View Details',
                                      ),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
                                        onSelected: (status) => _updateStatus(order['id'], status),
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(value: 'pending', child: Text('Mark as Pending')),
                                          const PopupMenuItem(value: 'confirmed', child: Text('Mark as Confirmed')),
                                          const PopupMenuItem(value: 'delivered', child: Text('Mark as Delivered')),
                                          const PopupMenuItem(value: 'refunded', child: Text('Mark as Refunded')),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
                      // Pagination Bar
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          border: Border(top: BorderSide(color: AppTheme.borderLight)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: _currentPage > 1 ? () => _fetchOrders(page: _currentPage - 1) : null,
                            ),
                            Text('Page $_currentPage of $_lastPage'),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: _currentPage < _lastPage ? () => _fetchOrders(page: _currentPage + 1) : null,
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed': return Colors.blue;
      case 'delivered': return Colors.green;
      case 'refunded': return Colors.red;
      case 'pending': 
      default: return Colors.orange;
    }
  }
}
