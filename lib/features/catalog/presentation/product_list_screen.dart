import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../data/catalog_repository.dart';
import '../../checkout/data/cart_provider.dart';

class ProductListScreen extends ConsumerWidget {
  final int categoryId;
  final String categoryName;

  const ProductListScreen({super.key, required this.categoryId, required this.categoryName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsByCategoryProvider(categoryId));
    final cart          = ref.watch(cartProvider);
    final fmt           = NumberFormat('#,###', 'fr_FR');

    return Scaffold(
      appBar: AppBar(title: Text(categoryName)),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e', style: const TextStyle(color: Colors.red))),
        data: (products) => products.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Aucun produit dans cette catégorie', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  final cartItem = cart.items.where((i) => i.product.id == product.id).firstOrNull;
                  final qty = cartItem?.quantity ?? 0;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // Product info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                if (product.description != null)
                                  Text(product.description!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text(
                                  '${fmt.format(product.priceFcfa)} FCFA / ${product.unit}',
                                  style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Quantity controls
                          qty == 0
                              ? IconButton(
                                  icon: const Icon(Icons.add_circle, color: Color(0xFF2E7D32), size: 32),
                                  onPressed: () => ref.read(cartProvider.notifier).addProduct(product),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                      onPressed: () => ref.read(cartProvider.notifier).updateQuantity(product.id, qty - 1),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2E7D32),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text('$qty', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, color: Color(0xFF2E7D32)),
                                      onPressed: () => ref.read(cartProvider.notifier).addProduct(product),
                                    ),
                                  ],
                                ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      bottomNavigationBar: cart.items.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.shopping_cart),
                  label: Text('Valider commande — ${fmt.format(cart.subtotal)} FCFA'),
                  onPressed: () => context.go('/checkout'),
                ),
              ),
            )
          : null,
    );
  }
}
