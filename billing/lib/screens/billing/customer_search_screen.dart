import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/customer_model.dart';
import '../../providers/customer_provider.dart';
import '../../theme/colors.dart';
import '../customer/add_customer_screen.dart';
import 'billing_screen.dart';

class CustomerSearchScreen extends ConsumerStatefulWidget {
  final String mode;
  const CustomerSearchScreen({super.key, this.mode = 'invoice'});

  @override
  ConsumerState<CustomerSearchScreen> createState() => _CustomerSearchScreenState();
}

class _CustomerSearchScreenState extends ConsumerState<CustomerSearchScreen> {
  final _searchCtrl = TextEditingController();
  List<Customer> _allCustomers = [];
  List<Customer> _filtered = [];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = [];
      } else {
        _filtered = _allCustomers.where((c) =>
          c.customerName.toLowerCase().contains(q) ||
          c.businessName.toLowerCase().contains(q) ||
          c.mobileNo.contains(q)
        ).toList();
      }
    });
  }

  void _selectCustomer(Customer c) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => BillingScreen(
          mode: widget.mode,
          invoiceType: 'customer',
          customer: c,
        ),
      ),
    );
  }

  Widget _buildCustomerCard(Customer c, int index) {
    final name = c.customerName.isNotEmpty ? c.customerName : c.businessName;
    final addressParts = c.gstNo.isNotEmpty
        ? c.address
        : [c.address, c.city, c.district, c.state]
            .where((e) => e.isNotEmpty).join(', ') + (c.pincode.isNotEmpty ? ' - ${c.pincode}' : '');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => _selectCustomer(c),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: const Color(0xFF0D9488),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (c.gstNo.isEmpty ? Colors.grey : const Color(0xFF0D9488)).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            c.gstNo.isEmpty ? 'Non GST' : 'GST',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: c.gstNo.isEmpty ? Colors.grey : const Color(0xFF0D9488),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (addressParts.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        addressParts,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(allCustomersProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Select Customer'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
              decoration: InputDecoration(
                hintText: 'Search by name or mobile...',
                hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.5)),
                prefixIcon: Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted.withValues(alpha: 0.5)),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              ),
            ),
          ),
          Expanded(
            child: customersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const SizedBox(),
              data: (customers) {
                _allCustomers = customers;
                if (_searchCtrl.text.isEmpty) {
                  final recent = List<Customer>.from(_allCustomers)
                    ..sort((a, b) => b.updated.compareTo(a.updated));
                  final display = recent.take(10).toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                        child: Text(
                          'Recent customers',
                          style: TextStyle(
                          fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted.withValues(alpha: 0.8),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 4, bottom: 16),
                          itemCount: display.length + 1,
                          itemBuilder: (_, i) {
                            if (i == display.length) {
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D9488).withValues(alpha: 0.04),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.2)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.person_add_rounded, size: 16, color: const Color(0xFF0D9488)),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Add New Customer',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF0D9488),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }
                            return _buildCustomerCard(display[i], i);
                          },
                        ),
                      ),
                    ],
                  );
                }
                if (_filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('No customers found', style: TextStyle(color: AppColors.textMuted)),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
                            );
                          },
                          icon: const Icon(Icons.person_add_rounded, size: 18),
                          label: const Text('Add New Customer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D9488),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) => _buildCustomerCard(_filtered[i], i),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
