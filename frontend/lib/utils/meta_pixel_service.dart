import 'dart:math';

import 'package:flutter/material.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import 'constants.dart';
import 'meta_pixel_service_stub.dart'
    if (dart.library.js_interop) 'meta_pixel_service_web.dart' as pixel_impl;

class MetaPixelService {
  static const String _configuredPixelId = String.fromEnvironment(
    'META_PIXEL_ID',
    defaultValue: '1282584640350629',
  );

  static String get pixelId => _configuredPixelId.trim().isEmpty
      ? '1282584640350629'
      : _configuredPixelId.trim();

  static void initialize() {
    pixel_impl.initialize(pixelId);
  }

  static void trackPageView([String? path]) {
    pixel_impl.track('PageView', {
      if (path != null) 'page_path': path,
    });
  }

  static void trackViewContent(Product product) {
    pixel_impl.track('ViewContent', _productPayload(product));
  }

  static void trackSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    pixel_impl.track('Search', {'search_string': trimmed});
  }

  static void trackAddToCart(Product product, {int quantity = 1}) {
    pixel_impl.track('AddToCart', _productPayload(product, quantity: quantity));
  }

  static void trackInitiateCheckout(Map<String, CartItem> items, double value) {
    if (items.isEmpty) return;
    pixel_impl.track('InitiateCheckout', _cartPayload(items, value));
  }

  static String generateEventId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final random = Random.secure().nextInt(1 << 32).toRadixString(16);
    return 'hh_purchase_${timestamp}_$random';
  }

  static void trackPurchase(Map<String, CartItem> items, double value, String eventId) {
    if (items.isEmpty) return;
    pixel_impl.track('Purchase', _cartPayload(items, value), eventId: eventId);
  }

  static String orderSuccessUrl(Object? orderId) {
    final id = orderId?.toString();
    return id == null || id.isEmpty
        ? '${AppConstants.baseUrl}/checkout'
        : '${AppConstants.baseUrl}/upload-slip/$id';
  }

  static Map<String, Object?> _productPayload(Product product, {int quantity = 1}) {
    final itemPrice = product.price;
    final value = itemPrice * quantity;
    return {
      'content_type': 'product',
      'content_ids': [product.id],
      'contents': [
        {'id': product.id, 'quantity': quantity, 'item_price': itemPrice},
      ],
      'currency': 'LKR',
      'value': value,
    };
  }

  static Map<String, Object?> _cartPayload(Map<String, CartItem> items, double value) {
    return {
      'content_type': 'product',
      'content_ids': items.values.map((item) => item.product.id).toList(),
      'contents': items.values
          .map((item) => {
                'id': item.product.id,
                'quantity': item.quantity,
                'item_price': item.product.price,
              })
          .toList(),
      'currency': 'LKR',
      'value': value,
    };
  }
}

class MetaRouteObserver extends NavigatorObserver {
  void _track(Route<dynamic>? route) {
    final name = route?.settings.name;
    MetaPixelService.trackPageView(name);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _track(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _track(newRoute);
  }
}
