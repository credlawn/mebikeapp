import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/item_list_model.dart';
import '../../providers/inventory_provider.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/app_snackbars.dart';
import 'add_inventory_screen.dart';
import 'inventory_detail_screen.dart';

class InventoryListScreen extends ConsumerStatefulWidget {
  const InventoryListScreen({super.key});

  @override
  ConsumerState<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends ConsumerState<InventoryListScreen> {
  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(allItemListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 20),
            onSelected: (value) {
              switch (value) {
                case 'types':
                  Navigator.pushNamed(context, '/item-types');
                case 'colors':
                  Navigator.pushNamed(context, '/item-colors');
                case 'variants':
                  Navigator.pushNamed(context, '/item-variants');
                case 'config':
                  Navigator.pushNamed(context, '/item-type-config');
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'types', child: Text('Item Types')),
              const PopupMenuItem(value: 'colors', child: Text('Item Colors')),
              const PopupMenuItem(value: 'variants', child: Text('Item Variants')),
              const PopupMenuItem(value: 'config', child: Text('Type Config')),
            ],
          ),
          IconButton(
            onPressed: () => _navigateToAdd(),
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
            tooltip: 'Add Item',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          try {
            await ref.refresh(allItemListProvider.future).timeout(const Duration(seconds: 5), onTimeout: () => throw 'Timeout');
            if (context.mounted) AppSnackBars.showSuccess(context, 'Inventory updated');
          } catch (e) {
            if (context.mounted) AppSnackBars.showError(context, e.toString());
          }
        },
        color: AppColors.primary,
        backgroundColor: Colors.white,
        child: itemsAsync.when(
          data: (items) => items.isEmpty
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textMuted),
                          const SizedBox(height: 16),
                          Text('No inventory items found.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
                          const SizedBox(height: 8),
                          Text('Pull to refresh', style: AppTypography.bodySmall),
                        ],
                      ),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return Column(
                          children: [
                            if (index > 0) const Divider(height: 1, color: AppColors.border),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _navigateToDetail(item),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 28,
                                        child: Text(
                                          '${index + 1}.',
                                          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    item.itemFullName.isNotEmpty ? item.itemFullName : item.itemName,
                                                    style: AppTypography.h3,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Text(
                                                  item.itemCode,
                                                  style: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Text(
                                                  '₹ ${item.itemMrp.toStringAsFixed(0)}',
                                                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                                ),
                                                const SizedBox(width: 8),
                                                Text('|', style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '${item.itemWeight % 1 == 0 ? item.itemWeight.toInt() : item.itemWeight} kg',
                                                  style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                                                ),
                                                const SizedBox(width: 8),
                                                Text('|', style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'GST ${item.gstSlab}%',
                                                  style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => RefreshIndicator(
            onRefresh: () async => ref.invalidate(allItemListProvider),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Center(child: Text('Error: $err\nPull to retry')),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToAdd() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddInventoryScreen()),
    );
  }

  void _navigateToDetail(ItemList item) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => InventoryDetailScreen(item: item)),
    );
  }
}
