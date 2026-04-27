import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'colors.dart';
import 'typography.dart';

class AppPickers {
  /// Shows a clean, flat, professional scrollable date picker (DD MMM YYYY) with dynamic day validation.
  static Future<DateTime?> showScrollableDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    int selDay = initialDate.day;
    int selMonth = initialDate.month;
    int selYear = initialDate.year;

    final List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    final startYear = firstDate?.year ?? 2000;
    final endYear = lastDate?.year ?? 2100;
    final List<int> years = List.generate((endYear - startYear) + 1, (index) => startYear + index);

    return await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Calculate dynamic days based on current selection
            int maxDays = DateUtils.getDaysInMonth(selYear, selMonth);
            if (selDay > maxDays) selDay = maxDays;

            // RESPONSIVE LOGIC: Calculate side padding to keep columns compact in the center
            final screenWidth = MediaQuery.of(context).size.width;
            final sidePadding = screenWidth > 400 ? (screenWidth - 300) / 2 : 24.0;

            return Container(
              height: 320,
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('Cancel', style: AppTypography.bodyMedium.copyWith(color: Colors.redAccent)),
                        ),
                        Text('Select Date', style: AppTypography.h3),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(DateTime(selYear, selMonth, selDay)),
                          child: Text('Done', style: AppTypography.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 0.5),
                  // Custom Flat Picker
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: sidePadding),
                      child: Row(
                        children: [
                          // DAY (DD)
                          Expanded(
                            flex: 2,
                            child: _FlatPickerColumn(
                              key: ValueKey('day_$maxDays'), 
                              items: List.generate(maxDays, (i) => (i + 1).toString().padLeft(2, '0')),
                              initialIndex: selDay - 1,
                              onChanged: (index) => selDay = index + 1,
                            ),
                          ),
                          // MONTH (MMM)
                          Expanded(
                            flex: 3,
                            child: _FlatPickerColumn(
                              items: months,
                              initialIndex: selMonth - 1,
                              onChanged: (index) {
                                setModalState(() => selMonth = index + 1);
                              },
                            ),
                          ),
                          // YEAR (YYYY)
                          Expanded(
                            flex: 3,
                            child: _FlatPickerColumn(
                              items: years.map((e) => e.toString()).toList(),
                              initialIndex: years.indexOf(selYear).clamp(0, years.length - 1),
                              onChanged: (index) {
                                setModalState(() => selYear = years[index]);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Future<T?> showSelectionSheet<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required String Function(T) labelBuilder,
    T? selectedValue,
  }) async {
    return await showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(padding: const EdgeInsets.all(20), child: Text(title, style: AppTypography.h2)),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = item == selectedValue;
                    return ListTile(
                      title: Text(
                        labelBuilder(item),
                        style: AppTypography.bodyLarge.copyWith(
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                      onTap: () => Navigator.of(context).pop(item),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _FlatPickerColumn extends StatelessWidget {
  final List<String> items;
  final int initialIndex;
  final ValueChanged<int> onChanged;

  const _FlatPickerColumn({
    super.key,
    required this.items,
    required this.initialIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoPicker(
      itemExtent: 44,
      scrollController: FixedExtentScrollController(initialItem: initialIndex),
      onSelectedItemChanged: onChanged,
      magnification: 1.0,
      squeeze: 1.0, // Fixed: set to 1.0 for a flatter, more centered look
      useMagnifier: false,
      selectionOverlay: Container(
        decoration: BoxDecoration(
          border: Border.symmetric(horizontal: BorderSide(color: AppColors.border, width: 0.5)),
        ),
      ),
      children: items.map((item) {
        return Center(
          child: Text(
            item,
            style: AppTypography.bodyLarge.copyWith(fontSize: 18, color: AppColors.textPrimary),
          ),
        );
      }).toList(),
    );
  }
}

class AppPickerField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const AppPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(value, style: AppTypography.bodyMedium),
              ],
            ),
            const Spacer(),
            const Icon(Icons.expand_more_rounded, size: 20, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
