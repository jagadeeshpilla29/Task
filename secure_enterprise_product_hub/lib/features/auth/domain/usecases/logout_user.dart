import '../repositories/auth_repository.dart';

class LogoutUser {
  LogoutUser(this._repository);

  final AuthRepository _repository;

  Future<void> call() => _repository.logout();
}
