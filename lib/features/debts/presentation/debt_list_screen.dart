import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_client.dart';

// Local provider for debts
final debtsProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, farmerId) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get('/farmers/$farmerId/debts');
  return Map<String, dynamic>.from(res.data['data']);
});

class DebtListScreen extends ConsumerWidget {
  final int farmerId;
  const DebtListScreen({super.key, required this.farmerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtsAsync = ref.watch(debtsProvider(farmerId));
    final fmt        = NumberFormat('#,###', 'fr_FR');

    return Scaffold(
      appBar: AppBar(title: const Text('Dettes ouvertes')),
      body: debtsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e', style: const TextStyle(color: Colors.red))),
        data: (data) {
          final debts = data['debts'] as List? ?? [];
          final total = data['total_outstanding'] ?? 0;
          final limit = data['credit_limit'] ?? 0;

          return Column(
            children: [
              // Summary header
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF2E7D32).withValues(alpha:0.08),
                child: Row(
                  children: [
                    Expanded(
                      child: _SummaryChip(label: 'Dette totale', value: '${fmt.format(total)} FCFA', color: total > 0 ? Colors.red : Colors.green),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryChip(label: 'Limite crédit', value: '${fmt.format(limit)} FCFA', color: Colors.blue.shade700),
                    ),
                  ],
                ),
              ),

              // Debt list
              Expanded(
                child: debts.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 64, color: Color(0xFF2E7D32)),
                            SizedBox(height: 16),
                            Text('Aucune dette en cours !', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: debts.length,
                        itemBuilder: (context, index) {
                          final debt   = debts[index] as Map<String, dynamic>;
                          final status = debt['status'] as String;
                          final original  = debt['original_amount_fcfa'] ?? 0;
                          final remaining = debt['remaining_amount_fcfa'] ?? 0;
                          final paid = original - remaining;
                          final progress = original > 0 ? paid / original : 0.0;
                          final txRef = (debt['transaction'] as Map?)?['reference'] ?? '-';

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: Text(txRef, style: const TextStyle(fontWeight: FontWeight.bold))),
                                      _StatusBadge(status: status),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Original: ${fmt.format(original)} FCFA', style: const TextStyle(color: Colors.grey)),
                                      Text('Restant: ${fmt.format(remaining)} FCFA', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: progress.toDouble(),
                                    backgroundColor: Colors.red.shade100,
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                                    minHeight: 8,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('${(progress * 100).toStringAsFixed(0)}% remboursé', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'open'           => ('Ouvert', Colors.red),
      'partially_paid' => ('Partiel', Colors.orange),
      'paid'           => ('Payé', Colors.green),
      _                => (status, Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha:0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
