import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/partner_model.dart';
import '../pb_service.dart';

// Repository for Partner data
class PartnerRepository {
  final PbService _pbService = PbService();

  Future<List<Partner>> getAllPartners() async {
    try {
      final records = await _pbService.pb.collection('partner').getFullList(
        sort: '-created',
      );
      return records.map((r) => Partner.fromJson(r.toJson())).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<String> getNextPartnerCode() async {
    try {
      final records = await _pbService.pb.collection('partner').getList(
        page: 1,
        perPage: 1,
        sort: '-partner_code',
        filter: 'partner_code != ""',
      );

      if (records.items.isEmpty) return 'PA001';

      final lastCode = records.items.first.getStringValue('partner_code');
      if (!lastCode.startsWith('PA')) return 'PA001';

      final numberPart = int.tryParse(lastCode.substring(2)) ?? 0;
      final nextNumber = numberPart + 1;
      return 'PA${nextNumber.toString().padLeft(3, '0')}';
    } catch (e) {
      return 'PA001'; // Fallback
    }
  }
}

// Provider for Repository
final partnerRepositoryProvider = Provider((ref) => PartnerRepository());

// FutureProvider for the raw partner list
final allPartnersProvider = FutureProvider<List<Partner>>((ref) async {
  ref.keepAlive();
  final repo = ref.watch(partnerRepositoryProvider);
  return repo.getAllPartners();
});

// Selector for Active Partners (Code exists + Active true)
final activePartnersProvider = Provider<List<Partner>>((ref) {
  final all = ref.watch(allPartnersProvider).value ?? [];
  return all.where((p) => p.partnerActive && p.partnerCode.isNotEmpty).toList();
});

// Selector for Inactive Partners (Code exists + Active false)
final inactivePartnersProvider = Provider<List<Partner>>((ref) {
  final all = ref.watch(allPartnersProvider).value ?? [];
  return all.where((p) => !p.partnerActive && p.partnerCode.isNotEmpty).toList();
});

// Selector for Draft Partners (No Partner Code)
final draftPartnersProvider = Provider<List<Partner>>((ref) {
  final all = ref.watch(allPartnersProvider).value ?? [];
  return all.where((p) => p.partnerCode.isEmpty).toList();
});
