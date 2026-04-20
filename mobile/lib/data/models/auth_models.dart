import '../../domain/entities/user.dart';

class TokenResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;

  const TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) => TokenResponse(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        tokenType: json['token_type'] as String? ?? 'bearer',
        expiresIn: json['expires_in'] as int,
      );
}

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.username,
    super.email,
    required super.fullName,
    required super.isActive,
    required super.roles,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        username: json['username'] as String,
        email: json['email'] as String?,
        fullName: json['full_name'] as String,
        isActive: json['is_active'] as bool,
        roles: List<String>.from(json['roles'] as List),
      );
}
