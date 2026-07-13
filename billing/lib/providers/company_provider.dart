import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/company_model.dart';
import '../pb_service.dart';

class CompanyRepository {
  final PbService _pbService = PbService();

  Future<Company?> getCompany() async {
    try {
      final records = await _pbService.pb.collection('company').getFullList(
        sort: '-created',
      );
      if (records.isEmpty) return null;
      return Company.fromJson(records.first.toJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<Company> saveCompany(Map<String, dynamic> body, {String? existingId}) async {
    if (existingId != null) {
      final record = await _pbService.pb.collection('company').update(existingId, body: body);
      return Company.fromJson(record.toJson());
    } else {
      final record = await _pbService.pb.collection('company').create(body: body);
      return Company.fromJson(record.toJson());
    }
  }
}

final companyRepositoryProvider = Provider((ref) => CompanyRepository());

final companyProvider = FutureProvider<Company?>((ref) async {
  ref.keepAlive();
  final repo = ref.watch(companyRepositoryProvider);
  return repo.getCompany();
});
