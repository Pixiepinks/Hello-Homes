import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../models/ui_settings.dart';
import '../providers/auth_provider.dart';
import '../providers/ui_settings_provider.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';

class AdminUiSettingsView extends StatefulWidget {
  const AdminUiSettingsView({super.key});

  @override
  State<AdminUiSettingsView> createState() => _AdminUiSettingsViewState();
}

class _AdminUiSettingsViewState extends State<AdminUiSettingsView> {
  final _currencyController = TextEditingController(text: 'Rs.');
  List<HeroBanner> _banners = [];
  bool _loading = true;
  String? _bannerLoadError;
  bool _saving = false;
  bool _savingOrder = false;
  bool _orderDirty = false;
  bool _productNameOneLine = true;
  int _productsPerRowDesktop = 6;
  bool _showCarouselArrows = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _currencyController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final settings = context.read<UiSettingsProvider>().settings;
    _productNameOneLine = settings.productNameOneLine;
    _productsPerRowDesktop = settings.productsPerRowDesktop;
    _currencyController.text = settings.currencySymbol;
    _showCarouselArrows = settings.showCarouselArrows;
    try {
      _bannerLoadError = null;
      final response = await http.get(Uri.parse('${AppConstants.apiUrl}/hero-banners'));
      if (response.statusCode == 200) {
        _banners = (json.decode(response.body) as List<dynamic>).map((item) => HeroBanner.fromJson(item)).toList();
        _orderDirty = false;
      } else {
        _bannerLoadError = 'Unable to load hero banners (HTTP ${response.statusCode}).';
      }
    } catch (e) {
      _bannerLoadError = 'Unable to load hero banners. Please check your connection and try again.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, String> get _authHeaders => {
        'Authorization': 'Bearer ${context.read<AuthProvider>().token}',
        'Content-Type': 'application/json',
      };

  Future<void> _saveSettings() async {
    setState(() => _saving = true);
    final ok = await context.read<UiSettingsProvider>().saveSettings(
          UiSettings(
            productNameOneLine: _productNameOneLine,
            productsPerRowDesktop: _productsPerRowDesktop,
            currencySymbol: _currencyController.text.trim().isEmpty ? 'Rs.' : _currencyController.text.trim(),
            showCarouselArrows: _showCarouselArrows,
          ),
          context.read<AuthProvider>().token,
        );
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'UI settings saved' : 'Unable to save UI settings')));
    }
  }

  bool _isRemoteImage(String imageUrl) => imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

  String _bannerFileName(HeroBanner banner) {
    final path = Uri.tryParse(banner.imageUrl)?.pathSegments;
    if (path != null && path.isNotEmpty && path.last.isNotEmpty) return path.last;
    return banner.imageUrl;
  }

  String _bannerLabel(HeroBanner banner) {
    if (banner.title?.trim().isNotEmpty == true) return banner.title!.trim();
    final fileName = _bannerFileName(banner);
    if (fileName.isNotEmpty) return fileName;
    return 'Banner ${banner.id}';
  }

  void _moveBanner(int oldIndex, int newIndex) {
    if (newIndex < 0 || newIndex >= _banners.length || oldIndex == newIndex) return;
    setState(() {
      final item = _banners.removeAt(oldIndex);
      _banners.insert(newIndex, item);
      _orderDirty = true;
    });
  }

  Future<void> _toggleBannerActive(int index, bool isActive) async {
    final banner = _banners[index];
    setState(() => _banners[index] = banner.copyWith(isActive: isActive));
    final response = await http.put(
      Uri.parse('${AppConstants.apiUrl}/hero-banners/${banner.id}'),
      headers: _authHeaders,
      body: json.encode(banner.copyWith(isActive: isActive).toJson()),
    );
    if (!mounted) return;
    if (response.statusCode != 200) {
      setState(() => _banners[index] = banner);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to update banner status')));
    }
  }

  Future<void> _showBannerDialog([HeroBanner? banner]) async {
    final title = TextEditingController(text: banner?.title ?? '');
    final imageUrl = TextEditingController(text: banner?.imageUrl ?? '');
    final linkUrl = TextEditingController(text: banner?.linkUrl ?? '');
    var isActive = banner?.isActive ?? true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(banner == null ? 'Add Hero Banner' : 'Edit Hero Banner'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
                TextField(controller: imageUrl, decoration: const InputDecoration(labelText: 'Image URL')),
                TextField(controller: linkUrl, decoration: const InputDecoration(labelText: 'Link URL (optional, app route)')),
                SwitchListTile(value: isActive, onChanged: (v) => setDialogState(() => isActive = v), title: const Text('Enabled')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final payload = json.encode({'title': title.text, 'image_url': imageUrl.text, 'link_url': linkUrl.text, 'is_active': isActive});
                final uri = banner == null ? Uri.parse('${AppConstants.apiUrl}/hero-banners') : Uri.parse('${AppConstants.apiUrl}/hero-banners/${banner.id}');
                final response = banner == null
                    ? await http.post(uri, headers: _authHeaders, body: payload)
                    : await http.put(uri, headers: _authHeaders, body: payload);
                if (response.statusCode == 200 || response.statusCode == 201) {
                  if (mounted) Navigator.pop(context);
                  _load();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bannerThumbnail(HeroBanner banner) {
    Widget errorFallback() => Container(
          width: 96,
          height: 54,
          color: AppTheme.backgroundLight,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image, color: AppTheme.textMuted),
        );

    if (_isRemoteImage(banner.imageUrl)) {
      return Image.network(
        banner.imageUrl,
        width: 96,
        height: 54,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => errorFallback(),
      );
    }

    return Image.asset(
      banner.imageUrl,
      width: 96,
      height: 54,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => errorFallback(),
    );
  }

  Future<void> _saveBannerOrder() async {
    setState(() => _savingOrder = true);
    final response = await http.post(
      Uri.parse('${AppConstants.apiUrl}/hero-banners/order'),
      headers: _authHeaders,
      body: json.encode({'banner_ids': _banners.map((b) => b.id).toList()}),
    );
    if (!mounted) return;
    setState(() => _savingOrder = false);
    if (response.statusCode == 200) {
      final saved = (json.decode(response.body) as List<dynamic>).map((item) => HeroBanner.fromJson(item)).toList();
      setState(() {
        _banners = saved;
        _orderDirty = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hero banner order saved')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to save hero banner order')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('UI Settings', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 24),
        _panel('Hero Banners', [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Reorder existing homepage slider images. Use the arrows or drag handle, then click Save Order.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _savingOrder || _banners.isEmpty || _bannerLoadError != null ? null : _saveBannerOrder,
                icon: const Icon(Icons.save),
                label: Text(_savingOrder ? 'Saving...' : 'Save Order'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_bannerLoadError != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade100)),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_bannerLoadError!, style: const TextStyle(color: Colors.red))),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          else if (_banners.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.backgroundLight, borderRadius: BorderRadius.circular(8)),
              child: const Text('No hero banners found. The default hero images will appear here after the banner API initializes them.'),
            )
          else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: _banners.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex--;
              _moveBanner(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Card(
                key: ValueKey(banner.id),
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppTheme.borderLight)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ReorderableDragStartListener(index: index, child: const Icon(Icons.drag_handle, color: AppTheme.textMuted)),
                      const SizedBox(width: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _bannerThumbnail(banner),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_bannerLabel(banner), style: Theme.of(context).textTheme.titleMedium, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text('File: ${_bannerFileName(banner)}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted)),
                            const SizedBox(height: 2),
                            Text('Current order: ${index + 1}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                      Switch(value: banner.isActive, onChanged: (value) => _toggleBannerActive(index, value)),
                      IconButton(tooltip: 'Move up', icon: const Icon(Icons.arrow_upward), onPressed: index == 0 ? null : () => _moveBanner(index, index - 1)),
                      IconButton(tooltip: 'Move down', icon: const Icon(Icons.arrow_downward), onPressed: index == _banners.length - 1 ? null : () => _moveBanner(index, index + 1)),
                      IconButton(tooltip: 'Edit banner details', icon: const Icon(Icons.edit), onPressed: () => _showBannerDialog(banner)),
                    ],
                  ),
                ),
              );
            },
          ),
        ]),
        _panel('Homepage Product Cards', [
          SwitchListTile(value: _productNameOneLine, onChanged: (v) => setState(() => _productNameOneLine = v), title: const Text('Display product names in one line')),
          DropdownButtonFormField<int>(
            value: _productsPerRowDesktop,
            decoration: const InputDecoration(labelText: 'Products per row on desktop'),
            items: [2, 3, 4, 5, 6].map((v) => DropdownMenuItem(value: v, child: Text('$v items'))).toList(),
            onChanged: (v) => setState(() => _productsPerRowDesktop = v ?? 6),
          ),
          const SizedBox(height: 8),
          const Text('Product cards show original price first with strikethrough, then sale price.'),
        ]),
        _panel('Currency Settings', [TextField(controller: _currencyController, decoration: const InputDecoration(labelText: 'Currency symbol'))]),
        _panel('Slider / Carousel Settings', [SwitchListTile(value: _showCarouselArrows, onChanged: (v) => setState(() => _showCarouselArrows = v), title: const Text('Show carousel arrow handlers'))]),
        Align(alignment: Alignment.centerRight, child: ElevatedButton.icon(onPressed: _saving ? null : _saveSettings, icon: const Icon(Icons.save), label: Text(_saving ? 'Saving...' : 'Save UI Settings'))),
      ]),
    );
  }

  Widget _panel(String title, List<Widget> children) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.borderLight)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.headlineMedium), const SizedBox(height: 16), ...children]),
      );
}
