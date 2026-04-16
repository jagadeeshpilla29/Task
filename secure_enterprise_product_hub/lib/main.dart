import 'package:flutter/material.dart';

import 'core/network/api_client.dart';
import 'core/state/app_cubit.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/login_user.dart';
import 'features/auth/domain/usecases/logout_user.dart';
import 'features/auth/domain/usecases/register_user.dart';
import 'features/auth/domain/usecases/restore_session.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/cubit/auth_state.dart';
import 'features/auth/presentation/screens/login_page.dart';
import 'features/products/data/datasources/product_remote_datasource.dart';
import 'features/products/data/repositories/product_repository_impl.dart';
import 'features/products/domain/usecases/create_product.dart';
import 'features/products/domain/usecases/delete_product.dart';
import 'features/products/domain/usecases/get_product_details.dart';
import 'features/products/domain/usecases/get_products.dart';
import 'features/products/domain/usecases/update_product.dart';
import 'features/products/domain/usecases/upload_product_image.dart';
import 'features/products/presentation/cubit/products_cubit.dart';
import 'features/products/presentation/screens/dashboard_page.dart';

void main() {
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(baseUrl: baseUrl, tokenStorage: tokenStorage);
  final authRepository = AuthRepositoryImpl(
    AuthRemoteDataSource(apiClient: apiClient, tokenStorage: tokenStorage),
  );
  final productRepository = ProductRepositoryImpl(
    ProductRemoteDataSource(apiClient),
  );
  final authCubit = AuthCubit(
    restoreSession: RestoreSession(authRepository),
    loginUser: LoginUser(authRepository),
    registerUser: RegisterUser(authRepository),
    logoutUser: LogoutUser(authRepository),
  );
  final productsCubit = ProductsCubit(
    getProducts: GetProducts(productRepository),
    getProductDetails: GetProductDetails(productRepository),
    createProduct: CreateProduct(productRepository),
    updateProduct: UpdateProduct(productRepository),
    deleteProduct: DeleteProduct(productRepository),
    uploadProductImage: UploadProductImage(productRepository),
  );

  runApp(ProductHubApp(authCubit: authCubit, productsCubit: productsCubit));
  authCubit.bootstrap();
}

class ProductHubApp extends StatelessWidget {
  const ProductHubApp({
    required this.authCubit,
    required this.productsCubit,
    super.key,
  });

  final AuthCubit authCubit;
  final ProductsCubit productsCubit;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secure Product Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F8FA),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Color(0xFFF6F8FA),
          foregroundColor: Color(0xFF101828),
          titleTextStyle: TextStyle(
            color: Color(0xFF101828),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.6),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shadowColor: const Color(0x1A101828),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE4E7EC)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 48),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: CubitBuilder<AuthCubit, AuthState>(
        cubit: authCubit,
        builder: (context, state) {
          if (state.status == AuthStatus.booting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (state.isAuthenticated && state.user != null) {
            return DashboardPage(
              authCubit: authCubit,
              productsCubit: productsCubit,
              user: state.user!,
            );
          }
          return LoginPage(authCubit: authCubit);
        },
      ),
    );
  }
}
