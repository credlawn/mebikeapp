import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/invoice_model.dart';
import '../../providers/invoice_provider.dart';
import '../../pb_service.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/app_snackbars.dart';
import '../billing/invoice_type_screen.dart';
import 'invoice_detail_screen.dart';

class InvoiceListScreen extends ConsumerStatefulWidget {
  final String mode;
  const InvoiceListScreen({super.key, this.mode = 'invoice'});

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool get _isQuotation => widget.mode == 'quotation';

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
      await ref.refresh(allInvoicesProvider(widget.mode).future).timeout(
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
      ref.invalidate(allInvoicesProvider(widget.mode));
      if (mounted) AppSnackBars.showSuccess(context, '${_isQuotation ? "Quotation" : "Invoice"} $no deleted');
    } catch (_) {
      if (mounted) AppSnackBars.showError(context, 'Delete failed');
    }
  }

  Future<void> _cancelInvoice(Invoice inv) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.cancel_outlined, color: Colors.orange, size: 28),
            ),
            const SizedBox(height: 20),
            Text(_isQuotation ? "Cancel Quotation" : "Cancel Invoice", style: AppTypography.h2.copyWith(fontSize: 18)),
            const SizedBox(height: 12),
            Text(
              'Cancel "${inv.invoiceNo.isNotEmpty ? inv.invoiceNo : 'Draft'}"?',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textMuted,
                    side: BorderSide(color: AppColors.textMuted.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('No', style: AppTypography.button.copyWith(color: AppColors.textMuted)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange, foregroundColor: Colors.white, elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(_isQuotation ? 'Cancel Quotation' : 'Cancel Invoice', style: AppTypography.button.copyWith(color: Colors.white)),
                ),
              ),
              ],
            ),
          ],
        ),
      );
    if (confirmed != true) return;
    try {
      await PbService().pb.collection('invoice').update(inv.id, body: {'status': 'cancelled'});
      ref.invalidate(allInvoicesProvider(widget.mode));
      if (mounted) AppSnackBars.showSuccess(context, _isQuotation ? 'Quotation cancelled' : 'Invoice cancelled');
    } catch (_) {
      if (mounted) AppSnackBars.showError(context, 'Failed to cancel');
    }
  }

  void _confirmDelete(String id, String invoiceNo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 28),
            ),
            const SizedBox(height: 20),
            Text('Delete ${_isQuotation ? "Quotation" : "Invoice"}', style: AppTypography.h2),
            const SizedBox(height: 12),
            Text(
              'Delete "$invoiceNo"? This cannot be undone.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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

  void _showInvoiceActions(Invoice inv) {
    final no = inv.invoiceNo.isNotEmpty ? inv.invoiceNo : 'Draft';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(no, style: AppTypography.h2.copyWith(fontSize: 16)),
              ),
              const Divider(),
              if (inv.status == 'confirmed' && !inv.locked) ...[
                ListTile(
                  leading: const Icon(Icons.cancel_outlined, color: Colors.orange),
                  title: Text(_isQuotation ? 'Cancel Quotation' : 'Cancel Invoice', style: AppTypography.bodyLarge),
                  onTap: () { Navigator.of(ctx).pop(); _cancelInvoice(inv); },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  title: Text('Delete ${_isQuotation ? "Quotation" : "Invoice"}', style: AppTypography.bodyLarge),
                  onTap: () { Navigator.of(ctx).pop(); _confirmDelete(inv.id, no); },
                ),
              ],
              if (inv.status == 'confirmed' && inv.locked)
                ListTile(
                  leading: const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted),
                  title: Text('Locked — cannot modify', style: AppTypography.bodyLarge.copyWith(color: AppColors.textMuted)),
                ),
              if (inv.status == 'draft')
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  title: Text('Delete ${_isQuotation ? "Draft Quotation" : "Draft"}', style: AppTypography.bodyLarge),
                  onTap: () { Navigator.of(ctx).pop(); _confirmDelete(inv.id, no); },
                ),
              if (inv.status == 'cancelled')
                ListTile(
                  leading: Icon(Icons.block_rounded, color: AppColors.textMuted),
                  title: Text('Cancelled — permanent record', style: AppTypography.bodyLarge.copyWith(color: AppColors.textMuted)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(allInvoicesProvider(widget.mode));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_isQuotation ? 'Quotations' : 'Invoices'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: [
            const Tab(text: 'All'),
            if (!_isQuotation) const Tab(text: 'Unpaid'),
            if (!_isQuotation) const Tab(text: 'Paid'),
            if (_isQuotation) const Tab(text: 'Draft'),
            if (_isQuotation) const Tab(text: 'Confirmed'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InvoiceTypeScreen(mode: widget.mode))),
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
          if (_isQuotation) {
            final all = invoices;
            final draft = invoices.where((i) => i.status == 'draft').toList();
            final confirmed = invoices.where((i) => i.status == 'confirmed').toList();
            return IndexedStack(
              index: _tabController.index,
              children: [
                _buildTab(all),
                _buildTab(draft),
                _buildTab(confirmed),
              ],
            );
          }
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
                  Icon(_isQuotation ? Icons.request_quote_outlined : Icons.receipt_long_outlined, size: 48, color: AppColors.textMuted.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text(_isQuotation ? 'No quotations found' : 'No invoices found', style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
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
            case 'cancelled':
              statusColor = AppColors.error;
              statusLabel = 'Cancelled';
              break;
            default:
              statusColor = Colors.orange;
              statusLabel = 'Draft';
          }

          final typeColor = inv.invoiceType == 'partner' ? AppColors.primary : const Color(0xFF0D9488);
          final typeLabel = inv.invoiceType == 'partner' ? 'Partner' : 'Customer';
          final subtitle = [
            if (inv.partyName.isNotEmpty) inv.partyName else inv.partyMobile,
            dateStr,
            typeLabel,
            if (inv.status == 'confirmed') '\u20B9${inv.grandTotal.toStringAsFixed(2)}',
          ].join(' | ');

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoice: inv)),
              ),
              onLongPress: () => _showInvoiceActions(inv),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(_isQuotation ? Icons.request_quote_outlined : Icons.receipt_outlined, size: 16, color: typeColor),
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
                                  inv.invoiceNo.isNotEmpty ? inv.invoiceNo : 'Draft',
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
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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
