import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/inventory/vehicle_model.dart';
import '../../../models/inventory/color_item_model.dart';
import '../../../providers/inventory/inventory_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/app_snackbars.dart';

class AddVehicleScreen extends ConsumerStatefulWidget {
  final Vehicle? editItem;
  const AddVehicleScreen({super.key, this.editItem});

  @override
  ConsumerState<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends ConsumerState<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _variantCtrl = TextEditingController();
  final _sellingPriceCtrl = TextEditingController();
  final _hsnCtrl = TextEditingController();
  String _vehicleType = '';
  final _selectedColorIds = <String>{};
  int _gstSlab = -1;
  bool _isLoading = false;
  bool _isAddingColor = false;
  final _newColorCtrl = TextEditingController();

  static const _gstOptions = [0, 5, 12, 18, 28];
  static const _vehicleOptions = ['BIKE', 'SCOOTER'];

  @override
  void initState() {
    super.initState();
    final e = widget.editItem;
    if (e != null) {
      _nameCtrl.text = e.name;
      _variantCtrl.text = '';
      _sellingPriceCtrl.text = e.sellingPrice > 0 ? e.sellingPrice.toStringAsFixed(0) : '';
      _hsnCtrl.text = e.hsnCode;
      _vehicleType = e.vehicleType;
      _gstSlab = e.gstSlab;
      if (e.color.isNotEmpty) {
        _selectedColorIds.addAll(e.color.split(',').map((c) => c.trim()));
      }
    } else {
      _prefillHsn();
    }
    _nameCtrl.addListener(() { if (mounted) setState(() {}); });
    _variantCtrl.addListener(() { if (mounted) setState(() {}); });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _variantCtrl.dispose();
    _sellingPriceCtrl.dispose();
    _hsnCtrl.dispose();
    _newColorCtrl.dispose();
    super.dispose();
  }

  String _generateFullName(String variant) {
    final n = _nameCtrl.text.trim().toUpperCase();
    final vt = _vehicleType.isNotEmpty ? ' - $_vehicleType' : '';
    final v = variant.isNotEmpty ? ' - $variant' : '';
    return 'ME $n$vt$v';
  }

  Future<void> _prefillHsn() async {
    try {
      final records = await ref.read(inventoryRepositoryProvider).getAllVehicles();
      if (records.isNotEmpty && records.first.hsnCode.isNotEmpty) {
        _hsnCtrl.text = records.first.hsnCode;
      }
    } catch (_) {}
  }

  Future<void> _addColorToCollection() async {
    final name = _newColorCtrl.text.trim().toUpperCase();
    if (name.isEmpty) return;
    try {
      final existing = await ref.read(inventoryRepositoryProvider).getAllColors();
      final isDuplicate = existing.any((c) => c.name.toUpperCase() == name);
      if (isDuplicate) {
        if (mounted) AppSnackBars.showError(context, 'Color "$name" already exists');
        return;
      }
      await ref.read(inventoryRepositoryProvider).createColor({'name': name, 'status': 'active'});
      ref.invalidate(allColorsProvider);
      _newColorCtrl.clear();
      _selectedColorIds.add(name);
      setState(() => _isAddingColor = false);
      if (mounted) AppSnackBars.showSuccess(context, 'Color added');
    } catch (_) {
      if (mounted) AppSnackBars.showError(context, 'Cannot reach server');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_vehicleType.isEmpty) {
      if (mounted) AppSnackBars.showError(context, 'Please select a vehicle type');
      return;
    }
    if (_selectedColorIds.isEmpty) {
      if (mounted) AppSnackBars.showError(context, 'Please select at least one color');
      return;
    }
    if (_gstSlab < 0) {
      if (mounted) AppSnackBars.showError(context, 'Please select a GST slab');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(inventoryRepositoryProvider);
      final variant = _variantCtrl.text.trim().toUpperCase();
      final fullName = _generateFullName(variant);

      final existing = await repo.getAllVehicles();
      final isDuplicate = existing.any((v) =>
        v.id != widget.editItem?.id &&
        v.fullName.trim().toLowerCase() == fullName.toLowerCase()
      );
      if (isDuplicate) {
        if (mounted) AppSnackBars.showError(context, 'Vehicle "$fullName" already exists');
        setState(() => _isLoading = false);
        return;
      }

      final body = {
        'item_code': widget.editItem?.itemCode ?? '',
        'name': _nameCtrl.text.trim().toUpperCase(),
        'full_name': fullName,
        'vehicle_type': _vehicleType.isEmpty ? null : _vehicleType,
        'color': _selectedColorIds.join(','),
        'selling_price': double.tryParse(_sellingPriceCtrl.text.trim()) ?? 0,
        'gst_slab': _gstSlab,
        'hsn_code': _hsnCtrl.text.trim().isEmpty ? null : _hsnCtrl.text.trim(),
        'status': widget.editItem?.status ?? 'active',
      };
      if (widget.editItem != null) {
        await repo.updateVehicle(widget.editItem!.id, body);
      } else {
        body['item_code'] = await _getNextCode();
        await repo.createVehicle(body);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => ref.invalidate(allVehiclesProvider));
      if (mounted) AppSnackBars.showSuccess(context, widget.editItem != null ? 'Vehicle updated' : 'Vehicle added');
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) AppSnackBars.showError(context, 'Cannot reach server');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String> _getNextCode() async {
    try {
      final records = await ref.read(inventoryRepositoryProvider).getAllVehicles();
      if (records.isEmpty) return 'VEH0001';
      final lastCode = records.first.itemCode;
      if (!lastCode.startsWith('VEH')) return 'VEH0001';
      final num = int.tryParse(lastCode.substring(3)) ?? 0;
      return 'VEH${(num + 1).toString().padLeft(4, '0')}';
    } catch (_) {
      return 'VEH0001';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(allColorsProvider).value ?? <ColorItem>[];
    final autoFullName = _generateFullName(_variantCtrl.text.trim().toUpperCase());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.editItem != null ? 'Edit Vehicle' : 'Add Vehicle'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: _isLoading ? null : _save,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                child: _isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Save', style: AppTypography.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
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
              Text('Vehicle Details', style: AppTypography.h2),
              const SizedBox(height: 24),
              Text('GST Slab *', style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _gstOptions.map((slab) {
                  final selected = _gstSlab == slab;
                  return GestureDetector(
                    onTap: () => setState(() => _gstSlab = slab),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 1),
                      ),
                      child: Text('$slab%', style: AppTypography.bodyMedium.copyWith(
                        color: selected ? Colors.white : AppColors.textSecondary,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              _buildField('HSN Code *', _hsnCtrl, Icons.receipt_long_outlined, 'Required', keyboardType: TextInputType.number),
              const SizedBox(height: 20),
              _buildField('Name *', _nameCtrl, Icons.directions_car_rounded, 'Required', textCapitalization: TextCapitalization.characters),
              const SizedBox(height: 20),
              _buildField('Variant (Leave blank if no variant)', _variantCtrl, Icons.tune_outlined, null, textCapitalization: TextCapitalization.characters),
              const SizedBox(height: 20),
              _buildField('Selling Price (₹) *', _sellingPriceCtrl, Icons.currency_rupee_rounded, 'Required', keyboardType: TextInputType.number),
              const SizedBox(height: 24),
              Text('Vehicle Type *', style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6, runSpacing: 6,
                children: _vehicleOptions.map((opt) {
                  final selected = _vehicleType == opt;
                  return GestureDetector(
                    onTap: () => setState(() => _vehicleType = selected ? '' : opt),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 1),
                      ),
                      child: Text(opt, style: AppTypography.bodySmall.copyWith(
                        color: selected ? Colors.white : AppColors.textSecondary,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text('Colors *', style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6, runSpacing: 6,
                children: [
                  ...colors.map((c) {
                    final selected = _selectedColorIds.contains(c.name);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (selected) {
                            _selectedColorIds.remove(c.name);
                          } else {
                            _selectedColorIds.add(c.name);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 1),
                        ),
                        child: Text(c.name, style: AppTypography.bodySmall.copyWith(
                          color: selected ? Colors.white : AppColors.textSecondary,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                      ),
                    );
                  }),
                  if (!_isAddingColor)
                    GestureDetector(
                      onTap: () => setState(() => _isAddingColor = true),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                      ),
                    ),
                ],
              ),
              if (_isAddingColor)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Expanded(child: SizedBox(
                        height: 40,
                        child: TextField(
                          controller: _newColorCtrl,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: 'Color name', hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                            filled: true, fillColor: AppColors.background,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          style: AppTypography.input,
                        ),
                      )),
                      const SizedBox(width: 8),
                      SizedBox(height: 40, child: ElevatedButton(
                        onPressed: _addColorToCollection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
                      )),
                      const SizedBox(width: 8),
                      SizedBox(height: 40, child: OutlinedButton(
                        onPressed: () => setState(() { _isAddingColor = false; _newColorCtrl.clear(); }),
                        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                      )),
                    ],
                  ),
                ),
              if (autoFullName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Flexible(child: Text('Name: $autoFullName',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, String? error, {TextInputType? keyboardType, TextCapitalization textCapitalization = TextCapitalization.none}) {
    return TextFormField(
      controller: ctrl, keyboardType: keyboardType, textCapitalization: textCapitalization,
      style: AppTypography.input,
      decoration: InputDecoration(
        labelText: label, labelStyle: AppTypography.bodySmall,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
        filled: true, fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: error != null ? (v) => v!.isEmpty ? error : null : null,
    );
  }
}
