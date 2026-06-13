import '../utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'auth_provider.dart';

class AppNotification {
  final int id;
  final String title;
  final String message;
  final String type;
  final String? referenceId;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.referenceId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      type: json['type'],
      referenceId: json['reference_id']?.toString(),
      isRead: json['is_read'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  Timer? _refreshTimer;
  final AuthProvider _auth;

  NotificationProvider(this._auth) {
    if (_auth.isAuthenticated) {
      fetchNotifications();
      startPolling();
    }
  }

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  void startPolling() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_auth.isAuthenticated) {
        fetchNotifications(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchNotifications({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiUrl}/notifications'),
        headers: {
          'Authorization': 'Bearer ${_auth.token}',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _notifications = data.map((n) => AppNotification.fromJson(n)).toList();
        _unreadCount = _notifications.where((n) => !n.isRead).length;
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.apiUrl}/notifications/$id/read'),
        headers: {
          'Authorization': 'Bearer ${_auth.token}',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final index = _notifications.indexWhere((n) => n.id == id);
        if (index != -1) {
          _notifications[index] = AppNotification(
            id: _notifications[index].id,
            title: _notifications[index].title,
            message: _notifications[index].message,
            type: _notifications[index].type,
            referenceId: _notifications[index].referenceId,
            isRead: true,
            createdAt: _notifications[index].createdAt,
          );
          _unreadCount = _notifications.where((n) => !n.isRead).length;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.apiUrl}/notifications/mark-all-read'),
        headers: {
          'Authorization': 'Bearer ${_auth.token}',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _notifications = _notifications.map((n) => AppNotification(
          id: n.id,
          title: n.title,
          message: n.message,
          type: n.type,
          referenceId: n.referenceId,
          isRead: true,
          createdAt: n.createdAt,
        )).toList();
        _unreadCount = 0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }
}
