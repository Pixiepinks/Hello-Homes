import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';

class MobileBottomNavigation extends StatelessWidget {
  static const double breakpoint = 1024;
  static const double barHeight = 72;
  static const String whatsappUrl = 'https://wa.me/94714755778';

  const MobileBottomNavigation({super.key});

  static bool isVisibleForWidth(double width) => width <= breakpoint;

  static double reservedBottomPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    if (!isVisibleForWidth(mediaQuery.size.width)) return 0;
    return barHeight + mediaQuery.padding.bottom;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    if (!isVisibleForWidth(mediaQuery.size.width)) {
      return const SizedBox.shrink();
    }

    final bottomInset = mediaQuery.padding.bottom;
    final currentPath = _currentPath(context);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: barHeight + bottomInset,
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            border: const Border(
              top: BorderSide(color: AppTheme.borderLight, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(18),
                blurRadius: 22,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            left: false,
            right: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
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
                    iconSize: 31,
                    activeIconSize: 33,
                    customIcon: const _WhatsAppMark(),
                    isProminent: true,
                    onTap: _openWhatsApp,
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
      ),
    );
  }

  String _currentPath(BuildContext context) {
    try {
      return GoRouterState.of(context).uri.path;
    } catch (_) {
      return GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
    }
  }

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse(whatsappUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
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
  final bool isProminent;
  final Widget? customIcon;

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
    this.isProminent = false,
    this.customIcon,
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
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(minHeight: 56, minWidth: 44),
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.primaryBlue.withAlpha(20)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedScale(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      scale: isActive || isProminent ? 1.04 : 1,
                      child: customIcon ??
                          Icon(
                            isActive ? activeIcon : icon,
                            color: color,
                            size: isActive ? activeIconSize : iconSize,
                          ),
                    ),
                    if (badgeCount > 0)
                      Positioned(
                        right: -10,
                        top: -8,
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
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  style: TextStyle(
                    color: color,
                    fontSize: isProminent ? 11.5 : 11,
                    fontWeight: isActive || isProminent
                        ? FontWeight.w800
                        : FontWeight.w600,
                    letterSpacing: -0.15,
                    height: 1.05,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

class _WhatsAppMark extends StatelessWidget {
  const _WhatsAppMark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 34,
      height: 34,
      child: CustomPaint(painter: _WhatsAppMarkPainter()),
    );
  }
}

class _WhatsAppMarkPainter extends CustomPainter {
  const _WhatsAppMarkPainter();

  static const Color _green = Color(0xFF25D366);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = _green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = _green.withAlpha(18)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2 - 1);
    final radius = size.width * 0.37;
    canvas.drawCircle(center, radius, fill);
    canvas.drawCircle(center, radius, stroke);

    final tail = Path()
      ..moveTo(size.width * 0.33, size.height * 0.72)
      ..lineTo(size.width * 0.24, size.height * 0.86)
      ..lineTo(size.width * 0.42, size.height * 0.79);
    canvas.drawPath(tail, stroke);

    final handset = Path()
      ..moveTo(size.width * 0.39, size.height * 0.39)
      ..cubicTo(
        size.width * 0.45,
        size.height * 0.58,
        size.width * 0.54,
        size.height * 0.66,
        size.width * 0.68,
        size.height * 0.62,
      );
    canvas.drawPath(handset, stroke);

    canvas.drawLine(
      Offset(size.width * 0.38, size.height * 0.38),
      Offset(size.width * 0.44, size.height * 0.32),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.68, size.height * 0.62),
      Offset(size.width * 0.73, size.height * 0.55),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
