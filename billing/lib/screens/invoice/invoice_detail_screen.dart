import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../models/invoice_model.dart';
import '../../pb_service.dart';
import '../../providers/company_provider.dart';
import '../../providers/invoice_provider.dart';
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
      if (widget.invoice.mode == 'quotation') {
        pdf = await CustomerInvoiceFormat.generate(widget.invoice, company);
      } else if (widget.invoice.invoiceType == 'partner') {
        pdf = await DealerInvoiceFormat.generate(widget.invoice, company);
      } else {
        pdf = await CustomerInvoiceFormat.generate(widget.invoice, company);
      }
      if (!mounted) return;
      await Printing.sharePdf(
        bytes: pdf,
        filename: widget.invoice.invoiceNo.isNotEmpty
            ? '${widget.invoice.invoiceNo.replaceAll('/', '-')}.pdf'
            : '${widget.invoice.mode == 'quotation' ? 'quotation' : 'invoice'}.pdf',
      );
      if (widget.invoice.mode == 'quotation' && widget.invoice.status == 'draft' && mounted) {
        final repo = ref.read(invoiceRepositoryProvider);
        await repo.updateInvoiceStatus(widget.invoice.id, 'sent');
        ref.invalidate(allInvoicesProvider(widget.invoice.mode));
        if (mounted) AppSnackBars.showSuccess(context, 'Quotation marked as Sent');
      }
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
            Text(widget.invoice.mode == 'quotation' ? 'Cancel Quotation' : 'Cancel Invoice', style: AppTypography.h2.copyWith(fontSize: 18)),
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
                  child: Text(widget.invoice.mode == 'quotation' ? 'Cancel Quotation' : 'Cancel Invoice', style: AppTypography.button.copyWith(color: Colors.white)),
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
        AppSnackBars.showSuccess(context, widget.invoice.mode == 'quotation' ? 'Quotation cancelled' : 'Invoice cancelled');
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (context.mounted) AppSnackBars.showError(context, 'Failed to cancel');
    }
  }

  Future<void> _convertToInvoice(BuildContext context) async {
    try {
      final repo = ref.read(invoiceRepositoryProvider);
      final inv = await repo.duplicateAsInvoice(widget.invoice);
      ref.invalidate(allInvoicesProvider(widget.invoice.mode));
      if (!context.mounted) return;
      AppSnackBars.showSuccess(context, 'Converted to Invoice (Draft)');
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoice: inv)));
    } catch (_) {
      if (!context.mounted) return;
      AppSnackBars.showError(context, 'Conversion failed');
    }
  }

  Future<void> _finalizeDraft(BuildContext context) async {
    try {
      final repo = ref.read(invoiceRepositoryProvider);
      final no = await repo.getNextInvoiceNo();
      final updated = await repo.updateInvoice(widget.invoice.id, {'invoice_no': no, 'status': 'confirmed'});
      ref.invalidate(allInvoicesProvider(widget.invoice.mode));
      if (!context.mounted) return;
      AppSnackBars.showSuccess(context, 'Invoice created');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => InvoiceDetailScreen(invoice: updated),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      AppSnackBars.showError(context, 'Failed to finalize');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = '${widget.invoice.invoiceDate.day}/${widget.invoice.invoiceDate.month}/${widget.invoice.invoiceDate.year}';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.invoice.mode == 'quotation' ? 'Quotation' : widget.invoice.invoiceNo),
        elevation: 0,
        actions: [
          if (_isPdfLoading)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.picture_as_pdf, color: AppColors.primary),
                onPressed: _generatePdf,
                tooltip: 'Download PDF',
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPartyCard(dateStr),
                const SizedBox(height: 16),
                _buildItemsTable(),
                const SizedBox(height: 16),
                _buildTotalsCard(),
                const SizedBox(height: 16),
                if (widget.invoice.notes.isNotEmpty) _buildNotes(),
                if (widget.invoice.status == 'draft') ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => AppSnackBars.showInfo(context, 'Edit coming soon'),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  if (widget.invoice.mode != 'quotation') ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _finalizeDraft(context),
                        icon: const Icon(Icons.check_circle_outlined, size: 18),
                        label: const Text('Create Invoice'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ],
                if (widget.invoice.mode == 'quotation' && widget.invoice.status == 'sent') ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => AppSnackBars.showInfo(context, 'Edit coming soon'),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit Quotation'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _convertToInvoice(context),
                      icon: const Icon(Icons.receipt_long_outlined, size: 18),
                      label: const Text('Convert to Invoice'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
                if (widget.invoice.mode != 'quotation' && widget.invoice.status == 'confirmed') ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelInvoice(context),
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: Text(widget.invoice.mode == 'quotation' ? 'Cancel Quotation' : 'Cancel Invoice'),
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
          if (widget.invoice.status == 'cancelled')
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Transform.rotate(
                    angle: -0.45,
                    child: Text(
                      'CANCELLED',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error.withValues(alpha: 0.15),
                        letterSpacing: 8,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPartyCard(String dateStr) {
    final typeColor = widget.invoice.invoiceType == 'partner' ? AppColors.primary : const Color(0xFF0D9488);
    final typeLabel = widget.invoice.invoiceType == 'partner' ? 'Partner' : 'Customer';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
              Expanded(
                child: Text(widget.invoice.partyName.isNotEmpty ? widget.invoice.partyName : 'N/A', style: AppTypography.h3.copyWith(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(typeLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: typeColor)),
              ),
            ],
          ),
          if (widget.invoice.partyMobile.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(widget.invoice.partyMobile, style: AppTypography.bodySmall.copyWith(fontSize: 13)),
          ],
          if (widget.invoice.partyGst.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('GST: ${widget.invoice.partyGst}', style: AppTypography.bodySmall.copyWith(fontSize: 11)),
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
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.receipt_outlined, size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(widget.invoice.mode == 'quotation' ? 'Quotation No' : 'Invoice No', style: AppTypography.bodySmall.copyWith(fontSize: 9, color: AppColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(widget.invoice.invoiceNo, style: AppTypography.h3.copyWith(fontSize: 13)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text('Date', style: AppTypography.bodySmall.copyWith(fontSize: 9, color: AppColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(dateStr, style: AppTypography.h3.copyWith(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Items', style: AppTypography.h2.copyWith(fontSize: 15)),
          const SizedBox(height: 12),
          ...widget.invoice.items.asMap().entries.map((entry) {
            final item = entry.value;
            final i = entry.key;
            return Column(
              children: [
                if (i > 0) Container(height: 1, color: AppColors.border),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 22, child: Text('${i + 1}.', style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted))),
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(item.itemName, style: AppTypography.h3.copyWith(fontSize: 12)),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: Text('\u20B9 ${item.total == item.total.roundToDouble() ? item.total.toStringAsFixed(0) : item.total.toStringAsFixed(2)}', style: AppTypography.h3.copyWith(fontSize: 12)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (item.gstSlab > 0)
                                Text('GST ${item.gstSlab}%', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                              if (item.gstSlab > 0 && item.discountPercent > 0) const SizedBox(width: 10),
                              if (item.discountPercent > 0) ...[
                                Text('${item.discountPercent}% off', style: TextStyle(color: Colors.orange, fontSize: 10)),
                                const SizedBox(width: 10),
                              ],
                              const Spacer(),
                              Text('${item.quantity.toInt()} x \u20B9${item.unitPrice == item.unitPrice.roundToDouble() ? item.unitPrice.toStringAsFixed(0) : item.unitPrice.toStringAsFixed(2)}', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Summary', style: AppTypography.h2.copyWith(fontSize: 14)),
          const SizedBox(height: 12),
          _buildTotalRow('Subtotal', widget.invoice.subtotal),
          if (widget.invoice.discount > 0) _buildTotalRow('Discount', -widget.invoice.discount, isNegative: true),
          _buildTotalRow('Taxable', widget.invoice.taxable),
          if (isInterState) ...[
            _buildTotalRow('IGST', widget.invoice.igstTotal),
          ] else ...[
            _buildTotalRow('CGST', widget.invoice.cgstTotal),
            _buildTotalRow('SGST', widget.invoice.sgstTotal),
          ],
          if (widget.invoice.roundOff != 0) _buildTotalRow('Round Off', widget.invoice.roundOff),
          const Divider(height: 16, color: AppColors.border),
          _buildTotalRow('Grand Total', widget.invoice.grandTotal, isBold: true),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isBold = false, bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: isBold ? AppTypography.h3.copyWith(fontSize: 13) : AppTypography.bodySmall.copyWith(fontSize: 11))),
          Text(
            '${isNegative ? '- ' : ''}\u20B9 ${amount.abs().toStringAsFixed(2)}',
            style: (isBold ? AppTypography.h3 : AppTypography.bodyMedium).copyWith(
              fontSize: isBold ? 14 : 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotes() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
              Icon(Icons.notes_rounded, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text('Notes', style: AppTypography.h2.copyWith(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          Text(widget.invoice.notes, style: AppTypography.bodyMedium.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}
