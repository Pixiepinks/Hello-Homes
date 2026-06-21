import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';

Widget? buildMobileBottomNavigationBar(BuildContext context) {
  final isMobile = MobileBottomNavigation.isVisibleForWidth(
    MediaQuery.sizeOf(context).width,
  );

  if (!isMobile) {
    return null;
  }

  return const MobileBottomNavigation();
}

class MobileBottomNavigation extends StatelessWidget {
  static const double breakpoint = 1024;
  static const double barHeight = 72;
  static const String whatsappUrl = 'https://wa.me/94714755778';

  const MobileBottomNavigation({super.key});

  static bool isVisibleForWidth(double width) => width <= breakpoint;

  @override
  Widget build(BuildContext context) {
    final currentPath = _currentPath(context);

    return Material(
      color: AppTheme.surfaceWhite,
      elevation: 10,
      shadowColor: Colors.black.withAlpha(18),
      child: Container(
        height: barHeight + MediaQuery.paddingOf(context).bottom,
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.borderLight, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          left: false,
          right: false,
          child: SizedBox(
            height: barHeight,
            child: Row(
              children: [
                _MobileBottomNavigationItem(
                  label: 'Home',
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  isActive: currentPath == '/',
                  onTap: () => context.go('/'),
                ),
                _MobileBottomNavigationItem(
                  label: 'Categories',
                  icon: Icons.grid_view_outlined,
                  activeIcon: Icons.grid_view_rounded,
                  isActive: currentPath.startsWith('/categories') ||
                      currentPath.startsWith('/category/'),
                  onTap: () => context.go('/categories'),
                ),
                _MobileBottomNavigationItem(
                  label: 'WhatsApp',
                  icon: Icons.chat_bubble_outline_rounded,
                  activeIcon: Icons.chat_bubble_rounded,
                  iconColor: const Color(0xFF25D366),
                  activeIconColor: const Color(0xFF25D366),
                  iconSize: 28,
                  activeIconSize: 28,
                  iconBuilder: (_, __) => SvgPicture.asset(
                    'assets/icons/whatsapp.svg',
                    width: 28,
                    height: 28,
                  ),
                  onTap: () => _openWhatsApp(context),
                ),
                _MobileBottomNavigationItem(
                  label: 'Offers',
                  icon: Icons.local_offer_outlined,
                  activeIcon: Icons.local_offer_rounded,
                  isActive: currentPath.startsWith('/offers'),
                  onTap: () => context.go('/offers'),
                ),
                Consumer<CartProvider>(
                  builder: (context, cart, _) => _MobileBottomNavigationItem(
                    label: 'Cart',
                    icon: Icons.shopping_bag_outlined,
                    activeIcon: Icons.shopping_bag_rounded,
                    isActive: currentPath.startsWith('/checkout'),
                    badgeCount: cart.itemCount,
                    onTap: () => context.go('/checkout'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _currentPath(BuildContext context) {
    return GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final uri = Uri.parse(whatsappUrl);
    final messenger = ScaffoldMessenger.maybeOf(context);

    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return;
    }

    messenger?.showSnackBar(
      const SnackBar(
        content: Text('Could not open WhatsApp. Please try again.'),
      ),
    );
  }
}

class _MobileBottomNavigationItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final VoidCallback onTap;
  final int badgeCount;
  final Color? iconColor;
  final Color? activeIconColor;
  final double iconSize;
  final double activeIconSize;
  final Widget Function(Color color, double size)? iconBuilder;

  const _MobileBottomNavigationItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.onTap,
    this.isActive = false,
    this.badgeCount = 0,
    this.iconColor,
    this.activeIconColor,
    this.iconSize = 24,
    this.activeIconSize = 25,
    this.iconBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor = activeIconColor ?? AppTheme.primaryBlue;
    final unselectedColor = iconColor ?? AppTheme.textMuted;
    final color = isActive ? selectedColor : unselectedColor;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isActive,
        label: label,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: MobileBottomNavigation.barHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 34,
                  height: 30,
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    alignment: Alignment.center,
                    children: [
                      iconBuilder?.call(
                            color,
                            isActive ? activeIconSize : iconSize,
                          ) ??
                          Icon(
                            isActive ? activeIcon : icon,
                            color: color,
                            size: isActive ? activeIconSize : iconSize,
                          ),
                      if (badgeCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: const BoxDecoration(
                              color: AppTheme.accentOrange,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              badgeCount > 99 ? '99+' : badgeCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                    letterSpacing: -0.15,
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
