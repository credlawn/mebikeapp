import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_snackbars.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import 'item_select_screen.dart';

class BatteryComboEntry {
  final dynamic batteryRecord;
  int qty;
  double totalPrice;
  final qtyCtrl = TextEditingController(text: '1');
  final priceCtrl = TextEditingController();
  BatteryComboEntry({required this.batteryRecord, this.qty = 1, this.totalPrice = 0});

  void dispose() {
    qtyCtrl.dispose();
    priceCtrl.dispose();
  }
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

  @override
  void dispose() {
    for (final e in _entries) { e.dispose(); }
    super.dispose();
  }

  int get _batterySum {
    var s = 0;
    for (final e in _entries) {
      s += e.qty;
    }
    return s;
  }
  int get _remaining => widget.totalQty - _batterySum;

  Future<void> _addBattery() async {
    final rec = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(builder: (_) => const ItemSelectScreen(itemType: 'battery')),
    );
    if (rec == null || !mounted) return;

    if (_entries.any((e) => e.batteryRecord.id == rec.id)) {
      AppSnackBars.showError(context, 'Battery already added');
      return;
    }

    setState(() {
      _entries.add(BatteryComboEntry(batteryRecord: rec));
    });
  }

  void _removeEntry(int index) {
    setState(() => _entries.removeAt(index));
  }

  bool get _canAddToInvoice => _entries.isNotEmpty && _remaining == 0;

  void _done() {
    if (!_canAddToInvoice) return;
    Navigator.of(context).pop({
      'batteryCombos': _entries.map((e) => {
        'batteryRecord': e.batteryRecord,
        'qty': e.qty,
        'totalPrice': e.totalPrice,
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
      appBar: AppBar(title: const Text('Battery Combo'), elevation: 0),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: AppColors.primary.withValues(alpha: 0.04),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$vName × ${widget.totalQty}', style: AppTypography.h3),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _remaining == 0 ? AppColors.success.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Left: $_remaining',
                    style: AppTypography.bodySmall.copyWith(
                      color: _remaining == 0 ? AppColors.success : Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _entries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.battery_charging_full_outlined, size: 48, color: AppColors.textMuted.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text('No batteries added yet', style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    itemCount: _entries.length,
                    itemBuilder: (_, i) {
                      final entry = _entries[i];
                      final String bFn = entry.batteryRecord.getStringValue('full_name');
                      final String bNn = entry.batteryRecord.getStringValue('name');
                      final String bName = bFn.isNotEmpty ? bFn : bNn;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.battery_charging_full_outlined, size: 18, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(bName, style: AppTypography.h3.copyWith(fontSize: 14))),
                                  InkWell(
                                    onTap: () => _removeEntry(i),
                                    child: const Icon(Icons.close_rounded, size: 18, color: AppColors.error),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      decoration: const InputDecoration(
                                        labelText: 'Qty',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                      ),
                                      controller: entry.qtyCtrl,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      onChanged: (v) {
                                        final q = int.tryParse(v) ?? 0;
                                        if (q <= _remaining + _entries[i].qty) {
                                          setState(() => _entries[i].qty = q);
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      decoration: const InputDecoration(
                                        labelText: 'Total Price',
                                        prefix: Text('₹ '),
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                      ),
                                      controller: entry.priceCtrl,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                                      onChanged: (v) {
                                        setState(() => _entries[i].totalPrice = double.tryParse(v) ?? 0);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              children: [
                SizedBox(
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
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _remaining == 0 ? AppColors.success.withValues(alpha: 0.08) : Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Battery Qty Total', style: AppTypography.bodyMedium),
                      Text(
                        '$_batterySum / ${widget.totalQty}',
                        style: AppTypography.h3.copyWith(
                          color: _remaining == 0 ? AppColors.success : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
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
