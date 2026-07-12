import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/inventory/accessory_model.dart';
import '../../../providers/inventory/inventory_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/app_snackbars.dart';

class AddAccessoryScreen extends ConsumerStatefulWidget {
  final Accessory? editItem;
  const AddAccessoryScreen({super.key, this.editItem});

  @override
  ConsumerState<AddAccessoryScreen> createState() => _AddAccessoryScreenState();
}

class _AddAccessoryScreenState extends ConsumerState<AddAccessoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _variantCtrl = TextEditingController();
  final _sellingPriceCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _hsnCtrl = TextEditingController();
  int _gstSlab = -1;
  bool _isLoading = false;

  static const _gstOptions = [0, 5, 12, 18, 28];

  @override
  void initState() {
    super.initState();
    final e = widget.editItem;
    if (e != null) {
      _nameCtrl.text = e.name;
      _variantCtrl.text = e.variant;
      _sellingPriceCtrl.text = e.sellingPrice > 0 ? e.sellingPrice.toStringAsFixed(0) : '';
      _weightCtrl.text = e.weight > 0 ? e.weight.toStringAsFixed(1) : '';
      _hsnCtrl.text = e.hsnCode;
      _gstSlab = e.gstSlab;
    }
    _nameCtrl.addListener(() { if (mounted) setState(() {}); });
    _variantCtrl.addListener(() { if (mounted) setState(() {}); });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _variantCtrl.dispose();
    _sellingPriceCtrl.dispose();
    _weightCtrl.dispose();
    _hsnCtrl.dispose();
    super.dispose();
  }

  String _generateFullName() {
    final n = _nameCtrl.text.trim();
    final v = _variantCtrl.text.trim();
    return v.isNotEmpty ? 'ME $n - $v' : 'ME $n';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_gstSlab < 0) {
      if (mounted) AppSnackBars.showError(context, 'Please select a GST slab');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(inventoryRepositoryProvider);
      final body = {
        'item_code': widget.editItem?.itemCode ?? '',
        'full_name': _generateFullName(),
        'name': _nameCtrl.text.trim(),
        'variant': _variantCtrl.text.trim().isEmpty ? null : _variantCtrl.text.trim(),
        'selling_price': double.tryParse(_sellingPriceCtrl.text.trim()) ?? 0,
        'weight': double.tryParse(_weightCtrl.text.trim()) ?? 0,
        'gst_slab': _gstSlab,
        'hsn_code': _hsnCtrl.text.trim().isEmpty ? null : _hsnCtrl.text.trim(),
        'status': widget.editItem?.status ?? 'active',
      };
      if (widget.editItem != null) {
        await repo.updateAccessory(widget.editItem!.id, body);
      } else {
        body['item_code'] = await _getNextCode();
        await repo.createAccessory(body);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => ref.invalidate(allAccessoriesProvider));
      if (mounted) AppSnackBars.showSuccess(context, widget.editItem != null ? 'Accessory updated' : 'Accessory added');
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) AppSnackBars.showError(context, 'Cannot reach server');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String> _getNextCode() async {
    try {
      final records = await ref.read(inventoryRepositoryProvider).getAllAccessories();
      if (records.isEmpty) return 'ACC0001';
      final lastCode = records.first.itemCode;
      if (!lastCode.startsWith('ACC')) return 'ACC0001';
      final num = int.tryParse(lastCode.substring(3)) ?? 0;
      return 'ACC${(num + 1).toString().padLeft(4, '0')}';
    } catch (_) {
      return 'ACC0001';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.editItem != null ? 'Edit Accessory' : 'Add Accessory'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: _isLoading ? null : _save,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
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
              Text('Accessory Details', style: AppTypography.h2),
              const SizedBox(height: 24),
              Text('GST Slab *', style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _gstOptions.map((slab) {
                  final selected = _gstSlab == slab;
                  return GestureDetector(
                    onTap: () => setState(() => _gstSlab = slab),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? AppColors.primary : AppColors.border,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        '$slab%',
                        style: AppTypography.bodyMedium.copyWith(
                          color: selected ? Colors.white : AppColors.textSecondary,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              _buildField('HSN Code *', _hsnCtrl, Icons.receipt_long_outlined, 'Required', keyboardType: TextInputType.number),
              const SizedBox(height: 20),
              _buildField('Name *', _nameCtrl, Icons.backpack_rounded, 'Required', textCapitalization: TextCapitalization.characters),
              const SizedBox(height: 20),
              _buildField('Variant (Leave blank if no variant)', _variantCtrl, Icons.tune_outlined, null, textCapitalization: TextCapitalization.characters),
              if (_nameCtrl.text.trim().isNotEmpty || _variantCtrl.text.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text('Name: ${_generateFullName()}',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              _buildField('Selling Price (₹) *', _sellingPriceCtrl, Icons.currency_rupee_rounded, 'Required', keyboardType: TextInputType.number),
              const SizedBox(height: 20),
              _buildField('Weight (kg) *', _weightCtrl, Icons.monitor_weight_outlined, 'Required', keyboardType: TextInputType.number),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, String? error, {TextInputType? keyboardType, TextCapitalization textCapitalization = TextCapitalization.none}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: AppTypography.input,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.bodySmall,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
        filled: true, fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: error != null ? (v) => v!.isEmpty ? error : null : null,
    );
  }
}
