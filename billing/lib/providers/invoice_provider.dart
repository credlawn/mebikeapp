import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/invoice_model.dart';
import '../pb_service.dart';

class InvoiceRepository {
  final PbService _pbService = PbService();

  Future<List<Invoice>> getAllInvoices({String mode = 'invoice'}) async {
    try {
      final records = await _pbService.pb.collection('invoice').getFullList(
        sort: '-created',
        filter: 'mode = "$mode"',
      );
      return records.map((r) => Invoice.fromJson(r.toJson())).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<String> getNextInvoiceNo() async {
    final fy = _currentFy(null);
    try {
      final records = await _pbService.pb.collection('invoice').getList(
        page: 1,
        perPage: 1,
        sort: '-created',
        filter: 'invoice_no ~ "MANNS/$fy/%" && mode = "invoice"',
      );
      if (records.items.isEmpty) {
        return 'MANNS/$fy/0001';
      }
      final lastNo = records.items.first.getStringValue('invoice_no');
      return _generateNextNo(lastNo, 'MANNS/$fy/');
    } catch (e) {
      return 'MANNS/$fy/0001';
    }
  }

  Future<String> getNextQuotationNo() async {
    final fy = _currentFy(null);
    final prefix = 'ME/Q/$fy/';
    try {
      final records = await _pbService.pb.collection('invoice').getList(
        page: 1,
        perPage: 1,
        sort: '-created',
        filter: 'invoice_no ~ "ME/Q/$fy/%" && mode = "quotation"',
      );
      if (records.items.isEmpty) {
        return '${prefix}0001';
      }
      final lastNo = records.items.first.getStringValue('invoice_no');
      return _generateNextNo(lastNo, prefix);
    } catch (e) {
      return '${prefix}0001';
    }
  }

  String _currentFy(DateTime? date) {
    final now = date ?? DateTime.now();
    final year = now.year;
    final month = now.month;
    if (month >= 4) {
      final y1 = year.toString().substring(2);
      final y2 = (year + 1).toString().substring(2);
      return '$y1-$y2';
    } else {
      final y1 = (year - 1).toString().substring(2);
      final y2 = year.toString().substring(2);
      return '$y1-$y2';
    }
  }

  String _generateNextNo(String lastNo, String prefix) {
    if (!lastNo.startsWith(prefix)) {
      return '${prefix}0001';
    }
    final numStr = lastNo.substring(prefix.length);
    final num = int.tryParse(numStr) ?? 0;
    return '$prefix${(num + 1).toString().padLeft(4, '0')}';
  }

  Future<Invoice> createInvoice(Map<String, dynamic> body) async {
    final record = await _pbService.pb.collection('invoice').create(body: body);
    return Invoice.fromJson(record.toJson());
  }

  Future<Invoice> updateInvoice(String id, Map<String, dynamic> body) async {
    final record = await _pbService.pb.collection('invoice').update(id, body: body);
    return Invoice.fromJson(record.toJson());
  }

  Future<void> deleteInvoice(String id) async {
    await _pbService.pb.collection('invoice').delete(id);
  }

  Future<void> updateInvoiceStatus(String id, String status) async {
    await _pbService.pb.collection('invoice').update(id, body: {'status': status});
  }

  Future<Invoice> duplicateAsInvoice(Invoice quotation) async {
    final body = quotation.toJson();
    body.remove('id');
    body['mode'] = 'invoice';
    body['status'] = 'draft';
    body['invoice_no'] = '';
    body['quotation_no'] = quotation.invoiceNo;
    body['locked'] = false;
    return createInvoice(body);
  }
}

final invoiceRepositoryProvider = Provider((ref) => InvoiceRepository());

final allInvoicesProvider = FutureProvider.family<List<Invoice>, String>((ref, mode) async {
  ref.keepAlive();
  final repo = ref.watch(invoiceRepositoryProvider);
  return repo.getAllInvoices(mode: mode);
});
