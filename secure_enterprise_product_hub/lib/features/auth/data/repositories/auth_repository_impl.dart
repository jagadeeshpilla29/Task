import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Future<AppUser?> restoreSession() async {
    return _remoteDataSource.restoreSession();
  }

  @override
  Future<AppUser> login(String email, String password) async {
    return _remoteDataSource.login(email, password);
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    await _remoteDataSource.register(
      name: name,
      email: email,
      password: password,
      role: role,
    );
  }

  @override
  Future<void> logout() async {
    await _remoteDataSource.logout();
  }
}
