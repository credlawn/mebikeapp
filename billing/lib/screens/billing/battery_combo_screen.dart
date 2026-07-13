import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_snackbars.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import 'item_select_screen.dart';

class BatteryComboEntry {
  final dynamic batteryRecord;
  int qty;
  double unitPrice;
  BatteryComboEntry({required this.batteryRecord, this.qty = 1, this.unitPrice = 0});
}

class BatteryComboScreen extends StatefulWidget {
  final dynamic vehicleRecord;
  final int totalQty;
  final List<Map<String, dynamic>> colorEntries;
  const BatteryComboScreen({
    super.key,
    required this.vehicleRecord,
    required this.totalQty,
    required this.colorEntries,
  });

  @override
  State<BatteryComboScreen> createState() => _BatteryComboScreenState();
}

class _BatteryComboScreenState extends State<BatteryComboScreen> {
  final _entries = <BatteryComboEntry>[];

  int get _batterySum {
    var s = 0;
    for (final e in _entries) { s += e.qty; }
    return s;
  }
  int get _remaining => widget.totalQty - _batterySum;
  bool get _canAddToInvoice => _entries.isNotEmpty && _remaining == 0;

  Future<void> _addBattery() async {
    final rec = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(builder: (_) => const ItemSelectScreen(itemType: 'battery')),
    );
    if (rec == null || !mounted) return;
    if (_entries.any((e) => e.batteryRecord.id == rec.id)) {
      AppSnackBars.showError(context, 'Battery already added');
      return;
    }

    final result = await _showEntryDialog(batteryRecord: rec);
    if (result != null && mounted) {
      setState(() => _entries.add(result));
    }
  }

  Future<void> _editEntry(int index) async {
    final result = await _showEntryDialog(
      batteryRecord: _entries[index].batteryRecord,
      initialQty: _entries[index].qty,
      initialPrice: _entries[index].unitPrice,
    );
    if (result != null && mounted) {
      setState(() {
        _entries[index].qty = result.qty;
        _entries[index].unitPrice = result.unitPrice;
      });
    }
  }

  Future<BatteryComboEntry?> _showEntryDialog({
    required dynamic batteryRecord,
    int initialQty = 1,
    double initialPrice = 0,
  }) async {
    final qtyCtrl = TextEditingController(text: initialQty.toString());
    final priceCtrl = TextEditingController(
      text: initialPrice > 0 ? initialPrice.toStringAsFixed(0) : '',
    );

    final String bFn = batteryRecord.getStringValue('full_name');
    final String bNm = batteryRecord.getStringValue('name');
    final String bName = bFn.isNotEmpty ? bFn : bNm;

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
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.battery_charging_full_outlined, color: AppColors.primary, size: 24),
            ),
            const SizedBox(height: 16),
            Text(bName, style: AppTypography.h3, textAlign: TextAlign.center),
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

    final qty = int.tryParse(qtyCtrl.text) ?? 0;
    final price = double.tryParse(priceCtrl.text) ?? 0;

    if (confirmed != true || qty <= 0) return null;
    return BatteryComboEntry(batteryRecord: batteryRecord, qty: qty, unitPrice: price);
  }

  void _removeEntry(int index) {
    setState(() => _entries.removeAt(index));
  }

  void _done() {
    if (!_canAddToInvoice) return;
    Navigator.of(context).pop({
      'batteryCombos': _entries.map((e) => {
        'batteryRecord': e.batteryRecord,
        'qty': e.qty,
        'unitPrice': e.unitPrice,
      }).toList(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final String vFn = widget.vehicleRecord.getStringValue('full_name');
    final String vNn = widget.vehicleRecord.getStringValue('name');
    final String vName = vFn.isNotEmpty ? vFn : vNn;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Add Batteries', style: AppTypography.h3),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _remaining == 0
                  ? AppColors.success.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _remaining > 0 ? '$_remaining Left' : 'Done',
              style: AppTypography.bodySmall.copyWith(
                fontSize: 12,
                color: _remaining == 0 ? AppColors.success : Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Vehicle info bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.04),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Icon(Icons.electric_scooter_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$vName × ${widget.totalQty}',
                    style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Add battery button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _remaining > 0 ? _addBattery : null,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text('Add Battery', style: AppTypography.button),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // Battery list
          Expanded(
            child: _entries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.battery_charging_full_outlined, size: 40, color: AppColors.textMuted.withValues(alpha: 0.3)),
                        const SizedBox(height: 8),
                        Text('Tap "Add Battery" to begin', style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    itemCount: _entries.length,
                    itemBuilder: (_, i) {
                      final entry = _entries[i];
                      final String bFn = entry.batteryRecord.getStringValue('full_name');
                      final String bNm = entry.batteryRecord.getStringValue('name');
                      final String bName = bFn.isNotEmpty ? bFn : bNm;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: InkWell(
                          onTap: () => _editEntry(i),
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.battery_charging_full_outlined, size: 16, color: AppColors.primary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(bName, style: AppTypography.bodyLarge),
                                      const SizedBox(height: 2),
                                      Text(
                                        '× ${entry.qty}  •  ₹${entry.unitPrice.toStringAsFixed(0)}/unit',
                                        style: AppTypography.bodySmall.copyWith(fontSize: 12, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _removeEntry(i),
                                  child: Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total assigned', style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
                    Text(
                      '$_batterySum / ${widget.totalQty}',
                      style: AppTypography.h3.copyWith(
                        color: _remaining == 0 ? AppColors.success : Colors.orange,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _canAddToInvoice ? _done : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Add to Invoice', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
