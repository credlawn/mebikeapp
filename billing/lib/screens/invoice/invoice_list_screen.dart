import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/invoice_provider.dart';
import '../../pb_service.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/app_snackbars.dart';
import '../billing/invoice_type_screen.dart';
import 'invoice_detail_screen.dart';

class InvoiceListScreen extends ConsumerStatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      await ref.refresh(allInvoicesProvider.future).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw 'Server timeout. Try again later.',
      );
      if (mounted) AppSnackBars.showSuccess(context, 'Data updated');
    } catch (e) {
      if (mounted) AppSnackBars.showError(context, e.toString());
    }
  }

  Future<void> _deleteInvoice(String id, String no) async {
    try {
      await PbService().pb.collection('invoice').delete(id);
      ref.invalidate(allInvoicesProvider);
      if (mounted) AppSnackBars.showSuccess(context, 'Invoice $no deleted');
    } catch (_) {
      if (mounted) AppSnackBars.showError(context, 'Delete failed');
    }
  }

  void _confirmDelete(String id, String invoiceNo) {
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
            Text('Delete Invoice', style: AppTypography.h2),
            const SizedBox(height: 12),
            Text(
              'Delete "$invoiceNo"? This cannot be undone.',
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
                    _deleteInvoice(id, invoiceNo);
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
    final invoicesAsync = ref.watch(allInvoicesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Invoices'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Unpaid'),
            Tab(text: 'Paid'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoiceTypeScreen())),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        child: const Icon(Icons.add_rounded),
      ),
      body: invoicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Cannot reach server', style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
        ),
        data: (invoices) {
          final all = invoices;
          final unpaid = invoices.where((i) => i.paymentStatus == 'unpaid' || i.paymentStatus == 'partial').toList();
          final paid = invoices.where((i) => i.paymentStatus == 'paid').toList();

          return IndexedStack(
            index: _tabController.index,
            children: [
              _buildTab(all),
              _buildTab(unpaid),
              _buildTab(paid),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTab(List invoices) {
    if (invoices.isEmpty) {
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
                  Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textMuted.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text('No invoices found', style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
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
        itemCount: invoices.length,
        itemBuilder: (_, i) {
          final inv = invoices[i];
          final dateStr = '${inv.invoiceDate.day}/${inv.invoiceDate.month}/${inv.invoiceDate.year}';

          Color statusColor;
          String statusLabel;
          switch (inv.status) {
            case 'confirmed':
              statusColor = AppColors.success;
              statusLabel = 'Confirmed';
              break;
            default:
              statusColor = Colors.orange;
              statusLabel = 'Draft';
          }

          final typeColor = inv.invoiceType == 'partner' ? AppColors.primary : const Color(0xFF0D9488);
          final typeLabel = inv.invoiceType == 'partner' ? 'Partner' : 'Customer';

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.border),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoice: inv)),
              ),
              onLongPress: () => _confirmDelete(inv.id, inv.invoiceNo.isNotEmpty ? inv.invoiceNo : 'Draft'),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                              inv.invoiceNo.isNotEmpty
                                  ? (inv.invoiceNo.length > 6
                                      ? inv.invoiceNo.substring(inv.invoiceNo.length - 4)
                                      : inv.invoiceNo)
                                  : 'DR',
                              style: AppTypography.bodyMedium.copyWith(
                                color: typeColor,
                                fontWeight: FontWeight.bold,
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
                              Text(
                                inv.invoiceNo.isNotEmpty ? inv.invoiceNo : 'Draft',
                                style: AppTypography.h3.copyWith(fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(
                                inv.partyName.isNotEmpty ? inv.partyName : inv.partyMobile,
                                style: AppTypography.bodySmall.copyWith(fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 11, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(dateStr, style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(typeLabel, style: TextStyle(color: typeColor, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                        const Spacer(),
                        Text(
                          '\u20B9 ${inv.grandTotal.toStringAsFixed(2)}',
                          style: AppTypography.h3.copyWith(fontSize: 14, color: AppColors.textPrimary),
                        ),
                      ],
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
