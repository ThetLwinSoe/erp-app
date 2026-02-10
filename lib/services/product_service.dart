import 'package:dio/dio.dart';
import '../models/product.dart';
import 'api_service.dart';

class ProductService {
  final ApiService _api = ApiService();

  Future<ApiResponse<PaginatedResponse<Product>>> getProducts({
    int page = 1,
    int limit = 10,
    String? search,
    String? category,
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
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      final response = await _api.get('/products', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final items = response.data['data'] as List;
        final products = items.map((json) => Product.fromJson(json)).toList();

        final pagination = response.data['pagination'];
        final paginatedResponse = PaginatedResponse<Product>(
          data: products,
          currentPage: pagination['page'] ?? page,
          totalPages: pagination['totalPages'] ?? 1,
          totalItems: pagination['total'] ?? products.length,
          itemsPerPage: pagination['limit'] ?? limit,
        );

        return ApiResponse.success(paginatedResponse);
      }

      return ApiResponse.error('Failed to fetch products');
    } on DioException catch (e) {
      return ApiResponse.error(_getErrorMessage(e));
    } catch (e) {
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  Future<ApiResponse<Product>> getProductById(int id) async {
    try {
      final response = await _api.get('/products/$id');

      if (response.statusCode == 200) {
        final product = Product.fromJson(response.data['data']);
        return ApiResponse.success(product);
      }

      return ApiResponse.error('Failed to fetch product details');
    } on DioException catch (e) {
      return ApiResponse.error(_getErrorMessage(e));
    } catch (e) {
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  Future<ApiResponse<List<Product>>> getLowStockProducts() async {
    try {
      final response = await _api.get('/inventory/low-stock');

      if (response.statusCode == 200) {
        final items = response.data['data'] as List;
        final products = items.map((json) => Product.fromJson(json['Product'])).toList();

        return ApiResponse.success(products);
      }

      return ApiResponse.error('Failed to fetch low stock products');
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
