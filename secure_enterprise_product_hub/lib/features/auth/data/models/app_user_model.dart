import '../../domain/entities/app_user.dart';

class AppUserModel extends AppUser {
  const AppUserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
  });

  factory AppUserModel.fromJson(Map<String, dynamic> json) {
    return AppUserModel(
      id: json['id'].toString(),
      name: json['name'].toString(),
      email: json['email'].toString(),
      role: json['role'].toString(),
    );
  }
}
