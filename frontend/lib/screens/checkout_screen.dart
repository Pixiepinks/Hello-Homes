import '../utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/global_layout.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import 'payment_gateway_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final CartItem? buyNowItem;
  const CheckoutScreen({super.key, this.buyNowItem});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _currentStep = 0;
  bool _isProcessing = false;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();

  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _nicController = TextEditingController();
  final _addressController = TextEditingController();
  final _districtController = TextEditingController();
  final _postalController = TextEditingController();
  
  bool _otpSent = false;
  final _otpController = TextEditingController();
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  
  bool? _isExistingUser;
  bool _isCheckingEmail = false;
  bool _isVerified = false;

  Timer? _timer;
  int _secondsRemaining = 120;
  bool _canResend = false;

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 120;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (_secondsRemaining > 0) {
          setState(() => _secondsRemaining--);
        } else {
          _timer?.cancel();
          setState(() => _canResend = true);
        }
      }
    });
  }

  List<dynamic> _deliveryOptions = [];
  bool _isLoadingOptions = true;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus && _emailController.text.isNotEmpty) {
        _checkEmail();
      }
    });

    _fetchDeliveryOptions();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated && auth.user != null) {
        setState(() {
          _isExistingUser = true;
          _isVerified = true;
          _emailController.text = auth.user!['email'] ?? '';
          _nameController.text = auth.user!['name'] ?? '';
          _phoneController.text = auth.user!['phone'] ?? '';
          _nicController.text = auth.user!['nic_number'] ?? '';
          _addressController.text = auth.user!['street_address'] ?? '';
          _districtController.text = auth.user!['district'] ?? '';
          _postalController.text = auth.user!['postal_code'] ?? '';
        });
      }
    });
  }

  Future<void> _fetchDeliveryOptions() async {
    try {
      final response = await http.get(Uri.parse('${AppConstants.apiUrl}/delivery-options'));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          setState(() {
            _deliveryOptions = decoded;
          });
        }
      } else {
        debugPrint('Failed to load delivery options: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching delivery options: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingOptions = false);
      }
    }
  }

  double _calculateDeliveryFee(Map<String, CartItem> items) {
    if (_deliveryOptions.isEmpty) return 0;
    
    double totalFee = 0;
    
    for (var item in items.values) {
      // Use assigned deliveryOptionId or fallback to the first available option (usually ID 1)
      final optionId = item.product.deliveryOptionId ?? 1;
      
      final option = _deliveryOptions.firstWhere(
        (o) => o['id'].toString() == optionId.toString(), 
        orElse: () => _deliveryOptions.isNotEmpty ? _deliveryOptions.first : null
      );
      
      if (option != null) {
        final double itemWeight = (item.product.weight > 0 ? item.product.weight : 1.0);
        final double totalWeight = itemWeight * item.quantity;
        
        if (option['type'] == 'free') {
          totalFee += 0;
        } else if (option['type'] == 'flat_rate') {
          totalFee += double.tryParse(option['base_fee'].toString()) ?? 0;
        } else if (option['type'] == 'weight_based') {
          double baseFee = double.tryParse(option['base_fee'].toString()) ?? 0;
          double additionalFee = double.tryParse(option['additional_fee_per_unit'].toString()) ?? 0;
          double unitWeight = double.tryParse(option['unit_weight'].toString()) ?? 1.0;

          if (totalWeight <= unitWeight) {
            totalFee += baseFee;
          } else {
            double extraWeight = totalWeight - unitWeight;
            totalFee += baseFee + (extraWeight * additionalFee);
          }
        }
      }
    }

    return totalFee;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailFocusNode.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    _nicController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _postalController.dispose();
    super.dispose();
  }

  void _checkEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) return;
    
    setState(() {
      _isCheckingEmail = true;
      _otpSent = false;
      _isVerified = false;
    });
    
    final exists = await context.read<AuthProvider>().checkEmail(email);
    
    if (mounted) {
      setState(() {
        _isCheckingEmail = false;
        _isExistingUser = exists;
      });
    }
  }

  void _handleSendOtp() async {
    if (_emailController.text.trim().isEmpty) return;
    setState(() => _isSendingOtp = true);
    final errorMessage = await context.read<AuthProvider>().sendOtp(_emailController.text.trim());
    if (mounted) {
      setState(() {
        _isSendingOtp = false;
        if (errorMessage == null) {
          _otpSent = true;
          _startTimer();
        }
      });
      if (errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP sent to email for auto-fill.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
  }

  void _handleVerifyOtp() async {
    if (_otpController.text.trim().isEmpty) return;
    setState(() => _isVerifyingOtp = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.verifyOtp(_emailController.text.trim(), _otpController.text.trim());
    if (mounted) {
      setState(() {
        _isVerifyingOtp = false;
        if (success) {
           _otpSent = false;
           _isVerified = true;
           if (auth.user != null) {
              _nameController.text = auth.user!['name'] ?? '';
              _phoneController.text = auth.user!['phone'] ?? '';
              _nicController.text = auth.user!['nic_number'] ?? '';
              _addressController.text = auth.user!['street_address'] ?? '';
              _districtController.text = auth.user!['district'] ?? '';
              _postalController.text = auth.user!['postal_code'] ?? '';
           }
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Billing details auto-filled.')));
        } else {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP.')));
        }
      });
    }
  }

  String _selectedPaymentMethod = 'card';

  Future<void> _placeOrder(double subtotal, double deliveryFee, Map<String, CartItem> items) async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _currentStep = 0);
      return;
    }

    final totalAmount = subtotal + deliveryFee;

    if (_selectedPaymentMethod == 'card') {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentGatewayScreen(totalAmount: totalAmount),
        ),
      );

      if (!mounted) return;

      if (result != 'OK') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment was not completed.')));
        return;
      }
    }

    if (!mounted) return;
    setState(() => _isProcessing = true);

    try {
      final itemsList = items.values.map((e) => {
        'id': e.product.id,
        'title': e.product.title,
        'quantity': e.quantity,
        'price': e.product.price,
      }).toList();

      final response = await http.post(
        Uri.parse('${AppConstants.apiUrl}/orders'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailController.text,
          'full_name': _nameController.text,
          'phone': _phoneController.text,
          'nic_number': _nicController.text,
          'street_address': _addressController.text,
          'district': _districtController.text,
          'postal_code': _postalController.text,
          'payment_method': _selectedPaymentMethod,
          'total_amount': totalAmount,
          'delivery_fee': deliveryFee,
          'items': itemsList,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['token'] != null) {
          context.read<AuthProvider>().setSession(data['token'], data['user']);
        }
        if (widget.buyNowItem == null) {
          context.read<CartProvider>().clear();
        }
        if (_selectedPaymentMethod == 'transfer') {
          context.go('/upload-slip/${data['order']['id']}');
        } else {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Order Placed Successfully!'),
              content: const Text('An email receipt has been sent to your address.'),
              actions: [
                TextButton(onPressed: () { Navigator.pop(context); context.go('/'); }, child: const Text('Continue Shopping')),
              ],
            ),
          );
        }
      } else {
        throw Exception('Failed to place order');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 1000;
    final cart = context.watch<CartProvider>();
    final isBuyNow = widget.buyNowItem != null;
    final displayItems = isBuyNow ? {widget.buyNowItem!.product.id: widget.buyNowItem!} : cart.items;
    final subtotal = isBuyNow ? (widget.buyNowItem!.product.price * widget.buyNowItem!.quantity) : cart.totalAmount;
    final deliveryFee = _calculateDeliveryFee(displayItems);
    final totalAmount = subtotal + deliveryFee;
    
    return Scaffold(
      appBar: const GlobalAppBar(showBackButton: true),
      drawer: const GlobalDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40, vertical: 20),
              child: isMobile 
                ? Column(children: [
                    _buildOrderSummary(displayItems, subtotal, deliveryFee, totalAmount, isBuyNow),
                    const SizedBox(height: 32),
                    _buildCheckoutForm(subtotal, deliveryFee, displayItems),
                  ])
                : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 6, child: _buildCheckoutForm(subtotal, deliveryFee, displayItems)),
                    Expanded(flex: 4, child: _buildOrderSummary(displayItems, subtotal, deliveryFee, totalAmount, isBuyNow)),
                  ]),
            ),
            const SizedBox(height: 80),
            const GlobalFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutForm(double subtotal, double deliveryFee, Map<String, CartItem> items) {
    return Form(
      key: _formKey,
      child: Stepper(
        physics: const NeverScrollableScrollPhysics(),
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 2) {
            if (_currentStep == 0 && !_formKey.currentState!.validate()) return;
            setState(() => _currentStep += 1);
          } else {
            _placeOrder(subtotal, deliveryFee, items);
          }
        },
        onStepCancel: () { if (_currentStep > 0) setState(() => _currentStep -= 1); },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Row(children: [
              ElevatedButton(
                onPressed: (_isProcessing || (_currentStep == 2 && subtotal == 0)) ? null : details.onStepContinue,
                child: _isProcessing && _currentStep == 2
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_currentStep == 2 ? 'Place Order' : 'Continue'),
              ),
              const SizedBox(width: 16),
              if (_currentStep > 0 && !_isProcessing) TextButton(onPressed: details.onStepCancel, child: const Text('Back')),
            ]),
          );
        },
        steps: [
          Step(title: const Text('Delivery & Billing Details'), content: _buildBillingForm(), isActive: _currentStep >= 0, state: _currentStep > 0 ? StepState.complete : StepState.indexed),
          Step(title: const Text('Payment Method'), content: _buildPaymentMethod(), isActive: _currentStep >= 1, state: _currentStep > 1 ? StepState.complete : StepState.indexed),
          Step(title: const Text('Confirmation'), content: _buildConfirmation(), isActive: _currentStep >= 2),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(Map<String, CartItem> displayItems, double subtotal, double deliveryFee, double totalAmount, bool isBuyNow) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppTheme.backgroundLight, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Order Summary', style: Theme.of(context).textTheme.headlineMedium),
          if (!isBuyNow && displayItems.isNotEmpty)
            TextButton.icon(
              onPressed: () => context.read<CartProvider>().clear(),
              icon: const Icon(Icons.delete_sweep, color: Colors.red, size: 20),
              label: const Text('Clear All', style: TextStyle(color: Colors.red)),
            ),
        ]),
        const SizedBox(height: 24),
        if (displayItems.isEmpty) const Text('Your cart is empty.') else ...displayItems.values.map((cartItem) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cartItem.product.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text('Rs.${cartItem.product.price.toStringAsFixed(2)}', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ],
              ),
            ),
            Row(mainAxisSize: MainAxisSize.min, children: [
              if (!isBuyNow) ...[
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppTheme.primaryBlue),
                  onPressed: () => context.read<CartProvider>().decreaseQuantity(cartItem.product.id),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('${cartItem.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20, color: AppTheme.primaryBlue),
                  onPressed: () => context.read<CartProvider>().addItem(cartItem.product),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), 
                  onPressed: () => context.read<CartProvider>().removeItem(cartItem.product.id), 
                  padding: EdgeInsets.zero, 
                  constraints: const BoxConstraints()
                ),
              ] else ...[
                Text('${cartItem.quantity}x', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
              const SizedBox(width: 12),
              Text('Rs.${(cartItem.product.price * cartItem.quantity).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
          ]),
        )).toList(),
        const Divider(height: 32),
        _buildSummaryRow('Subtotal', 'Rs.${subtotal.toStringAsFixed(2)}'),
        const SizedBox(height: 12),
        _buildSummaryRow('Shipping Fee', _isLoadingOptions ? 'Calculating...' : 'Rs.${deliveryFee.toStringAsFixed(2)}'),
        const Divider(height: 32),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Total', style: Theme.of(context).textTheme.titleLarge),
          Text('Rs.${totalAmount.toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.primaryBlue)),
        ]),
      ]),
    );
  }

  Widget _buildBillingForm() {
    bool fieldsEnabled = _isExistingUser == false || _isVerified || _isExistingUser == null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: TextFormField(controller: _emailController, focusNode: _emailFocusNode, decoration: const InputDecoration(labelText: 'Email Address'), validator: (v) => v!.isEmpty ? 'Required' : null)),
        if (_isCheckingEmail) const Padding(padding: EdgeInsets.only(left: 16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      ]),
      if (_isExistingUser != null) ...[
        const SizedBox(height: 12),
        if (_isExistingUser!) Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.blue.withAlpha(20), borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('This email is already registered.', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Verify via OTP to auto-fill details.', style: TextStyle(color: Colors.blue)),
            if (!_isVerified && !_otpSent) Padding(padding: const EdgeInsets.only(top: 12), child: ElevatedButton(onPressed: _isSendingOtp ? null : _handleSendOtp, child: _isSendingOtp ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Send OTP'))),
          ]),
        ) else const Text('New user detected.', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
      ],
      if (_otpSent) ...[
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: TextFormField(controller: _otpController, decoration: const InputDecoration(labelText: 'OTP'))),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: _isVerifyingOtp ? null : _handleVerifyOtp, child: _isVerifyingOtp ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Verify'))
          ]
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Time remaining: ${(_secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}',
              style: TextStyle(
                color: _secondsRemaining > 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            if (_canResend)
              TextButton(
                onPressed: _isSendingOtp ? null : _handleSendOtp,
                child: const Text('Resend OTP', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
      ],
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: TextFormField(enabled: fieldsEnabled, controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name'), validator: (v) => v!.isEmpty ? 'Required' : null)),
        const SizedBox(width: 16),
        Expanded(child: TextFormField(enabled: fieldsEnabled, controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone Number'), validator: (v) => v!.isEmpty ? 'Required' : null)),
      ]),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: TextFormField(enabled: fieldsEnabled, controller: _addressController, decoration: const InputDecoration(labelText: 'Street Address'), validator: (v) => v!.isEmpty ? 'Required' : null)),
        const SizedBox(width: 16),
        Expanded(child: TextFormField(enabled: fieldsEnabled, controller: _nicController, decoration: const InputDecoration(labelText: 'NIC Number'))),
      ]),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: TextFormField(enabled: fieldsEnabled, controller: _districtController, decoration: const InputDecoration(labelText: 'District'), validator: (v) => v!.isEmpty ? 'Required' : null)),
        const SizedBox(width: 16),
        Expanded(child: TextFormField(enabled: fieldsEnabled, controller: _postalController, decoration: const InputDecoration(labelText: 'Postal Code'), validator: (v) => v!.isEmpty ? 'Required' : null)),
      ]),
    ]);
  }

  Widget _buildPaymentMethod() {
    return Column(children: [
      RadioListTile(value: 'card', groupValue: _selectedPaymentMethod, onChanged: (val) => setState(() => _selectedPaymentMethod = val.toString()), title: const Text('Card Payment')),
      RadioListTile(value: 'transfer', groupValue: _selectedPaymentMethod, onChanged: (val) => setState(() => _selectedPaymentMethod = val.toString()), title: const Text('Bank Transfer')),
    ]);
  }

  Widget _buildConfirmation() { return const Text('Please review your order details before placing the order.'); }

  Widget _buildSummaryRow(String title, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(color: AppTheme.textMuted)), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))]);
  }
}
