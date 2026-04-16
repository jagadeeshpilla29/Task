import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/app_user_model.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource({required this.apiClient, required this.tokenStorage});

  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  Future<AppUserModel?> restoreSession() async {
    final token = await tokenStorage.readToken();
    if (token == null) {
      return null;
    }
    try {
      return me();
    } on ApiException {
      await tokenStorage.clear();
      return null;
    }
  }

  Future<AppUserModel> login(String email, String password) async {
    final response = await apiClient.post(
      '/api/auth/login',
      auth: false,
      body: {'email': email.trim(), 'password': password},
    );
    final data = response['data'] as Map<String, dynamic>;
    await tokenStorage.saveToken(data['accessToken'].toString());
    return me();
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) {
    return apiClient.post(
      '/api/auth/register',
      auth: false,
      body: {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'role': role,
      },
    );
  }

  Future<AppUserModel> me() async {
    final response = await apiClient.get('/api/auth/me');
    return AppUserModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      await apiClient.post('/api/auth/logout');
    } catch (_) {
      // The token is still cleared locally even if the server is unreachable.
    }
    await tokenStorage.clear();
  }
}
