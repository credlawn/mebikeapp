import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/item_type_model.dart';
import '../../models/item_color_model.dart';
import '../../models/item_variant_model.dart';
import '../../models/item_type_config_model.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/app_snackbars.dart';
import '../../providers/inventory_provider.dart';

class _CombinationInfo {
  final String key;
  final String name;

  const _CombinationInfo({required this.key, required this.name});
}

class AddInventoryScreen extends ConsumerStatefulWidget {
  const AddInventoryScreen({super.key});

  @override
  ConsumerState<AddInventoryScreen> createState() => _AddInventoryScreenState();
}

class _AddInventoryScreenState extends ConsumerState<AddInventoryScreen> {
  final _itemNameController = TextEditingController();
  final _hsnCodeController = TextEditingController();

  ItemType? _selectedType;
  ItemTypeConfig? _typeConfig;
  Set<String> _selectedColorIds = {};
  Set<String> _selectedVariantIds = {};
  int? _gstSlab;
  bool _isLoading = false;
  bool _syncWeightMrp = true;
  bool _itemNameLocked = false;

  final Map<String, TextEditingController> _weightControllers = {};
  final Map<String, TextEditingController> _mrpControllers = {};

  static const _gstOptions = [0, 5, 12, 18, 28];

  @override
  void dispose() {
    _itemNameController.dispose();
    _hsnCodeController.dispose();
    for (final c in _weightControllers.values) {
      c.dispose();
    }
    for (final c in _mrpControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _buildFullName(String itemName, String typeName, String colorName, String variantName) {
    var name = '$itemName $typeName';
    if (colorName.isNotEmpty) name += ' - $colorName';
    if (variantName.isNotEmpty) name += ' - $variantName';
    return name;
  }

  List<_CombinationInfo> _computeCombinations(
    String itemName,
    String typeName,
    List<ItemColor> selectedColors,
    List<ItemVariant> selectedVariants,
  ) {
    final hasColors = selectedColors.isNotEmpty;
    final hasVariants = selectedVariants.isNotEmpty;

    if (!hasColors && !hasVariants) {
      return [_CombinationInfo(key: 'base', name: _buildFullName(itemName, typeName, '', ''))];
    }

    final result = <_CombinationInfo>[];
    if (hasColors && !hasVariants) {
      for (final color in selectedColors) {
        result.add(_CombinationInfo(
          key: 'c_${color.id}',
          name: _buildFullName(itemName, typeName, color.name, ''),
        ));
      }
    } else if (!hasColors && hasVariants) {
      for (final variant in selectedVariants) {
        result.add(_CombinationInfo(
          key: 'v_${variant.id}',
          name: _buildFullName(itemName, typeName, '', variant.name),
        ));
      }
    } else {
      for (final color in selectedColors) {
        for (final variant in selectedVariants) {
          result.add(_CombinationInfo(
            key: 'c_${color.id}_v_${variant.id}',
            name: _buildFullName(itemName, typeName, color.name, variant.name),
          ));
        }
      }
    }
    return result;
  }

  void _rebuildVariantDetails(List<_CombinationInfo> combos) {
    final newKeys = combos.map((c) => c.key).toSet();
    final oldKeys = _weightControllers.keys.toSet();

    for (final key in oldKeys.difference(newKeys)) {
      _weightControllers[key]?.dispose();
      _mrpControllers[key]?.dispose();
      _weightControllers.remove(key);
      _mrpControllers.remove(key);
    }
    for (final key in newKeys.difference(oldKeys)) {
      _weightControllers[key] = TextEditingController();
      _mrpControllers[key] = TextEditingController();
      if (_syncWeightMrp && combos.length > 1 && key != combos.first.key) {
        final srcWeight = _weightControllers[combos.first.key]?.text ?? '';
        final srcMrp = _mrpControllers[combos.first.key]?.text ?? '';
        _weightControllers[key]?.text = srcWeight;
        _mrpControllers[key]?.text = srcMrp;
      }
    }
  }

  void _toggleSync(bool value, List<_CombinationInfo> combos) {
    setState(() {
      _syncWeightMrp = value;
      if (value && combos.length > 1) {
        final firstKey = combos.first.key;
        final firstWeight = _weightControllers[firstKey]?.text ?? '';
        final firstMrp = _mrpControllers[firstKey]?.text ?? '';
        for (final combo in combos.skip(1)) {
          _weightControllers[combo.key]?.text = firstWeight;
          _mrpControllers[combo.key]?.text = firstMrp;
        }
      }
    });
  }

  bool get _isAutoNameType => _selectedType != null && _selectedType!.name != 'Scooter' && _selectedType!.name != 'Bike';

  void _onTypeChanged(ItemType? type, List<ItemTypeConfig> configs) {
    setState(() {
      _selectedType = type;
      _selectedColorIds = {};
      _selectedVariantIds = {};
      _gstSlab = null;
      _hsnCodeController.clear();
      for (final c in _weightControllers.values) {
        c.dispose();
      }
      _weightControllers.clear();
      for (final c in _mrpControllers.values) {
        c.dispose();
      }
      _mrpControllers.clear();
      _typeConfig = type != null
          ? configs.where((c) => c.itemTypeId == type.id).firstOrNull
          : null;
      if (type != null && type.name != 'Scooter' && type.name != 'Bike') {
        _itemNameController.text = 'ME';
        _itemNameLocked = true;
      } else {
        _itemNameController.clear();
        _itemNameLocked = false;
      }
    });
  }

  void _onColorToggled(String id) {
    setState(() {
      if (_selectedColorIds.contains(id)) {
        _selectedColorIds.remove(id);
      } else {
        _selectedColorIds.add(id);
      }
    });
  }

  void _onVariantToggled(String id) {
    setState(() {
      if (_selectedVariantIds.contains(id)) {
        _selectedVariantIds.remove(id);
      } else {
        _selectedVariantIds.add(id);
      }
    });
  }

  Future<void> _handleSave() async {
    final itemName = _itemNameController.text.trim();
    if (itemName.isEmpty) {
      AppSnackBars.showError(context, 'Enter item name');
      return;
    }
    if (_selectedType == null) {
      AppSnackBars.showError(context, 'Select item type');
      return;
    }
    final hsn = _hsnCodeController.text.trim();
    if (hsn.isEmpty) {
      AppSnackBars.showError(context, 'Enter HSN code');
      return;
    }
    if (_gstSlab == null) {
      AppSnackBars.showError(context, 'Select GST slab');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(inventoryRepositoryProvider);
      final nextCode = await repo.getNextItemCode();

      final colors = _typeConfig?.appliesColor == true
          ? await repo.getAllItemColors()
          : <ItemColor>[];
      final variants = _typeConfig?.appliesVariant == true
          ? await repo.getAllItemVariants()
          : <ItemVariant>[];

      final selectedColors = colors.where((c) => _selectedColorIds.contains(c.id)).toList();
      final selectedVariants = variants.where((v) => _selectedVariantIds.contains(v.id)).toList();

      final combos = _computeCombinations(itemName, _selectedType!.name, selectedColors, selectedVariants);
      final hsn = _hsnCodeController.text.trim();

      final recordsToCreate = <Map<String, dynamic>>[];
      var codeNum = int.parse(nextCode.substring(2));

      for (final combo in combos) {
        final srcKey = _syncWeightMrp ? combos.first.key : combo.key;
        final weightCtrl = _weightControllers[srcKey];
        final mrpCtrl = _mrpControllers[srcKey];

        final parts = combo.key.split('_');
        String? colorId;
        String? variantId;
        if (parts.length == 2 && parts[0] == 'c') {
          colorId = parts[1];
        } else if (parts.length == 2 && parts[0] == 'v') {
          variantId = parts[1];
        } else if (parts.length == 4) {
          colorId = parts[1];
          variantId = parts[3];
        }

        final code = 'ME${codeNum.toString().padLeft(4, '0')}';
        final entry = <String, dynamic>{
          'item_full_name': combo.name,
          'item_name': itemName,
          'item_code': code,
          'item_type': _selectedType!.id,
          'item_weight': weightCtrl?.text ?? '0',
          'item_mrp': mrpCtrl?.text ?? '0',
          'gst_slab': _gstSlab,
          'status': 'active',
        };
        if (colorId != null) entry['item_color'] = colorId;
        if (variantId != null) entry['item_variant'] = variantId;
        if (hsn.isNotEmpty) entry['hsn_code'] = hsn;
        recordsToCreate.add(entry);
        codeNum++;
      }

      for (final body in recordsToCreate) {
        await repo.createItem(body);
      }

      ref.invalidate(allItemListProvider);
      if (mounted) {
        AppSnackBars.showSuccess(context, '${recordsToCreate.length} item(s) created');
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) AppSnackBars.showError(context, 'Cannot reach server');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typesAsync = ref.watch(allItemTypesProvider);
    final configsAsync = ref.watch(allItemTypeConfigsProvider);
    final colorsAsync = ref.watch(allItemColorsProvider);
    final variantsAsync = ref.watch(allItemVariantsProvider);

    final activeTypes = typesAsync.asData?.value.where((t) => t.status == 'active').toList() ?? <ItemType>[];
    final configs = configsAsync.asData?.value ?? <ItemTypeConfig>[];
    if (_selectedType != null && !activeTypes.any((t) => t.id == _selectedType!.id)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedType = null);
      });
    }

    final allColors = colorsAsync.asData?.value ?? <ItemColor>[];
    final activeColors = allColors.where((c) => c.status == 'active').toList();
    final allVariants = variantsAsync.asData?.value ?? <ItemVariant>[];
    final activeVariants = allVariants.where((v) => v.status == 'active').toList();
    final filteredVariants = _selectedType != null
        ? activeVariants.where((v) => v.variantFor.isEmpty || v.variantFor.contains(_selectedType!.id)).toList()
        : activeVariants;

    final selectedColors = activeColors.where((c) => _selectedColorIds.contains(c.id)).toList();
    final selectedVariants = filteredVariants.where((v) => _selectedVariantIds.contains(v.id)).toList();
    final combos = _computeCombinations(
      _itemNameController.text.trim(),
      _selectedType?.name ?? '',
      selectedColors,
      selectedVariants,
    );
    _rebuildVariantDetails(combos);

    final hasColorChips = _typeConfig?.appliesColor == true && activeColors.isNotEmpty;
    final hasVariantChips = _typeConfig?.appliesVariant == true && filteredVariants.isNotEmpty;
    final showWeightMrp = _selectedType != null && (!hasColorChips && !hasVariantChips || _selectedColorIds.isNotEmpty || _selectedVariantIds.isNotEmpty);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Inventory Item'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _handleSave,
            icon: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.cloud_upload_outlined, color: AppColors.primary),
            tooltip: 'Save Data',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWhiteCard(children: [
              _buildTypePicker(activeTypes, configs),
              if (_selectedType != null) ...[
                const SizedBox(height: 16),
                _isAutoNameType && _itemNameLocked
                    ? _buildLockedNameField()
                    : _buildTextField(
                        label: 'Item Name *',
                        controller: _itemNameController,
                        icon: Icons.inventory_2_outlined,
                        capitalization: TextCapitalization.words,
                        onTapOutside: _isAutoNameType ? () => setState(() => _itemNameLocked = true) : null,
                      ),
                const SizedBox(height: 16),
                _buildTextField(label: 'HSN Code *', controller: _hsnCodeController, icon: Icons.confirmation_number_outlined, keyboardType: TextInputType.number),
              ],
            ]),
            const SizedBox(height: 16),
            if (_typeConfig?.appliesColor == true && activeColors.isNotEmpty)
              _buildWhiteCard(children: [
                _buildChipSection(label: 'Colors', items: activeColors, selectedIds: _selectedColorIds, onToggle: _onColorToggled),
              ]),
            if (_typeConfig?.appliesVariant == true && filteredVariants.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildWhiteCard(children: [
                _buildChipSection(label: 'Variants', items: filteredVariants, selectedIds: _selectedVariantIds, onToggle: _onVariantToggled),
              ]),
            ],
            if (showWeightMrp) ...[
              const SizedBox(height: 16),
              _buildWhiteCard(children: [
                _buildWeightMrpHeader(combos),
                const SizedBox(height: 16),
                _buildGstSlabPicker(),
                const SizedBox(height: 16),
                ...combos.asMap().entries.map((entry) => Padding(
                  padding: EdgeInsets.only(bottom: entry.key < combos.length - 1 ? 10 : 0),
                  child: _buildVariantCard(entry.value, entry.key, combos.first.key),
                )),
              ]),
            ],
            if (_selectedType != null && _selectedType!.id.isNotEmpty) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(_isLoading ? 'Saving...' : 'Save Item(s)', style: AppTypography.button),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWhiteCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.none,
    VoidCallback? onTapOutside,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      style: AppTypography.input,
      onTapOutside: onTapOutside != null ? (_) => onTapOutside() : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.bodySmall,
        prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildLockedNameField() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Item Name *', style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text('ME', style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _itemNameLocked = false),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.link_rounded, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text('Tap to edit', style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        height: 50,
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted)),
                  const SizedBox(height: 2),
                  Text(value.isNotEmpty ? value : 'Select', style: AppTypography.bodyMedium.copyWith(color: value.isNotEmpty ? AppColors.textPrimary : AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.expand_more_rounded, size: 20, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  void _showGstPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Select GST Slab', style: AppTypography.h2),
            ),
            ..._gstOptions.map((opt) {
              final isSel = _gstSlab == opt;
              return ListTile(
                leading: Icon(
                  isSel ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: isSel ? AppColors.primary : AppColors.textMuted,
                  size: 22,
                ),
                title: Text(
                  '$opt%',
                  style: AppTypography.bodyLarge.copyWith(
                    color: isSel ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _gstSlab = opt);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTypePicker(List<ItemType> types, List<ItemTypeConfig> configs) {
    final value = _selectedType?.name ?? '';
    return _buildPickerField(
      label: 'Item Type *',
      value: value,
      icon: Icons.category_outlined,
      onTap: () {
        if (types.isEmpty) {
          AppSnackBars.showError(context, 'No active types available');
          return;
        }
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Select Item Type', style: AppTypography.h2),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: types.length,
                    itemBuilder: (ctx, i) {
                      final type = types[i];
                      final isSelected = _selectedType?.id == type.id;
                      return ListTile(
                        leading: Icon(
                          isSelected ? Icons.check_circle_rounded : Icons.category_outlined,
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          size: 22,
                        ),
                        title: Text(
                          type.name,
                          style: AppTypography.bodyLarge.copyWith(
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          _onTypeChanged(type, configs);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChipSection<T>({
    required String label,
    required List<T> items,
    required Set<String> selectedIds,
    required ValueChanged<String> onToggle,
  }) {
    String getId(dynamic item) => item.id;
    String getName(dynamic item) => item.name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.bodySmall.copyWith(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items.map((item) {
            final id = getId(item);
            final name = getName(item);
            final isSelected = selectedIds.contains(id);
            return InkWell(
              onTap: () => onToggle(id),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryLight : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                      size: 18,
                      color: isSelected ? AppColors.primary : AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      name,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGstSlabPicker() {
    return _buildPickerField(
      label: 'GST Slab',
      value: _gstSlab != null ? '$_gstSlab%' : 'Select',
      icon: Icons.percent_rounded,
      onTap: _showGstPickerSheet,
    );
  }

  Widget _buildWeightMrpHeader(List<_CombinationInfo> combos) {
    return Row(
      children: [
        Text('Weight & MRP', style: AppTypography.h3.copyWith(fontSize: 16)),
        const Spacer(),
        if (combos.length > 1)
          GestureDetector(
            onTap: () => _toggleSync(!_syncWeightMrp, combos),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _syncWeightMrp ? AppColors.primaryLight : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _syncWeightMrp ? AppColors.primary : AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _syncWeightMrp ? Icons.link_rounded : Icons.link_off_rounded,
                    size: 16,
                    color: _syncWeightMrp ? AppColors.primary : AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Same for all',
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 11,
                      color: _syncWeightMrp ? AppColors.primary : AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVariantCard(_CombinationInfo combo, int index, String firstKey) {
    final isSynced = _syncWeightMrp && index > 0;
    final weightCtrl = isSynced ? _weightControllers[firstKey]! : _weightControllers[combo.key]!;
    final mrpCtrl = isSynced ? _mrpControllers[firstKey]! : _mrpControllers[combo.key]!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSynced ? AppColors.background.withValues(alpha: 0.5) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isSynced ? AppColors.border.withValues(alpha: 0.4) : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fiber_manual_record_rounded, size: 8, color: isSynced ? AppColors.textMuted : AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(combo.name, style: AppTypography.bodyMedium.copyWith(
                  fontSize: 13,
                  color: isSynced ? AppColors.textMuted : AppColors.textPrimary,
                  fontWeight: isSynced ? FontWeight.normal : FontWeight.w600,
                )),
              ),
              if (isSynced)
                Icon(Icons.sync_lock_rounded, size: 14, color: AppColors.textMuted),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInlineField(ctrl: weightCtrl, label: 'Weight (kg)', icon: Icons.monitor_weight_outlined, readOnly: isSynced),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInlineField(ctrl: mrpCtrl, label: 'MRP (₹)', icon: Icons.currency_rupee_outlined, readOnly: isSynced),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInlineField({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      readOnly: readOnly,
      style: AppTypography.input.copyWith(fontSize: 14, color: readOnly ? AppColors.textMuted : AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.bodySmall.copyWith(fontSize: 11, color: readOnly ? AppColors.textMuted : AppColors.textSecondary),
        prefixIcon: Icon(icon, size: 18, color: readOnly ? AppColors.textMuted : AppColors.textSecondary),
        filled: true,
        fillColor: readOnly ? AppColors.background.withValues(alpha: 0.4) : AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
