import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/inventory/battery_model.dart';
import '../../../providers/inventory/inventory_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/app_snackbars.dart';

class BatteryDetailScreen extends ConsumerStatefulWidget {
  final Battery item;
  const BatteryDetailScreen({super.key, required this.item});

  @override
  ConsumerState<BatteryDetailScreen> createState() => _BatteryDetailScreenState();
}

class _BatteryDetailScreenState extends ConsumerState<BatteryDetailScreen> {
  late Battery _item;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  Future<void> _toggleStatus() async {
    setState(() => _isLoading = true);
    try {
      final newStatus = _item.status == 'active' ? 'inactive' : 'active';
      await ref.read(inventoryRepositoryProvider).updateBattery(_item.id, {'status': newStatus});
      WidgetsBinding.instance.addPostFrameCallback((_) => ref.invalidate(allBatteriesProvider));
      setState(() => _item = Battery(
        id: _item.id, collectionId: _item.collectionId,
        itemCode: _item.itemCode, name: _item.name, fullName: _item.fullName, status: newStatus,
        volt: _item.volt, amp: _item.amp, cellType: _item.cellType, variant: _item.variant,
        sellingPrice: _item.sellingPrice, weight: _item.weight,
        gstSlab: _item.gstSlab, hsnCode: _item.hsnCode,
        created: _item.created, updated: _item.updated,
      ));
      if (mounted) AppSnackBars.showSuccess(context, newStatus == 'active' ? 'Activated' : 'Deactivated');
    } catch (_) {
      if (mounted) AppSnackBars.showError(context, 'Cannot reach server');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _item.status == 'active';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(_item.fullName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSection('Battery Info', [
              _buildRow('Item Code', _item.itemCode),
              _buildRow('Full Name', _item.fullName),
              _buildRow('Name', _item.name),
              if (_item.volt.isNotEmpty) _buildRow('Volt', _item.volt),
              if (_item.amp.isNotEmpty) _buildRow('Amp', _item.amp),
              if (_item.cellType.isNotEmpty) _buildRow('Cell Type', _item.cellType),
              if (_item.variant.isNotEmpty) _buildRow('Variant', _item.variant),
            ]),
            const SizedBox(height: 12),
            _buildSection('Pricing & Compliance', [
              if (_item.sellingPrice > 0) _buildRow('Selling Price', '₹${_item.sellingPrice.toStringAsFixed(0)}'),
              if (_item.weight > 0) _buildRow('Weight', '${_item.weight % 1 == 0 ? _item.weight.toInt() : _item.weight} kg'),
              _buildRow('GST Slab', '${_item.gstSlab}%'),
              if (_item.hsnCode.isNotEmpty) _buildRow('HSN Code', _item.hsnCode),
            ]),
            const SizedBox(height: 12),
            _buildSection('Status', [_buildStatusRow(_item.status)]),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity, height: 44,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _toggleStatus,
              icon: _isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(isActive ? Icons.block_outlined : Icons.check_circle_outline, size: 18),
              label: Text(isActive ? 'Mark Inactive' : 'Mark Active'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive ? AppColors.error : AppColors.primary,
                foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> rows) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.h3.copyWith(color: AppColors.primary, fontSize: 13)),
          const SizedBox(height: 12), ...rows,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textMuted))),
          Expanded(child: Text(value.isNotEmpty ? value : '—', style: AppTypography.bodyMedium.copyWith(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String status) {
    final isActive = status == 'active';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 110, child: Text('Status', style: TextStyle(fontSize: 11, color: AppColors.textMuted))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(isActive ? 'Active' : 'Inactive',
              style: TextStyle(fontSize: 11, color: isActive ? AppColors.success : AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
