import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/inventory/accessory_model.dart';
import '../../../providers/inventory/inventory_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/app_snackbars.dart';
import 'add_accessory_screen.dart';
import 'accessory_detail_screen.dart';

class AccessoryListScreen extends ConsumerStatefulWidget {
  const AccessoryListScreen({super.key});

  @override
  ConsumerState<AccessoryListScreen> createState() => _AccessoryListScreenState();
}

class _AccessoryListScreenState extends ConsumerState<AccessoryListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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

  Future<void> _deleteItem(Accessory item) async {
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
              width: 56, height: 56,
              decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 28),
            ),
            const SizedBox(height: 20),
            Text('Delete Accessory?', style: AppTypography.h2.copyWith(fontSize: 18)),
            const SizedBox(height: 12),
            Text('Are you sure you want to delete "${item.fullName}"?',
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
                    foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary, width: 1.2),
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
                    backgroundColor: AppColors.error, foregroundColor: Colors.white, elevation: 0,
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
      await ref.read(inventoryRepositoryProvider).deleteAccessory(item.id);
      WidgetsBinding.instance.addPostFrameCallback((_) => ref.invalidate(allAccessoriesProvider));
      if (mounted) AppSnackBars.showSuccess(context, 'Accessory deleted');
    } catch (_) {
      if (mounted) AppSnackBars.showError(context, 'Cannot reach server');
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeAccessoriesProvider);
    final inactive = ref.watch(inactiveAccessoriesProvider);
    final async = ref.watch(allAccessoriesProvider);
    final tabColor = _tabColors[_tabController.index];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Accessories'),
        actions: [
          IconButton(
            onPressed: () => _navigateToAdd(),
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
            tooltip: 'Add Accessory',
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: tabColor, labelColor: tabColor,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: AppTypography.h3,
          tabs: [
            Tab(text: 'Active (${active.length})'),
            Tab(text: 'Inactive (${inactive.length})'),
          ],
        ),
      ),
      body: IndexedStack(
        index: _tabController.index,
        children: [
          _buildList(active, async),
          _buildList(inactive, async),
        ],
      ),
    );
  }

  Widget _buildList(List<Accessory> items, AsyncValue<List<Accessory>> async) {
    return RefreshIndicator(
      onRefresh: () async {
        try {
          await ref.refresh(allAccessoriesProvider.future).timeout(const Duration(seconds: 5), onTimeout: () => throw 'Timeout');
          if (mounted) AppSnackBars.showSuccess(context, 'Accessories updated');
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
          child: async.when(
            data: (_) => items.isEmpty
                ? SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.backpack_rounded, size: 64, color: AppColors.textMuted),
                          const SizedBox(height: 16),
                          Text('No accessories found.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(12),
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
                                        child: Text('${index + 1}.',
                                          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Flexible(
                                                  child: Text(item.fullName, style: AppTypography.h3, overflow: TextOverflow.ellipsis),
                                                ),
                                                Text(item.itemCode,
                                                  style: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                if (item.sellingPrice > 0) ...[
                                                  Text('₹ ${item.sellingPrice.toStringAsFixed(0)}',
                                                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                                                  const SizedBox(width: 8),
                                                  Text('|', style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                                                  const SizedBox(width: 8),
                                                ],
                                                Text('GST ${item.gstSlab}%',
                                                  style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
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
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddAccessoryScreen()));
  }

  void _navigateToDetail(Accessory item) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AccessoryDetailScreen(item: item)));
  }
}

const _tabColors = [AppColors.primary, AppColors.error];
