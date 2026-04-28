import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../data/cart_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _successResult;

  Future<void> _submit() async {
    final cart = ref.read(cartProvider);
    if (cart.farmer == null) {
      setState(() => _error = 'Veuillez d\'abord sélectionner un agriculteur.');
      return;
    }
    if (cart.items.isEmpty) {
      setState(() => _error = 'Le panier est vide.');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      final result = await ref.read(checkoutRepositoryProvider).submitTransaction(
        farmerId:      cart.farmer!.id,
        items:         cart.items,
        paymentMethod: cart.paymentMethod,
      );
      setState(() { _successResult = result; _isLoading = false; });
      ref.read(cartProvider.notifier).clearCart();
    } catch (e) {
      setState(() {
        _error = (e as dynamic).response?.data['message'] ?? e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final fmt  = NumberFormat('#,###', 'fr_FR');

    // Interest calculation preview
    const interestRate = 30.0;
    final interest     = cart.paymentMethod == 'credit' ? (cart.subtotal * interestRate / 100).round() : 0;
    final total        = cart.subtotal + interest;

    if (_successResult != null) {
      return _SuccessView(result: _successResult!, onNewOrder: () {
        setState(() => _successResult = null);
        context.go('/farmers');
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Validation Commande')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Farmer info
            if (cart.farmer != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person, color: Color(0xFF2E7D32)),
                  title: Text(cart.farmer!.fullName),
                  subtitle: Text('ID: ${cart.farmer!.identifier}'),
                  trailing: TextButton(
                    child: const Text('Changer'),
                    onPressed: () => context.go('/farmers'),
                  ),
                ),
              )
            else
              Card(
                color: Colors.orange.shade50,
                child: ListTile(
                  leading: const Icon(Icons.warning, color: Colors.orange),
                  title: const Text('Aucun agriculteur sélectionné'),
                  trailing: ElevatedButton(
                    child: const Text('Sélectionner'),
                    onPressed: () => context.go('/farmers'),
                  ),
                ),
              ),

            const SizedBox(height: 16),
            const Text('Produits commandés', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // Cart items
            ...cart.items.map((item) => Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: Text(item.product.name),
                subtitle: Text('${fmt.format(item.product.priceFcfa)} FCFA × ${item.quantity}'),
                trailing: Text('${fmt.format(item.lineTotal)} FCFA', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            )),

            const SizedBox(height: 16),
            const Divider(),

            // Payment method
            const Text('Mode de paiement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: ['cash', 'credit'].map((method) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: cart.paymentMethod == method ? const Color(0xFF2E7D32) : null,
                      foregroundColor: cart.paymentMethod == method ? Colors.white : null,
                    ),
                    onPressed: () => ref.read(cartProvider.notifier).setPaymentMethod(method),
                    child: Text(method == 'cash' ? '💵 Espèces' : '📋 Crédit'),
                  ),
                ),
              )).toList(),
            ),

            const SizedBox(height: 16),

            // Total summary
            Card(
              color: const Color(0xFF2E7D32).withValues(alpha:0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _TotalRow('Sous-total', '${fmt.format(cart.subtotal)} FCFA'),
                    if (cart.paymentMethod == 'credit') ...[
                      _TotalRow('Intérêt (30%)', '+ ${fmt.format(interest)} FCFA', color: Colors.orange),
                    ],
                    const Divider(),
                    _TotalRow('TOTAL', '${fmt.format(total)} FCFA', bold: true, color: const Color(0xFF2E7D32)),
                  ],
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade300)),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle),
                label: Text(_isLoading ? 'Traitement...' : 'Confirmer la commande'),
                onPressed: _isLoading || cart.farmer == null ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF2E7D32),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;

  const _TotalRow(this.label, this.value, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontSize:   bold ? 18 : 14,
      color:      color,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final Map<String, dynamic> result;
  final VoidCallback onNewOrder;

  const _SuccessView({required this.result, required this.onNewOrder});

  @override
  Widget build(BuildContext context) {
    final data = result['data'] as Map<String, dynamic>? ?? {};
    final fmt  = NumberFormat('#,###', 'fr_FR');
    final total = data['total_fcfa'] ?? 0;
    final method = data['payment_method'] ?? '';

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(color: Color(0xFF2E7D32), shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 64),
              ),
              const SizedBox(height: 24),
              const Text('Commande enregistrée !', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Réf: ${data['reference'] ?? '-'}', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _TotalRow('Montant total', '${fmt.format(total)} FCFA', bold: true, color: const Color(0xFF2E7D32)),
                      _TotalRow('Paiement', method == 'credit' ? '📋 Crédit' : '💵 Espèces'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Nouvelle commande'),
                onPressed: onNewOrder,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
