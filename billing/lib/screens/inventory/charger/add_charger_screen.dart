import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/inventory/charger_model.dart';
import '../../../providers/inventory/inventory_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/app_snackbars.dart';
import '../../../theme/pickers.dart';

class AddChargerScreen extends ConsumerStatefulWidget {
  final Charger? editItem;
  const AddChargerScreen({super.key, this.editItem});

  @override
  ConsumerState<AddChargerScreen> createState() => _AddChargerScreenState();
}

class _AddChargerScreenState extends ConsumerState<AddChargerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _ampRatingCtrl;
  late TextEditingController _mrpCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _hsnCtrl;
  String _chargerType = '';
  int _gstSlab = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final e = widget.editItem;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _ampRatingCtrl = TextEditingController(text: e?.ampRating ?? '');
    _mrpCtrl = TextEditingController(text: (e?.mrp ?? 0) > 0 ? e!.mrp.toStringAsFixed(0) : '');
    _weightCtrl = TextEditingController(text: (e?.weight ?? 0) > 0 ? e!.weight.toStringAsFixed(1) : '');
    _hsnCtrl = TextEditingController(text: e?.hsnCode ?? '');
    _chargerType = e?.chargerType ?? '';
    _gstSlab = e?.gstSlab ?? 0;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ampRatingCtrl.dispose();
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
        'charger_type': _chargerType.isEmpty ? null : _chargerType,
        'amp_rating': _ampRatingCtrl.text.trim().isEmpty ? null : _ampRatingCtrl.text.trim(),
        'mrp': double.tryParse(_mrpCtrl.text.trim()) ?? 0,
        'weight': double.tryParse(_weightCtrl.text.trim()) ?? 0,
        'gst_slab': _gstSlab,
        'hsn_code': _hsnCtrl.text.trim().isEmpty ? null : _hsnCtrl.text.trim(),
        'status': widget.editItem?.status ?? 'active',
      };
      if (widget.editItem != null) {
        await repo.updateCharger(widget.editItem!.id, body);
      } else {
        body['item_code'] = await _getNextCode();
        await repo.createCharger(body);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => ref.invalidate(allChargersProvider));
      if (mounted) AppSnackBars.showSuccess(context, widget.editItem != null ? 'Charger updated' : 'Charger added');
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) AppSnackBars.showError(context, 'Cannot reach server');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String> _getNextCode() async {
    try {
      final records = await ref.read(inventoryRepositoryProvider).getAllChargers();
      if (records.isEmpty) return 'CHG0001';
      final lastCode = records.first.itemCode;
      if (!lastCode.startsWith('CHG')) return 'CHG0001';
      final num = int.tryParse(lastCode.substring(3)) ?? 0;
      return 'CHG${(num + 1).toString().padLeft(4, '0')}';
    } catch (_) {
      return 'CHG0001';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.editItem != null ? 'Edit Charger' : 'Add Charger'),
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
              Text('Charger Details', style: AppTypography.h2),
              const SizedBox(height: 24),
              _buildField('Name *', _nameCtrl, Icons.battery_std_rounded, 'Required', textCapitalization: TextCapitalization.words),
              const SizedBox(height: 16),
              AppPickerField(
                label: 'Charger Type',
                value: _chargerType.isEmpty ? 'Select' : _toTitleCase(_chargerType),
                icon: Icons.category_outlined,
                onTap: () async {
                  final result = await AppPickers.showSelectionSheet<String>(
                    context: context, title: 'Select Charger Type',
                    items: ['fast', 'slow'],
                    labelBuilder: _toTitleCase, selectedValue: _chargerType,
                  );
                  if (result != null) setState(() => _chargerType = result);
                },
              ),
              const SizedBox(height: 16),
              _buildField('Amp Rating', _ampRatingCtrl, Icons.electric_bolt_rounded, null, keyboardType: TextInputType.number),
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
