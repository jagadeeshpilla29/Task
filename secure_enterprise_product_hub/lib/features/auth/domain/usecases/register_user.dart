import '../repositories/auth_repository.dart';

class RegisterUser {
  RegisterUser(this._repository);

  final AuthRepository _repository;

  Future<void> call({
    required String name,
    required String email,
    required String password,
    required String role,
  }) {
    return _repository.register(
      name: name,
      email: email,
      password: password,
      role: role,
    );
  }
}
