import 'package:flutter/material.dart';
import '../../models/invoice_model.dart';
import '../../pb_service.dart';
import '../../theme/app_snackbars.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';

class InvoiceDetailScreen extends StatelessWidget {
  final Invoice invoice;
  const InvoiceDetailScreen({super.key, required this.invoice});

  void _cancelInvoice(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
            Text('Cancel Invoice', style: AppTypography.h2.copyWith(fontSize: 18)),
            const SizedBox(height: 12),
            Text(
              'Cancel "${invoice.invoiceNo}"?',
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
                    foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('No', style: AppTypography.button.copyWith(color: AppColors.primary)),
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
                  child: const Text('Cancel Invoice'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await PbService().pb.collection('invoice').update(invoice.id, body: {'status': 'cancelled'});
      if (context.mounted) {
        AppSnackBars.showSuccess(context, 'Invoice cancelled');
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (context.mounted) AppSnackBars.showError(context, 'Failed to cancel');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = '${invoice.invoiceDate.day}/${invoice.invoiceDate.month}/${invoice.invoiceDate.year}';

    Color statusColor;
    String statusLabel;
    switch (invoice.paymentStatus) {
      case 'paid':
        statusColor = AppColors.success;
        statusLabel = 'Paid';
        break;
      case 'partial':
        statusColor = Colors.orange;
        statusLabel = 'Partial';
        break;
      default:
        statusColor = AppColors.error;
        statusLabel = 'Unpaid';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(invoice.invoiceNo),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPartyCard(),
            const SizedBox(height: 24),
            _buildInvoiceInfo(dateStr),
            const SizedBox(height: 24),
            _buildItemsTable(),
            const SizedBox(height: 24),
            _buildTotalsCard(),
            const SizedBox(height: 24),
            if (invoice.notes.isNotEmpty) _buildNotes(),
            if (invoice.status == 'confirmed') ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _cancelInvoice(context),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Cancel Invoice'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPartyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (invoice.invoiceType == 'partner' ? AppColors.primary : const Color(0xFF0D9488)).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  invoice.invoiceType == 'partner' ? Icons.people_alt_rounded : Icons.person_outline_rounded,
                  color: invoice.invoiceType == 'partner' ? AppColors.primary : const Color(0xFF0D9488),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                invoice.invoiceType == 'partner' ? 'Partner' : 'Customer',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(invoice.partyName.isNotEmpty ? invoice.partyName : 'N/A', style: AppTypography.h2),
          if (invoice.partyMobile.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(invoice.partyMobile, style: AppTypography.bodyMedium),
          ],
          if (invoice.partyGst.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('GST: ${invoice.partyGst}', style: AppTypography.bodySmall),
          ],
          if (invoice.partyAddress.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              invoice.partyAddress,
              style: AppTypography.bodySmall.copyWith(fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInvoiceInfo(String dateStr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildInfoRow(Icons.receipt_outlined, 'Invoice No', invoice.invoiceNo),
          ),
          Expanded(
            child: _buildInfoRow(Icons.calendar_today_outlined, 'Date', dateStr),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Text(label, style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: 6),
        Text(value, style: AppTypography.h3.copyWith(fontSize: 14)),
      ],
    );
  }

  Widget _buildItemsTable() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Items', style: AppTypography.h2.copyWith(fontSize: 16)),
          const SizedBox(height: 16),
          ...invoice.items.asMap().entries.map((entry) {
            final item = entry.value;
            final i = entry.key;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text('${i + 1}', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(item.itemName, style: AppTypography.h3.copyWith(fontSize: 13))),
                      Text('\u20B9 ${item.total.toStringAsFixed(2)}', style: AppTypography.h3.copyWith(fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('${item.quantity} x \u20B9${item.unitPrice.toStringAsFixed(2)}', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      if (item.discountPercent > 0) ...[
                        const SizedBox(width: 12),
                        Text('${item.discountPercent}% off', style: TextStyle(color: Colors.orange, fontSize: 11)),
                      ],
                      const Spacer(),
                      if (item.gstSlab > 0)
                        Text('GST ${item.gstSlab}%', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                  if (item.hsnCode.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('HSN: ${item.hsnCode}', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTotalsCard() {
    final isInterState = invoice.igstTotal > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Summary', style: AppTypography.h2.copyWith(fontSize: 16)),
          const SizedBox(height: 16),
          _buildTotalRow('Subtotal', invoice.subtotal),
          if (invoice.discount > 0) _buildTotalRow('Discount', -invoice.discount, isNegative: true),
          _buildTotalRow('Taxable', invoice.taxable),
          if (isInterState) ...[
            _buildTotalRow('IGST @ ${invoice.items.isNotEmpty ? invoice.items.first.igstRate.toStringAsFixed(1) : '0'}%', invoice.igstTotal),
          ] else ...[
            _buildTotalRow('CGST', invoice.cgstTotal),
            _buildTotalRow('SGST', invoice.sgstTotal),
          ],
          if (invoice.roundOff != 0) _buildTotalRow('Round Off', invoice.roundOff),
          const Divider(height: 24, color: AppColors.border),
          _buildTotalRow('Grand Total', invoice.grandTotal, isBold: true),
          const SizedBox(height: 16),
          _buildPaymentInfo(),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isBold = false, bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: isBold ? AppTypography.h3.copyWith(fontSize: 13) : AppTypography.bodySmall.copyWith(fontSize: 12))),
          Text(
            '${isNegative ? '- ' : ''}\u20B9 ${amount.abs().toStringAsFixed(2)}',
            style: (isBold ? AppTypography.h3 : AppTypography.bodyMedium).copyWith(
              fontSize: isBold ? 15 : 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.payments_outlined, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Text(_paymentModeLabel(invoice.paymentMode), style: AppTypography.bodySmall.copyWith(fontSize: 11)),
          const Spacer(),
          if (invoice.paidAmount > 0)
            Text('Paid: \u20B9${invoice.paidAmount.toStringAsFixed(2)}', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
          if (invoice.balanceAmount > 0) ...[
            const SizedBox(width: 12),
            Text('Due: \u20B9${invoice.balanceAmount.toStringAsFixed(2)}', style: TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }

  String _paymentModeLabel(String mode) {
    switch (mode) {
      case 'cash': return 'Cash';
      case 'card': return 'Card';
      case 'upi': return 'UPI';
      case 'bank': return 'Bank Transfer';
      case 'credit': return 'Credit';
      default: return mode;
    }
  }

  Widget _buildNotes() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes_rounded, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Text('Notes', style: AppTypography.h2.copyWith(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Text(invoice.notes, style: AppTypography.bodyMedium.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}
