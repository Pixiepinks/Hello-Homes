import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'providers/cart_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/ui_settings_provider.dart';
import 'screens/user_dashboard_screen.dart';
import 'screens/category_products_screen.dart';
import 'screens/all_categories_screen.dart';
import 'screens/all_products_screen.dart';
import 'screens/upload_slip_screen.dart';
import 'widgets/cookie_consent_banner.dart';
import 'widgets/mobile_bottom_navigation.dart';

void main() {
  usePathUrlStrategy();
  runApp(const HelloHomesApp());
}

GoRouter _buildRouter(AuthProvider authProvider) {
  return GoRouter(
    refreshListenable: authProvider,
    redirect: (context, state) {
      if (authProvider.isLoadingSession) {
        return null;
      }

      final location = state.uri.path;
      final isLoginRoute = location == '/login';
      final isAdminRoute = location == '/admin';

      if (isAdminRoute && (!authProvider.isAuthenticated || !authProvider.isAdmin)) {
        return '/login';
      }

      if (isLoginRoute && authProvider.isAuthenticated && authProvider.isAdmin) {
        return '/admin';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProductDetailScreen(productId: id);
        },
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const UserDashboardScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) {
          final orderId = state.uri.queryParameters['orderId'];
          return AdminDashboardScreen(initialOrderId: orderId);
        },
      ),
      GoRoute(
        path: '/category/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final title = state.uri.queryParameters['title'] ?? 'Category';
          return CategoryProductsScreen(categoryId: id, categoryTitle: title);
        },
      ),
      GoRoute(
        path: '/products',
        builder: (context, state) => const AllProductsScreen(),
      ),
      GoRoute(
        path: '/offers',
        builder: (context, state) => const AllProductsScreen(offersOnly: true),
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) => const AllCategoriesScreen(),
      ),
      GoRoute(
        path: '/upload-slip/:orderId',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return UploadSlipScreen(orderId: orderId);
        },
      ),
    ],
  );
}

class HelloHomesApp extends StatefulWidget {
  const HelloHomesApp({super.key});

  @override
  State<HelloHomesApp> createState() => _HelloHomesAppState();
}

class _HelloHomesAppState extends State<HelloHomesApp> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _router = _buildRouter(_authProvider);
  }

  @override
  void dispose() {
    _router.dispose();
    _authProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => UiSettingsProvider()),
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (context) => NotificationProvider(context.read<AuthProvider>()),
          update: (context, auth, previous) => previous ?? NotificationProvider(auth),
        ),
      ],
      child: MaterialApp.router(
        title: 'Hello Homes',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: _router,
        builder: (context, child) {
          return Column(
            children: [
              Expanded(child: child ?? const SizedBox.shrink()),
              const CookieConsentBanner(),
              const MobileBottomNavigation(),
            ],
          );
        },
      ),
    );
  }
}
