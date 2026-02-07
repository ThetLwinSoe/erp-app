import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/sales_provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../models/sale.dart';

class SaleDetailScreen extends StatefulWidget {
  final int saleId;

  const SaleDetailScreen({super.key, required this.saleId});

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesProvider>().fetchSaleById(widget.saleId);
    });
  }

  void _showStatusUpdateDialog(Sale sale) {
    final currentIndex = AppConstants.saleStatuses.indexOf(sale.status);
    final availableStatuses = <String>[];

    // Determine available status transitions
    if (sale.status == 'pending') {
      availableStatuses.addAll(['confirmed', 'cancelled']);
    } else if (sale.status == 'confirmed') {
      availableStatuses.addAll(['shipped', 'cancelled']);
    } else if (sale.status == 'shipped') {
      availableStatuses.add('delivered');
    }

    if (availableStatuses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No status changes available')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: availableStatuses.map((status) {
            final color = Color(AppConstants.statusColors[status] ?? 0xFF9E9E9E);
            return ListTile(
              leading: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(status[0].toUpperCase() + status.substring(1)),
              onTap: () async {
                Navigator.pop(context);
                final provider = context.read<SalesProvider>();
                final success = await provider.updateSaleStatus(widget.saleId, status);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Status updated successfully')),
                  );
                } else if (mounted && provider.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(provider.errorMessage!)),
                  );
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Sale sale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Sale'),
        content: Text('Are you sure you want to delete order ${sale.orderNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = context.read<SalesProvider>();
              final success = await provider.deleteSale(widget.saleId);
              if (success && mounted) {
                Navigator.pop(context, true);
              } else if (mounted && provider.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(provider.errorMessage!)),
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sale Details'),
        actions: [
          Consumer<SalesProvider>(
            builder: (context, provider, _) {
              final sale = provider.selectedSale;
              if (sale == null) return const SizedBox.shrink();

              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'status') {
                    _showStatusUpdateDialog(sale);
                  } else if (value == 'delete' && sale.canCancel) {
                    _showDeleteConfirmation(sale);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'status',
                    child: Row(
                      children: [
                        Icon(Icons.update),
                        SizedBox(width: 8),
                        Text('Update Status'),
                      ],
                    ),
                  ),
                  if (sale.canCancel)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: AppTheme.errorColor),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<SalesProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final sale = provider.selectedSale;
          if (sale == null) {
            return const Center(child: Text('Sale not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrderHeader(sale),
                const SizedBox(height: 20),
                _buildCustomerInfo(sale),
                const SizedBox(height: 20),
                _buildItemsList(sale),
                const SizedBox(height: 20),
                _buildOrderSummary(sale),
                if (sale.notes != null && sale.notes!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildNotes(sale),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderHeader(Sale sale) {
    final statusColor = Color(AppConstants.statusColors[sale.status] ?? 0xFF9E9E9E);
    final dateFormat = DateFormat('MMMM d, yyyy • h:mm a');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sale.orderNumber,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  sale.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            sale.createdAt != null ? dateFormat.format(sale.createdAt!) : 'N/A',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo(Sale sale) {
    final customer = sale.customer;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(),
          if (customer != null) ...[
            _buildInfoRow(Icons.person_outline, customer.name),
            if (customer.email != null)
              _buildInfoRow(Icons.email_outlined, customer.email!),
            if (customer.phone != null)
              _buildInfoRow(Icons.phone_outlined, customer.phone!),
            if (customer.fullAddress.isNotEmpty)
              _buildInfoRow(Icons.location_on_outlined, customer.fullAddress),
          ] else
            const Text(
              'Customer information not available',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(Sale sale) {
    final items = sale.items ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Items (${items.length})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(),
          if (items.isEmpty)
            const Text(
              'No items',
              style: TextStyle(color: AppTheme.textSecondary),
            )
          else
            ...items.map((item) => _buildItemRow(item)),
        ],
      ),
    );
  }

  Widget _buildItemRow(SaleItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product?.name ?? 'Product #${item.productId}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${item.quantity} x ${item.unitPrice.toStringAsFixed(2)}'
                  '${item.discountPercent > 0 ? '  (-${item.discountPercent.toStringAsFixed(1)}%)' : ''}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${item.total.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(Sale sale) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', '${sale.subtotal.toStringAsFixed(2)}'),
          if (sale.discountPercent > 0) ...[
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Discount (${sale.discountPercent.toStringAsFixed(1)}%)',
              '-${sale.discountAmount.toStringAsFixed(2)}',
              isDiscount: true,
            ),
          ],
          const SizedBox(height: 8),
          _buildSummaryRow('Tax', '${sale.tax.toStringAsFixed(2)}'),
          const Divider(height: 24),
          _buildSummaryRow(
            'Total',
            '${sale.total.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 20 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isDiscount ? AppTheme.errorColor : (isTotal ? AppTheme.primaryColor : AppTheme.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildNotes(Sale sale) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            sale.notes!,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
