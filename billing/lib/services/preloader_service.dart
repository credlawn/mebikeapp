import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/partner_provider.dart';
import '../providers/inventory/inventory_provider.dart';
import '../pb_service.dart';

class PreloaderService {
  static final Map<String, List<dynamic>> _roleRegistry = {
    'company': [
      allPartnersProvider,
      allVehiclesProvider,
      allBatteriesProvider,
      allMotorsProvider,
      allAccessoriesProvider,
      allChargersProvider,
    ],
    'sales': [],
    'mechanic': [],
  };

  static Future<void> preloadAppData(WidgetRef ref) async {
    try {
      final pb = PbService().pb;
      final role = (pb.authStore.record?.getStringValue('role') ?? '').toLowerCase();
      final providersToLoad = _roleRegistry[role] ?? [];
      if (providersToLoad.isEmpty) return;

      final List<Future<dynamic>> futures = [];
      for (final provider in providersToLoad) {
        try {
          futures.add(ref.read(provider.future));
        } catch (e) {
          ref.read(provider);
        }
      }

      if (futures.isNotEmpty) {
        await Future.wait(futures).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('Preloader Log: Safety timeout hit after 5s. Moving to dashboard.');
            return [];
          },
        );
      }
      debugPrint('Preloader Log: Successfully preloaded ${providersToLoad.length} modules for role: $role');
    } catch (e) {
      debugPrint('Preloader Log: Preloading finished with fallback: $e');
    }
  }
}
