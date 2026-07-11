import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/item_list_model.dart';
import '../../models/item_type_model.dart';
import '../../models/item_color_model.dart';
import '../../models/item_variant_model.dart';
import '../../providers/inventory_provider.dart';
import '../../services/date_utils.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';

class InventoryDetailScreen extends ConsumerWidget {
  final ItemList item;

  const InventoryDetailScreen({super.key, required this.item});

  String _resolveType(List<ItemType> types) {
    final match = types.where((t) => t.id == item.itemTypeId).firstOrNull;
    return match?.name ?? item.itemTypeId;
  }

  String _resolveColor(List<ItemColor> colors) {
    if (item.itemColorId.isEmpty) return '';
    final match = colors.where((c) => c.id == item.itemColorId).firstOrNull;
    return match?.name ?? item.itemColorId;
  }

  String _resolveVariant(List<ItemVariant> variants) {
    if (item.itemVariantId.isEmpty) return '';
    final match = variants.where((v) => v.id == item.itemVariantId).firstOrNull;
    return match?.name ?? item.itemVariantId;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final types = ref.watch(allItemTypesProvider).asData?.value ?? <ItemType>[];
    final colors = ref.watch(allItemColorsProvider).asData?.value ?? <ItemColor>[];
    final variants = ref.watch(allItemVariantsProvider).asData?.value ?? <ItemVariant>[];
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    final typeName = _resolveType(types);
    final colorName = _resolveColor(colors);
    final variantName = _resolveVariant(variants);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(item.itemFullName.isNotEmpty ? item.itemFullName : item.itemName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSection('Item Details', [
              _buildRow('Item Name', item.itemName),
              _buildRow('Full Name', item.itemFullName),
              _buildRow('Item Code', item.itemCode),
              _buildRow('Item Type', typeName),
              if (colorName.isNotEmpty) _buildRow('Color', colorName),
              if (variantName.isNotEmpty) _buildRow('Variant', variantName),
            ]),
            const SizedBox(height: 12),
            _buildSection('Pricing & Compliance', [
              if (item.hsnCode.isNotEmpty) _buildRow('HSN Code', item.hsnCode),
              if (item.itemWeight > 0) _buildRow('Weight', '${item.itemWeight % 1 == 0 ? item.itemWeight.toInt() : item.itemWeight} kg'),
              if (item.itemMrp > 0) _buildRow('MRP', '₹${item.itemMrp.toStringAsFixed(0)}'),
              _buildRow('GST Slab', '${item.gstSlab}%'),
            ]),
            const SizedBox(height: 12),
            _buildSection('Status & Dates', [
              _buildStatusRow(item.status),
              _buildRow('Created', dateFormat.format(AppDateUtils.fromServer(item.created))),
              _buildRow('Updated', dateFormat.format(AppDateUtils.fromServer(item.updated))),
            ]),
          ],
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
