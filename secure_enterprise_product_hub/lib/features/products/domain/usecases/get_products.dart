import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetProducts {
  GetProducts(this._repository);

  final ProductRepository _repository;

  Future<ProductPage> call({
    required int page,
    required int limit,
    String? search,
    String? category,
  }) {
    return _repository.list(
      page: page,
      limit: limit,
      search: search,
      category: category,
    );
  }
}
