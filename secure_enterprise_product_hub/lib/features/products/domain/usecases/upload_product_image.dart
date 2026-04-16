import 'dart:io';

import '../repositories/product_repository.dart';

class UploadProductImage {
  UploadProductImage(this._repository);

  final ProductRepository _repository;

  Future<String> call(String id, File image) {
    return _repository.uploadImage(id, image);
  }
}
