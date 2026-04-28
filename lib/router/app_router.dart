import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/farmers/presentation/farmer_search_screen.dart';
import '../features/farmers/presentation/farmer_detail_screen.dart';
import '../features/farmers/presentation/create_farmer_screen.dart';
import '../features/catalog/presentation/category_list_screen.dart';
import '../features/catalog/presentation/product_list_screen.dart';
import '../features/checkout/presentation/checkout_screen.dart';
import '../features/checkout/presentation/repayment_screen.dart';
import '../features/debts/presentation/debt_list_screen.dart';
import '../features/users/presentation/user_management_screen.dart';
import '../shared/widgets/main_scaffold.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn      = authState.isAuthenticated;
      final isGoingToLogin  = state.matchedLocation == '/login';

      if (!isLoggedIn && !isGoingToLogin) return '/login';
      if (isLoggedIn  && isGoingToLogin)  return '/farmers';

      // Protéger /users : uniquement admin et supervisor
      if (state.matchedLocation == '/users') {
        final role = authState.user?.role ?? '';
        if (role != 'admin' && role != 'supervisor') return '/farmers';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          // ── Agriculteurs ─────────────────────────────────────────────
          GoRoute(
            path: '/farmers',
            builder: (context, state) => const FarmerSearchScreen(),
          ),
          GoRoute(
            path: '/farmers/new',
            builder: (context, state) => const CreateFarmerScreen(),
          ),
          GoRoute(
            path: '/farmers/:id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return FarmerDetailScreen(farmerId: id);
            },
          ),
          GoRoute(
            path: '/farmers/:id/debts',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return DebtListScreen(farmerId: id);
            },
          ),
          GoRoute(
            path: '/farmers/:id/repayment',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return RepaymentScreen(farmerId: id);
            },
          ),

          // ── Catalogue ─────────────────────────────────────────────────
          GoRoute(
            path: '/catalog',
            builder: (context, state) => const CategoryListScreen(),
          ),
          GoRoute(
            path: '/catalog/category/:id',
            builder: (context, state) {
              final id   = int.parse(state.pathParameters['id']!);
              final name = state.uri.queryParameters['name'] ?? 'Produits';
              return ProductListScreen(categoryId: id, categoryName: name);
            },
          ),

          // ── Commande ──────────────────────────────────────────────────
          GoRoute(
            path: '/checkout',
            builder: (context, state) => const CheckoutScreen(),
          ),

          // ── Gestion utilisateurs (admin → superviseurs, supervisor → opérateurs) ──
          GoRoute(
            path: '/users',
            builder: (context, state) => const UserManagementScreen(),
          ),
        ],
      ),
    ],
  );
});
