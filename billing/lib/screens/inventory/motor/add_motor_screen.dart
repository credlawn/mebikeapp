import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/inventory/motor_model.dart';
import '../../../providers/inventory/inventory_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/app_snackbars.dart';

class AddMotorScreen extends ConsumerStatefulWidget {
  final Motor? editItem;
  const AddMotorScreen({super.key, this.editItem});

  @override
  ConsumerState<AddMotorScreen> createState() => _AddMotorScreenState();
}

class _AddMotorScreenState extends ConsumerState<AddMotorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _powerWattCtrl = TextEditingController();
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
      _powerWattCtrl.text = e.powerWatt;
      _variantCtrl.text = e.variant;
      _sellingPriceCtrl.text = e.sellingPrice > 0 ? e.sellingPrice.toStringAsFixed(0) : '';
      _weightCtrl.text = e.weight > 0 ? e.weight.toStringAsFixed(1) : '';
      _hsnCtrl.text = e.hsnCode;
      _gstSlab = e.gstSlab;
    } else {
      _prefillHsn();
    }
    _powerWattCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _variantCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _powerWattCtrl.dispose();
    _variantCtrl.dispose();
    _sellingPriceCtrl.dispose();
    _weightCtrl.dispose();
    _hsnCtrl.dispose();
    super.dispose();
  }

  String _generateFullName() {
    final v = _variantCtrl.text.trim();
    final watt = _powerWattCtrl.text.trim();
    final prefix = v.isNotEmpty ? 'ME $v Motor' : 'ME Motor';
    return watt.isNotEmpty ? '$prefix - ${watt}W' : prefix;
  }

  Future<void> _prefillHsn() async {
    try {
      final records = await ref.read(inventoryRepositoryProvider).getAllMotors();
      if (records.isNotEmpty && records.first.hsnCode.isNotEmpty) {
        _hsnCtrl.text = records.first.hsnCode;
      }
    } catch (_) {}
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
      final fullName = _generateFullName();

      final existing = await repo.getAllMotors();
      final isDuplicate = existing.any((m) =>
        m.id != widget.editItem?.id &&
        m.name.trim().toLowerCase() == fullName.toLowerCase()
      );
      if (isDuplicate) {
        if (mounted) AppSnackBars.showError(context, 'Motor "$fullName" already exists');
        setState(() => _isLoading = false);
        return;
      }

      final body = {
        'item_code': widget.editItem?.itemCode ?? '',
        'name': fullName,
        'variant': _variantCtrl.text.trim().isEmpty ? null : _variantCtrl.text.trim(),
        'power_watt': _powerWattCtrl.text.trim().isEmpty ? null : _powerWattCtrl.text.trim(),
        'selling_price': double.tryParse(_sellingPriceCtrl.text.trim()) ?? 0,
        'weight': double.tryParse(_weightCtrl.text.trim()) ?? 0,
        'gst_slab': _gstSlab,
        'hsn_code': _hsnCtrl.text.trim().isEmpty ? null : _hsnCtrl.text.trim(),
        'status': widget.editItem?.status ?? 'active',
      };
      if (widget.editItem != null) {
        await repo.updateMotor(widget.editItem!.id, body);
      } else {
        body['item_code'] = await _getNextCode();
        await repo.createMotor(body);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => ref.invalidate(allMotorsProvider));
      if (mounted) AppSnackBars.showSuccess(context, widget.editItem != null ? 'Motor updated' : 'Motor added');
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) AppSnackBars.showError(context, 'Cannot reach server');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String> _getNextCode() async {
    try {
      final records = await ref.read(inventoryRepositoryProvider).getAllMotors();
      if (records.isEmpty) return 'MOT0001';
      final lastCode = records.first.itemCode;
      if (!lastCode.startsWith('MOT')) return 'MOT0001';
      final num = int.tryParse(lastCode.substring(3)) ?? 0;
      return 'MOT${(num + 1).toString().padLeft(4, '0')}';
    } catch (_) {
      return 'MOT0001';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.editItem != null ? 'Edit Motor' : 'Add Motor'),
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
              Text('Motor Details', style: AppTypography.h2),
              const SizedBox(height: 24),
              _buildField('HSN Code *', _hsnCtrl, Icons.receipt_long_outlined, 'Required', keyboardType: TextInputType.number),
              const SizedBox(height: 20),
              _buildField('Weight (kg) *', _weightCtrl, Icons.monitor_weight_outlined, 'Required', keyboardType: TextInputType.number),
              const SizedBox(height: 20),
              _buildField('Power in Watt *', _powerWattCtrl, Icons.speed_rounded, 'Required', keyboardType: TextInputType.number),
              const SizedBox(height: 20),
              _buildField('Selling Price (₹) *', _sellingPriceCtrl, Icons.currency_rupee_rounded, 'Required', keyboardType: TextInputType.number),
              const SizedBox(height: 20),
              _buildField('Variant (Leave blank if no variant)', _variantCtrl, Icons.tune_outlined, null, textCapitalization: TextCapitalization.characters),
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
              if (_powerWattCtrl.text.trim().isNotEmpty || _variantCtrl.text.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Name: ${_generateFullName()}',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, String? error, {TextInputType? keyboardType, TextCapitalization textCapitalization = TextCapitalization.none, String? helperText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
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
        ),
        if (helperText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(helperText, style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textMuted)),
          ),
      ],
    );
  }
}
