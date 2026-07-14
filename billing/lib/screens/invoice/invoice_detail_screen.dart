import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../models/invoice_model.dart';
import '../../pb_service.dart';
import '../../providers/company_provider.dart';
import '../../services/pdf/dealer_format.dart';
import '../../services/pdf/customer_format.dart';
import '../../theme/app_snackbars.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';

class InvoiceDetailScreen extends ConsumerStatefulWidget {
  final Invoice invoice;
  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  ConsumerState<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  bool _isPdfLoading = false;

  Future<void> _generatePdf() async {
    setState(() => _isPdfLoading = true);
    try {
      final company = await ref.read(companyProvider.future);
      if (company == null) {
        if (mounted) AppSnackBars.showError(context, 'Company profile not found');
        return;
      }
      Uint8List pdf;
      if (widget.invoice.invoiceType == 'partner') {
        pdf = await DealerInvoiceFormat.generate(widget.invoice, company);
      } else {
        pdf = await CustomerInvoiceFormat.generate(widget.invoice, company);
      }
      if (!mounted) return;
      await Printing.sharePdf(
        bytes: pdf,
        filename: widget.invoice.invoiceNo.isNotEmpty
            ? '${widget.invoice.invoiceNo.replaceAll('/', '-')}.pdf'
            : 'invoice.pdf',
      );
    } catch (e) {
      if (mounted) AppSnackBars.showError(context, 'PDF generation failed: $e');
    } finally {
      if (mounted) setState(() => _isPdfLoading = false);
    }
  }

  Future<void> _cancelInvoice(BuildContext context) async {
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
              'Cancel "${widget.invoice.invoiceNo}"?',
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
      await PbService().pb.collection('invoice').update(widget.invoice.id, body: {'status': 'cancelled'});
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
    final dateStr = '${widget.invoice.invoiceDate.day}/${widget.invoice.invoiceDate.month}/${widget.invoice.invoiceDate.year}';

    Color statusColor;
    String statusLabel;
    switch (widget.invoice.paymentStatus) {
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
        title: Text(widget.invoice.invoiceNo),
        elevation: 0,
        actions: [
          if (_isPdfLoading)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: _generatePdf,
              tooltip: 'Download PDF',
            ),
          Container(
            margin: const EdgeInsets.only(right: 8),
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
            if (widget.invoice.notes.isNotEmpty) _buildNotes(),
            if (widget.invoice.status == 'confirmed') ...[
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
                  color: (widget.invoice.invoiceType == 'partner' ? AppColors.primary : const Color(0xFF0D9488)).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.invoice.invoiceType == 'partner' ? Icons.people_alt : Icons.person_outline,
                  color: widget.invoice.invoiceType == 'partner' ? AppColors.primary : const Color(0xFF0D9488),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                widget.invoice.invoiceType == 'partner' ? 'Partner' : 'Customer',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(widget.invoice.partyName.isNotEmpty ? widget.invoice.partyName : 'N/A', style: AppTypography.h2),
          if (widget.invoice.partyMobile.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(widget.invoice.partyMobile, style: AppTypography.bodyMedium),
          ],
          if (widget.invoice.partyGst.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('GST: ${widget.invoice.partyGst}', style: AppTypography.bodySmall),
          ],
          if (widget.invoice.partyAddress.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              widget.invoice.partyAddress,
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
            child: _buildInfoRow(Icons.receipt_outlined, 'Invoice No', widget.invoice.invoiceNo),
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
          ...widget.invoice.items.asMap().entries.map((entry) {
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
    final isInterState = widget.invoice.igstTotal > 0;

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
          _buildTotalRow('Subtotal', widget.invoice.subtotal),
          if (widget.invoice.discount > 0) _buildTotalRow('Discount', -widget.invoice.discount, isNegative: true),
          _buildTotalRow('Taxable', widget.invoice.taxable),
          if (isInterState) ...[
            _buildTotalRow('IGST @ ${widget.invoice.items.isNotEmpty ? widget.invoice.items.first.igstRate.toStringAsFixed(1) : '0'}%', widget.invoice.igstTotal),
          ] else ...[
            _buildTotalRow('CGST', widget.invoice.cgstTotal),
            _buildTotalRow('SGST', widget.invoice.sgstTotal),
          ],
          if (widget.invoice.roundOff != 0) _buildTotalRow('Round Off', widget.invoice.roundOff),
          const Divider(height: 24, color: AppColors.border),
          _buildTotalRow('Grand Total', widget.invoice.grandTotal, isBold: true),
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
          Text(_paymentModeLabel(widget.invoice.paymentMode), style: AppTypography.bodySmall.copyWith(fontSize: 11)),
          const Spacer(),
          if (widget.invoice.paidAmount > 0)
            Text('Paid: \u20B9${widget.invoice.paidAmount.toStringAsFixed(2)}', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
          if (widget.invoice.balanceAmount > 0) ...[
            const SizedBox(width: 12),
            Text('Due: \u20B9${widget.invoice.balanceAmount.toStringAsFixed(2)}', style: TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.bold)),
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
          Text(widget.invoice.notes, style: AppTypography.bodyMedium.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}
