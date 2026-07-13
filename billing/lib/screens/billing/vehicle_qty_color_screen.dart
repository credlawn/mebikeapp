import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';

class VehicleQtyColorScreen extends StatefulWidget {
  final dynamic vehicleRecord;
  const VehicleQtyColorScreen({super.key, required this.vehicleRecord});

  @override
  State<VehicleQtyColorScreen> createState() => _VehicleQtyColorScreenState();
}

class _VehicleQtyColorScreenState extends State<VehicleQtyColorScreen> {
  final _totalQtyCtrl = TextEditingController();
  final _colorQtys = <TextEditingController>[];
  late List<String> _colors;

  @override
  void initState() {
    super.initState();
    final String raw = widget.vehicleRecord.getStringValue('color');
    _colors = raw.split(',').map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
    for (var i = 0; i < _colors.length; i++) {
      _colorQtys.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _totalQtyCtrl.dispose();
    for (final c in _colorQtys) { c.dispose(); }
    super.dispose();
  }

  int get _totalQty => int.tryParse(_totalQtyCtrl.text) ?? 0;
  int get _colorSum {
    var s = 0;
    for (final c in _colorQtys) {
      s += int.tryParse(c.text) ?? 0;
    }
    return s;
  }

  bool get _isValid => _totalQty > 0 && _colorSum == _totalQty;

  void _next() {
    if (!_isValid) return;
    final colors = <Map<String, dynamic>>[];
    for (var i = 0; i < _colors.length; i++) {
      final qty = int.tryParse(_colorQtys[i].text) ?? 0;
      if (qty > 0) {
        colors.add({'color': _colors[i], 'qty': qty});
      }
    }
    Navigator.of(context).pop({
      'vehicle': widget.vehicleRecord,
      'totalQty': _totalQty,
      'colorEntries': colors,
    });
  }

  @override
  Widget build(BuildContext context) {
    final String fn = widget.vehicleRecord.getStringValue('full_name');
    final String nn = widget.vehicleRecord.getStringValue('name');
    final String name = fn.isNotEmpty ? fn : nn;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Vehicle Details'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: AppTypography.h2),
            const SizedBox(height: 24),
            TextField(
              controller: _totalQtyCtrl,
              decoration: const InputDecoration(
                labelText: 'Total Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            Container(height: 1, color: AppColors.border),
            const SizedBox(height: 16),
            Text('Color Distribution', style: AppTypography.h3),
            const SizedBox(height: 12),
            ...List.generate(_colors.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(width: 100, child: Text(_colors[i], style: AppTypography.bodyLarge)),
                    const Spacer(),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: _colorQtys[i],
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: AppTypography.h3),
                Text(
                  '$_colorSum / $_totalQty',
                  style: AppTypography.h3.copyWith(
                    color: _colorSum == _totalQty && _totalQty > 0
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isValid ? _next : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Next: Add Batteries', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
