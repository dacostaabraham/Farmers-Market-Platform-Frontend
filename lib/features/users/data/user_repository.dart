import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

// ── Model ────────────────────────────────────────────────────────────────

class AppUser {
  final int id;
  final String name;
  final String email;
  final String role;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id:    json['id'],
        name:  json['name'],
        email: json['email'],
        role:  json['role'],
      );
}

// ── Repository ───────────────────────────────────────────────────────────

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(ref.read(apiClientProvider)),
);

class UserRepository {
  final ApiClient _api;
  UserRepository(this._api);

  /// Admin → liste des superviseurs
  Future<List<AppUser>> getSupervisors() async {
    final res = await _api.get('/users/supervisors');
    final list = res.data['data'] as List;
    return list.map((e) => AppUser.fromJson(e)).toList();
  }

  /// Admin → créer un superviseur
  Future<AppUser> createSupervisor({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await _api.post('/users/supervisors', data: {
      'name':     name,
      'email':    email,
      'password': password,
      'role':     'supervisor',
    });
    return AppUser.fromJson(res.data['data']);
  }

  /// Admin + Supervisor → liste des opérateurs
  Future<List<AppUser>> getOperators() async {
    final res = await _api.get('/users/operators');
    final list = res.data['data'] as List;
    return list.map((e) => AppUser.fromJson(e)).toList();
  }

  /// Admin + Supervisor → créer un opérateur
  Future<AppUser> createOperator({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await _api.post('/users/operators', data: {
      'name':     name,
      'email':    email,
      'password': password,
      'role':     'operator',
    });
    return AppUser.fromJson(res.data['data']);
  }
}

// ── State ────────────────────────────────────────────────────────────────

class UserListState {
  final List<AppUser> users;
  final bool isLoading;
  final String? error;

  const UserListState({
    this.users     = const [],
    this.isLoading = false,
    this.error,
  });

  UserListState copyWith({
    List<AppUser>? users,
    bool? isLoading,
    String? error,
  }) =>
      UserListState(
        users:     users     ?? this.users,
        isLoading: isLoading ?? this.isLoading,
        error:     error,
      );
}

// ── Notifier ─────────────────────────────────────────────────────────────

class UserListNotifier extends StateNotifier<UserListState> {
  final UserRepository _repo;
  final bool isSupervisorList; // true → /supervisors, false → /operators

  UserListNotifier(this._repo, {required this.isSupervisorList})
      : super(const UserListState()) {
    loadAll();
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = isSupervisorList
          ? await _repo.getSupervisors()
          : await _repo.getOperators();
      state = state.copyWith(users: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final user = isSupervisorList
          ? await _repo.createSupervisor(name: name, email: email, password: password)
          : await _repo.createOperator(name: name, email: email, password: password);
      state = state.copyWith(users: [...state.users, user]);
      return true;
    } catch (e) {
      return false;
    }
  }
}

// Providers séparés pour superviseurs et opérateurs
final supervisorListProvider =
    StateNotifierProvider<UserListNotifier, UserListState>(
  (ref) => UserListNotifier(
    ref.read(userRepositoryProvider),
    isSupervisorList: true,
  ),
);

final operatorListProvider =
    StateNotifierProvider<UserListNotifier, UserListState>(
  (ref) => UserListNotifier(
    ref.read(userRepositoryProvider),
    isSupervisorList: false,
  ),
);
