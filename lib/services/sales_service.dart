import 'package:dio/dio.dart';
import '../models/sale.dart';
import 'api_service.dart';

class SalesService {
  final ApiService _api = ApiService();

  Future<ApiResponse<PaginatedResponse<Sale>>> getSales({
    int page = 1,
    int limit = 10,
    String? status,
    String? search,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (startDate != null) {
        queryParams['startDate'] = startDate;
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate;
      }

      final response = await _api.get('/sales', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final items = response.data['data'] as List;
        final sales = items.map((json) => Sale.fromJson(json)).toList();

        final pagination = response.data['pagination'];
        final paginatedResponse = PaginatedResponse<Sale>(
          data: sales,
          currentPage: pagination['page'] ?? page,
          totalPages: pagination['totalPages'] ?? 1,
          totalItems: pagination['total'] ?? sales.length,
          itemsPerPage: pagination['limit'] ?? limit,
        );

        return ApiResponse.success(paginatedResponse);
      }

      return ApiResponse.error('Failed to fetch sales');
    } on DioException catch (e) {
      return ApiResponse.error(_getErrorMessage(e));
    } catch (e) {
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  Future<ApiResponse<Sale>> getSaleById(int id) async {
    try {
      final response = await _api.get('/sales/$id');

      if (response.statusCode == 200) {
        final sale = Sale.fromJson(response.data['data']);
        return ApiResponse.success(sale);
      }

      return ApiResponse.error('Failed to fetch sale details');
    } on DioException catch (e) {
      return ApiResponse.error(_getErrorMessage(e));
    } catch (e) {
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  Future<ApiResponse<Sale>> createSale(CreateSaleRequest request) async {
    try {
      final response = await _api.post('/sales', data: request.toJson());

      if (response.statusCode == 201) {
        final sale = Sale.fromJson(response.data['data']);
        return ApiResponse.success(sale, message: 'Sale created successfully');
      }

      return ApiResponse.error('Failed to create sale');
    } on DioException catch (e) {
      return ApiResponse.error(_getErrorMessage(e));
    } catch (e) {
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  Future<ApiResponse<Sale>> updateSale(int id, CreateSaleRequest request) async {
    try {
      final response = await _api.put('/sales/$id', data: request.toJson());

      if (response.statusCode == 200) {
        final sale = Sale.fromJson(response.data['data']);
        return ApiResponse.success(sale, message: 'Sale updated successfully');
      }

      return ApiResponse.error('Failed to update sale');
    } on DioException catch (e) {
      return ApiResponse.error(_getErrorMessage(e));
    } catch (e) {
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  Future<ApiResponse<Sale>> updateSaleStatus(int id, String status) async {
    try {
      final response = await _api.patch('/sales/$id/status', data: {
        'status': status,
      });

      if (response.statusCode == 200) {
        final sale = Sale.fromJson(response.data['data']);
        return ApiResponse.success(sale, message: 'Status updated successfully');
      }

      return ApiResponse.error('Failed to update status');
    } on DioException catch (e) {
      return ApiResponse.error(_getErrorMessage(e));
    } catch (e) {
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  Future<ApiResponse<bool>> deleteSale(int id) async {
    try {
      final response = await _api.delete('/sales/$id');

      if (response.statusCode == 200) {
        return ApiResponse.success(true, message: 'Sale deleted successfully');
      }

      return ApiResponse.error('Failed to delete sale');
    } on DioException catch (e) {
      return ApiResponse.error(_getErrorMessage(e));
    } catch (e) {
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getSalesReport({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final response = await _api.get('/reports/sales', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final reportData = response.data['data'] as Map<String, dynamic>;
        return ApiResponse.success(reportData);
      }

      return ApiResponse.error('Failed to fetch sales report');
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
