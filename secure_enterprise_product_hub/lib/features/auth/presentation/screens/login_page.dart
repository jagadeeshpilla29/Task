import 'package:flutter/material.dart';

import '../../../../core/state/app_cubit.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({required this.authCubit, super.key});

  final AuthCubit authCubit;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController(text: 'Admin User');
  final _email = TextEditingController(text: 'admin@example.com');
  final _password = TextEditingController(text: 'Password123');
  var _registerMode = false;
  var _role = 'admin';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFF101828),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'SECURE ENTERPRISE',
                    style: TextStyle(
                      color: Color(0xFF84E1BC),
                      fontSize: 12,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Product Hub',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'JWT protected catalog operations with admin controls.',
                    style: TextStyle(color: Color(0xFFD0D5DD), fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x40101828),
                          blurRadius: 32,
                          offset: Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: CubitBuilder<AuthCubit, AuthState>(
                          cubit: widget.authCubit,
                          builder: (context, state) {
                            final loading = state.status == AuthStatus.loading;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: scheme.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.verified_user_outlined,
                                    color: scheme.onPrimary,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  _registerMode
                                      ? 'Create account'
                                      : 'Welcome back',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _registerMode
                                      ? 'Register an admin or viewer profile.'
                                      : 'Sign in with your assigned role.',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 24),
                                if (_registerMode) ...[
                                  TextFormField(
                                    controller: _name,
                                    decoration: const InputDecoration(
                                      labelText: 'Name',
                                    ),
                                    validator: (value) =>
                                        value == null || value.trim().length < 2
                                        ? 'Enter your name'
                                        : null,
                                  ),
                                  const SizedBox(height: 14),
                                ],
                                TextFormField(
                                  controller: _email,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) =>
                                      value == null || !value.contains('@')
                                      ? 'Enter a valid email'
                                      : null,
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _password,
                                  decoration: const InputDecoration(
                                    labelText: 'Password',
                                  ),
                                  obscureText: true,
                                  validator: (value) =>
                                      value == null || value.length < 8
                                      ? 'Use at least 8 characters'
                                      : null,
                                ),
                                if (_registerMode) ...[
                                  const SizedBox(height: 14),
                                  DropdownButtonFormField<String>(
                                    initialValue: _role,
                                    decoration: const InputDecoration(
                                      labelText: 'Role',
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'admin',
                                        child: Text('Admin'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'user',
                                        child: Text('User'),
                                      ),
                                    ],
                                    onChanged: (value) =>
                                        setState(() => _role = value ?? 'user'),
                                  ),
                                ],
                                if (state.message != null) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    state.message!,
                                    style: TextStyle(color: scheme.error),
                                  ),
                                ],
                                const SizedBox(height: 24),
                                FilledButton(
                                  onPressed: loading ? null : _submit,
                                  child: Text(
                                    loading
                                        ? 'Please wait...'
                                        : _registerMode
                                        ? 'Create account'
                                        : 'Login',
                                  ),
                                ),
                                TextButton(
                                  onPressed: loading
                                      ? null
                                      : () => setState(
                                          () => _registerMode = !_registerMode,
                                        ),
                                  child: Text(
                                    _registerMode
                                        ? 'Use existing account'
                                        : 'Create a new account',
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_registerMode) {
      await widget.authCubit.register(
        _name.text,
        _email.text,
        _password.text,
        _role,
      );
    } else {
      await widget.authCubit.login(_email.text, _password.text);
    }
  }
}
