import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/invoice_model.dart';
import '../../models/partner_model.dart';
import '../../models/customer_model.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/company_provider.dart';
import '../../pb_service.dart';
import '../../theme/app_snackbars.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';

class BillingScreen extends ConsumerStatefulWidget {
  final String invoiceType;
  final Customer? customer;
  final Partner? partner;
  const BillingScreen({
    super.key,
    required this.invoiceType,
    this.customer,
    this.partner,
  });

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  String _invoiceNo = '';

  late String _invoiceType;
  String _customerId = '';
  String _partyName = '';
  String _partyMobile = '';
  String _partyGst = '';
  String _partyAddress = '';
  String _partyStateCode = '';

  final List<InvoiceItem> _items = [];

  String _paymentMode = 'cash';
  String _paymentStatus = 'paid';
  final _paidAmountCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _invoiceType = widget.invoiceType;
    if (widget.customer != null) {
      final c = widget.customer!;
      _customerId = c.id;
      _partyName = c.customerName.isNotEmpty ? c.customerName : c.businessName;
      _partyMobile = c.mobileNo;
      _partyGst = c.gstNo;
      _partyStateCode = c.stateCode;
      _partyAddress = [c.address, c.city, c.district, c.state, c.pincode].where((e) => e.isNotEmpty).join(', ');
    } else if (widget.partner != null) {
      final p = widget.partner!;
      _partyName = p.partnerName;
      _partyMobile = p.mobileNo;
      _partyGst = p.gstNo;
      _partyStateCode = p.stateCode;
    }
    _loadInvoiceNo();
  }

  Future<void> _loadInvoiceNo() async {
    final repo = ref.read(invoiceRepositoryProvider);
    final no = await repo.getNextInvoiceNo();
    if (mounted) setState(() => _invoiceNo = no);
  }

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.taxableValue);
  double get _discount => _items.fold(0, (sum, item) => sum + (item.unitPrice * item.quantity * item.discountPercent / 100));
  double get _taxable => _items.fold(0, (sum, item) => sum + item.taxableValue);
  double get _cgstTotal => _items.fold(0, (sum, item) => sum + item.cgstAmount);
  double get _sgstTotal => _items.fold(0, (sum, item) => sum + item.sgstAmount);
  double get _igstTotal => _items.fold(0, (sum, item) => sum + item.igstAmount);
  double get _grandTotal => _taxable + _cgstTotal + _sgstTotal + _igstTotal;

  bool get _isInterState {
    final company = ref.read(companyProvider).value;
    final companyCode = company?.stateCode ?? '';
    final partyCode = _partyStateCode;
    if (companyCode.isEmpty || partyCode.isEmpty) return false;
    return companyCode != partyCode;
  }

  void _recalculateItem(int index) {
    final item = _items[index];
    final gstSlab = item.gstSlab;
    final qty = item.quantity;
    final basePrice = item.unitPrice * qty;
    final discAmt = basePrice * item.discountPercent / 100;
    item.taxableValue = basePrice - discAmt;

    if (_isInterState) {
      item.cgstRate = 0;
      item.sgstRate = 0;
      item.igstRate = gstSlab.toDouble();
      item.cgstAmount = 0;
      item.sgstAmount = 0;
      item.igstAmount = item.taxableValue * gstSlab / 100;
      item.total = item.taxableValue + item.igstAmount;
    } else {
      final gstHalf = gstSlab / 2;
      item.cgstRate = gstHalf;
      item.sgstRate = gstHalf;
      item.igstRate = 0;
      item.cgstAmount = item.taxableValue * gstHalf / 100;
      item.sgstAmount = item.taxableValue * gstHalf / 100;
      item.igstAmount = 0;
      item.total = item.taxableValue + item.cgstAmount + item.sgstAmount;
    }
    setState(() {});
  }

  void _addItemFromInventory() async {
    // Show dialog to pick item type first
    final type = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select Item Type', style: AppTypography.h2),
            const SizedBox(height: 16),
            ...['vehicle', 'battery', 'motor', 'accessory', 'charger'].map((t) => ListTile(
              title: Text(t[0].toUpperCase() + t.substring(1), style: AppTypography.bodyLarge),
              leading: Icon(_iconForType(t), color: _colorForType(t)),
              onTap: () => Navigator.of(ctx).pop(t),
            )),
          ],
        ),
      ),
    );
    if (type == null || !mounted) return;

    // Fetch items from the selected collection
    try {
      final records = await PbService().pb.collection(type).getFullList(
        filter: 'status = "active"',
        sort: 'name',
      );
      if (!mounted) return;
      if (records.isEmpty) {
        AppSnackBars.showError(context, 'No active $type items found');
        return;
      }

      final names = records.map((r) {
        final name = r.getStringValue('full_name').isNotEmpty
            ? r.getStringValue('full_name')
            : r.getStringValue('name');
        final price = r.getDoubleValue('selling_price');
        final code = r.getStringValue('item_code');
        return '$name (₹${price.toStringAsFixed(0)}) - $code';
      }).toList();

      final selected = await showDialog<int>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Select ${type[0].toUpperCase() + type.substring(1)}', style: AppTypography.h2),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: names.length,
                    itemBuilder: (_, i) => ListTile(
                      title: Text(names[i], style: AppTypography.bodyMedium),
                      onTap: () => Navigator.of(ctx).pop(i),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (selected == null || !mounted) {
        return;
      }

      final rec = records[selected];
      final hsn = rec.getStringValue('hsn_code');
      final gstSlab = rec.getDoubleValue('gst_slab').toInt();
      final price = rec.getDoubleValue('selling_price');
      final code = rec.getStringValue('item_code');
      final name = rec.getStringValue('full_name').isNotEmpty
          ? rec.getStringValue('full_name')
          : rec.getStringValue('name');

      final item = InvoiceItem(
        itemType: type,
        itemId: rec.id,
        itemCode: code,
        itemName: name,
        hsnCode: hsn,
        gstSlab: gstSlab,
        quantity: 1,
        unitPrice: price,
      );

      final qtyCtrl = TextEditingController(text: '1');
      final discCtrl = TextEditingController(text: '0');

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: StatefulBuilder(
            builder: (ctx, setDlgState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Item', style: AppTypography.h2),
                const SizedBox(height: 16),
                Text(name, style: AppTypography.h3),
                const SizedBox(height: 4),
                Text('₹${price.toStringAsFixed(2)} • HSN: $hsn • GST: $gstSlab%', style: AppTypography.bodySmall),
                const SizedBox(height: 16),
                TextField(
                  controller: qtyCtrl,
                  decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: discCtrl,
                  decoration: const InputDecoration(labelText: 'Discount (%)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Add')),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        item.quantity = double.tryParse(qtyCtrl.text) ?? 1;
        item.discountPercent = double.tryParse(discCtrl.text) ?? 0;
        _items.add(item);
        _recalculateItem(_items.length - 1);
      }
    } catch (_) {
      if (mounted) AppSnackBars.showError(context, 'Cannot fetch items');
    }
  }

  Future<void> _saveInvoice({bool isFinal = true}) async {
    if (_invoiceType == 'customer' && _customerId.isEmpty && _partyName.isEmpty) {
      AppSnackBars.showError(context, 'Enter or look up a customer first');
      return;
    }
    if (_items.isEmpty) {
      AppSnackBars.showError(context, 'Add at least one item');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final paidAmount = double.tryParse(_paidAmountCtrl.text) ?? _grandTotal;
      final balance = _grandTotal - paidAmount;

      final body = {
        'invoice_no': _invoiceNo,
        'invoice_type': _invoiceType,
        'invoice_date': DateTime.now().toIso8601String(),
        'partner_id': _invoiceType == 'partner' ? widget.partner?.id : null,
        'customer_id': _invoiceType == 'customer' ? (_customerId.isNotEmpty ? _customerId : null) : null,
        'party_name': _partyName,
        'party_mobile': _partyMobile,
        'party_gst': _partyGst,
        'party_state_code': _partyStateCode,
        'party_address': _partyAddress,
        'items': _items.map((e) => e.toJson()).toList(),
        'subtotal': _subtotal,
        'discount': _discount,
        'taxable': _taxable,
        'cgst_total': _cgstTotal,
        'sgst_total': _sgstTotal,
        'igst_total': _igstTotal,
        'grand_total': _grandTotal,
        'payment_mode': _paymentMode,
        'payment_status': _paymentStatus,
        'paid_amount': paidAmount,
        'balance_amount': balance < 0 ? 0 : balance,
        'status': isFinal ? 'confirmed' : 'draft',
        'notes': '',
      };

      final repo = ref.read(invoiceRepositoryProvider);
      await repo.createInvoice(body);
      ref.invalidate(allInvoicesProvider);
      if (mounted) {
        AppSnackBars.showSuccess(context, 'Invoice Created: $_invoiceNo');
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) AppSnackBars.showError(context, 'Save failed. Try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  IconData _iconForType(String t) {
    switch (t) {
      case 'vehicle': return Icons.directions_bike_outlined;
      case 'battery': return Icons.battery_charging_full_outlined;
      case 'motor': return Icons.bolt_outlined;
      case 'accessory': return Icons.handyman_outlined;
      case 'charger': return Icons.power_outlined;
      default: return Icons.inventory_2_outlined;
    }
  }

  Color _colorForType(String t) {
    switch (t) {
      case 'vehicle': return Colors.blue;
      case 'battery': return Colors.green;
      case 'motor': return Colors.orange;
      case 'accessory': return Colors.purple;
      case 'charger': return Colors.teal;
      default: return Colors.grey;
    }
  }

  @override
  void dispose() {
    _paidAmountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('New Invoice'),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => _saveInvoice(),
            child: _isSaving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                : Text('Save', style: AppTypography.button.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Invoice No
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text('Invoice No: $_invoiceNo', style: AppTypography.h3.copyWith(color: AppColors.primary)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Type + Tax indicator
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _invoiceType == 'partner' ? AppColors.primary.withValues(alpha: 0.1) : const Color(0xFF0D9488).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _invoiceType == 'partner' ? Icons.business_outlined : Icons.people_outline_rounded,
                          size: 14,
                          color: _invoiceType == 'partner' ? AppColors.primary : const Color(0xFF0D9488),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _invoiceType == 'partner' ? 'Dealer' : 'Customer',
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 11,
                            color: _invoiceType == 'partner' ? AppColors.primary : const Color(0xFF0D9488),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isInterState ? Colors.purple.withValues(alpha: 0.08) : AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isInterState ? Icons.swap_horiz_rounded : Icons.home_rounded,
                          size: 14,
                          color: _isInterState ? Colors.purple : AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isInterState ? 'IGST (Inter-State)' : 'CGST+SGST (Intra-State)',
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 10,
                            color: _isInterState ? Colors.purple : AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(height: 1, color: AppColors.border),
              const SizedBox(height: 24),

              // Party Section
              _buildPartyCard(),
              const SizedBox(height: 24),
              Container(height: 1, color: AppColors.border),
              const SizedBox(height: 24),

              // Items Section
              _buildSectionHeader('Items'),
              const SizedBox(height: 16),
              if (_items.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.textMuted.withValues(alpha: 0.4)),
                        const SizedBox(height: 8),
                        Text('No items added', style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
              ...List.generate(_items.length, (i) => _buildItemCard(i)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _addItemFromInventory,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text('Add Item', style: AppTypography.button),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              const SizedBox(height: 24),
              Container(height: 1, color: AppColors.border),
              const SizedBox(height: 24),

              // Summary
              _buildSectionHeader('Summary'),
              const SizedBox(height: 16),
              _buildSummaryRow('Subtotal', _subtotal),
              _buildSummaryRow('Discount', -_discount, color: AppColors.error),
              _buildSummaryRow('Taxable', _taxable),
              if (_cgstTotal > 0) _buildSummaryRow('CGST', _cgstTotal),
              if (_sgstTotal > 0) _buildSummaryRow('SGST', _sgstTotal),
              if (_igstTotal > 0) _buildSummaryRow('IGST', _igstTotal),
              Container(height: 1, color: AppColors.border, margin: const EdgeInsets.symmetric(vertical: 8)),
              _buildSummaryRow('Grand Total', _grandTotal, color: AppColors.primary, bold: true),
              const SizedBox(height: 24),
              Container(height: 1, color: AppColors.border),
              const SizedBox(height: 24),

              // Payment
              _buildSectionHeader('Payment'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildPickerField(
                      'Mode',
                      _paymentMode,
                      Icons.payment_outlined,
                      ['cash', 'card', 'upi', 'credit'],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPickerField(
                      'Status',
                      _paymentStatus,
                      Icons.check_circle_outline,
                      ['paid', 'unpaid', 'partial'],
                    ),
                  ),
                ],
              ),
              if (_paymentStatus != 'paid') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _paidAmountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                  style: AppTypography.input,
                  decoration: InputDecoration(
                    labelText: 'Paid Amount',
                    labelStyle: AppTypography.bodySmall,
                    prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 18, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : () => _saveInvoice(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Create Invoice', style: AppTypography.button.copyWith(color: Colors.white, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPartyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
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
                  color: (_invoiceType == 'partner' ? AppColors.primary : const Color(0xFF0D9488)).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _invoiceType == 'partner' ? Icons.business_outlined : Icons.people_outline_rounded,
                  size: 18,
                  color: _invoiceType == 'partner' ? AppColors.primary : const Color(0xFF0D9488),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_partyName, style: AppTypography.h3),
                    if (_partyMobile.isNotEmpty)
                      Text(_partyMobile, style: AppTypography.bodySmall.copyWith(fontSize: 11)),
                  ],
                ),
              ),
              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
            ],
          ),
          if (_partyGst.isNotEmpty || _partyAddress.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(height: 1, color: AppColors.border),
            const SizedBox(height: 10),
            if (_partyGst.isNotEmpty)
              Text('GST: $_partyGst', style: AppTypography.bodySmall.copyWith(fontSize: 11)),
            if (_partyAddress.isNotEmpty)
              Text(_partyAddress, style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textMuted)),
          ],
        ],
      ),
    );
  }

  Widget _buildItemCard(int index) {
    final item = _items[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.border)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_iconForType(item.itemType), size: 18, color: _colorForType(item.itemType)),
                const SizedBox(width: 8),
                Expanded(child: Text(item.itemName, style: AppTypography.h3.copyWith(fontSize: 14))),
                InkWell(
                  onTap: () => setState(() => _items.removeAt(index)),
                  child: const Icon(Icons.close_rounded, size: 18, color: AppColors.error),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _itemDetail('Qty', item.quantity.toString()),
                const SizedBox(width: 16),
                _itemDetail('Rate', '₹${item.unitPrice.toStringAsFixed(0)}'),
                const SizedBox(width: 16),
                _itemDetail('Disc', '${item.discountPercent.toStringAsFixed(0)}%'),
                const Spacer(),
                Text('₹${item.total.toStringAsFixed(2)}', style: AppTypography.h3.copyWith(color: AppColors.primary, fontSize: 14)),
              ],
            ),
            Text(
              'HSN: ${item.hsnCode} • GST: ${item.gstSlab}% • Taxable: ₹${item.taxableValue.toStringAsFixed(2)}',
              style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.bodySmall.copyWith(fontSize: 9, color: AppColors.textMuted)),
        Text(value, style: AppTypography.bodyMedium.copyWith(fontSize: 12)),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double amount, {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: bold ? AppTypography.h3 : AppTypography.bodyMedium),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: (bold ? AppTypography.h3 : AppTypography.bodyMedium).copyWith(
              color: color,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerField(String label, String value, IconData icon, List<String> options) {
    return InkWell(
      onTap: () async {
        final result = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: AppTypography.h2),
                const SizedBox(height: 16),
                ...options.map((o) => ListTile(
                  title: Text(o[0].toUpperCase() + o.substring(1), style: AppTypography.bodyLarge),
                  trailing: value == o ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                  onTap: () => Navigator.of(ctx).pop(o),
                )),
              ],
            ),
          ),
        );
        if (result != null && mounted) {
          setState(() {
            if (label == 'Mode') _paymentMode = result;
            if (label == 'Status') _paymentStatus = result;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(value[0].toUpperCase() + value.substring(1), style: AppTypography.bodyMedium),
              ],
            ),
            const Spacer(),
            const Icon(Icons.expand_more_rounded, size: 20, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: AppTypography.h2);
  }
}
