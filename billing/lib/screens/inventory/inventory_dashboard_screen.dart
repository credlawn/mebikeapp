import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/inventory/inventory_provider.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';

class InventoryDashboardScreen extends ConsumerWidget {
  const InventoryDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(allVehiclesProvider).value ?? [];
    final batteries = ref.watch(allBatteriesProvider).value ?? [];
    final motors = ref.watch(allMotorsProvider).value ?? [];
    final accessories = ref.watch(allAccessoriesProvider).value ?? [];
    final chargers = ref.watch(allChargersProvider).value ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Inventory'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Categories', style: AppTypography.h2),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.15,
              children: [
                _buildCategoryCard(
                  context, 'Vehicles', '${vehicles.length} items',
                  Icons.directions_car_rounded, AppColors.primary,
                  () => Navigator.pushNamed(context, '/vehicle-list'),
                ),
                _buildCategoryCard(
                  context, 'Batteries', '${batteries.length} items',
                  Icons.battery_charging_full_rounded, Colors.green,
                  () => Navigator.pushNamed(context, '/battery-list'),
                ),
                _buildCategoryCard(
                  context, 'Motors', '${motors.length} items',
                  Icons.electrical_services_rounded, Colors.blue,
                  () => Navigator.pushNamed(context, '/motor-list'),
                ),
                _buildCategoryCard(
                  context, 'Accessories', '${accessories.length} items',
                  Icons.backpack_rounded, Colors.orange,
                  () => Navigator.pushNamed(context, '/accessory-list'),
                ),
                _buildCategoryCard(
                  context, 'Chargers', '${chargers.length} items',
                  Icons.battery_std_rounded, Colors.purple,
                  () => Navigator.pushNamed(context, '/charger-list'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, String subtitle,
      IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Text(title, style: AppTypography.h3),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
