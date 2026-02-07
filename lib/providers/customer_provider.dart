import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';

class CustomerProvider with ChangeNotifier {
  final CustomerService _customerService = CustomerService();

  List<Customer> _customers = [];
  Customer? _selectedCustomer;
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  String? _searchQuery;

  List<Customer> get customers => _customers;
  Customer? get selectedCustomer => _selectedCustomer;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;
  bool get hasNextPage => _currentPage < _totalPages;

  Future<void> fetchCustomers({
    int page = 1,
    String? search,
    bool refresh = false,
  }) async {
    if (refresh) {
      _customers = [];
      _currentPage = 1;
    }

    _isLoading = true;
    _errorMessage = null;
    _searchQuery = search;
    notifyListeners();

    final result = await _customerService.getCustomers(
      page: page,
      search: search,
      type: 'customer',
    );

    if (result.success && result.data != null) {
      if (refresh || page == 1) {
        _customers = result.data!.data;
      } else {
        _customers.addAll(result.data!.data);
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
    await fetchCustomers(
      page: _currentPage + 1,
      search: _searchQuery,
    );
  }

  Future<void> refreshCustomers() async {
    await fetchCustomers(
      page: 1,
      search: _searchQuery,
      refresh: true,
    );
  }

  Future<bool> fetchCustomerById(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _customerService.getCustomerById(id);

    _isLoading = false;
    if (result.success && result.data != null) {
      _selectedCustomer = result.data;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.message;
      notifyListeners();
      return false;
    }
  }

  Future<Customer?> createCustomer(Customer customer) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _customerService.createCustomer(customer);

    _isLoading = false;
    if (result.success && result.data != null) {
      _customers.insert(0, result.data!);
      notifyListeners();
      return result.data;
    } else {
      _errorMessage = result.message;
      notifyListeners();
      return null;
    }
  }

  Future<Customer?> updateCustomer(int id, Customer customer) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _customerService.updateCustomer(id, customer);

    _isLoading = false;
    if (result.success && result.data != null) {
      final index = _customers.indexWhere((c) => c.id == id);
      if (index != -1) {
        _customers[index] = result.data!;
      }
      _selectedCustomer = result.data;
      notifyListeners();
      return result.data;
    } else {
      _errorMessage = result.message;
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteCustomer(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _customerService.deleteCustomer(id);

    _isLoading = false;
    if (result.success) {
      _customers.removeWhere((c) => c.id == id);
      if (_selectedCustomer?.id == id) {
        _selectedCustomer = null;
      }
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.message;
      notifyListeners();
      return false;
    }
  }

  void selectCustomer(Customer customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void clearSelectedCustomer() {
    _selectedCustomer = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
