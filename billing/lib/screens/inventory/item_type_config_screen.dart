import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/item_type_model.dart';
import '../../models/item_type_config_model.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/app_snackbars.dart';
import '../../providers/inventory_provider.dart';

class ItemTypeConfigScreen extends ConsumerStatefulWidget {
  const ItemTypeConfigScreen({super.key});

  @override
  ConsumerState<ItemTypeConfigScreen> createState() => _ItemTypeConfigScreenState();
}

class _ItemTypeConfigScreenState extends ConsumerState<ItemTypeConfigScreen> {
  @override
  Widget build(BuildContext context) {
    final typesAsync = ref.watch(allItemTypesProvider);
    final configsAsync = ref.watch(allItemTypeConfigsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Item Type Config')),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.refresh(allItemTypeConfigsProvider.future).timeout(const Duration(seconds: 5), onTimeout: () => throw 'Timeout');
          await ref.refresh(allItemTypesProvider.future).timeout(const Duration(seconds: 5), onTimeout: () => throw 'Timeout');
        },
        color: AppColors.primary,
        backgroundColor: Colors.white,
        child: typesAsync.when(
          data: (types) => configsAsync.when(
            data: (configs) {
              final filteredTypes = types.where((type) {
                final config = configs.where((c) => c.itemTypeId == type.id).firstOrNull;
                return type.status == 'active' || config != null;
              }).toList();
              return filteredTypes.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.tune_rounded, size: 64, color: AppColors.textMuted),
                            const SizedBox(height: 16),
                            Text('No item types found.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
                            const SizedBox(height: 8),
                            Text('Pull to refresh', style: AppTypography.bodySmall),
                          ],
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filteredTypes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final type = filteredTypes[index];
                      final config = configs.where((c) => c.itemTypeId == type.id).firstOrNull;
                      final appliesColor = config?.appliesColor ?? false;
                      final appliesVariant = config?.appliesVariant ?? false;
                      return _buildConfigCard(type, config, appliesColor, appliesVariant);
                    },
                  );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Widget _buildConfigCard(ItemType type, ItemTypeConfig? config, bool appliesColor, bool appliesVariant) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(type.name, style: AppTypography.h3),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildToggle(
                    label: 'Color Applicable',
                    value: appliesColor,
                    onChanged: (v) => _updateConfig(config, type.id, 'applies_color', v),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildToggle(
                    label: 'Variant Applicable',
                    value: appliesVariant,
                    onChanged: (v) => _updateConfig(config, type.id, 'applies_variant', v),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: value ? AppColors.primaryLight : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: value ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              value ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 18,
              color: value ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: value ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: value ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateConfig(ItemTypeConfig? config, String typeId, String field, bool value) async {
    try {
      final repo = ref.read(inventoryRepositoryProvider);
      if (config == null) {
        final body = <String, dynamic>{
          'item_type': typeId,
          'applies_color': field == 'applies_color' ? value : false,
          'applies_variant': field == 'applies_variant' ? value : false,
        };
        await repo.createItemTypeConfig(body);
      } else {
        final body = <String, dynamic>{field: value};
        await repo.updateItemTypeConfig(config.id, body);
      }
      ref.invalidate(allItemTypeConfigsProvider);
    } catch (_) {
      if (mounted) AppSnackBars.showError(context, 'Cannot reach server');
    }
  }
}
