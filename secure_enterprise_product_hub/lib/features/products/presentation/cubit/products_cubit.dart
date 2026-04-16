import 'dart:io';

import '../../../../core/network/api_client.dart';
import '../../../../core/state/app_cubit.dart';
import '../../domain/usecases/create_product.dart';
import '../../domain/usecases/delete_product.dart';
import '../../domain/usecases/get_product_details.dart';
import '../../domain/usecases/get_products.dart';
import '../../domain/usecases/update_product.dart';
import '../../domain/usecases/upload_product_image.dart';
import 'products_state.dart';

class ProductsCubit extends AppCubit<ProductsState> {
  ProductsCubit({
    required GetProducts getProducts,
    required GetProductDetails getProductDetails,
    required CreateProduct createProduct,
    required UpdateProduct updateProduct,
    required DeleteProduct deleteProduct,
    required UploadProductImage uploadProductImage,
  }) : _getProducts = getProducts,
       _getProductDetails = getProductDetails,
       _createProduct = createProduct,
       _updateProduct = updateProduct,
       _deleteProduct = deleteProduct,
       _uploadProductImage = uploadProductImage,
       super(const ProductsState(status: ProductsStatus.initial));

  final GetProducts _getProducts;
  final GetProductDetails _getProductDetails;
  final CreateProduct _createProduct;
  final UpdateProduct _updateProduct;
  final DeleteProduct _deleteProduct;
  final UploadProductImage _uploadProductImage;

  Future<void> refresh({String? search, String? category}) async {
    emit(
      state.copyWith(
        status: ProductsStatus.loading,
        search: search,
        category: category,
        page: 1,
        clearMessage: true,
      ),
    );
    try {
      final page = await _getProducts(
        page: 1,
        limit: state.limit,
        search: state.search,
        category: state.category,
      );
      emit(
        state.copyWith(
          status: ProductsStatus.ready,
          products: page.products,
          page: page.page,
          total: page.total,
          limit: page.limit,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(status: ProductsStatus.failure, message: error.message),
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.status == ProductsStatus.loading) {
      return;
    }
    emit(state.copyWith(status: ProductsStatus.loading));
    try {
      final next = await _getProducts(
        page: state.page + 1,
        limit: state.limit,
        search: state.search,
        category: state.category,
      );
      emit(
        state.copyWith(
          status: ProductsStatus.ready,
          products: [...state.products, ...next.products],
          page: next.page,
          total: next.total,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(status: ProductsStatus.failure, message: error.message),
      );
    }
  }

  Future<void> loadDetails(String id) async {
    try {
      final product = await _getProductDetails(id);
      emit(state.copyWith(selected: product));
    } on ApiException catch (error) {
      emit(state.copyWith(message: error.message));
    }
  }

  Future<bool> save({
    String? id,
    required String name,
    required double price,
    required String currency,
    required String category,
    File? image,
  }) async {
    emit(state.copyWith(status: ProductsStatus.saving, clearMessage: true));
    try {
      if (id == null) {
        final createdId = await _createProduct(
          name: name,
          price: price,
          currency: currency,
          category: category,
        );
        if (image != null && createdId.isNotEmpty) {
          await _uploadProductImage(createdId, image);
        }
      } else {
        await _updateProduct(
          id: id,
          name: name,
          price: price,
          currency: currency,
          category: category,
        );
        if (image != null) {
          await _uploadProductImage(id, image);
        }
      }
      await refresh();
      return true;
    } on ApiException catch (error) {
      emit(
        state.copyWith(status: ProductsStatus.failure, message: error.message),
      );
      return false;
    }
  }

  Future<void> uploadImage(String id, File image) async {
    emit(state.copyWith(status: ProductsStatus.saving));
    try {
      final imageUrl = await _uploadProductImage(id, image);
      final products = state.products
          .map(
            (item) => item.id == id ? item.copyWith(imageUrl: imageUrl) : item,
          )
          .toList();
      final selected = state.selected?.id == id
          ? state.selected!.copyWith(imageUrl: imageUrl)
          : state.selected;
      emit(state.copyWith(products: products, selected: selected));
      await refresh();
    } on ApiException catch (error) {
      emit(
        state.copyWith(status: ProductsStatus.failure, message: error.message),
      );
    }
  }

  Future<void> remove(String id) async {
    final previous = state.products;
    emit(
      state.copyWith(
        products: previous.where((item) => item.id != id).toList(),
      ),
    );
    try {
      await _deleteProduct(id);
      await refresh();
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          products: previous,
          status: ProductsStatus.failure,
          message: error.message,
        ),
      );
    }
  }
}
