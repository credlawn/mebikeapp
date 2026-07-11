import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/item_type_model.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/app_snackbars.dart';
import '../../providers/inventory_provider.dart';

class InventoryMasterScreen extends ConsumerStatefulWidget {
  final String title;
  final String collectionName;
  final InventoryMasterType masterType;
  final IconData icon;

  const InventoryMasterScreen({
    super.key,
    required this.title,
    required this.collectionName,
    required this.masterType,
    required this.icon,
  });

  @override
  ConsumerState<InventoryMasterScreen> createState() => _InventoryMasterScreenState();
}

enum InventoryMasterType { itemType, itemColor, itemVariant }

class _InventoryMasterScreenState extends ConsumerState<InventoryMasterScreen> {
  final _nameController = TextEditingController();
  Set<String> _selectedVariantForIds = {};

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createItem(String name, {List<String>? variantFor}) async {
    final repo = ref.read(inventoryRepositoryProvider);
    final body = <String, dynamic>{'name': name, 'status': 'active'};
    if (variantFor != null && variantFor.isNotEmpty) {
      body['variant_for'] = variantFor;
    }
    switch (widget.masterType) {
      case InventoryMasterType.itemType:
        await repo.createItemType(body);
        ref.invalidate(allItemTypesProvider);
      case InventoryMasterType.itemColor:
        await repo.createItemColor(body);
        ref.invalidate(allItemColorsProvider);
      case InventoryMasterType.itemVariant:
        await repo.createItemVariant(body);
        ref.invalidate(allItemVariantsProvider);
    }
  }

  Future<void> _toggleStatus(dynamic item, bool isActive) async {
    final repo = ref.read(inventoryRepositoryProvider);
    final newStatus = isActive ? 'inactive' : 'active';
    final body = <String, dynamic>{'status': newStatus};
    switch (widget.masterType) {
      case InventoryMasterType.itemType:
        await repo.updateItemType(item.id, body);
        ref.invalidate(allItemTypesProvider);
      case InventoryMasterType.itemColor:
        await repo.updateItemColor(item.id, body);
        ref.invalidate(allItemColorsProvider);
      case InventoryMasterType.itemVariant:
        await repo.updateItemVariant(item.id, body);
        ref.invalidate(allItemVariantsProvider);
    }
  }

  String _getName(dynamic item) => item.name;
  String _getStatus(dynamic item) => item.status;

  void _showAddDialog() {
    _nameController.clear();
    _selectedVariantForIds = {};
    final isVariant = widget.masterType == InventoryMasterType.itemVariant;

    showDialog(
      context: context,
      builder: (ctx) {
        final typesAsync = ref.watch(allItemTypesProvider);
        var volt = '';
        var amp = '';
        var selectedChem = <String>{};

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final types = (typesAsync.asData?.value ?? <ItemType>[]).where((t) => t.status == 'active').toList();
            final selectedTypeNames = types
                .where((t) => _selectedVariantForIds.contains(t.id))
                .map((t) => t.name)
                .toList();
            final isBatteryOnly = selectedTypeNames.length == 1 && selectedTypeNames.first == 'Battery';
            final hasSelection = _selectedVariantForIds.isNotEmpty;

            String autoBase = '';
            if (isBatteryOnly && volt.isNotEmpty && amp.isNotEmpty) {
              autoBase = '${volt}V-${amp}Ah';
            }
            final names = isBatteryOnly && autoBase.isNotEmpty
                ? (selectedChem.isEmpty ? [autoBase] : selectedChem.map((c) => '$c $autoBase').toList())
                : <String>[];

            return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Add ${widget.title}', style: AppTypography.h3),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isVariant) ...[
                      Text('Variant For', style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: types.map((type) {
                          final selected = _selectedVariantForIds.contains(type.id);
                          return InkWell(
                            onTap: () {
                              setDialogState(() {
                                if (selected) {
                                  _selectedVariantForIds.remove(type.id);
                                } else {
                                  _selectedVariantForIds.add(type.id);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: selected ? AppColors.primaryLight : AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                              ),
                              child: Text(
                                type.name,
                                style: AppTypography.bodySmall.copyWith(
                                  color: selected ? AppColors.primary : AppColors.textSecondary,
                                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      if (hasSelection && !isBatteryOnly)
                        TextFormField(
                          controller: _nameController,
                          autofocus: true,
                          style: AppTypography.input,
                          decoration: InputDecoration(
                            labelText: 'Name',
                            labelStyle: AppTypography.bodySmall,
                            prefixIcon: Icon(widget.icon, size: 18, color: AppColors.textSecondary),
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      if (isBatteryOnly) ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                keyboardType: TextInputType.number,
                                style: AppTypography.input,
                                decoration: InputDecoration(
                                  labelText: 'Volt',
                                  labelStyle: AppTypography.bodySmall,
                                  suffixText: 'V',
                                  suffixStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                                  filled: true,
                                  fillColor: AppColors.background,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                                onChanged: (v) => setDialogState(() => volt = v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                keyboardType: TextInputType.number,
                                style: AppTypography.input,
                                decoration: InputDecoration(
                                  labelText: 'Amp',
                                  labelStyle: AppTypography.bodySmall,
                                  suffixText: 'Ah',
                                  suffixStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                                  filled: true,
                                  fillColor: AppColors.background,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                                onChanged: (a) => setDialogState(() => amp = a),
                              ),
                            ),
                          ],
                        ),
                        if (autoBase.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text('Chemistry', style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ['LI', 'LFP'].map((chem) {
                              final selected = selectedChem.contains(chem);
                              return InkWell(
                                onTap: () {
                                  setDialogState(() {
                                    if (selected) {
                                      selectedChem.remove(chem);
                                    } else {
                                      selectedChem.add(chem);
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: selected ? AppColors.primaryLight : AppColors.background,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                        size: 16,
                                        color: selected ? AppColors.primary : AppColors.textMuted,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        chem,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: selected ? AppColors.primary : AppColors.textSecondary,
                                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          ...names.map((n) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(n, style: AppTypography.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )),
                        ],
                      ],
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: AppTypography.bodyMedium.copyWith(color: Colors.redAccent)),
              ),
              TextButton(
                onPressed: () async {
                  final variantFor = isVariant && _selectedVariantForIds.isNotEmpty
                      ? _selectedVariantForIds.toList()
                      : null;
                  try {
                    if (isBatteryOnly && names.isNotEmpty) {
                      for (final n in names) {
                        await _createItem(n, variantFor: variantFor);
                      }
                    } else {
                      final name = _nameController.text.trim();
                      if (name.isEmpty) return;
                      await _createItem(name, variantFor: variantFor);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) AppSnackBars.showSuccess(context, '${widget.title} added');
                  } catch (_) {
                    if (mounted) AppSnackBars.showError(context, 'Cannot reach server');
                  }
                },
                child: Text('Save', style: AppTypography.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          );
          },
        );
      },
    );
  }

  Future<void> _deleteItem(dynamic item) async {
    final repo = ref.read(inventoryRepositoryProvider);
    switch (widget.masterType) {
      case InventoryMasterType.itemType:
        await repo.deleteItemType(item.id);
        ref.invalidate(allItemTypesProvider);
      case InventoryMasterType.itemColor:
        await repo.deleteItemColor(item.id);
        ref.invalidate(allItemColorsProvider);
      case InventoryMasterType.itemVariant:
        await repo.deleteItemVariant(item.id);
        ref.invalidate(allItemVariantsProvider);
    }
  }

  void _showDeleteConfirmDialog(dynamic item) {
    showDialog(
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
            Text('Delete ${widget.title}?', style: AppTypography.h2.copyWith(fontSize: 18)),
            const SizedBox(height: 12),
            Text(
              'Are you sure you want to delete "${_getName(item)}"? This cannot be undone.',
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
                  onPressed: () => Navigator.of(ctx).pop(),
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
                  onPressed: () async {
                    try {
                      await _deleteItem(item);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) AppSnackBars.showSuccess(context, '${widget.title} deleted');
                    } catch (_) {
                      if (mounted) AppSnackBars.showError(context, 'Cannot reach server');
                    }
                  },
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
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = _buildAsyncValue();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
            tooltip: 'Add ${widget.title}',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          try {
            switch (widget.masterType) {
              case InventoryMasterType.itemType:
                await ref.refresh(allItemTypesProvider.future).timeout(const Duration(seconds: 5), onTimeout: () => throw 'Timeout');
              case InventoryMasterType.itemColor:
                await ref.refresh(allItemColorsProvider.future).timeout(const Duration(seconds: 5), onTimeout: () => throw 'Timeout');
              case InventoryMasterType.itemVariant:
                await ref.refresh(allItemVariantsProvider.future).timeout(const Duration(seconds: 5), onTimeout: () => throw 'Timeout');
            }
            if (context.mounted) AppSnackBars.showSuccess(context, '${widget.title} updated');
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
                          Icon(widget.icon, size: 64, color: AppColors.textMuted),
                          const SizedBox(height: 16),
                          Text('No ${widget.title.toLowerCase()} found.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
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
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isActive = _getStatus(item) == 'active';
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onLongPress: () async {
                            final repo = ref.read(inventoryRepositoryProvider);
                            final field = switch (widget.masterType) {
                              InventoryMasterType.itemType => 'item_type',
                              InventoryMasterType.itemColor => 'item_color',
                              InventoryMasterType.itemVariant => 'item_variant',
                            };
                            final inUse = await repo.isItemReferenced(field, item.id);
                            if (inUse) {
                              if (context.mounted) AppSnackBars.showError(context, 'Cannot delete — already in use. Mark as inactive instead.');
                              return;
                            }
                            _showDeleteConfirmDialog(item);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      _getName(item).isNotEmpty ? _getName(item)[0].toUpperCase() : '?',
                                      style: AppTypography.h3.copyWith(color: AppColors.primary),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_getName(item), style: AppTypography.h3),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: isActive ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              isActive ? 'Active' : 'Inactive',
                                              style: AppTypography.bodySmall.copyWith(
                                                fontSize: 10,
                                                color: isActive ? AppColors.success : AppColors.error,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () async {
                                    try {
                                      await _toggleStatus(item, isActive);
                                      if (context.mounted) AppSnackBars.showSuccess(context, isActive ? 'Deactivated' : 'Activated');
                                    } catch (_) {
                                      if (context.mounted) AppSnackBars.showError(context, 'Cannot reach server');
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      isActive ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                      color: isActive ? AppColors.success : AppColors.textMuted,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allItemListProvider);
            },
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

  AsyncValue<List<dynamic>> _buildAsyncValue() {
    switch (widget.masterType) {
      case InventoryMasterType.itemType:
        return ref.watch(allItemTypesProvider);
      case InventoryMasterType.itemColor:
        return ref.watch(allItemColorsProvider);
      case InventoryMasterType.itemVariant:
        return ref.watch(allItemVariantsProvider);
    }
  }
}
