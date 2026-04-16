import 'dart:io';

import '../entities/product.dart';

abstract class ProductRepository {
  Future<ProductPage> list({
    required int page,
    required int limit,
    String? search,
    String? category,
  });

  Future<Product> getById(String id);

  Future<String> create({
    required String name,
    required double price,
    required String currency,
    required String category,
  });

  Future<void> update({
    required String id,
    required String name,
    required double price,
    required String currency,
    required String category,
  });

  Future<void> delete(String id);

  Future<String> uploadImage(String id, File image);
}
