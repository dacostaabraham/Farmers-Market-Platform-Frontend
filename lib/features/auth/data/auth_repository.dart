import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_constants.dart';

// ── Models ──────────────────────────────────────────────────────────────

class AuthUser {
  final int id;
  final String name;
  final String email;
  final String role;

  const AuthUser({required this.id, required this.name, required this.email, required this.role});

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id:    json['id'],
    name:  json['name'],
    email: json['email'],
    role:  json['role'],
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email, 'role': role};

  bool get isOperator   => role == 'operator';
  bool get isSupervisor => role == 'supervisor';
  bool get isAdmin      => role == 'admin';
}

// ── Repository ──────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.read(apiClientProvider)),
);

class AuthRepository {
  final ApiClient _api;
  final _storage = const FlutterSecureStorage();

  AuthRepository(this._api);

  Future<AuthUser> login(String email, String password) async {
    final response = await _api.post('/auth/login', data: {
      'email': email,
      'password': password,
    });

    final data = response.data;
    final token = data['token'] as String;
    final user  = AuthUser.fromJson(data['user'] as Map<String, dynamic>);

    await _storage.write(key: AppConstants.tokenKey, value: token);
    await _storage.write(key: AppConstants.userKey, value: jsonEncode(user.toJson()));

    return user;
  }

  Future<void> logout() async {
    try { await _api.post('/auth/logout'); } catch (_) {}
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.userKey);
  }

  Future<AuthUser?> getStoredUser() async {
    final raw = await _storage.read(key: AppConstants.userKey);
    if (raw == null) return null;
    return AuthUser.fromJson(jsonDecode(raw));
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    return token != null;
  }
}

// ── State ──────────────────────────────────────────────────────────────

class AuthState {
  final AuthUser? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({AuthUser? user, bool? isLoading, String? error}) => AuthState(
    user:      user      ?? this.user,
    isLoading: isLoading ?? this.isLoading,
    error:     error,
  );

  bool get isAuthenticated => user != null;
}

// ── Notifier ──────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  final ApiClient _apiClient;

  AuthNotifier(this._repo, this._apiClient) : super(const AuthState()) {
    // Déconnexion automatique si le token est rejeté (401)
    _apiClient.onUnauthorized = () async {
      state = const AuthState();
    };
    _init();
  }

  Future<void> _init() async {
    final user = await _repo.getStoredUser();
    if (user != null) {
      state = state.copyWith(user: user);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repo.login(email, password);
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      final msg = _extractError(e);
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState();
  }

  String _extractError(dynamic e) {
    try {
      return (e as dynamic).response?.data['message'] ?? e.toString();
    } catch (_) {
      return e.toString();
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(
    ref.read(authRepositoryProvider),
    ref.read(apiClientProvider),
  ),
);
