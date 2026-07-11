import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/item_list_model.dart';
import '../../models/item_type_model.dart';
import '../../models/item_color_model.dart';
import '../../models/item_variant_model.dart';
import '../../providers/inventory_provider.dart';
import '../../services/date_utils.dart';
import '../../theme/app_snackbars.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';

class InventoryDetailScreen extends ConsumerStatefulWidget {
  final ItemList item;

  const InventoryDetailScreen({super.key, required this.item});

  @override
  ConsumerState<InventoryDetailScreen> createState() => _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends ConsumerState<InventoryDetailScreen> {
  late ItemList _item;
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
      await ref.read(inventoryRepositoryProvider).updateItem(_item.id, {'status': newStatus});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.invalidate(allItemListProvider);
      });
      setState(() {
        _item = ItemList(
          id: _item.id,
          collectionId: _item.collectionId,
          collectionName: _item.collectionName,
          itemFullName: _item.itemFullName,
          itemName: _item.itemName,
          itemCode: _item.itemCode,
          itemTypeId: _item.itemTypeId,
          itemColorId: _item.itemColorId,
          itemVariantId: _item.itemVariantId,
          hsnCode: _item.hsnCode,
          itemWeight: _item.itemWeight,
          itemMrp: _item.itemMrp,
          gstSlab: _item.gstSlab,
          status: newStatus,
          created: _item.created,
          updated: _item.updated,
        );
      });
      if (mounted) AppSnackBars.showSuccess(context, newStatus == 'active' ? 'Item activated' : 'Item deactivated');
    } catch (_) {
      if (mounted) AppSnackBars.showError(context, 'Cannot reach server');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _resolveType(List<ItemType> types) {
    final match = types.where((t) => t.id == _item.itemTypeId).firstOrNull;
    return match?.name ?? _item.itemTypeId;
  }

  String _resolveColor(List<ItemColor> colors) {
    if (_item.itemColorId.isEmpty) return '';
    final match = colors.where((c) => c.id == _item.itemColorId).firstOrNull;
    return match?.name ?? _item.itemColorId;
  }

  String _resolveVariant(List<ItemVariant> variants) {
    if (_item.itemVariantId.isEmpty) return '';
    final match = variants.where((v) => v.id == _item.itemVariantId).firstOrNull;
    return match?.name ?? _item.itemVariantId;
  }

  @override
  Widget build(BuildContext context) {
    final types = ref.watch(allItemTypesProvider).asData?.value ?? <ItemType>[];
    final colors = ref.watch(allItemColorsProvider).asData?.value ?? <ItemColor>[];
    final variants = ref.watch(allItemVariantsProvider).asData?.value ?? <ItemVariant>[];
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    final typeName = _resolveType(types);
    final colorName = _resolveColor(colors);
    final variantName = _resolveVariant(variants);
    final isActive = _item.status == 'active';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_item.itemFullName.isNotEmpty ? _item.itemFullName : _item.itemName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSection('Item Details', [
              _buildRow('Item Name', _item.itemName),
              _buildRow('Full Name', _item.itemFullName),
              _buildRow('Item Code', _item.itemCode),
              _buildRow('Item Type', typeName),
              if (colorName.isNotEmpty) _buildRow('Color', colorName),
              if (variantName.isNotEmpty) _buildRow('Variant', variantName),
            ]),
            const SizedBox(height: 12),
            _buildSection('Pricing & Compliance', [
              if (_item.hsnCode.isNotEmpty) _buildRow('HSN Code', _item.hsnCode),
              if (_item.itemWeight > 0) _buildRow('Weight', '${_item.itemWeight % 1 == 0 ? _item.itemWeight.toInt() : _item.itemWeight} kg'),
              if (_item.itemMrp > 0) _buildRow('MRP', '₹${_item.itemMrp.toStringAsFixed(0)}'),
              _buildRow('GST Slab', '${_item.gstSlab}%'),
            ]),
            const SizedBox(height: 12),
            _buildSection('Status & Dates', [
              _buildStatusRow(_item.status),
              _buildRow('Created', dateFormat.format(AppDateUtils.fromServer(_item.created))),
              _buildRow('Updated', dateFormat.format(AppDateUtils.fromServer(_item.updated))),
            ]),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _toggleStatus,
              icon: _isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(isActive ? Icons.block_outlined : Icons.check_circle_outline, size: 18),
              label: Text(isActive ? 'Mark Inactive' : 'Mark Active'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive ? AppColors.error : AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
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
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.h3.copyWith(color: AppColors.primary, fontSize: 13)),
          const SizedBox(height: 12),
          ...rows,
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
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '—',
              style: AppTypography.bodyMedium.copyWith(fontSize: 13),
            ),
          ),
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
          const SizedBox(
            width: 120,
            child: Text(
              'Status',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                fontSize: 11,
                color: isActive ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
