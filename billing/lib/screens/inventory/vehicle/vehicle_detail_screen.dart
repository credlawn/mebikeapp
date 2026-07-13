import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/inventory/vehicle_model.dart';
import '../../../providers/inventory/inventory_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/app_snackbars.dart';

class VehicleDetailScreen extends ConsumerStatefulWidget {
  final Vehicle item;
  const VehicleDetailScreen({super.key, required this.item});

  @override
  ConsumerState<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends ConsumerState<VehicleDetailScreen> {
  late Vehicle _item;
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
      await ref.read(inventoryRepositoryProvider).updateVehicle(_item.id, {'status': newStatus});
      WidgetsBinding.instance.addPostFrameCallback((_) => ref.invalidate(allVehiclesProvider));
      setState(() => _item = Vehicle(
        id: _item.id, collectionId: _item.collectionId,
        itemCode: _item.itemCode, name: _item.name, fullName: _item.fullName, status: newStatus,
        vehicleType: _item.vehicleType, color: _item.color,
        sellingPrice: _item.sellingPrice,
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
      appBar: AppBar(title: Text(_item.fullName.isNotEmpty ? _item.fullName : _item.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSection('Vehicle Info', [
              _buildRow('Item Code', _item.itemCode),
              _buildRow('Full Name', _item.fullName),
              _buildRow('Name', _item.name),
              if (_item.vehicleType.isNotEmpty) _buildRow('Type', _item.vehicleType),
              if (_item.color.isNotEmpty) _buildRow('Colors', _item.color.replaceAll(',', ', ')),
            ]),
            const SizedBox(height: 12),
            _buildSection('Pricing & Compliance', [
              if (_item.sellingPrice > 0) _buildRow('Selling Price', '₹${_item.sellingPrice.toStringAsFixed(0)}'),
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
