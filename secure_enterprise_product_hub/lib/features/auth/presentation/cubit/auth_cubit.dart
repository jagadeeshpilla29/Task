import '../../../../core/network/api_client.dart';
import '../../../../core/state/app_cubit.dart';
import '../../domain/usecases/login_user.dart';
import '../../domain/usecases/logout_user.dart';
import '../../domain/usecases/register_user.dart';
import '../../domain/usecases/restore_session.dart';
import 'auth_state.dart';

class AuthCubit extends AppCubit<AuthState> {
  AuthCubit({
    required RestoreSession restoreSession,
    required LoginUser loginUser,
    required RegisterUser registerUser,
    required LogoutUser logoutUser,
  }) : _restoreSession = restoreSession,
       _loginUser = loginUser,
       _registerUser = registerUser,
       _logoutUser = logoutUser,
       super(const AuthState(status: AuthStatus.booting));

  final RestoreSession _restoreSession;
  final LoginUser _loginUser;
  final RegisterUser _registerUser;
  final LogoutUser _logoutUser;

  Future<void> bootstrap() async {
    final user = await _restoreSession();
    if (user == null) {
      emit(const AuthState(status: AuthStatus.unauthenticated));
      return;
    }
    emit(AuthState(status: AuthStatus.authenticated, user: user));
  }

  Future<void> login(String email, String password) async {
    emit(state.copyWith(status: AuthStatus.loading, clearMessage: true));
    try {
      final user = await _loginUser(email, password);
      emit(AuthState(status: AuthStatus.authenticated, user: user));
    } on ApiException catch (error) {
      emit(AuthState(status: AuthStatus.failure, message: error.message));
    }
  }

  Future<void> register(
    String name,
    String email,
    String password,
    String role,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearMessage: true));
    try {
      await _registerUser(
        name: name,
        email: email,
        password: password,
        role: role,
      );
      final user = await _loginUser(email, password);
      emit(AuthState(status: AuthStatus.authenticated, user: user));
    } on ApiException catch (error) {
      emit(AuthState(status: AuthStatus.failure, message: error.message));
    }
  }

  Future<void> logout() async {
    await _logoutUser();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}
