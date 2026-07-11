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

class _InventoryListScreenState extends ConsumerState<InventoryListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabColors = [
    AppColors.primary,
    AppColors.error,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tabController.addListener(() {
        if (!_tabController.indexIsChanging && mounted) setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _deleteItem(ItemList item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 28),
            ),
            const SizedBox(height: 20),
            Text('Delete Item?', style: AppTypography.h2.copyWith(fontSize: 18)),
            const SizedBox(height: 12),
            Text(
              'Are you sure you want to delete "${item.itemFullName.isNotEmpty ? item.itemFullName : item.itemName}"?',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Cancel', style: AppTypography.button.copyWith(color: AppColors.primary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Delete', style: AppTypography.button.copyWith(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final repo = ref.read(inventoryRepositoryProvider);
      await repo.deleteItem(item.id);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.invalidate(allItemListProvider);
      });
      if (mounted) AppSnackBars.showSuccess(context, 'Item deleted');
    } catch (_) {
      if (mounted) AppSnackBars.showError(context, 'Cannot reach server');
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeItems = ref.watch(activeItemListProvider);
    final inactiveItems = ref.watch(inactiveItemListProvider);
    final itemsAsync = ref.watch(allItemListProvider);
    final tabColor = _tabColors[_tabController.index];

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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: tabColor,
          labelColor: tabColor,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: AppTypography.h3,
          tabs: [
            Tab(text: 'Active (${activeItems.length})'),
            Tab(text: 'Inactive (${inactiveItems.length})'),
          ],
        ),
      ),
      body: IndexedStack(
        index: _tabController.index,
        children: [
          _buildItemList(activeItems, itemsAsync),
          _buildItemList(inactiveItems, itemsAsync),
        ],
      ),
    );
  }

  Widget _buildItemList(List<ItemList> items, AsyncValue<List<ItemList>> itemsAsync) {
    return RefreshIndicator(
      onRefresh: () async {
        try {
          await ref.refresh(allItemListProvider.future).timeout(const Duration(seconds: 5), onTimeout: () => throw 'Timeout');
          if (mounted) AppSnackBars.showSuccess(context, 'Inventory updated');
        } catch (e) {
          if (mounted) AppSnackBars.showError(context, e.toString());
        }
      },
      color: AppColors.primary,
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.8),
          child: itemsAsync.when(
            data: (_) => items.isEmpty
                ? SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textMuted),
                          const SizedBox(height: 16),
                          Text('No items found.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  )
                : Container(
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
                                    onLongPress: () => _deleteItem(item),
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err\nPull to retry')),
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
