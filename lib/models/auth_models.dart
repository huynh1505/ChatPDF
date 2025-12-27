class LoginDto {
  final String email;
  final String password;

  LoginDto({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class RegisterDto {
  final String fullName;
  final String email;
  final String password;
  final String confirmPassword;

  RegisterDto({
    required this.fullName,
    required this.email,
    required this.password,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'password': password,
      'confirmPassword': confirmPassword,
    };
  }
}

class AuthResponseDto {
  final String? token;
  final String? message;
  final bool success;
  final String? fullName;
  final String? email;
  final String? role;
  final int? userId;

  AuthResponseDto({
    this.token,
    this.message,
    required this.success,
    this.fullName,
    this.email,
    this.role,
    this.userId,
  });

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    var data = json['data'];
    return AuthResponseDto(
      success: json['success'] ?? false,
      message: json['message'],
      token: data != null ? data['token'] : null,
      fullName: data != null ? data['fullName'] : null,
      email: data != null ? data['email'] : null,
      role: data != null ? data['role'] : null,
      userId: data != null ? data['userId'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': {
        'token': token,
        'fullName': fullName,
        'email': email,
        'role': role,
        'userId': userId,
      }
    };
  }
}
