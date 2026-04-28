import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../core/constants/app_constants.dart';

class MainScaffold extends ConsumerWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.name ?? '',
                        style:
                            const TextStyle(fontWeight: FontWeight.bold)),
                    Text(user?.role ?? '',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                  value: 'logout', child: Text('Déconnexion')),
            ],
            onSelected: (value) async {
              if (value == 'logout') {
                await ref.read(authProvider.notifier).logout();
              }
            },
          ),
        ],
      ),
      drawer: _AppDrawer(parentContext: context, ref: ref),
      body: child,
    );
  }
}

// ── Drawer avec navigation par rôle ───────────────────────────────────────

class _AppDrawer extends StatelessWidget {
  final BuildContext parentContext;
  final WidgetRef ref;

  const _AppDrawer({required this.parentContext, required this.ref});

  @override
  Widget build(BuildContext context) {
    final user   = ref.watch(authProvider).user;
    final role   = user?.role ?? '';
    final isAdmin      = role == 'admin';
    final isSupervisor = role == 'supervisor';
    final isOperator   = role == 'operator';

    // Couleur badge rôle
    final roleColor = isAdmin
        ? const Color(0xFFD32F2F)   // rouge → admin
        : isSupervisor
            ? const Color(0xFF1565C0) // bleu → supervisor
            : const Color(0xFF2E7D32); // vert → operator

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── En-tête ──────────────────────────────────────────────────
          DrawerHeader(
            decoration: BoxDecoration(color: roleColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.agriculture, color: Colors.white, size: 40),
                const SizedBox(height: 8),
                Text(
                  user?.name ?? '',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // ── Section commune (tous les rôles) ─────────────────────────
          _sectionHeader('MARCHÉ'),
          _navTile(
            context,
            icon: Icons.person_search,
            label: 'Agriculteurs',
            route: '/farmers',
          ),
          _navTile(
            context,
            icon: Icons.inventory_2,
            label: 'Catalogue Produits',
            route: '/catalog',
          ),
          _navTile(
            context,
            icon: Icons.shopping_cart,
            label: 'Commande en cours',
            route: '/checkout',
          ),

          // ── Section admin : gestion superviseurs ─────────────────────
          if (isAdmin) ...[
            const Divider(),
            _sectionHeader('ADMINISTRATION'),
            _navTile(
              context,
              icon: Icons.supervised_user_circle,
              label: 'Gestion Superviseurs',
              route: '/users',
              color: const Color(0xFFD32F2F),
            ),
          ],

          // ── Section supervisor : gestion opérateurs ──────────────────
          if (isSupervisor) ...[
            const Divider(),
            _sectionHeader('ÉQUIPE'),
            _navTile(
              context,
              icon: Icons.people,
              label: 'Gestion Opérateurs',
              route: '/users',
              color: const Color(0xFF1565C0),
            ),
          ],

          // ── Opérateur : aucune section supplémentaire ─────────────────
          // (intentionnellement vide)

          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Déconnexion',
                style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _navTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    Color color = const Color(0xFF2E7D32),
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        parentContext.go(route);
      },
    );
  }
}
