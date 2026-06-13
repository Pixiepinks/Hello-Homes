import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PaymentGatewayScreen extends StatefulWidget {
  final double totalAmount;
  
  const PaymentGatewayScreen({super.key, required this.totalAmount});

  @override
  State<PaymentGatewayScreen> createState() => _PaymentGatewayScreenState();
}

class _PaymentGatewayScreenState extends State<PaymentGatewayScreen> {
  bool _isProcessing = false;

  void _simulatePayment() async {
    setState(() => _isProcessing = true);
    
    // Simulate gateway processing delay
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      // Return 'OK' to indicate successful payment
      Navigator.pop(context, 'OK');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light grey background
      appBar: AppBar(
        title: const Text('Sampath Bank Secure Gateway', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFE26113), // Sampath Bank orange
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, 'CANCELLED'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            width: MediaQuery.of(context).size.width * 0.9,
            margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mock Logo / Header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE26113),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Sampath IPG',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE26113),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount:', style: TextStyle(fontSize: 16, color: Colors.black54)),
                    Text('LKR ${widget.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              const Text(
                'TEST ENVIRONMENT',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              const SizedBox(height: 8),
              const Text(
                'This is a simulated payment page. No real transaction will occur. Click the Pay button to simulate a successful payment return to the Hello Homes platform.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              
              const SizedBox(height: 40),
              
              // Mock Card Input
              TextFormField(
                initialValue: '4111 1111 1111 1111',
                decoration: const InputDecoration(
                  labelText: 'Card Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.credit_card),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: '12/28',
                      decoration: const InputDecoration(
                        labelText: 'Expiry (MM/YY)',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      initialValue: '123',
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE26113),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isProcessing ? null : _simulatePayment,
                  child: _isProcessing 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('PAY SECURELY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
              
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isProcessing ? null : () => Navigator.pop(context, 'CANCELLED'),
                child: const Text('Cancel Payment', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
