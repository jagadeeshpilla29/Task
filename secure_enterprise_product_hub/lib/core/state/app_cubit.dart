import 'package:flutter/widgets.dart';

abstract class AppCubit<S> extends ChangeNotifier {
  AppCubit(this._state);

  S _state;
  S get state => _state;

  @protected
  void emit(S state) {
    _state = state;
    notifyListeners();
  }
}

class CubitBuilder<C extends AppCubit<S>, S> extends StatelessWidget {
  const CubitBuilder({required this.cubit, required this.builder, super.key});

  final C cubit;
  final Widget Function(BuildContext context, S state) builder;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: cubit,
      builder: (context, _) => builder(context, cubit.state),
    );
  }
}
