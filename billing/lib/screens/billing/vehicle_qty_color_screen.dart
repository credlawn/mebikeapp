import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../pb_service.dart';
import '../../theme/app_snackbars.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';

class VehicleQtyColorScreen extends StatefulWidget {
  final dynamic vehicleRecord;
  const VehicleQtyColorScreen({super.key, required this.vehicleRecord});

  @override
  State<VehicleQtyColorScreen> createState() => _VehicleQtyColorScreenState();
}

class _ColorEntry {
  final String name;
  int qty;
  _ColorEntry({required this.name, this.qty = 0});
}

class _VehicleQtyColorScreenState extends State<VehicleQtyColorScreen> {
  final _totalQtyCtrl = TextEditingController();
  final _addQtyCtrl = TextEditingController();
  final _colorSearchCtrl = TextEditingController();
  final _colorFocus = FocusNode();
  final _selected = <_ColorEntry>[];
  late List<String> _allColors;
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    final String raw = widget.vehicleRecord.getStringValue('color');
    _allColors = raw.split(',').map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
    _colorSearchCtrl.addListener(_onColorSearchChanged);
  }

  @override
  void dispose() {
    _totalQtyCtrl.dispose();
    _addQtyCtrl.dispose();
    _colorSearchCtrl.removeListener(_onColorSearchChanged);
    _colorSearchCtrl.dispose();
    _colorFocus.dispose();
    super.dispose();
  }

  int get _totalQty => int.tryParse(_totalQtyCtrl.text) ?? 0;
  int get _colorSum => _selected.fold(0, (s, e) => s + e.qty);
  int get _remaining => _totalQty - _colorSum;
  bool get _isValid => _totalQty > 0 && _colorSum == _totalQty;

  List<String> get _availableColors =>
      _allColors.where((c) => !_selected.any((e) => e.name == c)).toList();

  bool get _showAddNew {
    final input = _colorSearchCtrl.text.trim();
    return input.isNotEmpty
        && _suggestions.isEmpty
        && !_allColors.any((c) => c.toLowerCase() == input.toLowerCase());
  }

  Future<void> _addNewColor() async {
    final color = _colorSearchCtrl.text.trim().toUpperCase();
    if (color.isEmpty) return;

    final String fn = widget.vehicleRecord.getStringValue('full_name');
    final String nn = widget.vehicleRecord.getStringValue('name');
    final String vName = fn.isNotEmpty ? fn : nn;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        content: SizedBox(
          width: MediaQuery.of(ctx).size.width - 88,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.color_lens_outlined, color: AppColors.primary, size: 32),
              ),
              const SizedBox(height: 24),
              Text('Add "$color"', style: AppTypography.h2.copyWith(fontSize: 20), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'to $vName?',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
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
    if (confirmed != true) return;
    try {
      final existing = widget.vehicleRecord.getStringValue('color');
      final updated = existing.isEmpty ? color : '$existing,$color';
      await PbService().pb.collection('vehicle').update(
        widget.vehicleRecord.id,
        body: {'color': updated},
      );
      _allColors.add(color);
      if (mounted) AppSnackBars.showSuccess(context, 'Added "$color"');
    } catch (_) {
      if (mounted) AppSnackBars.showError(context, 'Failed to save color');
      return;
    }
    setState(() {
      _colorSearchCtrl.text = color;
      _colorSearchCtrl.selection = TextSelection.collapsed(offset: color.length);
      _suggestions = [];
    });
    _colorFocus.unfocus();
  }

  void _onColorSearchChanged() {
    final input = _colorSearchCtrl.text.trim().toLowerCase();
    if (input.isEmpty) {
      setState(() => _suggestions = []);
    } else {
      setState(() {
        _suggestions = _availableColors
            .where((c) => c.toLowerCase().contains(input))
            .toList();
      });
    }
  }

  void _selectSuggestion(String color) {
    setState(() {
      _colorSearchCtrl.text = color;
      _colorSearchCtrl.selection = TextSelection.collapsed(offset: color.length);
      _suggestions = [];
    });
    _colorFocus.unfocus();
  }

  void _addColor() {
    final color = _colorSearchCtrl.text.trim();
    if (color.isEmpty || !_availableColors.any((c) => c.toLowerCase() == color.toLowerCase())) return;
    final qty = int.tryParse(_addQtyCtrl.text) ?? 1;
    if (qty <= 0 || qty > _remaining) return;
    setState(() {
      _selected.add(_ColorEntry(name: color, qty: qty));
      _colorSearchCtrl.clear();
      _addQtyCtrl.clear();
      _suggestions = [];
    });
  }

  void _removeColor(int i) {
    setState(() => _selected.removeAt(i));
  }

  void _next() {
    if (!_isValid) return;
    final colors = _selected.map((e) => <String, dynamic>{
      'color': e.name,
      'qty': e.qty,
    }).toList();
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
      appBar: AppBar(
        title: Text(name, style: AppTypography.h3),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _totalQtyCtrl,
              decoration: InputDecoration(
                labelText: 'Total Quantity',
                labelStyle: AppTypography.bodySmall,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: AppTypography.input,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
            ),
            if (_totalQty > 0) ...[
              const SizedBox(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Add Color', style: AppTypography.h3),
                      if (_totalQty > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _remaining > 0
                                ? Colors.orange.withValues(alpha: 0.08)
                                : AppColors.success.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _remaining > 0 ? '$_remaining Remaining' : 'Done',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 12,
                              color: _remaining > 0 ? Colors.orange : AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFormField(
                              controller: _colorSearchCtrl,
                              focusNode: _colorFocus,
                              textCapitalization: TextCapitalization.words,
                              style: AppTypography.input,
                              decoration: InputDecoration(
                                hintText: 'Search color',
                                hintStyle: AppTypography.bodySmall,
                                prefixIcon: Icon(Icons.color_lens_outlined, size: 18, color: AppColors.textSecondary),
                                filled: true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                            if (_suggestions.isNotEmpty)
                              Container(
                                constraints: const BoxConstraints(maxHeight: 160),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
                                ),
                                child: ListView.separated(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: _suggestions.length,
                                  separatorBuilder: (_, _) => const Divider(height: 1, indent: 16),
                                  itemBuilder: (_, i) {
                                    final option = _suggestions[i];
                                    return ListTile(
                                      dense: true,
                                      visualDensity: VisualDensity.compact,
                                      title: Text(option, style: AppTypography.bodyMedium.copyWith(fontSize: 13)),
                                      onTap: () => _selectSuggestion(option),
                                    );
                                  },
                                ),
                              ),
                            if (_showAddNew)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
                                ),
                                child: ListTile(
                                  dense: true,
                                  visualDensity: VisualDensity.compact,
                                  leading: Icon(Icons.add_circle_outline, size: 18, color: AppColors.primary),
                                  title: Text(
                                    'Add "${_colorSearchCtrl.text.trim().toUpperCase()}" to list',
                                    style: AppTypography.bodyMedium.copyWith(fontSize: 13, color: AppColors.primary),
                                  ),
                                  onTap: _addNewColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _addQtyCtrl,
                          decoration: InputDecoration(
                            hintText: 'Qty',
                            hintStyle: AppTypography.bodySmall,
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                          style: AppTypography.input,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _colorSearchCtrl.text.trim().isNotEmpty &&
                              _availableColors.any((c) => c.toLowerCase() == _colorSearchCtrl.text.trim().toLowerCase()) &&
                              _remaining > 0 &&
                              (int.tryParse(_addQtyCtrl.text) ?? 0) > 0
                              ? _addColor
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: const Icon(Icons.add_rounded, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),

            if (_selected.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Colors', style: AppTypography.h3),
                  Text(
                    '$_colorSum / $_totalQty',
                    style: AppTypography.h3.copyWith(
                      color: _totalQty > 0
                          ? (_colorSum == _totalQty ? AppColors.success : AppColors.warning)
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...List.generate(_selected.length, (i) {
                final e = _selected[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.textMuted,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(e.name, style: AppTypography.bodyLarge),
                        const Spacer(),
                        Text('× ${e.qty}', style: AppTypography.h3.copyWith(color: AppColors.primary)),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _removeColor(i),
                          child: Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
            const SizedBox(height: 24),
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
                child: const Text('Next: Batteries', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
