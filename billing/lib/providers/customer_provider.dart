import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer_model.dart';
import '../pb_service.dart';

class CustomerRepository {
  final PbService _pbService = PbService();

  Future<List<Customer>> getAllCustomers() async {
    try {
      final records = await _pbService.pb.collection('customer').getFullList(
        sort: '-created',
      );
      return records.map((r) => Customer.fromJson(r.toJson())).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Customer?> getCustomerByMobile(String mobile) async {
    try {
      final records = await _pbService.pb.collection('customer').getFullList(
        filter: 'mobile_no = "$mobile"',
      );
      if (records.isEmpty) return null;
      return Customer.fromJson(records.first.toJson());
    } catch (e) {
      return null;
    }
  }

  Future<Customer> createCustomer(Map<String, dynamic> body) async {
    final record = await _pbService.pb.collection('customer').create(body: body);
    return Customer.fromJson(record.toJson());
  }

  Future<Customer> updateCustomer(String id, Map<String, dynamic> body) async {
    final record = await _pbService.pb.collection('customer').update(id, body: body);
    return Customer.fromJson(record.toJson());
  }
}

final customerRepositoryProvider = Provider((ref) => CustomerRepository());

final allCustomersProvider = FutureProvider<List<Customer>>((ref) async {
  ref.keepAlive();
  final repo = ref.watch(customerRepositoryProvider);
  return repo.getAllCustomers();
});
