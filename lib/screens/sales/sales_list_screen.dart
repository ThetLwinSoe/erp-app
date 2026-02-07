import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/sales_provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../models/sale.dart';
import 'sale_detail_screen.dart';
import 'create_sale_screen.dart';

class SalesListScreen extends StatefulWidget {
  const SalesListScreen({super.key});

  @override
  State<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends State<SalesListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  bool _todayOnly = true;

  String get _todayDate => DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSales();
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<SalesProvider>().loadNextPage();
    }
  }

  void _loadSales() {
    context.read<SalesProvider>().fetchSales(
          search: _searchController.text.isEmpty ? null : _searchController.text,
          startDate: _todayOnly ? _todayDate : null,
          endDate: _todayOnly ? _todayDate : null,
          refresh: true,
        );
  }

  void _onSearch(String query) {
    _loadSales();
  }

  void _toggleTodayFilter() {
    setState(() {
      _todayOnly = !_todayOnly;
    });
    _loadSales();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: Consumer<SalesProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.sales.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.errorMessage != null && provider.sales.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
                        const SizedBox(height: 16),
                        Text(provider.errorMessage!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.refreshSales(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.sales.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long, size: 64, color: AppTheme.textSecondary),
                        const SizedBox(height: 16),
                        Text(
                          _todayOnly ? 'No sales for today' : 'No sales found',
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CreateSaleScreen()),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Create Sale'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.refreshSales(),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.sales.length + (provider.hasNextPage ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.sales.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return _buildSaleCard(provider.sales[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateSaleScreen()),
          );
          if (result == true) {
            context.read<SalesProvider>().refreshSales();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by order number...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearch('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: _onSearch,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: ActionChip(
              avatar: Icon(
                _todayOnly ? Icons.today : Icons.date_range,
                size: 18,
                color: _todayOnly ? Colors.white : AppTheme.primaryColor,
              ),
              label: Text(
                _todayOnly ? 'Today' : 'All Dates',
                style: TextStyle(
                  color: _todayOnly ? Colors.white : AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: _todayOnly ? AppTheme.primaryColor : Colors.grey[200],
              onPressed: _toggleTodayFilter,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleCard(Sale sale) {
    final statusColor = Color(AppConstants.statusColors[sale.status] ?? 0xFF9E9E9E);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SaleDetailScreen(saleId: sale.id)),
          );
          if (result == true) {
            context.read<SalesProvider>().refreshSales();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    sale.orderNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      sale.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      sale.customer?.name ?? 'Unknown Customer',
                      style: const TextStyle(color: AppTheme.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    sale.createdAt != null ? dateFormat.format(sale.createdAt!) : 'N/A',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${sale.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
