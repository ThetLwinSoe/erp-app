import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/product_provider.dart';
import '../../config/theme.dart';
import '../../models/customer.dart';
import '../../models/product.dart';
import '../../models/sale.dart';

class CreateSaleScreen extends StatefulWidget {
  const CreateSaleScreen({super.key});

  @override
  State<CreateSaleScreen> createState() => _CreateSaleScreenState();
}

class _CreateSaleScreenState extends State<CreateSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _taxController = TextEditingController(text: '0');
  final _orderDiscountController = TextEditingController(text: '0');

  Customer? _selectedCustomer;
  final List<_CartItem> _cartItems = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().fetchCustomers(refresh: true);
      context.read<ProductProvider>().fetchProducts(refresh: true);
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _taxController.dispose();
    _orderDiscountController.dispose();
    super.dispose();
  }

  double get _subtotal => _cartItems.fold(0, (sum, item) => sum + item.total);
  double get _orderDiscountPercent => double.tryParse(_orderDiscountController.text) ?? 0;
  double get _orderDiscountAmount => _subtotal * (_orderDiscountPercent / 100);
  double get _tax => double.tryParse(_taxController.text) ?? 0;
  double get _total => _subtotal - _orderDiscountAmount + _tax;

  void _selectCustomer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CustomerSelector(
        onSelect: (customer) {
          setState(() {
            _selectedCustomer = customer;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _addProduct() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ProductSelector(
        onSelect: (product) {
          Navigator.pop(context);
          _showQuantityDialog(product);
        },
      ),
    );
  }

  void _showQuantityDialog(Product product) {
    final quantityController = TextEditingController(text: '1');
    final focQuantityController = TextEditingController(text: '0');
    final discountController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add to Cart'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Price: ${product.sellingPrice.toStringAsFixed(2)}',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            if (product.inventory != null)
              Text(
                'In Stock: ${product.stockQuantity}',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: focQuantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'FOC Qty (free of charge)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: discountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Discount %',
                suffixText: '%',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = int.tryParse(quantityController.text) ?? 0;
              final focQuantity = int.tryParse(focQuantityController.text) ?? 0;
              final discount = double.tryParse(discountController.text) ?? 0;
              if (quantity + focQuantity > 0) {
                setState(() {
                  final existingIndex = _cartItems.indexWhere((item) => item.product.id == product.id);
                  if (existingIndex != -1) {
                    _cartItems[existingIndex].quantity += quantity;
                    _cartItems[existingIndex].focQuantity += focQuantity;
                    _cartItems[existingIndex].discountPercent = discount;
                  } else {
                    _cartItems.add(_CartItem(
                      product: product,
                      quantity: quantity,
                      focQuantity: focQuantity,
                      unitPrice: product.sellingPrice,
                      discountPercent: discount,
                    ));
                  }
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a quantity or FOC quantity of at least 1')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _removeCartItem(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
  }

  void _updateCartItemQuantity(int index, int quantity) {
    if (quantity <= 0) {
      _removeCartItem(index);
    } else {
      setState(() {
        _cartItems[index].quantity = quantity;
      });
    }
  }

  Future<void> _submitSale() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer')),
      );
      return;
    }

    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final request = CreateSaleRequest(
      customerId: _selectedCustomer!.id,
      tax: _tax,
      discountPercent: _orderDiscountPercent,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      items: _cartItems
          .map((item) => CreateSaleItemRequest(
                productId: item.product.id,
                quantity: item.quantity,
                focQuantity: item.focQuantity,
                unitPrice: item.unitPrice,
                discountPercent: item.discountPercent,
              ))
          .toList(),
    );

    final sale = await context.read<SalesProvider>().createSale(request);

    setState(() {
      _isSubmitting = false;
    });

    if (sale != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sale ${sale.orderNumber} created successfully')),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      final error = context.read<SalesProvider>().errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Failed to create sale')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Sale'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Selection
                    _buildSectionTitle('Customer'),
                    _buildCustomerSelector(),
                    const SizedBox(height: 24),

                    // Products
                    _buildSectionTitle('Products'),
                    _buildProductsList(),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _addProduct,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Product'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Order Discount
                    _buildSectionTitle('Order Discount %'),
                    TextField(
                      controller: _orderDiscountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        suffixText: '%',
                        hintText: '0',
                        helperText: 'Applied after item discounts',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 24),

                    // Tax
                    _buildSectionTitle('Tax'),
                    TextField(
                      controller: _taxController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        hintText: '0.00',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 24),

                    // Notes
                    _buildSectionTitle('Notes (Optional)'),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Add any notes for this sale...',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Summary and Submit
            _buildBottomSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildCustomerSelector() {
    return InkWell(
      onTap: _selectCustomer,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_outline, color: AppTheme.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: _selectedCustomer != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedCustomer!.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (_selectedCustomer!.phone != null)
                          Text(
                            _selectedCustomer!.phone!,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    )
                  : const Text(
                      'Select a customer',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsList() {
    if (_cartItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'No products added',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    return Column(
      children: _cartItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${item.unitPrice.toStringAsFixed(2)} x ${item.quantity}'
                            '${item.focQuantity > 0 ? '  +${item.focQuantity} FOC' : ''}'
                            '${item.discountPercent > 0 ? '  (-${item.discountPercent.toStringAsFixed(1)}%)' : ''}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => _updateCartItemQuantity(index, item.quantity - 1),
                          iconSize: 20,
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            '${item.quantity}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => _updateCartItemQuantity(index, item.quantity + 1),
                          iconSize: 20,
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${item.total.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                      onPressed: () => _removeCartItem(index),
                      iconSize: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal'),
                Text('${_subtotal.toStringAsFixed(2)}'),
              ],
            ),
            if (_orderDiscountPercent > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Discount (${_orderDiscountPercent.toStringAsFixed(1)}%)'),
                  Text(
                    '-${_orderDiscountAmount.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppTheme.errorColor),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tax'),
                Text('${_tax.toStringAsFixed(2)}'),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitSale,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Create Sale',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItem {
  final Product product;
  int quantity;
  int focQuantity;
  final double unitPrice;
  double discountPercent;

  _CartItem({
    required this.product,
    required this.quantity,
    this.focQuantity = 0,
    required this.unitPrice,
    this.discountPercent = 0,
  });

  // FOC quantity is free - it never enters pricing, only stock movement.
  double get subtotal => quantity * unitPrice;
  double get discountAmount => subtotal * (discountPercent / 100);
  double get total => subtotal - discountAmount;
}

class _CustomerSelector extends StatefulWidget {
  final Function(Customer) onSelect;

  const _CustomerSelector({required this.onSelect});

  @override
  State<_CustomerSelector> createState() => _CustomerSelectorState();
}

class _CustomerSelectorState extends State<_CustomerSelector> {
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Customer',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search customers...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppTheme.backgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  context.read<CustomerProvider>().fetchCustomers(
                        search: value.isEmpty ? null : value,
                        refresh: true,
                      );
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Consumer<CustomerProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading && provider.customers.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (provider.customers.isEmpty) {
                      return const Center(
                        child: Text('No customers found'),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: provider.customers.length,
                      itemBuilder: (context, index) {
                        final customer = provider.customers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                            child: Text(
                              customer.name[0].toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(customer.name),
                          subtitle: Text(customer.phone ?? customer.email ?? ''),
                          onTap: () => widget.onSelect(customer),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProductSelector extends StatefulWidget {
  final Function(Product) onSelect;

  const _ProductSelector({required this.onSelect});

  @override
  State<_ProductSelector> createState() => _ProductSelectorState();
}

class _ProductSelectorState extends State<_ProductSelector> {
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Product',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppTheme.backgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  context.read<ProductProvider>().fetchProducts(
                        search: value.isEmpty ? null : value,
                        refresh: true,
                      );
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Consumer<ProductProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading && provider.products.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (provider.products.isEmpty) {
                      return const Center(
                        child: Text('No products found'),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: provider.products.length,
                      itemBuilder: (context, index) {
                        final product = provider.products[index];
                        return ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.inventory_2,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          title: Text('${product.name} | ${product.sku}'),
                          subtitle: Text(
                            '${product.sellingPrice.toStringAsFixed(2)} • Stock: ${product.stockQuantity}',
                          ),
                          trailing: product.isInStock
                              ? const Icon(Icons.check_circle, color: AppTheme.successColor)
                              : const Icon(Icons.warning, color: AppTheme.warningColor),
                          onTap: () => widget.onSelect(product),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
