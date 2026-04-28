import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

// ── Models ──────────────────────────────────────────────────────────────

class Farmer {
  final int id;
  final String identifier;
  final String firstname;
  final String lastname;
  final String phone;
  final String? village;
  final int creditLimitFcfa;

  const Farmer({
    required this.id,
    required this.identifier,
    required this.firstname,
    required this.lastname,
    required this.phone,
    this.village,
    required this.creditLimitFcfa,
  });

  String get fullName => '$firstname $lastname';

  factory Farmer.fromJson(Map<String, dynamic> json) => Farmer(
    id:              json['id'],
    identifier:      json['identifier'],
    firstname:       json['firstname'],
    lastname:        json['lastname'],
    phone:           json['phone'],
    village:         json['village'],
    creditLimitFcfa: json['credit_limit_fcfa'] ?? 500000,
  );
}

class FarmerDetail extends Farmer {
  final int totalOutstandingDebt;
  final int availableCredit;
  final List<Map<String, dynamic>> debts;

  const FarmerDetail({
    required super.id,
    required super.identifier,
    required super.firstname,
    required super.lastname,
    required super.phone,
    super.village,
    required super.creditLimitFcfa,
    required this.totalOutstandingDebt,
    required this.availableCredit,
    required this.debts,
  });

  factory FarmerDetail.fromJson(Map<String, dynamic> json) => FarmerDetail(
    id:                  json['id'],
    identifier:          json['identifier'],
    firstname:           json['firstname'],
    lastname:            json['lastname'],
    phone:               json['phone'],
    village:             json['village'],
    creditLimitFcfa:     json['credit_limit_fcfa'] ?? 500000,
    totalOutstandingDebt: json['total_outstanding_debt'] ?? 0,
    availableCredit:     json['available_credit'] ?? 0,
    debts:               List<Map<String, dynamic>>.from(json['debts'] ?? []),
  );
}

// ── Repository ──────────────────────────────────────────────────────────

final farmerRepositoryProvider = Provider<FarmerRepository>(
  (ref) => FarmerRepository(ref.read(apiClientProvider)),
);

class FarmerRepository {
  final ApiClient _api;
  FarmerRepository(this._api);

  Future<List<Farmer>> getAll() async {
    final res = await _api.get('/farmers');
    final list = res.data['data'] as List;
    return list.map((e) => Farmer.fromJson(e)).toList();
  }

  Future<List<Farmer>> search(String query) async {
    final res = await _api.get('/farmers/search', queryParams: {'q': query});
    final list = res.data['data'] as List;
    return list.map((e) => Farmer.fromJson(e)).toList();
  }

  Future<FarmerDetail> getById(int id) async {
    final res = await _api.get('/farmers/$id');
    return FarmerDetail.fromJson(res.data['data']);
  }

  Future<Farmer> create({
    required String identifier,
    required String firstname,
    required String lastname,
    required String phone,
    String? village,
    int? creditLimitFcfa,
  }) async {
    final res = await _api.post('/farmers', data: {
      'identifier':        identifier,
      'firstname':         firstname,
      'lastname':          lastname,
      'phone':             phone,
      if (village != null)          'village':           village,
      if (creditLimitFcfa != null)  'credit_limit_fcfa': creditLimitFcfa,
    });
    return Farmer.fromJson(res.data['data']);
  }
}

// ── State ──────────────────────────────────────────────────────────────

class FarmerSearchState {
  final List<Farmer> allFarmers;   // liste complète chargée au démarrage
  final List<Farmer> results;      // résultats filtrés affichés
  final bool isLoading;
  final String? error;

  const FarmerSearchState({
    this.allFarmers = const [],
    this.results    = const [],
    this.isLoading  = false,
    this.error,
  });

  FarmerSearchState copyWith({
    List<Farmer>? allFarmers,
    List<Farmer>? results,
    bool? isLoading,
    String? error,
  }) => FarmerSearchState(
    allFarmers: allFarmers ?? this.allFarmers,
    results:    results    ?? this.results,
    isLoading:  isLoading  ?? this.isLoading,
    error:      error,
  );
}

class FarmerSearchNotifier extends StateNotifier<FarmerSearchState> {
  final FarmerRepository _repo;
  FarmerSearchNotifier(this._repo) : super(const FarmerSearchState()) {
    loadAll(); // charge tous les agriculteurs dès l'initialisation
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final all = await _repo.getAll();
      state = state.copyWith(allFarmers: all, results: all, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> search(String query) async {
    if (query.trim().length < 2) {
      // Requête trop courte → réafficher tous les agriculteurs
      state = state.copyWith(results: state.allFarmers);
      return;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await _repo.search(query.trim());
      state = state.copyWith(results: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clear() => state = state.copyWith(results: state.allFarmers);
}

final farmerSearchProvider = StateNotifierProvider<FarmerSearchNotifier, FarmerSearchState>(
  (ref) => FarmerSearchNotifier(ref.read(farmerRepositoryProvider)),
);

final farmerDetailProvider = FutureProvider.family<FarmerDetail, int>((ref, id) async {
  return ref.read(farmerRepositoryProvider).getById(id);
});
