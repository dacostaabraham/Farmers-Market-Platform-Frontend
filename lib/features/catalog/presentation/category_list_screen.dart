import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/catalog_repository.dart';
import '../../checkout/data/cart_provider.dart';

class CategoryListScreen extends ConsumerWidget {
  const CategoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treeAsync = ref.watch(categoryTreeProvider);
    final cart      = ref.watch(cartProvider);

    return Scaffold(
      body: Column(
        children: [
          // Active farmer banner
          if (cart.farmer != null)
            Container(
              color: const Color(0xFF2E7D32).withValues(alpha:0.1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Color(0xFF2E7D32), size: 18),
                  const SizedBox(width: 8),
                  Text('Commande pour: ${cart.farmer!.fullName}',
                      style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('${cart.items.length} article(s)', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),

          Expanded(
            child: treeAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e', style: const TextStyle(color: Colors.red))),
              data: (categories) => ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: categories.length,
                itemBuilder: (context, i) => _CategoryTile(category: categories[i]),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: cart.items.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/checkout'),
              icon: const Icon(Icons.shopping_cart),
              label: Text('Panier (${cart.items.length})'),
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    final hasChildren = category.children.isNotEmpty;

    if (hasChildren) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ExpansionTile(
          leading: const Icon(Icons.folder, color: Color(0xFF2E7D32)),
          title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${category.children.length} sous-catégories'),
          children: category.children.map((child) => _SubCategoryTile(category: child)).toList(),
        ),
      );
    } else {
      return _SubCategoryTile(category: category);
    }
  }
}

class _SubCategoryTile extends StatelessWidget {
  final Category category;
  const _SubCategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: const Icon(Icons.inventory_2, color: Color(0xFF388E3C)),
      title: Text(category.name),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF2E7D32)),
      onTap: () => context.go(
        '/catalog/category/${category.id}',
        extra: category.name,
      ),
    );
  }
}
