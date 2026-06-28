import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';

class AdminMetaFeedView extends StatefulWidget {
  const AdminMetaFeedView({super.key});

  @override
  State<AdminMetaFeedView> createState() => _AdminMetaFeedViewState();
}

class _AdminMetaFeedViewState extends State<AdminMetaFeedView> {
  bool _loading = true;
  bool _regenerating = false;
  String _feedUrl = '${AppConstants.baseUrl}/meta-feed.xml';
  String? _lastGenerationTime;
  int _productCount = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiUrl}/admin/meta-feed'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        _applyStatus(json.decode(response.body) as Map<String, dynamic>);
      } else {
        _error = 'Unable to load Meta feed status (${response.statusCode}).';
      }
    } catch (error) {
      _error = 'Unable to load Meta feed status: $error';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _regenerateFeed() async {
    setState(() {
      _regenerating = true;
      _error = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiUrl}/admin/meta-feed/regenerate'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        _applyStatus(json.decode(response.body) as Map<String, dynamic>);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Meta catalog feed regenerated.')),
          );
        }
      } else {
        _error = 'Unable to regenerate feed (${response.statusCode}).';
      }
    } catch (error) {
      _error = 'Unable to regenerate feed: $error';
    } finally {
      if (mounted) setState(() => _regenerating = false);
    }
  }

  Map<String, String> _headers() => {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${context.read<AuthProvider>().token}',
      };

  void _applyStatus(Map<String, dynamic> data) {
    if (!mounted) return;
    setState(() {
      _feedUrl = data['feed_url']?.toString() ?? _feedUrl;
      _lastGenerationTime = data['last_generation_time']?.toString();
      _productCount = int.tryParse(data['product_count']?.toString() ?? '') ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Meta Commerce Manager', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Catalog Feed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _infoRow('Feed URL', _feedUrl),
                _infoRow('Last generation time', _lastGenerationTime?.isNotEmpty == true ? _lastGenerationTime! : 'Not generated yet'),
                _infoRow('Product count', _productCount.toString()),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _regenerating ? null : _regenerateFeed,
                      icon: _regenerating
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.refresh),
                      label: Text(_regenerating ? 'Regenerating...' : 'Regenerate Feed'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _fetchStatus,
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Refresh Status'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Use this XML URL in Meta Commerce Manager as a scheduled data source. The backend caches the feed for up to 60 minutes for catalog performance.',
          style: TextStyle(color: AppTheme.textMuted),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 180, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
            Expanded(child: SelectableText(value)),
          ],
        ),
      );
}
