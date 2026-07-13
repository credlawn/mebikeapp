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
import 'item_select_screen.dart';
import 'vehicle_qty_color_screen.dart';
import 'battery_combo_screen.dart';

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
      _partyAddress = p.billingAddress;
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
    final netAmount = basePrice - discAmt;

    final double taxable;
    if (item.isGstInclusive) {
      taxable = netAmount / (1 + gstSlab / 100);
    } else {
      taxable = netAmount;
    }
    item.taxableValue = taxable;

    if (_isInterState) {
      item.cgstRate = 0;
      item.sgstRate = 0;
      item.igstRate = gstSlab.toDouble();
      item.cgstAmount = 0;
      item.sgstAmount = 0;
      item.igstAmount = taxable * gstSlab / 100;
      item.total = taxable + item.igstAmount;
    } else {
      final gstHalf = gstSlab / 2;
      item.cgstRate = gstHalf;
      item.sgstRate = gstHalf;
      item.igstRate = 0;
      item.cgstAmount = taxable * gstHalf / 100;
      item.sgstAmount = taxable * gstHalf / 100;
      item.igstAmount = 0;
      item.total = taxable + item.cgstAmount + item.sgstAmount;
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
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Text('Select Item Type', style: AppTypography.h2),
              const SizedBox(height: 20),
              ...['vehicle', 'battery', 'motor', 'accessory', 'charger'].map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () => Navigator.of(ctx).pop(t),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _colorForType(t).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _colorForType(t).withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_iconForType(t), color: _colorForType(t), size: 20),
                        const SizedBox(width: 10),
                        Text(
                          t[0].toUpperCase() + t.substring(1),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _colorForType(t),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
              const SizedBox(height: 4),
            ],
          ),
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

      final rec = await Navigator.of(context).push<dynamic>(
        MaterialPageRoute(
          builder: (_) => ItemSelectScreen(itemType: type),
        ),
      );

      if (rec == null || !mounted) return;

      if (type == 'vehicle') {
        await _handleVehicleFlow(rec);
        return;
      }

      final hsn = rec.getStringValue('hsn_code');
      final int gstSlab = rec.getDoubleValue('gst_slab').toInt();
      final code = rec.getStringValue('item_code');
      final String fn = rec.getStringValue('full_name');
      final String nn = rec.getStringValue('name');
      final String name = fn.isNotEmpty ? fn : nn;

      final qtyCtrl = TextEditingController(text: '1');
      final priceCtrl = TextEditingController();

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          content: SizedBox(
            width: MediaQuery.of(ctx).size.width - 88,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: _colorForType(type).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_iconForType(type), color: _colorForType(type), size: 24),
                ),
                const SizedBox(height: 16),
                Text(name, style: AppTypography.h3, textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _colorForType(type).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'HSN: $hsn  •  GST: $gstSlab%',
                    style: AppTypography.bodySmall.copyWith(fontSize: 10, color: _colorForType(type)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        decoration: InputDecoration(
                          labelText: 'Quantity',
                          labelStyle: AppTypography.bodySmall,
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        style: AppTypography.input,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        decoration: InputDecoration(
                          labelText: 'Per Unit Price',
                          labelStyle: AppTypography.bodySmall,
                          prefixText: '₹ ',
                          prefixStyle: AppTypography.bodySmall,
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        style: AppTypography.input,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Cancel', style: AppTypography.button.copyWith(color: AppColors.primary)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Add', style: AppTypography.button.copyWith(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        final qty = double.tryParse(qtyCtrl.text) ?? 1;
        final perUnitPrice = double.tryParse(priceCtrl.text) ?? 0;
        _items.add(InvoiceItem(
          itemType: type,
          itemId: rec.id,
          itemCode: code,
          itemName: name,
          hsnCode: hsn,
          gstSlab: gstSlab,
          quantity: qty,
          unitPrice: perUnitPrice,
          isGstInclusive: true,
        ));
        _recalculateItem(_items.length - 1);
      }
    } catch (_) {
      if (mounted) AppSnackBars.showError(context, 'Cannot fetch items');
    }
  }

  Future<void> _handleVehicleFlow(dynamic rec) async {
    final vehicleData = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => VehicleQtyColorScreen(vehicleRecord: rec),
      ),
    );
    if (vehicleData == null || !mounted) return;

    final vehicle = vehicleData['vehicle'] as dynamic;
    final int totalQty = vehicleData['totalQty'] as int;
    final colorEntries = vehicleData['colorEntries'] as List<Map<String, dynamic>>;

    final batteryResult = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => BatteryComboScreen(
          vehicleRecord: vehicle,
          totalQty: totalQty,
          colorEntries: colorEntries,
        ),
      ),
    );
    if (batteryResult == null || !mounted) return;

    final int gstSlab = vehicle.getDoubleValue('gst_slab').toInt();
    final String hsn = vehicle.getStringValue('hsn_code');
    final String code = vehicle.getStringValue('item_code');
    final String fn = vehicle.getStringValue('full_name');
    final String nm = vehicle.getStringValue('name');
    final String fullName = fn.isNotEmpty ? fn : nm;

    if (batteryResult['noBattery'] == true) {
      final wbPrice = batteryResult['wbUnitPrice'] as double;
      for (final c in colorEntries) {
        final colorName = c['color'] as String;
        final itemName = '$fullName - $colorName (WB)';
        final existing = _items.where((i) => i.itemName == itemName).toList();
        if (existing.any((i) => i.unitPrice == wbPrice)) {
          if (mounted) AppSnackBars.showError(context, '"$itemName" at ₹$wbPrice already exists');
          return;
        }
        if (existing.any((i) => i.unitPrice != wbPrice)) {
          final oldItem = existing.first;
          final oldPrice = oldItem.unitPrice;
          final oldQty = oldItem.quantity.toInt();
          final newQty = c['qty'] as int;
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
              contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              content: SizedBox(
                width: MediaQuery.of(ctx).size.width - 88,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
                    ),
                    const SizedBox(height: 16),
                    Text('Price Change', style: AppTypography.h2.copyWith(fontSize: 18)),
                    const SizedBox(height: 12),
                    Text(
                      'Already added Qty-$oldQty at ₹${oldPrice.toStringAsFixed(0)}',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5),
                    ),
                    Text(
                      'Add Qty-$newQty at ₹${wbPrice.toStringAsFixed(0)}?',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5),
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary, width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text('Cancel', style: AppTypography.button.copyWith(color: AppColors.primary)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text('Add', style: AppTypography.button.copyWith(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
          if (confirm != true) return;
        }
      }
      for (final c in colorEntries) {
        final colorName = c['color'] as String;
        final qty = c['qty'] as int;
        _items.add(InvoiceItem(
          itemType: 'vehicle', itemId: vehicle.id, itemCode: code,
          itemName: '$fullName - $colorName (WB)',
          hsnCode: hsn, gstSlab: gstSlab,
          quantity: qty.toDouble(), unitPrice: wbPrice,
          isGstInclusive: true,
        ));
        _recalculateItem(_items.length - 1);
      }
      if (mounted) AppSnackBars.showSuccess(context, '${_items.length} items added');
      return;
    }

    final batteryCombos = batteryResult['batteryCombos'] as List<Map<String, dynamic>>;

    // Greedy: always match highest qty color with highest qty battery
    var cRemaining = colorEntries.map((c) => Map<String, dynamic>.from(c)).toList();
    var bRemaining = batteryCombos.map((b) => Map<String, dynamic>.from(b)).toList();

    // Pre-compute unit rates from original battery data
    final unitRateOf = <String, double>{};
    for (final b in batteryCombos) {
      final rec = b['batteryRecord'] as dynamic;
      final unitPrice = b['unitPrice'] as double;
      unitRateOf[rec.id] = unitPrice;
    }

    while (true) {
      cRemaining.removeWhere((c) => (c['qty'] as int) <= 0);
      bRemaining.removeWhere((b) => (b['qty'] as int) <= 0);
      if (cRemaining.isEmpty || bRemaining.isEmpty) break;

      cRemaining.sort((a, b) => (b['qty'] as int).compareTo(a['qty'] as int));
      bRemaining.sort((a, b) => (b['qty'] as int).compareTo(a['qty'] as int));

      final int maxC = cRemaining.first['qty'] as int;
      final int maxB = bRemaining.first['qty'] as int;

      if (maxC >= maxB) {
        final color = cRemaining.first;
        final colorName = color['color'] as String;
        int need = maxC;
        for (final batt in bRemaining) {
          if (need <= 0) break;
          final int battQty = batt['qty'] as int;
          if (battQty <= 0) continue;
          final int take = need < battQty ? need : battQty;
          final battRec = batt['batteryRecord'] as dynamic;
          final String bFn = battRec.getStringValue('full_name');
          final String bNm = battRec.getStringValue('name');
          final String bName = bFn.isNotEmpty ? bFn : bNm;
          final String comboName = '$fullName - $colorName + $bName';
          final comboPrice = unitRateOf[battRec.id]!;
          final existing = _items.where((i) => i.itemName == comboName).toList();
          if (existing.any((i) => i.unitPrice == comboPrice)) {
            if (mounted) AppSnackBars.showError(context, '"$comboName" at ₹$comboPrice already exists');
            return;
          }
          if (existing.any((i) => i.unitPrice != comboPrice)) {
            final oldItem = existing.first;
            final oldPrice = oldItem.unitPrice;
            final oldQty = oldItem.quantity.toInt();
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
                contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                content: SizedBox(
                  width: MediaQuery.of(ctx).size.width - 88,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
                      ),
                      const SizedBox(height: 16),
                      Text('Price Change', style: AppTypography.h2.copyWith(fontSize: 18)),
                      const SizedBox(height: 12),
                      Text(
                        'Already added Qty-$oldQty at ₹${oldPrice.toStringAsFixed(0)}',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5),
                      ),
                      Text(
                        'Add Qty-$take at ₹${comboPrice.toStringAsFixed(0)}?',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5),
                      ),
                    ],
                  ),
                ),
                actions: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary, width: 1.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text('Cancel', style: AppTypography.button.copyWith(color: AppColors.primary)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text('Add', style: AppTypography.button.copyWith(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
            if (confirm != true) return;
          }
          _items.add(InvoiceItem(
            itemType: 'vehicle', itemId: vehicle.id, itemCode: code,
            itemName: comboName,
            hsnCode: hsn, gstSlab: gstSlab,
            quantity: take.toDouble(), unitPrice: comboPrice,
            isGstInclusive: true,
          ));
          _recalculateItem(_items.length - 1);
          need -= take;
        }
        color['qty'] = need;
      } else {
        final batt = bRemaining.first;
        final battRec = batt['batteryRecord'] as dynamic;
        final String bFn = battRec.getStringValue('full_name');
        final String bNm = battRec.getStringValue('name');
        final String bName = bFn.isNotEmpty ? bFn : bNm;
        int need = maxB;
        for (final color in cRemaining) {
          if (need <= 0) break;
          final int colorQty = color['qty'] as int;
          if (colorQty <= 0) continue;
          final int take = need < colorQty ? need : colorQty;
          final colorName = color['color'] as String;
          final String comboName = '$fullName - $colorName + $bName';
          final comboPrice = unitRateOf[battRec.id]!;
          final existing = _items.where((i) => i.itemName == comboName).toList();
          if (existing.any((i) => i.unitPrice == comboPrice)) {
            if (mounted) AppSnackBars.showError(context, '"$comboName" at ₹$comboPrice already exists');
            return;
          }
          if (existing.any((i) => i.unitPrice != comboPrice)) {
            final oldItem = existing.first;
            final oldPrice = oldItem.unitPrice;
            final oldQty = oldItem.quantity.toInt();
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
                contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                content: SizedBox(
                  width: MediaQuery.of(ctx).size.width - 88,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
                      ),
                      const SizedBox(height: 16),
                      Text('Price Change', style: AppTypography.h2.copyWith(fontSize: 18)),
                      const SizedBox(height: 12),
                      Text(
                        'Already added Qty-$oldQty at ₹${oldPrice.toStringAsFixed(0)}',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5),
                      ),
                      Text(
                        'Add Qty-$take at ₹${comboPrice.toStringAsFixed(0)}?',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5),
                      ),
                    ],
                  ),
                ),
                actions: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary, width: 1.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text('Cancel', style: AppTypography.button.copyWith(color: AppColors.primary)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text('Add', style: AppTypography.button.copyWith(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
            if (confirm != true) return;
          }
          _items.add(InvoiceItem(
            itemType: 'vehicle', itemId: vehicle.id, itemCode: code,
            itemName: comboName,
            hsnCode: hsn, gstSlab: gstSlab,
            quantity: take.toDouble(), unitPrice: comboPrice,
            isGstInclusive: true,
          ));
          _recalculateItem(_items.length - 1);
          need -= take;
        }
        batt['qty'] = need;
      }
    }

    if (mounted) {
      AppSnackBars.showSuccess(context, '${_items.length} items added');
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
                _itemDetail('Qty', item.quantity.toInt().toString()),
                const SizedBox(width: 16),
                _itemDetail('Rate', '₹${item.unitPrice.toStringAsFixed(0)}'),
                const SizedBox(width: 16),
                _itemDetail('GST', '${item.gstSlab}%'),
                const Spacer(),
                Text('₹${item.total.toStringAsFixed(2)}', style: AppTypography.h3.copyWith(color: AppColors.primary, fontSize: 14)),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Taxable: ₹${item.taxableValue.toStringAsFixed(2)}',
                style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted),
              ),
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
