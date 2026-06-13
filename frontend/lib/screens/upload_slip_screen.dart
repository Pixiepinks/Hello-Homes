import '../utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
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
  Uint8List? _fileBytes;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  List _bankDetails = [];
  bool _isLoadingBank = true;

  @override
  void initState() {
    super.initState();
    _fetchBankDetails();
  }

  Future<void> _fetchBankDetails() async {
    try {
      final response = await http.get(Uri.parse('${AppConstants.apiUrl}/bank-details/active'));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _bankDetails = json.decode(response.body);
            _isLoadingBank = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingBank = false);
    }
  }

  Future<void> _pickFile() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedFile = image;
        _fileBytes = bytes;
      });
    }
  }

  Future<void> _uploadSlip() async {
    if (_selectedFile == null || _fileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a file first')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.apiUrl}/orders/${widget.orderId}/upload-slip'),
      );
      request.headers.addAll({'Accept': 'application/json'});

      // Web and Mobile safe upload using bytes
      request.files.add(http.MultipartFile.fromBytes(
        'slip',
        _fileBytes!,
        filename: _selectedFile!.name,
      ));

      var response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          _showSuccessDialog();
        }
      } else {
        throw Exception('Failed to upload slip. Status code: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading slip: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Order Placed Successfully!'),
        content: const Text('Your payment slip has been uploaded. An email receipt has been sent to your address. Admin will verify your payment and update the status soon.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/');
            },
            child: const Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlobalAppBar(),
      body: Center(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_balance, size: 64, color: AppTheme.primaryBlue),
              const SizedBox(height: 16),
              Text(
                'Upload Bank Transfer Slip',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Please upload the receipt or screenshot of your bank transfer to complete your order. Your order is pending verification.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 24),
              
              if (_isLoadingBank)
                const CircularProgressIndicator()
              else if (_bankDetails.isNotEmpty) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Bank Accounts:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(height: 8),
                ..._bankDetails.map((bank) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bank['bank_name'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                      if (bank['branch_name'] != null) Text('Branch: ${bank['branch_name']}', style: const TextStyle(fontSize: 12)),
                      Text('Acc Name: ${bank['account_name']}', style: const TextStyle(fontSize: 12)),
                      Text('Acc No: ${bank['account_number']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                )).toList(),
              ],
              
              const SizedBox(height: 24),
              
              if (_selectedFile != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedFile!.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => setState(() => _selectedFile = null),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Select Image File'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedFile == null || _isUploading ? null : _uploadSlip,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: _isUploading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Submit Payment Slip', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _showSuccessDialog(),
                child: const Text('Upload Later (Go Home)', style: TextStyle(color: AppTheme.textMuted)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
