import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/inventory/accessory_model.dart';
import '../../../providers/inventory/inventory_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/app_snackbars.dart';

class _VariantEntry {
  final String variant;
  final double sellingPrice;
  _VariantEntry(this.variant, this.sellingPrice);
}

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
  final _hsnCtrl = TextEditingController();
  int _gstSlab = -1;
  bool _isLoading = false;
  final _pendingVariants = <_VariantEntry>[];

  static const _gstOptions = [0, 5, 12, 18, 28];

  @override
  void initState() {
    super.initState();
    final e = widget.editItem;
    if (e != null) {
      _nameCtrl.text = e.name;
      _variantCtrl.text = e.variant;
      _sellingPriceCtrl.text = e.sellingPrice > 0 ? e.sellingPrice.toStringAsFixed(0) : '';
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
    _hsnCtrl.dispose();
    super.dispose();
  }

  String _generateFullName(String variant) {
    final n = _nameCtrl.text.trim();
    return variant.isNotEmpty ? 'ME $n - $variant' : 'ME $n';
  }

  void _addVariant({bool keepPrice = false}) {
    final v = _variantCtrl.text.trim().toUpperCase();
    if (v.isEmpty) {
      AppSnackBars.showError(context, 'Enter a variant name first');
      return;
    }
    final price = double.tryParse(_sellingPriceCtrl.text.trim()) ?? 0;
    setState(() {
      _pendingVariants.add(_VariantEntry(v, price));
      _variantCtrl.clear();
      if (!keepPrice) _sellingPriceCtrl.clear();
    });
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
      final entries = <_VariantEntry>[];
      if (_pendingVariants.isNotEmpty) {
        entries.addAll(_pendingVariants);
        final curVariant = _variantCtrl.text.trim().toUpperCase();
        if (curVariant.isNotEmpty) {
          entries.add(_VariantEntry(curVariant, double.tryParse(_sellingPriceCtrl.text.trim()) ?? 0));
        }
      } else {
        entries.add(_VariantEntry(_variantCtrl.text.trim().toUpperCase(), double.tryParse(_sellingPriceCtrl.text.trim()) ?? 0));
      }

      for (final entry in entries) {
        if (entry.variant.isEmpty) {
          if (mounted) AppSnackBars.showError(context, 'Variant is required');
          setState(() => _isLoading = false);
          return;
        }
      }

      final existing = await repo.getAllAccessories();
      final baseNum = existing.isEmpty ? 0 : (int.tryParse(existing.first.itemCode.substring(3)) ?? 0);
      var codeOffset = 0;
      var created = 0;
      var skipped = 0;
      for (final entry in entries) {
        final fullName = _generateFullName(entry.variant);
        final isDuplicate = existing.any((a) =>
          a.id != widget.editItem?.id &&
          a.fullName.trim().toLowerCase() == fullName.toLowerCase()
        );
        if (isDuplicate) { skipped++; continue; }
        final body = {
          'item_code': widget.editItem?.itemCode ?? 'ACC${(baseNum + 1 + codeOffset).toString().padLeft(4, '0')}',
          'full_name': fullName,
          'name': _nameCtrl.text.trim(),
          'variant': entry.variant.isEmpty ? null : entry.variant,
          'selling_price': entry.sellingPrice,
          'gst_slab': _gstSlab,
          'hsn_code': _hsnCtrl.text.trim().isEmpty ? null : _hsnCtrl.text.trim(),
          'status': widget.editItem?.status ?? 'active',
        };
        if (widget.editItem != null) {
          await repo.updateAccessory(widget.editItem!.id, body);
        } else {
          await repo.createAccessory(body);
        }
        created++;
        codeOffset++;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => ref.invalidate(allAccessoriesProvider));
      final parts = <String>[];
      if (created > 0) parts.add('$created added');
      if (skipped > 0) parts.add('$skipped skipped (duplicate)');
      if (mounted) AppSnackBars.showSuccess(context, parts.join(', '));
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) AppSnackBars.showError(context, 'Cannot reach server');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              Text('Accessory Details', style: AppTypography.h2),
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
              _buildField('Name *', _nameCtrl, Icons.backpack_rounded, 'Required', textCapitalization: TextCapitalization.characters),
              const SizedBox(height: 20),
              _buildField('Variant', _variantCtrl, Icons.tune_outlined, null, textCapitalization: TextCapitalization.characters),
              if (_nameCtrl.text.trim().isNotEmpty || _variantCtrl.text.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Flexible(child: Text('Name: ${_generateFullName(_variantCtrl.text.trim().toUpperCase())}',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              _buildField('Selling Price (₹)', _sellingPriceCtrl, Icons.currency_rupee_rounded, null, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              Row(
                children: [
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'new') {
                        _addVariant();
                      } else {
                        _addVariant(keepPrice: true);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text('Add Variant', style: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                          const Icon(Icons.expand_more_rounded, size: 16, color: AppColors.primary),
                        ],
                      ),
                    ),
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'new', child: Text('New Variant')),
                      const PopupMenuItem(value: 'same_price', child: Text('Same Price')),
                    ],
                  ),
                  if (_pendingVariants.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                      child: Text('${_pendingVariants.length} pending',
                        style: AppTypography.bodySmall.copyWith(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
              if (_pendingVariants.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pending Variants', style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted)),
                      const SizedBox(height: 8),
                      ..._pendingVariants.asMap().entries.map((entry) {
                        final i = entry.key;
                        final v = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Expanded(child: Text('${v.variant}  |  ₹${v.sellingPrice.toStringAsFixed(0)}',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600))),
                              GestureDetector(
                                onTap: () => setState(() => _pendingVariants.removeAt(i)),
                                child: const Icon(Icons.close_rounded, size: 16, color: AppColors.error),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
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
