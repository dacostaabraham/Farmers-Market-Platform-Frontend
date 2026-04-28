import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/farmer_repository.dart';

class FarmerSearchScreen extends ConsumerStatefulWidget {
  const FarmerSearchScreen({super.key});

  @override
  ConsumerState<FarmerSearchScreen> createState() => _FarmerSearchScreenState();
}

class _FarmerSearchScreenState extends ConsumerState<FarmerSearchScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(farmerSearchProvider);

    return Scaffold(
      body: Column(
        children: [
          // Header avec compteur
          Container(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.05),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                // Barre de recherche
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Rechercher par nom, ID ou téléphone...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              ref.read(farmerSearchProvider.notifier).clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (value) {
                    setState(() {});
                    ref.read(farmerSearchProvider.notifier).search(value);
                  },
                ),
                // Compteur d'agriculteurs
                if (!searchState.isLoading) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.people, size: 14, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 4),
                      Text(
                        _searchCtrl.text.isEmpty
                            ? '${searchState.allFarmers.length} agriculteur(s) inscrit(s)'
                            : '${searchState.results.length} résultat(s)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Liste / états
          Expanded(
            child: searchState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : searchState.error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Erreur: ${searchState.error}',
                                style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('Réessayer'),
                              onPressed: () =>
                                  ref.read(farmerSearchProvider.notifier).loadAll(),
                            ),
                          ],
                        ),
                      )
                    : searchState.results.isEmpty && _searchCtrl.text.isNotEmpty
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_search, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('Aucun agriculteur trouvé',
                                    style: TextStyle(color: Colors.grey, fontSize: 16)),
                              ],
                            ),
                          )
                        : searchState.results.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.agriculture,
                                        size: 80, color: Color(0xFF2E7D32)),
                                    const SizedBox(height: 16),
                                    const Text('Aucun agriculteur enregistré',
                                        style: TextStyle(fontSize: 18, color: Colors.grey)),
                                    const SizedBox(height: 12),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Actualiser'),
                                      onPressed: () =>
                                          ref.read(farmerSearchProvider.notifier).loadAll(),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                color: const Color(0xFF2E7D32),
                                onRefresh: () =>
                                    ref.read(farmerSearchProvider.notifier).loadAll(),
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(12),
                                  itemCount: searchState.results.length,
                                  itemBuilder: (context, index) {
                                    final farmer = searchState.results[index];
                                    return _FarmerCard(farmer: farmer);
                                  },
                                ),
                              ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/farmers/new'),
        icon: const Icon(Icons.person_add),
        label: const Text('Nouvel Agriculteur'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _FarmerCard extends StatelessWidget {
  final Farmer farmer;
  const _FarmerCard({required this.farmer});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF2E7D32),
          child: Text(
            farmer.firstname[0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(farmer.fullName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('ID: ${farmer.identifier} • ${farmer.phone}'),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF2E7D32)),
        onTap: () => context.go('/farmers/${farmer.id}'),
      ),
    );
  }
}
