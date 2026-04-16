import '../entities/app_user.dart';

abstract class AuthRepository {
  Future<AppUser?> restoreSession();

  Future<AppUser> login(String email, String password);

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
  });

  Future<void> logout();
}
