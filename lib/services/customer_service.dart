import 'package:dio/dio.dart';
import '../models/customer.dart';
import 'api_service.dart';

class CustomerService {
  final ApiService _api = ApiService();

  Future<ApiResponse<PaginatedResponse<Customer>>> getCustomers({
    int page = 1,
    int limit = 10,
    String? search,
    String? type,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'status': 'active',
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (type != null && type.isNotEmpty) {
        queryParams['type'] = type;
      }

      final response = await _api.get('/customers', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final items = response.data['data'] as List;
        final customers = items.map((json) => Customer.fromJson(json)).toList();

        final pagination = response.data['pagination'];
        final paginatedResponse = PaginatedResponse<Customer>(
          data: customers,
          currentPage: pagination['page'] ?? page,
          totalPages: pagination['totalPages'] ?? 1,
          totalItems: pagination['total'] ?? customers.length,
          itemsPerPage: pagination['limit'] ?? limit,
        );

        return ApiResponse.success(paginatedResponse);
      }

      return ApiResponse.error('Failed to fetch customers');
    } on DioException catch (e) {
      return ApiResponse.error(_getErrorMessage(e));
    } catch (e) {
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  Future<ApiResponse<Customer>> getCustomerById(int id) async {
    try {
      final response = await _api.get('/customers/$id');

      if (response.statusCode == 200) {
        final customer = Customer.fromJson(response.data['data']);
        return ApiResponse.success(customer);
      }

      return ApiResponse.error('Failed to fetch customer details');
    } on DioException catch (e) {
      return ApiResponse.error(_getErrorMessage(e));
    } catch (e) {
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  Future<ApiResponse<Customer>> createCustomer(Customer customer) async {
    try {
      final response = await _api.post('/customers', data: customer.toJson());

      if (response.statusCode == 201) {
        final newCustomer = Customer.fromJson(response.data['data']);
        return ApiResponse.success(newCustomer, message: 'Customer created successfully');
      }

      return ApiResponse.error('Failed to create customer');
    } on DioException catch (e) {
      return ApiResponse.error(_getErrorMessage(e));
    } catch (e) {
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  Future<ApiResponse<Customer>> updateCustomer(int id, Customer customer) async {
    try {
      final response = await _api.put('/customers/$id', data: customer.toJson());

      if (response.statusCode == 200) {
        final updatedCustomer = Customer.fromJson(response.data['data']);
        return ApiResponse.success(updatedCustomer, message: 'Customer updated successfully');
      }

      return ApiResponse.error('Failed to update customer');
    } on DioException catch (e) {
      return ApiResponse.error(_getErrorMessage(e));
    } catch (e) {
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  Future<ApiResponse<bool>> deleteCustomer(int id) async {
    try {
      final response = await _api.delete('/customers/$id');

      if (response.statusCode == 200) {
        return ApiResponse.success(true, message: 'Customer deleted successfully');
      }

      return ApiResponse.error('Failed to delete customer');
    } on DioException catch (e) {
      return ApiResponse.error(_getErrorMessage(e));
    } catch (e) {
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  String _getErrorMessage(DioException e) {
    if (e.response?.data != null && e.response?.data is Map) {
      final data = e.response?.data as Map;
      if (data.containsKey('message')) {
        return data['message'];
      }
    }
    return 'An error occurred. Please try again.';
  }
}
