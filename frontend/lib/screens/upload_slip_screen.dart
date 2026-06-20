import '../utils/constants.dart';
import '../utils/price_formatter.dart';
import '../utils/supabase_storage_upload_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_theme.dart';
import '../widgets/global_layout.dart';

class UploadSlipScreen extends StatefulWidget {
  final String orderId;

  const UploadSlipScreen({super.key, required this.orderId});

  @override
  State<UploadSlipScreen> createState() => _UploadSlipScreenState();
}

class _UploadSlipScreenState extends State<UploadSlipScreen> {
  XFile? _selectedFile;
  bool _isUploading = false;
  bool _submitted = false;
  Map<String, dynamic>? _order;
  List _bankDetails = [];
  bool _isLoading = true;
  final SupabaseStorageUploadService _storageService = SupabaseStorageUploadService();

  @override
  void initState() {
    super.initState();
    _loadPageData();
  }

  Future<void> _loadPageData() async {
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('${AppConstants.apiUrl}/orders/${widget.orderId}')),
        http.get(Uri.parse('${AppConstants.apiUrl}/bank-details/active')),
      ]);
      if (mounted) {
        setState(() {
          if (responses[0].statusCode == 200) _order = json.decode(responses[0].body);
          if (responses[1].statusCode == 200) _bankDetails = json.decode(responses[1].body);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: SupabaseStorageUploadService.allowedPaymentSlipExtensions.toList(),
      withData: true,
    );
    final file = result?.files.single;
    if (file == null) return;

    final bytes = file.bytes;
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to read selected file.')));
      return;
    }

    setState(() {
      _selectedFile = XFile.fromData(bytes, name: file.name, mimeType: SupabaseStorageUploadService.contentTypeForExtension(SupabaseStorageUploadService.fileExtension(file.name)));
    });
  }

  Future<void> _uploadSlip() async {
    if (_selectedFile == null) return;
    if (!_storageService.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Supabase storage is not configured. Please set SUPABASE_URL and SUPABASE_ANON_KEY.')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final slipUrl = await _storageService.uploadPaymentSlip(file: _selectedFile!, orderId: widget.orderId);
      final response = await http.post(
        Uri.parse('${AppConstants.apiUrl}/orders/${widget.orderId}/upload-slip'),
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: json.encode({'payment_slip_url': slipUrl}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) setState(() => _submitted = true);
      } else {
        throw Exception('Failed to save uploaded slip. Status code: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading slip: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = _order == null ? 'Loading...' : formatDynamicPrice(_order!['total_amount']);
    return Scaffold(
      appBar: const GlobalAppBar(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: 560,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 5))]),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.account_balance, size: 64, color: AppTheme.primaryBlue),
                    const SizedBox(height: 16),
                    Text('Upload Bank Transfer Slip', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    _summaryRow('Order Number', '#${widget.orderId}'),
                    _summaryRow('Total Amount', totalAmount),
                    _summaryRow('Payment Method', 'Bank Transfer'),
                    const SizedBox(height: 12),
                    const Text('Please transfer the exact amount and upload your payment slip.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 24),
                    _buildBankDetails(),
                    const SizedBox(height: 24),
                    if (!_storageService.isConfigured)
                      Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)), child: const Text('Supabase storage is not configured. Uploads are unavailable.', style: TextStyle(color: Colors.red))),
                    const SizedBox(height: 16),
                    if (_selectedFile != null) _selectedFileCard() else OutlinedButton.icon(onPressed: _pickFile, icon: const Icon(Icons.upload_file), label: const Text('Upload Payment Slip'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16))),
                    const SizedBox(height: 24),
                    SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _selectedFile == null || _isUploading ? null : _uploadSlip, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white), child: _isUploading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Submit Payment Slip', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
                    if (_submitted) ...[
                      const SizedBox(height: 16),
                      const Text('Payment slip submitted. Your order is pending verification.', textAlign: TextAlign.center, style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      TextButton(onPressed: () => context.go('/'), child: const Text('Continue Shopping')),
                    ],
                  ]),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: AppTheme.textMuted)), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))]));

  Widget _buildBankDetails() {
    if (_bankDetails.isEmpty) return const Text('No active bank accounts are available. Please contact support.', style: TextStyle(color: AppTheme.textMuted));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Align(alignment: Alignment.centerLeft, child: Text('Bank Account Details:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
      const SizedBox(height: 8),
      ..._bankDetails.map((bank) => Container(width: double.infinity, margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[200]!)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(bank['bank_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)), if (bank['branch_name'] != null) Text('Branch: ${bank['branch_name']}', style: const TextStyle(fontSize: 12)), Text('Acc Name: ${bank['account_name']}', style: const TextStyle(fontSize: 12)), Text('Acc No: ${bank['account_number']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))]))
    ]);
  }

  Widget _selectedFileCard() => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.green.withAlpha(20), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green)), child: Row(children: [const Icon(Icons.check_circle, color: Colors.green), const SizedBox(width: 12), Expanded(child: Text(_selectedFile!.name, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)), IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => setState(() => _selectedFile = null))]));
}
