import 'package:flutter_test/flutter_test.dart';
import 'package:secure_enterprise_product_hub/core/network/api_client.dart';
import 'package:secure_enterprise_product_hub/core/storage/token_storage.dart';
import 'package:secure_enterprise_product_hub/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:secure_enterprise_product_hub/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:secure_enterprise_product_hub/features/auth/domain/usecases/login_user.dart';
import 'package:secure_enterprise_product_hub/features/auth/domain/usecases/logout_user.dart';
import 'package:secure_enterprise_product_hub/features/auth/domain/usecases/register_user.dart';
import 'package:secure_enterprise_product_hub/features/auth/domain/usecases/restore_session.dart';
import 'package:secure_enterprise_product_hub/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:secure_enterprise_product_hub/features/products/data/datasources/product_remote_datasource.dart';
import 'package:secure_enterprise_product_hub/features/products/data/repositories/product_repository_impl.dart';
import 'package:secure_enterprise_product_hub/features/products/domain/usecases/create_product.dart';
import 'package:secure_enterprise_product_hub/features/products/domain/usecases/delete_product.dart';
import 'package:secure_enterprise_product_hub/features/products/domain/usecases/get_product_details.dart';
import 'package:secure_enterprise_product_hub/features/products/domain/usecases/get_products.dart';
import 'package:secure_enterprise_product_hub/features/products/domain/usecases/update_product.dart';
import 'package:secure_enterprise_product_hub/features/products/domain/usecases/upload_product_image.dart';
import 'package:secure_enterprise_product_hub/features/products/presentation/cubit/products_cubit.dart';
import 'package:secure_enterprise_product_hub/main.dart';

void main() {
  testWidgets('renders login screen while unauthenticated', (
    WidgetTester tester,
  ) async {
    final storage = TokenStorage.memory();
    final api = ApiClient(
      baseUrl: 'http://localhost:8000',
      tokenStorage: storage,
    );
    final authRepository = AuthRepositoryImpl(
      AuthRemoteDataSource(apiClient: api, tokenStorage: storage),
    );
    final productRepository = ProductRepositoryImpl(
      ProductRemoteDataSource(api),
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

    await tester.pumpWidget(
      ProductHubApp(authCubit: authCubit, productsCubit: productsCubit),
    );
    await authCubit.bootstrap();
    await tester.pump();

    expect(find.text('Product Hub'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
