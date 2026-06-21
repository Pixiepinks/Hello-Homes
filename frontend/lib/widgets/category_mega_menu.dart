import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../models/category.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';

class CategoryTreeRepository {
  CategoryTreeRepository._();
  static List<Category>? _cache;
  static Future<List<Category>>? _inFlight;

  static Future<List<Category>> load() {
    if (_cache != null) return Future.value(_cache);
    return _inFlight ??= http
        .get(Uri.parse('${AppConstants.apiUrl}/categories/tree'))
        .then((response) async {
      if (response.statusCode == 404) {
        final fallback = await http.get(Uri.parse('${AppConstants.apiUrl}/categories'));
        if (fallback.statusCode != 200) throw Exception('Failed to load categories');
        return fallback;
      }
      if (response.statusCode != 200) throw Exception('Failed to load categories');
      return response;
    }).then((response) {
      final decoded = json.decode(response.body);
      final list = decoded is List ? decoded : decoded['data'] as List? ?? const [];
      _cache = list
          .whereType<Map>()
          .map((item) => Category.fromJson(Map<String, dynamic>.from(item)))
          .where((category) => category.title.isNotEmpty)
          .toList();
      return _cache!;
    }).whenComplete(() => _inFlight = null);
  }
}

String _slug(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-|-$'), '');

String _categoryUrl(Category category) => '/category/${category.slug.isNotEmpty ? category.slug : _slug(category.title)}';
String _subcategoryUrl(Category category, Subcategory subcategory) => '${_categoryUrl(category)}/${subcategory.slug.isNotEmpty ? subcategory.slug : _slug(subcategory.name)}';
String _childUrl(Category category, Subcategory subcategory, ChildCategory child) => '${_subcategoryUrl(category, subcategory)}/${child.slug.isNotEmpty ? child.slug : _slug(child.name)}';

class AllCategoriesMenuButton extends StatefulWidget {
  const AllCategoriesMenuButton({super.key});

  @override
  State<AllCategoriesMenuButton> createState() => _AllCategoriesMenuButtonState();
}

class _AllCategoriesMenuButtonState extends State<AllCategoriesMenuButton> {
  OverlayEntry? _overlay;
  Timer? _closeTimer;
  bool _open = false;

  void _cancelCloseTimer() {
    _closeTimer?.cancel();
    _closeTimer = null;
  }

  void _scheduleClose() {
    _cancelCloseTimer();
    _closeTimer = Timer(const Duration(milliseconds: 200), _close);
  }

  void _openDesktop() {
    _cancelCloseTimer();
    if (_overlay != null) return;
    final box = context.findRenderObject() as RenderBox;
    final position = box.localToGlobal(Offset.zero);
    _overlay = OverlayEntry(
      builder: (_) => _DesktopCategoryMegaMenu(
        triggerTop: position.dy,
        triggerHeight: box.size.height,
        onClose: _close,
        onEnter: _cancelCloseTimer,
        onExit: _scheduleClose,
      ),
    );
    Overlay.of(context).insert(_overlay!);
    setState(() => _open = true);
  }

  void _close() {
    _cancelCloseTimer();
    _overlay?.remove();
    _overlay = null;
    if (mounted) setState(() => _open = false);
  }

  void _removeOverlay() {
    _cancelCloseTimer();
    _overlay?.remove();
    _overlay = null;
  }

  void _openMobile() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close categories',
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, __, ___) => const Align(
        alignment: Alignment.centerLeft,
        child: _MobileCategoryDrawer(),
      ),
      transitionBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween(begin: const Offset(-1, 0), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    return MouseRegion(
      onEnter: (_) {
        if (!isMobile) _openDesktop();
      },
      onExit: (_) {
        if (!isMobile) _scheduleClose();
      },
      child: InkWell(
        onTap: isMobile ? _openMobile : _openDesktop,
        child: Container(
          height: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 12),
          alignment: Alignment.center,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.menu, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            const Text('All Categories', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            Icon(_open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.white, size: 16),
          ]),
        ),
      ),
    );
  }
}

class _DesktopCategoryMegaMenu extends StatefulWidget {
  final double triggerTop;
  final double triggerHeight;
  final VoidCallback onClose;
  final VoidCallback onEnter;
  final VoidCallback onExit;

  const _DesktopCategoryMegaMenu({
    required this.triggerTop,
    required this.triggerHeight,
    required this.onClose,
    required this.onEnter,
    required this.onExit,
  });

  @override
  State<_DesktopCategoryMegaMenu> createState() => _DesktopCategoryMegaMenuState();
}

class _DesktopCategoryMegaMenuState extends State<_DesktopCategoryMegaMenu> {
  static const double _menuHeight = 480;
  String? _activeCategoryId;

  Category? _activeCategory(List<Category> categories) {
    final activeCategoryId = _activeCategoryId;
    if (activeCategoryId == null) return null;

    for (final category in categories) {
      if (category.id == activeCategoryId) return category;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: widget.onClose,
                child: Container(color: Colors.transparent),
              ),
            ),
            Positioned(
              top: widget.triggerTop,
              left: 0,
              right: 0,
              height: widget.triggerHeight + _menuHeight,
              child: MouseRegion(
                onEnter: (_) => widget.onEnter(),
                onExit: (_) => widget.onExit(),
                child: Stack(
                  children: [
                    Positioned(
                      top: widget.triggerHeight,
                      left: 36,
                      right: 36,
                      child: FutureBuilder<List<Category>>(
                        future: CategoryTreeRepository.load(),
                        builder: (context, snapshot) {
                          final categories = snapshot.data ?? const <Category>[];
                          final active = _activeCategory(categories);
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            height: _menuHeight,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(35),
                                  blurRadius: 28,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            child: snapshot.connectionState == ConnectionState.waiting
                                ? const Center(child: CircularProgressIndicator())
                                : Row(
                                    children: [
                                      SizedBox(
                                        width: 280,
                                        child: ListView.builder(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          itemCount: categories.length,
                                          itemBuilder: (_, i) {
                                            final category = categories[i];
                                            final selected = category.id == _activeCategoryId;
                                            return InkWell(
                                              onHover: (hovering) {
                                                if (hovering && _activeCategoryId != category.id) {
                                                  setState(() => _activeCategoryId = category.id);
                                                }
                                              },
                                              onTap: () {
                                                widget.onClose();
                                                context.go(_categoryUrl(category));
                                              },
                                              child: Container(
                                                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                                decoration: BoxDecoration(
                                                  color: selected ? AppTheme.primaryBlue.withAlpha(18) : Colors.transparent,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.home_work_outlined,
                                                      size: 20,
                                                      color: selected ? AppTheme.accentOrange : AppTheme.primaryBlue,
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Text(
                                                        category.title,
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.w700,
                                                          color: selected ? AppTheme.primaryBlue : AppTheme.darkBlue,
                                                        ),
                                                      ),
                                                    ),
                                                    Icon(
                                                      Icons.chevron_right,
                                                      size: 18,
                                                      color: selected ? AppTheme.accentOrange : Colors.black38,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      const VerticalDivider(width: 1),
                                      Expanded(
                                        child: active == null
                                            ? const _DesktopMegaMenuBlankState()
                                            : _DesktopSubcategoryGrid(category: active, onClose: widget.onClose),
                                      ),
                                    ],
                                  ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopMegaMenuBlankState extends StatelessWidget {
  const _DesktopMegaMenuBlankState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Hover a category to view subcategories',
        style: TextStyle(
          color: AppTheme.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _DesktopSubcategoryGrid extends StatelessWidget {
  final Category category;
  final VoidCallback onClose;
  const _DesktopSubcategoryGrid({required this.category, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 220, mainAxisExtent: 150, crossAxisSpacing: 22, mainAxisSpacing: 18),
      itemCount: category.subcategories.length,
      itemBuilder: (_, index) {
        final sub = category.subcategories[index];
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          InkWell(onTap: () { onClose(); context.go(_subcategoryUrl(category, sub)); }, child: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.darkBlue))),
          const SizedBox(height: 8),
          ...sub.childCategories.take(5).map((child) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(onTap: () { onClose(); context.go(_childUrl(category, sub, child)); }, child: Text(child.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted))),
              )),
        ]);
      },
    );
  }
}

class _MobileCategoryDrawer extends StatelessWidget {
  const _MobileCategoryDrawer();
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * .88,
        height: double.infinity,
        child: SafeArea(
          child: Column(children: [
            ListTile(leading: const Icon(Icons.close), title: const Text('All Categories', style: TextStyle(fontWeight: FontWeight.w800)), onTap: () => Navigator.of(context).pop()),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<Category>>(
                future: CategoryTreeRepository.load(),
                builder: (_, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  final categories = snapshot.data ?? const <Category>[];
                  return ListView(children: categories.map((category) => ExpansionTile(
                    leading: const Icon(Icons.home_work_outlined, color: AppTheme.primaryBlue),
                    title: Text(category.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    children: [
                      ListTile(contentPadding: const EdgeInsets.only(left: 56, right: 16), title: const Text('View all'), onTap: () { Navigator.of(context).pop(); context.go(_categoryUrl(category)); }),
                      ...category.subcategories.map((sub) => ExpansionTile(
                        tilePadding: const EdgeInsets.only(left: 56, right: 16),
                        title: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        children: [
                          ListTile(contentPadding: const EdgeInsets.only(left: 80, right: 16), title: const Text('View all'), onTap: () { Navigator.of(context).pop(); context.go(_subcategoryUrl(category, sub)); }),
                          ...sub.childCategories.map((child) => ListTile(contentPadding: const EdgeInsets.only(left: 96, right: 16), title: Text(child.name), onTap: () { Navigator.of(context).pop(); context.go(_childUrl(category, sub, child)); })),
                        ],
                      )),
                    ],
                  )).toList());
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
