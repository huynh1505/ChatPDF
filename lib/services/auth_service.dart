import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_models.dart';

class AuthService {
   // Use localhost for Web/Windows
   // docker exposes port 8080
   static const String baseUrl = 'http://localhost:8080/api/Auth';
   // static const String baseUrl = 'http://localhost:8080/api/Auth';

  Future<AuthResponseDto> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(LoginDto(email: email, password: password).toJson()),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        final authResponse = AuthResponseDto.fromJson(responseData);
        if (authResponse.success) {
          await _saveUser(authResponse);
        }
        return authResponse;
      } else {
        return AuthResponseDto(
          success: false, 
          message: responseData['message'] ?? 'Login failed'
        );
      }
    } catch (e) {
      return AuthResponseDto(success: false, message: e.toString());
    }
  }

  Future<AuthResponseDto> register(String fullName, String email, String password, String confirmPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(RegisterDto(
          fullName: fullName,
          email: email,
          password: password,
          confirmPassword: confirmPassword,
        ).toJson()),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Automatically save user if backend returns token on register
        final authResponse = AuthResponseDto.fromJson(responseData);
         if (authResponse.success) {
          await _saveUser(authResponse);
        }
        return authResponse;
      } else {
        return AuthResponseDto(
          success: false, 
          message: responseData['message'] ?? 'Registration failed'
        );
      }
    } catch (e) {
      return AuthResponseDto(success: false, message: e.toString());
    }
  }

  Future<void> _saveUser(AuthResponseDto user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_user', jsonEncode(user.toJson()));
    if (user.token != null) {
      await prefs.setString('auth_token', user.token!);
    }
  }

  Future<AuthResponseDto?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userJson = prefs.getString('auth_user');
    if (userJson != null) {
      return AuthResponseDto.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
  }
}
