class Vehicle {
  final String id;
  final String collectionId;
  final String itemCode;
  final String name;
  final String fullName;
  final String vehicleType;
  final String color;
  final double sellingPrice;
  final int gstSlab;
  final String hsnCode;
  final String status;
  final DateTime created;
  final DateTime updated;

  Vehicle({
    required this.id,
    required this.collectionId,
    required this.itemCode,
    required this.name,
    required this.fullName,
    this.vehicleType = '',
    this.color = '',
    this.sellingPrice = 0,
    this.gstSlab = 0,
    this.hsnCode = '',
    this.status = 'active',
    required this.created,
    required this.updated,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] ?? '',
      collectionId: json['collectionId'] ?? '',
      itemCode: (json['item_code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      fullName: (json['full_name'] ?? '').toString(),
      vehicleType: (json['vehicle_type'] ?? '').toString(),
      color: (json['color'] ?? '').toString(),
      sellingPrice: (json['selling_price'] is String ? double.tryParse(json['selling_price']) ?? 0 : (json['selling_price'] ?? 0)).toDouble(),
      gstSlab: (json['gst_slab'] ?? 0).toInt(),
      hsnCode: (json['hsn_code'] ?? '').toString(),
      status: (json['status'] ?? 'active').toString(),
      created: DateTime.parse(json['created']),
      updated: DateTime.parse(json['updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_code': itemCode,
      'name': name,
      'full_name': fullName,
      'vehicle_type': vehicleType.isEmpty ? null : vehicleType,
      'color': color.isEmpty ? null : color,
      'selling_price': sellingPrice,
      'gst_slab': gstSlab,
      'hsn_code': hsnCode.isEmpty ? null : hsnCode,
      'status': status,
    };
  }
}
