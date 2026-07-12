import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/inventory/vehicle_model.dart';
import '../../models/inventory/battery_model.dart';
import '../../models/inventory/motor_model.dart';
import '../../models/inventory/accessory_model.dart';
import '../../models/inventory/charger_model.dart';
import '../../pb_service.dart';

class InventoryRepository {
  final PbService _pbService = PbService();

  // ── Vehicle ──
  Future<List<Vehicle>> getAllVehicles() async {
    final records = await _pbService.pb.collection('vehicle').getFullList(sort: '-created');
    return records.map((r) => Vehicle.fromJson(r.toJson())).toList();
  }

  Future<void> createVehicle(Map<String, dynamic> body) async {
    await _pbService.pb.collection('vehicle').create(body: body);
  }

  Future<void> updateVehicle(String id, Map<String, dynamic> body) async {
    await _pbService.pb.collection('vehicle').update(id, body: body);
  }

  Future<void> deleteVehicle(String id) async {
    await _pbService.pb.collection('vehicle').delete(id);
  }

  // ── Battery ──
  Future<List<Battery>> getAllBatteries() async {
    final records = await _pbService.pb.collection('battery').getFullList(sort: '-created');
    return records.map((r) => Battery.fromJson(r.toJson())).toList();
  }

  Future<void> createBattery(Map<String, dynamic> body) async {
    await _pbService.pb.collection('battery').create(body: body);
  }

  Future<void> updateBattery(String id, Map<String, dynamic> body) async {
    await _pbService.pb.collection('battery').update(id, body: body);
  }

  Future<void> deleteBattery(String id) async {
    await _pbService.pb.collection('battery').delete(id);
  }

  // ── Motor ──
  Future<List<Motor>> getAllMotors() async {
    final records = await _pbService.pb.collection('motor').getFullList(sort: '-created');
    return records.map((r) => Motor.fromJson(r.toJson())).toList();
  }

  Future<void> createMotor(Map<String, dynamic> body) async {
    await _pbService.pb.collection('motor').create(body: body);
  }

  Future<void> updateMotor(String id, Map<String, dynamic> body) async {
    await _pbService.pb.collection('motor').update(id, body: body);
  }

  Future<void> deleteMotor(String id) async {
    await _pbService.pb.collection('motor').delete(id);
  }

  // ── Accessory ──
  Future<List<Accessory>> getAllAccessories() async {
    final records = await _pbService.pb.collection('accessory').getFullList(sort: '-created');
    return records.map((r) => Accessory.fromJson(r.toJson())).toList();
  }

  Future<void> createAccessory(Map<String, dynamic> body) async {
    await _pbService.pb.collection('accessory').create(body: body);
  }

  Future<void> updateAccessory(String id, Map<String, dynamic> body) async {
    await _pbService.pb.collection('accessory').update(id, body: body);
  }

  Future<void> deleteAccessory(String id) async {
    await _pbService.pb.collection('accessory').delete(id);
  }

  // ── Charger ──
  Future<List<Charger>> getAllChargers() async {
    final records = await _pbService.pb.collection('charger').getFullList(sort: '-created');
    return records.map((r) => Charger.fromJson(r.toJson())).toList();
  }

  Future<void> createCharger(Map<String, dynamic> body) async {
    await _pbService.pb.collection('charger').create(body: body);
  }

  Future<void> updateCharger(String id, Map<String, dynamic> body) async {
    await _pbService.pb.collection('charger').update(id, body: body);
  }

  Future<void> deleteCharger(String id) async {
    await _pbService.pb.collection('charger').delete(id);
  }
}

final inventoryRepositoryProvider = Provider((ref) => InventoryRepository());

// ── Vehicle Providers ──
final allVehiclesProvider = FutureProvider<List<Vehicle>>((ref) async {
  ref.keepAlive();
  return ref.watch(inventoryRepositoryProvider).getAllVehicles();
});

final activeVehiclesProvider = Provider<List<Vehicle>>((ref) {
  final all = ref.watch(allVehiclesProvider).value ?? [];
  return all.where((i) => i.status == 'active').toList();
});

final inactiveVehiclesProvider = Provider<List<Vehicle>>((ref) {
  final all = ref.watch(allVehiclesProvider).value ?? [];
  return all.where((i) => i.status == 'inactive').toList();
});

// ── Battery Providers ──
final allBatteriesProvider = FutureProvider<List<Battery>>((ref) async {
  ref.keepAlive();
  return ref.watch(inventoryRepositoryProvider).getAllBatteries();
});

final activeBatteriesProvider = Provider<List<Battery>>((ref) {
  final all = ref.watch(allBatteriesProvider).value ?? [];
  return all.where((i) => i.status == 'active').toList();
});

final inactiveBatteriesProvider = Provider<List<Battery>>((ref) {
  final all = ref.watch(allBatteriesProvider).value ?? [];
  return all.where((i) => i.status == 'inactive').toList();
});

// ── Motor Providers ──
final allMotorsProvider = FutureProvider<List<Motor>>((ref) async {
  ref.keepAlive();
  return ref.watch(inventoryRepositoryProvider).getAllMotors();
});

final activeMotorsProvider = Provider<List<Motor>>((ref) {
  final all = ref.watch(allMotorsProvider).value ?? [];
  return all.where((i) => i.status == 'active').toList();
});

final inactiveMotorsProvider = Provider<List<Motor>>((ref) {
  final all = ref.watch(allMotorsProvider).value ?? [];
  return all.where((i) => i.status == 'inactive').toList();
});

// ── Accessory Providers ──
final allAccessoriesProvider = FutureProvider<List<Accessory>>((ref) async {
  ref.keepAlive();
  return ref.watch(inventoryRepositoryProvider).getAllAccessories();
});

final activeAccessoriesProvider = Provider<List<Accessory>>((ref) {
  final all = ref.watch(allAccessoriesProvider).value ?? [];
  return all.where((i) => i.status == 'active').toList();
});

final inactiveAccessoriesProvider = Provider<List<Accessory>>((ref) {
  final all = ref.watch(allAccessoriesProvider).value ?? [];
  return all.where((i) => i.status == 'inactive').toList();
});

// ── Charger Providers ──
final allChargersProvider = FutureProvider<List<Charger>>((ref) async {
  ref.keepAlive();
  return ref.watch(inventoryRepositoryProvider).getAllChargers();
});

final activeChargersProvider = Provider<List<Charger>>((ref) {
  final all = ref.watch(allChargersProvider).value ?? [];
  return all.where((i) => i.status == 'active').toList();
});

final inactiveChargersProvider = Provider<List<Charger>>((ref) {
  final all = ref.watch(allChargersProvider).value ?? [];
  return all.where((i) => i.status == 'inactive').toList();
});
