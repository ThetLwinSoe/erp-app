import 'package:flutter/material.dart';
import '../models/sale.dart';
import '../services/sales_service.dart';

class SalesProvider with ChangeNotifier {
  final SalesService _salesService = SalesService();

  List<Sale> _sales = [];
  Sale? _selectedSale;
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  String? _statusFilter;
  String? _searchQuery;
  String? _startDate;
  String? _endDate;

  List<Sale> get sales => _sales;
  Sale? get selectedSale => _selectedSale;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;
  bool get hasNextPage => _currentPage < _totalPages;
  bool get hasPreviousPage => _currentPage > 1;

  Future<void> fetchSales({
    int page = 1,
    String? status,
    String? search,
    String? startDate,
    String? endDate,
    bool refresh = false,
  }) async {
    if (refresh) {
      _sales = [];
      _currentPage = 1;
    }

    _isLoading = true;
    _errorMessage = null;
    _statusFilter = status;
    _searchQuery = search;
    _startDate = startDate;
    _endDate = endDate;
    notifyListeners();

    final result = await _salesService.getSales(
      page: page,
      status: status,
      search: search,
      startDate: startDate,
      endDate: endDate,
    );

    if (result.success && result.data != null) {
      if (refresh || page == 1) {
        _sales = result.data!.data;
      } else {
        _sales.addAll(result.data!.data);
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
    await fetchSales(
      page: _currentPage + 1,
      status: _statusFilter,
      search: _searchQuery,
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  Future<void> refreshSales() async {
    await fetchSales(
      page: 1,
      status: _statusFilter,
      search: _searchQuery,
      startDate: _startDate,
      endDate: _endDate,
      refresh: true,
    );
  }

  Future<bool> fetchSaleById(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _salesService.getSaleById(id);

    _isLoading = false;
    if (result.success && result.data != null) {
      _selectedSale = result.data;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.message;
      notifyListeners();
      return false;
    }
  }

  Future<Sale?> createSale(CreateSaleRequest request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _salesService.createSale(request);

    _isLoading = false;
    if (result.success && result.data != null) {
      _sales.insert(0, result.data!);
      notifyListeners();
      return result.data;
    } else {
      _errorMessage = result.message;
      notifyListeners();
      return null;
    }
  }

  Future<Sale?> updateSale(int id, CreateSaleRequest request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _salesService.updateSale(id, request);

    _isLoading = false;
    if (result.success && result.data != null) {
      final index = _sales.indexWhere((s) => s.id == id);
      if (index != -1) {
        _sales[index] = result.data!;
      }
      _selectedSale = result.data;
      notifyListeners();
      return result.data;
    } else {
      _errorMessage = result.message;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateSaleStatus(int id, String status) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _salesService.updateSaleStatus(id, status);

    _isLoading = false;
    if (result.success && result.data != null) {
      final index = _sales.indexWhere((s) => s.id == id);
      if (index != -1) {
        _sales[index] = result.data!;
      }
      _selectedSale = result.data;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSale(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _salesService.deleteSale(id);

    _isLoading = false;
    if (result.success) {
      _sales.removeWhere((s) => s.id == id);
      if (_selectedSale?.id == id) {
        _selectedSale = null;
      }
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.message;
      notifyListeners();
      return false;
    }
  }

  void clearSelectedSale() {
    _selectedSale = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
