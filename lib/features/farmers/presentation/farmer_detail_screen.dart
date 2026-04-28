import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../data/farmer_repository.dart';
import '../../checkout/data/cart_provider.dart';

class FarmerDetailScreen extends ConsumerWidget {
  final int farmerId;
  const FarmerDetailScreen({super.key, required this.farmerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmerAsync = ref.watch(farmerDetailProvider(farmerId));
    final fmt = NumberFormat('#,###', 'fr_FR');

    return farmerAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Erreur: $e'))),
      data: (farmer) => Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: const Color(0xFF2E7D32),
                        child: Text(
                          farmer.firstname[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(farmer.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            Text('ID: ${farmer.identifier}', style: TextStyle(color: Colors.grey.shade600)),
                            Text(farmer.phone, style: TextStyle(color: Colors.grey.shade600)),
                            if (farmer.village != null) Text('📍 ${farmer.village}', style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Credit summary
              Row(
                children: [
                  Expanded(child: _SummaryCard(
                    label: 'Dette totale',
                    value: '${fmt.format(farmer.totalOutstandingDebt)} FCFA',
                    color: farmer.totalOutstandingDebt > 0 ? Colors.red.shade600 : Colors.green,
                    icon: Icons.account_balance_wallet,
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: _SummaryCard(
                    label: 'Crédit dispo.',
                    value: '${fmt.format(farmer.availableCredit)} FCFA',
                    color: const Color(0xFF2E7D32),
                    icon: Icons.credit_score,
                  )),
                ],
              ),
              const SizedBox(height: 8),
              _SummaryCard(
                label: 'Limite de crédit',
                value: '${fmt.format(farmer.creditLimitFcfa)} FCFA',
                color: Colors.blue.shade700,
                icon: Icons.shield,
              ),
              const SizedBox(height: 24),

              // Actions
              const Text('Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              // Start order
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('Nouvelle Commande'),
                  onPressed: () {
                    ref.read(cartProvider.notifier).setFarmer(farmer);
                    context.go('/catalog');
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.receipt_long),
                      label: const Text('Voir Dettes'),
                      onPressed: () => context.go('/farmers/$farmerId/debts'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.payments),
                      label: const Text('Rembourser'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.orange.shade700),
                      onPressed: () => context.go('/farmers/$farmerId/repayment'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
