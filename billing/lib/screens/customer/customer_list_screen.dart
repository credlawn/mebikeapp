import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/customer_provider.dart';
import '../../pb_service.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/app_snackbars.dart';
import '../customer/add_customer_screen.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    try {
      await ref.refresh(allCustomersProvider.future).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw 'Server timeout. Try again later.',
      );
      if (mounted) AppSnackBars.showSuccess(context, 'Data updated');
    } catch (e) {
      if (mounted) AppSnackBars.showError(context, e.toString());
    }
  }

  Future<void> _deleteCustomer(String id) async {
    try {
      await PbService().pb.collection('customer').delete(id);
      ref.invalidate(allCustomersProvider);
      if (mounted) AppSnackBars.showSuccess(context, 'Customer deleted');
    } catch (_) {
      if (mounted) AppSnackBars.showError(context, 'Delete failed');
    }
  }

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 28),
            ),
            const SizedBox(height: 20),
            Text('Delete Customer', style: AppTypography.h2),
            const SizedBox(height: 12),
            Text(
              'Delete "$name"? This cannot be undone.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textMuted,
                    side: BorderSide(color: AppColors.textMuted.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Cancel', style: AppTypography.button.copyWith(color: AppColors.textMuted)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _deleteCustomer(id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Delete', style: AppTypography.button.copyWith(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(allCustomersProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Customers'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Inactive'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddCustomerScreen())),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        child: const Icon(Icons.add_rounded),
      ),
      body: customersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Cannot reach server', style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
        ),
        data: (customers) {
          final active = customers.where((c) => c.status == 'active').toList();
          final inactive = customers.where((c) => c.status != 'active').toList();

          return IndexedStack(
            index: _tabController.index,
            children: [
              _buildTab(active),
              _buildTab(inactive),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTab(List customers) {
    if (customers.isEmpty) {
      return RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.primary,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 400,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline_rounded, size: 48, color: AppColors.textMuted.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text('No customers found', style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppColors.primary,
      backgroundColor: Colors.white,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: customers.length,
        itemBuilder: (_, i) {
          final c = customers[i];
          final displayName = c.customerName.isNotEmpty
              ? c.customerName
              : (c.businessName.isNotEmpty ? c.businessName : c.mobileNo);
          final subtitle = c.gstNo.isNotEmpty ? 'GST: ${c.gstNo}' : c.mobileNo;
          final typeLabel = c.customerType == 'normal'
              ? 'Normal'
              : (c.customerType == 'gst_individual' ? 'GST Ind' : 'GST Biz');
          final typeColor = c.customerType == 'normal'
              ? Colors.grey
              : (c.customerType == 'gst_individual' ? Colors.orange : AppColors.primary);

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.border),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {},
              onLongPress: () => _confirmDelete(c.id, displayName),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: AppTypography.bodyMedium.copyWith(
                            color: typeColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(displayName, style: AppTypography.h3.copyWith(fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(subtitle, style: AppTypography.bodySmall.copyWith(fontSize: 11)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(
                          color: typeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}