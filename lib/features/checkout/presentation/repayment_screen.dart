import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../data/cart_provider.dart';
import '../../farmers/data/farmer_repository.dart';

class RepaymentScreen extends ConsumerStatefulWidget {
  final int farmerId;
  const RepaymentScreen({super.key, required this.farmerId});

  @override
  ConsumerState<RepaymentScreen> createState() => _RepaymentScreenState();
}

class _RepaymentScreenState extends ConsumerState<RepaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _kgCtrl  = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _isLoadingPreview  = false;
  bool _isSubmitting      = false;
  Map<String, dynamic>? _previewData;
  String? _error;
  bool _success = false;

  final fmt = NumberFormat('#,###', 'fr_FR');

  @override
  void dispose() {
    _kgCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchPreview() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoadingPreview = true; _error = null; _previewData = null; });

    try {
      final result = await ref.read(repaymentRepositoryProvider).previewRepayment(
        widget.farmerId,
        double.parse(_kgCtrl.text),
      );
      setState(() { _previewData = result; _isLoadingPreview = false; });
    } catch (e) {
      setState(() {
        _error = (e as dynamic).response?.data['message'] ?? e.toString();
        _isLoadingPreview = false;
      });
    }
  }

  Future<void> _submit() async {
    setState(() { _isSubmitting = true; _error = null; });
    try {
      await ref.read(repaymentRepositoryProvider).recordRepayment(
        widget.farmerId,
        double.parse(_kgCtrl.text),
        notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
      );
      setState(() { _success = true; _isSubmitting = false; });
      // Refresh farmer detail
      ref.invalidate(farmerDetailProvider(widget.farmerId));
    } catch (e) {
      setState(() {
        _error = (e as dynamic).response?.data['message'] ?? e.toString();
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_success) {
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
                const Text('Remboursement enregistré !', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Retour à l\'agriculteur'),
                  onPressed: () => context.go('/farmers/${widget.farmerId}'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Enregistrer Remboursement')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info card
              Card(
                color: const Color(0xFF2E7D32).withValues(alpha:0.08),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF2E7D32)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Le remboursement se fait en kg de cacao. Le système convertit en FCFA et solde les dettes les plus anciennes en premier (FIFO).',
                          style: TextStyle(color: Color(0xFF2E7D32)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // KG input
              TextFormField(
                controller: _kgCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Quantité de cacao reçue (kg)',
                  prefixIcon: Icon(Icons.scale),
                  suffixText: 'kg',
                  border: OutlineInputBorder(),
                  helperText: 'Entrez la quantité en kilogrammes',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Champ requis';
                  final n = double.tryParse(v);
                  if (n == null || n <= 0) return 'Valeur invalide';
                  return null;
                },
                onChanged: (_) => setState(() { _previewData = null; }),
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (optionnel)',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Preview button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: _isLoadingPreview
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.calculate),
                  label: const Text('Calculer la conversion'),
                  onPressed: _isLoadingPreview ? null : _fetchPreview,
                ),
              ),

              // Preview result
              if (_previewData != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Aperçu de la conversion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        _PreviewRow('Cacao reçu', '${_previewData!['commodity_kg']} kg'),
                        _PreviewRow('Taux de conversion', '${fmt.format(_previewData!['rate_fcfa_per_kg'])} FCFA/kg'),
                        const Divider(),
                        _PreviewRow(
                          'Valeur FCFA',
                          '${fmt.format(_previewData!['total_fcfa'])} FCFA',
                          bold: true, color: const Color(0xFF2E7D32),
                        ),
                        _PreviewRow('Dette restante', '${fmt.format(_previewData!['outstanding_debt'])} FCFA'),
                        const SizedBox(height: 16),

                        // Confirm
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: _isSubmitting
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.check_circle),
                            label: const Text('Confirmer le remboursement'),
                            onPressed: _isSubmitting ? null : _submit,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

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
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;

  const _PreviewRow(this.label, this.value, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color, fontSize: bold ? 16 : 14)),
        ],
      ),
    );
  }
}
