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
  bool _saving = false;
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
      final response = await http.get(Uri.parse('${AppConstants.apiUrl}/hero-banners'));
      if (response.statusCode == 200) {
        _banners = (json.decode(response.body) as List<dynamic>).map((item) => HeroBanner.fromJson(item)).toList();
      }
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

  Future<void> _deleteBanner(HeroBanner banner) async {
    await http.delete(Uri.parse('${AppConstants.apiUrl}/hero-banners/${banner.id}'), headers: _authHeaders);
    _load();
  }

  Future<void> _saveBannerOrder() async {
    await http.post(Uri.parse('${AppConstants.apiUrl}/hero-banners/order'), headers: _authHeaders, body: json.encode({'banner_ids': _banners.map((b) => b.id).toList()}));
    _load();
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
          Align(alignment: Alignment.centerRight, child: ElevatedButton.icon(onPressed: () => _showBannerDialog(), icon: const Icon(Icons.add), label: const Text('Add Banner'))),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _banners.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = _banners.removeAt(oldIndex);
                _banners.insert(newIndex, item);
              });
              _saveBannerOrder();
            },
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return ListTile(
                key: ValueKey(banner.id),
                leading: const Icon(Icons.drag_handle),
                title: Text(banner.title?.isNotEmpty == true ? banner.title! : 'Banner ${banner.id}'),
                subtitle: Text('${banner.isActive ? 'Enabled' : 'Disabled'} • Order ${index + 1}'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.edit), onPressed: () => _showBannerDialog(banner)),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteBanner(banner)),
                ]),
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
