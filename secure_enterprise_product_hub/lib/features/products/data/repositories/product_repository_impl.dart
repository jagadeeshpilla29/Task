import 'dart:io';

import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this._remoteDataSource);

  final ProductRemoteDataSource _remoteDataSource;

  @override
  Future<ProductPage> list({
    required int page,
    required int limit,
    String? search,
    String? category,
  }) async {
    return _remoteDataSource.list(
      page: page,
      limit: limit,
      search: search,
      category: category,
    );
  }

  @override
  Future<Product> getById(String id) async {
    return _remoteDataSource.getById(id);
  }

  @override
  Future<String> create({
    required String name,
    required double price,
    required String currency,
    required String category,
  }) async {
    return _remoteDataSource.create(
      name: name,
      price: price,
      currency: currency,
      category: category,
    );
  }

  @override
  Future<void> update({
    required String id,
    required String name,
    required double price,
    required String currency,
    required String category,
  }) async {
    await _remoteDataSource.update(
      id: id,
      name: name,
      price: price,
      currency: currency,
      category: category,
    );
  }

  @override
  Future<void> delete(String id) => _remoteDataSource.delete(id);

  @override
  Future<String> uploadImage(String id, File image) async {
    return _remoteDataSource.uploadImage(id, image);
  }
}
