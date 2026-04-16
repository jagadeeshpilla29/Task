import 'dart:io';

import '../../../../core/network/api_client.dart';
import '../models/product_model.dart';

class ProductRemoteDataSource {
  ProductRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<ProductPageModel> list({
    required int page,
    required int limit,
    String? search,
    String? category,
  }) async {
    final response = await _apiClient.get(
      '/api/products',
      query: {
        'page': page.toString(),
        'limit': limit.toString(),
        'search': search,
        'category': category,
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return ProductPageModel.fromJson(
      data,
      imageResolver: _apiClient.resolveMediaUrl,
    );
  }

  Future<ProductModel> getById(String id) async {
    final response = await _apiClient.get('/api/products/$id');
    return ProductModel.fromJson(
      response['data'] as Map<String, dynamic>,
      imageResolver: _apiClient.resolveMediaUrl,
    );
  }

  Future<String> create({
    required String name,
    required double price,
    required String currency,
    required String category,
  }) async {
    final response = await _apiClient.post(
      '/api/products',
      body: {
        'name': name.trim(),
        'price': price,
        'currency': currency,
        'category': category.trim(),
      },
    );
    final data = response['data'] as Map<String, dynamic>?;
    return data?['id']?.toString() ?? '';
  }

  Future<void> update({
    required String id,
    required String name,
    required double price,
    required String currency,
    required String category,
  }) {
    return _apiClient.put(
      '/api/products/$id',
      body: {
        'name': name.trim(),
        'price': price,
        'currency': currency,
        'category': category.trim(),
      },
    );
  }

  Future<void> delete(String id) => _apiClient.delete('/api/products/$id');

  Future<String> uploadImage(String id, File image) async {
    final response = await _apiClient.uploadImage(
      '/api/products/$id/image',
      image,
    );
    return _apiClient.resolveMediaUrl(response['imageUrl']?.toString());
  }
}
