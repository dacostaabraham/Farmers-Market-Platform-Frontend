import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/farmer_repository.dart';

class CreateFarmerScreen extends ConsumerStatefulWidget {
  const CreateFarmerScreen({super.key});

  @override
  ConsumerState<CreateFarmerScreen> createState() => _CreateFarmerScreenState();
}

class _CreateFarmerScreenState extends ConsumerState<CreateFarmerScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _idCtrl        = TextEditingController();
  final _firstnameCtrl = TextEditingController();
  final _lastnameCtrl  = TextEditingController();
  final _phoneCtrl     = TextEditingController();
  final _villageCtrl   = TextEditingController();
  final _limitCtrl     = TextEditingController(text: '500000');

  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_idCtrl, _firstnameCtrl, _lastnameCtrl, _phoneCtrl, _villageCtrl, _limitCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      final farmer = await ref.read(farmerRepositoryProvider).create(
        identifier:      _idCtrl.text.trim(),
        firstname:       _firstnameCtrl.text.trim(),
        lastname:        _lastnameCtrl.text.trim(),
        phone:           _phoneCtrl.text.trim(),
        village:         _villageCtrl.text.trim().isEmpty ? null : _villageCtrl.text.trim(),
        creditLimitFcfa: int.tryParse(_limitCtrl.text),
      );
      if (mounted) context.go('/farmers/${farmer.id}');
    } catch (e) {
      setState(() {
        // Affiche les erreurs de validation champ par champ si disponibles
        final data = (e as dynamic).response?.data;
        if (data != null && data['errors'] != null) {
          final errors = data['errors'] as Map<String, dynamic>;
          _error = errors.entries
              .map((entry) => '• ${entry.value[0]}')
              .join('\n');
        } else {
          _error = data?['message'] ?? e.toString();
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvel Agriculteur')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _field(_idCtrl,        'Numéro de carte agriculteur', Icons.badge, required: true),
              _field(_firstnameCtrl, 'Prénom',  Icons.person, required: true),
              _field(_lastnameCtrl,  'Nom',     Icons.person_outline, required: true),
              _field(_phoneCtrl,     'Téléphone', Icons.phone, required: true, keyboardType: TextInputType.phone),
              _field(_villageCtrl,   'Village / Localité', Icons.location_on),
              _field(_limitCtrl,     'Limite de crédit (FCFA)', Icons.credit_card, required: true, keyboardType: TextInputType.number),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _isLoading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check),
                  label: Text(_isLoading ? 'Enregistrement...' : 'Créer le profil'),
                  onPressed: _isLoading ? null : _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {bool required = false, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        validator: required ? (v) => v!.isEmpty ? 'Champ requis' : null : null,
      ),
    );
  }
}
