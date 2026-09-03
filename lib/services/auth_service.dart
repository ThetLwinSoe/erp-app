import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/constants.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<ApiResponse<User>> login(String email, String password) async {
    try {
      final response = await _api.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final responseData = response.data['data'];
        final token = responseData['token'];
        final userData = responseData['user'];

        // Store token
        await _api.setToken(token);

        // Store user data
        await _storage.write(
          key: AppConstants.userKey,
          value: jsonEncode(userData),
        );

        final user = User.fromJson(userData);
        return ApiResponse.success(user, message: 'Login successful');
      }

      return ApiResponse.error('Login failed');
    } on DioException catch (e) {
      final message = _getErrorMessage(e);
      return ApiResponse.error(message, statusCode: e.response?.statusCode);
    } catch (e) {
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  Future<ApiResponse<User>> getCurrentUser() async {
    try {
      final response = await _api.get('/auth/me');

      if (response.statusCode == 200) {
        final user = User.fromJson(response.data['data']);
        return ApiResponse.success(user);
      }

      return ApiResponse.error('Failed to get user');
    } on DioException catch (e) {
      final message = _getErrorMessage(e);
      return ApiResponse.error(message, statusCode: e.response?.statusCode);
    } catch (e) {
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  Future<User?> getSavedUser() async {
    try {
      final userData = await _storage.read(key: AppConstants.userKey);
      if (userData != null) {
        return User.fromJson(jsonDecode(userData));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _api.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    await _api.clearToken();
    await _storage.delete(key: AppConstants.userKey);
  }

  String _getErrorMessage(DioException e) => mapDioErrorMessage(e, statusMessages: const {
        401: 'Invalid email or password',
        403: 'Access denied',
        404: 'Resource not found',
        500: 'Server error. Please try again later.',
      });
}
