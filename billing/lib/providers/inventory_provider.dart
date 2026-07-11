import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item_type_model.dart';
import '../models/item_color_model.dart';
import '../models/item_variant_model.dart';
import '../models/item_type_config_model.dart';
import '../models/item_list_model.dart';
import '../pb_service.dart';

class InventoryRepository {
  final PbService _pbService = PbService();

  // ── Item Types ──
  Future<List<ItemType>> getAllItemTypes() async {
    final records = await _pbService.pb.collection('item_type').getFullList(sort: '-created');
    return records.map((r) => ItemType.fromJson(r.toJson())).toList();
  }

  Future<void> createItemType(Map<String, dynamic> body) async {
    await _pbService.pb.collection('item_type').create(body: body);
  }

  Future<void> updateItemType(String id, Map<String, dynamic> body) async {
    await _pbService.pb.collection('item_type').update(id, body: body);
  }

  Future<bool> isItemReferenced(String field, String id) async {
    final result = await _pbService.pb.collection('item_list').getList(
      filter: '$field = "$id"',
      perPage: 1,
    );
    return result.items.isNotEmpty;
  }

  Future<void> deleteItemType(String id) async {
    await _pbService.pb.collection('item_type').delete(id);
  }

  // ── Item Colors ──
  Future<List<ItemColor>> getAllItemColors() async {
    final records = await _pbService.pb.collection('item_color').getFullList(sort: '-created');
    return records.map((r) => ItemColor.fromJson(r.toJson())).toList();
  }

  Future<void> createItemColor(Map<String, dynamic> body) async {
    await _pbService.pb.collection('item_color').create(body: body);
  }

  Future<void> updateItemColor(String id, Map<String, dynamic> body) async {
    await _pbService.pb.collection('item_color').update(id, body: body);
  }

  Future<void> deleteItemColor(String id) async {
    await _pbService.pb.collection('item_color').delete(id);
  }

  // ── Item Variants ──
  Future<List<ItemVariant>> getAllItemVariants() async {
    final records = await _pbService.pb.collection('item_variant').getFullList(sort: '-created');
    return records.map((r) => ItemVariant.fromJson(r.toJson())).toList();
  }

  Future<void> createItemVariant(Map<String, dynamic> body) async {
    await _pbService.pb.collection('item_variant').create(body: body);
  }

  Future<void> updateItemVariant(String id, Map<String, dynamic> body) async {
    await _pbService.pb.collection('item_variant').update(id, body: body);
  }

  Future<void> deleteItemVariant(String id) async {
    await _pbService.pb.collection('item_variant').delete(id);
  }

  // ── Item Type Config ──
  Future<List<ItemTypeConfig>> getAllItemTypeConfigs() async {
    final records = await _pbService.pb.collection('item_type_config').getFullList(sort: '-created');
    return records.map((r) => ItemTypeConfig.fromJson(r.toJson())).toList();
  }

  Future<void> createItemTypeConfig(Map<String, dynamic> body) async {
    await _pbService.pb.collection('item_type_config').create(body: body);
  }

  Future<void> updateItemTypeConfig(String id, Map<String, dynamic> body) async {
    await _pbService.pb.collection('item_type_config').update(id, body: body);
  }

  // ── Item List ──
  Future<List<ItemList>> getAllItemList() async {
    final records = await _pbService.pb.collection('item_list').getFullList(sort: '-created');
    return records.map((r) => ItemList.fromJson(r.toJson())).toList();
  }

  Future<String> getNextItemCode() async {
    try {
      final records = await _pbService.pb.collection('item_list').getList(
        page: 1,
        perPage: 1,
        sort: '-item_code',
        filter: 'item_code != ""',
      );

      if (records.items.isEmpty) return 'ME0001';

      final lastCode = records.items.first.getStringValue('item_code');
      if (!lastCode.startsWith('ME')) return 'ME0001';

      final numberPart = int.tryParse(lastCode.substring(2)) ?? 0;
      final nextNumber = numberPart + 1;
      return 'ME${nextNumber.toString().padLeft(4, '0')}';
    } catch (e) {
      return 'ME0001';
    }
  }

  Future<void> createItem(Map<String, dynamic> body) async {
    await _pbService.pb.collection('item_list').create(body: body);
  }

  Future<void> updateItem(String id, Map<String, dynamic> body) async {
    await _pbService.pb.collection('item_list').update(id, body: body);
  }
}

final inventoryRepositoryProvider = Provider((ref) => InventoryRepository());

final allItemTypesProvider = FutureProvider<List<ItemType>>((ref) async {
  ref.keepAlive();
  return ref.watch(inventoryRepositoryProvider).getAllItemTypes();
});

final allItemColorsProvider = FutureProvider<List<ItemColor>>((ref) async {
  ref.keepAlive();
  return ref.watch(inventoryRepositoryProvider).getAllItemColors();
});

final allItemVariantsProvider = FutureProvider<List<ItemVariant>>((ref) async {
  ref.keepAlive();
  return ref.watch(inventoryRepositoryProvider).getAllItemVariants();
});

final allItemTypeConfigsProvider = FutureProvider<List<ItemTypeConfig>>((ref) async {
  ref.keepAlive();
  return ref.watch(inventoryRepositoryProvider).getAllItemTypeConfigs();
});

final allItemListProvider = FutureProvider<List<ItemList>>((ref) async {
  ref.keepAlive();
  return ref.watch(inventoryRepositoryProvider).getAllItemList();
});
