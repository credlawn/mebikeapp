import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/inventory/accessory_model.dart';
import '../../../providers/inventory/inventory_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/app_snackbars.dart';
import '../../../theme/pickers.dart';

class AddAccessoryScreen extends ConsumerStatefulWidget {
  final Accessory? editItem;
  const AddAccessoryScreen({super.key, this.editItem});

  @override
  ConsumerState<AddAccessoryScreen> createState() => _AddAccessoryScreenState();
}

class _AddAccessoryScreenState extends ConsumerState<AddAccessoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _mrpCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _hsnCtrl;
  String _category = '';
  int _gstSlab = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final e = widget.editItem;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _mrpCtrl = TextEditingController(text: (e?.mrp ?? 0) > 0 ? e!.mrp.toStringAsFixed(0) : '');
    _weightCtrl = TextEditingController(text: (e?.weight ?? 0) > 0 ? e!.weight.toStringAsFixed(1) : '');
    _hsnCtrl = TextEditingController(text: e?.hsnCode ?? '');
    _category = e?.category ?? '';
    _gstSlab = e?.gstSlab ?? 0;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mrpCtrl.dispose();
    _weightCtrl.dispose();
    _hsnCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(inventoryRepositoryProvider);
      final body = {
        'item_code': widget.editItem?.itemCode ?? '',
        'name': _nameCtrl.text.trim(),
        'category': _category.isEmpty ? null : _category,
        'mrp': double.tryParse(_mrpCtrl.text.trim()) ?? 0,
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
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Save', style: AppTypography.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
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
              _buildField('Name *', _nameCtrl, Icons.backpack_rounded, 'Required', textCapitalization: TextCapitalization.words),
              const SizedBox(height: 16),
              AppPickerField(
                label: 'Category',
                value: _category.isEmpty ? 'Select' : _toTitleCase(_category),
                icon: Icons.category_outlined,
                onTap: () async {
                  final result = await AppPickers.showSelectionSheet<String>(
                    context: context, title: 'Select Category',
                    items: ['helmet', 'gloves', 'cover', 'other'],
                    labelBuilder: _toTitleCase, selectedValue: _category,
                  );
                  if (result != null) setState(() => _category = result);
                },
              ),
              const SizedBox(height: 24),
              Text('Pricing & Compliance', style: AppTypography.h2),
              const SizedBox(height: 24),
              _buildField('MRP', _mrpCtrl, Icons.currency_rupee_rounded, null, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildField('Weight (kg)', _weightCtrl, Icons.monitor_weight_outlined, null, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              AppPickerField(
                label: 'GST Slab',
                value: _gstSlab > 0 ? '$_gstSlab%' : 'Select',
                icon: Icons.percent_outlined,
                onTap: () async {
                  final result = await AppPickers.showSelectionSheet<int>(
                    context: context, title: 'Select GST Slab',
                    items: [0, 5, 12, 18, 28],
                    labelBuilder: (v) => '$v%', selectedValue: _gstSlab,
                  );
                  if (result != null) setState(() => _gstSlab = result);
                },
              ),
              const SizedBox(height: 16),
              _buildField('HSN Code', _hsnCtrl, Icons.receipt_long_outlined, null, keyboardType: TextInputType.number),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: error != null ? (v) => v!.isEmpty ? error : null : null,
    );
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}
