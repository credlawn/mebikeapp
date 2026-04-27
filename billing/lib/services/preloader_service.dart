import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/partner_provider.dart';
import '../pb_service.dart';

class PreloaderService {
  /// REGISTRY: Role -> List of required providers.
  static final Map<String, List<dynamic>> _roleRegistry = {
    'company': [
      allPartnersProvider,
    ],
    'sales': [],
    'mechanic': [],
  };

  /// Main Preloader function that dynamically warms up providers based on the user's role.
  /// Includes a safety timeout to prevent the splash screen from hanging indefinitely.
  static Future<void> preloadAppData(WidgetRef ref) async {
    try {
      final pb = PbService().pb;
      final role = pb.authStore.record?.getStringValue('role')?.toLowerCase() ?? '';
      
      final providersToLoad = _roleRegistry[role] ?? [];
      if (providersToLoad.isEmpty) return;

      final List<Future<dynamic>> futures = [];

      for (final provider in providersToLoad) {
        try {
          // Trigger the fetch for FutureProviders
          futures.add(ref.read(provider.future));
        } catch (e) {
          // If it's a standard provider, just trigger a read
          ref.read(provider);
        }
      }

      if (futures.isNotEmpty) {
        // SAFETY TIMEOUT: We wait a maximum of 5 seconds for all data.
        // If it takes longer (slow internet), we move on to keep the app responsive.
        await Future.wait(futures).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            print('Preloader Log: Safety timeout hit after 5s. Moving to dashboard.');
            return []; 
          },
        );
      }
      
      print('Preloader Log: Successfully preloaded ${providersToLoad.length} modules for role: $role');

    } catch (e) {
      print('Preloader Log: Preloading finished with fallback: $e');
    }
  }
}
