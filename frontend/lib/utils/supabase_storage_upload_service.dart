import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'constants.dart';

class SupabaseStorageUploadService {
  SupabaseStorageUploadService({
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  static const int maxImageBytes = 5 * 1024 * 1024;
  static const Set<String> allowedImageExtensions = {'jpg', 'jpeg', 'png', 'webp'};
  static const Set<String> allowedPaymentSlipExtensions = {'jpg', 'jpeg', 'png', 'webp', 'pdf'};

  bool get isConfigured => AppConstants.isSupabaseStorageConfigured;

  Future<String?> uploadImage({
    required XFile file,
    required String bucket,
    required String folder,
  }) async {
    if (!isConfigured) {
      return null;
    }

    final extension = fileExtension(file.name);
    if (!allowedImageExtensions.contains(extension)) {
      throw const SupabaseStorageUploadException('Only JPG, JPEG, PNG, and WEBP images are allowed.');
    }

    final Uint8List bytes = await file.readAsBytes();
    if (bytes.length > maxImageBytes) {
      throw const SupabaseStorageUploadException('Each image must be 5MB or smaller.');
    }

    final path = '$folder/${DateTime.now().millisecondsSinceEpoch}-${safeFileName(file.name)}';
    return _uploadBytes(
      bucket: bucket,
      path: path,
      bytes: bytes,
      contentType: contentTypeForExtension(extension),
    );
  }

  static String safeFileName(String name) {
    final cleaned = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9._-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-');
    return cleaned.isEmpty ? 'image.jpg' : cleaned;
  }

  static String fileExtension(String name) {
    final parts = name.toLowerCase().split('.');
    return parts.length > 1 ? parts.last : '';
  }

  Future<String> uploadPaymentSlip({
    required XFile file,
    required String orderId,
  }) async {
    if (!isConfigured) {
      throw const SupabaseStorageUploadException('Supabase storage is not configured. Please set SUPABASE_URL and SUPABASE_ANON_KEY.');
    }

    final extension = fileExtension(file.name);
    if (!allowedPaymentSlipExtensions.contains(extension)) {
      throw const SupabaseStorageUploadException('Only JPG, JPEG, PNG, WEBP, and PDF files are allowed.');
    }

    final Uint8List bytes = await file.readAsBytes();
    if (bytes.length > maxImageBytes) {
      throw const SupabaseStorageUploadException('Payment slip must be 5MB or smaller.');
    }

    final path = 'order-$orderId/${DateTime.now().millisecondsSinceEpoch}-${safeFileName(file.name)}';
    return _uploadBytes(
      bucket: AppConstants.supabasePaymentSlipBucket,
      path: path,
      bytes: bytes,
      contentType: contentTypeForExtension(extension),
    );
  }

  Future<String> _uploadBytes({
    required String bucket,
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final encodedPath = path.split('/').map(Uri.encodeComponent).join('/');
    final uploadUrl = Uri.parse('${AppConstants.supabaseUrl}/storage/v1/object/$bucket/$encodedPath');

    final response = await _httpClient.post(
      uploadUrl,
      headers: {
        'apikey': AppConstants.supabaseAnonKey,
        'Authorization': 'Bearer ${AppConstants.supabaseAnonKey}',
        'Content-Type': contentType,
        'x-upsert': 'false',
      },
      body: bytes,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SupabaseStorageUploadException('Supabase upload failed (${response.statusCode}): ${response.body}');
    }

    return '${AppConstants.supabaseUrl}/storage/v1/object/public/$bucket/$encodedPath';
  }

  static String contentTypeForExtension(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}

class SupabaseStorageUploadException implements Exception {
  const SupabaseStorageUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}
