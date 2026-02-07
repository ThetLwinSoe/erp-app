import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();

  List<Product> _products = [];
  Product? _selectedProduct;
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  String? _searchQuery;
  String? _categoryFilter;

  List<Product> get products => _products;
  Product? get selectedProduct => _selectedProduct;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;
  bool get hasNextPage => _currentPage < _totalPages;

  Future<void> fetchProducts({
    int page = 1,
    String? search,
    String? category,
    bool refresh = false,
  }) async {
    if (refresh) {
      _products = [];
      _currentPage = 1;
    }

    _isLoading = true;
    _errorMessage = null;
    _searchQuery = search;
    _categoryFilter = category;
    notifyListeners();

    final result = await _productService.getProducts(
      page: page,
      search: search,
      category: category,
    );

    if (result.success && result.data != null) {
      if (refresh || page == 1) {
        _products = result.data!.data;
      } else {
        _products.addAll(result.data!.data);
      }
      _currentPage = result.data!.currentPage;
      _totalPages = result.data!.totalPages;
      _totalItems = result.data!.totalItems;
    } else {
      _errorMessage = result.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadNextPage() async {
    if (!hasNextPage || _isLoading) return;
    await fetchProducts(
      page: _currentPage + 1,
      search: _searchQuery,
      category: _categoryFilter,
    );
  }

  Future<void> refreshProducts() async {
    await fetchProducts(
      page: 1,
      search: _searchQuery,
      category: _categoryFilter,
      refresh: true,
    );
  }

  Future<bool> fetchProductById(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _productService.getProductById(id);

    _isLoading = false;
    if (result.success && result.data != null) {
      _selectedProduct = result.data;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.message;
      notifyListeners();
      return false;
    }
  }

  void selectProduct(Product product) {
    _selectedProduct = product;
    notifyListeners();
  }

  void clearSelectedProduct() {
    _selectedProduct = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
