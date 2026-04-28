import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import '../data/user_repository.dart';

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authProvider).user?.role ?? '';
    final isAdmin = role == 'admin';

    // Admin gère les superviseurs, supervisor gère les opérateurs
    final provider = isAdmin ? supervisorListProvider : operatorListProvider;
    final state    = ref.watch(provider);
    final title    = isAdmin ? 'Gestion Superviseurs' : 'Gestion Opérateurs';
    final subRole  = isAdmin ? 'superviseur' : 'opérateur';

    return Scaffold(
      body: Column(
        children: [
          // En-tête avec compteur
          Container(
            color: const Color(0xFF1565C0).withValues(alpha: 0.05),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.manage_accounts, color: Color(0xFF1565C0)),
                const SizedBox(width: 8),
                if (!state.isLoading)
                  Text(
                    '${state.users.length} $subRole(s)',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1565C0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),

          // Liste
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Erreur: ${state.error}',
                                style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('Réessayer'),
                              onPressed: () =>
                                  ref.read(provider.notifier).loadAll(),
                            ),
                          ],
                        ),
                      )
                    : state.users.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person_off,
                                    size: 64, color: Colors.grey),
                                const SizedBox(height: 12),
                                Text('Aucun $subRole enregistré',
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 16)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            color: const Color(0xFF1565C0),
                            onRefresh: () =>
                                ref.read(provider.notifier).loadAll(),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: state.users.length,
                              itemBuilder: (context, index) {
                                final u = state.users[index];
                                return _UserCard(user: u);
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref, isAdmin, subRole),
        icon: const Icon(Icons.person_add),
        label: Text('Nouvel $subRole'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showCreateDialog(
      BuildContext context, WidgetRef ref, bool isAdmin, String subRole) {
    showDialog(
      context: context,
      builder: (_) => _CreateUserDialog(
        isAdmin:  isAdmin,
        subRole:  subRole,
        onSaved:  () {
          final provider = isAdmin ? supervisorListProvider : operatorListProvider;
          ref.read(provider.notifier).loadAll();
        },
      ),
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final AppUser user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1565C0),
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(user.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(user.email),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            user.role.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF1565C0),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Dialogue de création ──────────────────────────────────────────────────

class _CreateUserDialog extends ConsumerStatefulWidget {
  final bool isAdmin;
  final String subRole;
  final VoidCallback onSaved;

  const _CreateUserDialog({
    required this.isAdmin,
    required this.subRole,
    required this.onSaved,
  });

  @override
  ConsumerState<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends ConsumerState<_CreateUserDialog> {
  final _formKey  = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl= TextEditingController();
  final _passCtrl = TextEditingController();

  bool _isLoading = false;
  String? _error;
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      final provider = widget.isAdmin ? supervisorListProvider : operatorListProvider;
      final ok = await ref.read(provider.notifier).createUser(
        name:     _nameCtrl.text.trim(),
        email:    _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      if (ok && mounted) {
        widget.onSaved();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.subRole.substring(0,1).toUpperCase()}${widget.subRole.substring(1)} créé avec succès'),
            backgroundColor: const Color(0xFF1565C0),
          ),
        );
      } else {
        setState(() { _isLoading = false; _error = 'Erreur lors de la création'; });
      }
    } catch (e) {
      final data = (e as dynamic).response?.data;
      String msg;
      if (data != null && data['errors'] != null) {
        final errors = data['errors'] as Map<String, dynamic>;
        msg = errors.entries.map((en) => '• ${en.value[0]}').join('\n');
      } else {
        msg = data?['message'] ?? e.toString();
      }
      setState(() { _isLoading = false; _error = msg; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Créer ${widget.subRole}',
        style: const TextStyle(color: Color(0xFF1565C0)),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v!.isEmpty) return 'Champ requis';
                  if (!v.contains('@')) return 'Email invalide';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) {
                  if (v!.isEmpty) return 'Champ requis';
                  if (v.length < 8) return 'Minimum 8 caractères';
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.red, fontSize: 13)),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Créer'),
        ),
      ],
    );
  }
}
