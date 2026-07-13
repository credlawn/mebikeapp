class Motor {
  final String id;
  final String collectionId;
  final String itemCode;
  final String name;
  final String variant;
  final String powerWatt;
  final double sellingPrice;
  final int gstSlab;
  final String hsnCode;
  final String status;
  final DateTime created;
  final DateTime updated;

  Motor({
    required this.id,
    required this.collectionId,
    required this.itemCode,
    required this.name,
    this.variant = '',
    this.powerWatt = '',
    this.sellingPrice = 0,
    this.gstSlab = 0,
    this.hsnCode = '',
    this.status = 'active',
    required this.created,
    required this.updated,
  });

  factory Motor.fromJson(Map<String, dynamic> json) {
    return Motor(
      id: json['id'] ?? '',
      collectionId: json['collectionId'] ?? '',
      itemCode: (json['item_code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      variant: (json['variant'] ?? '').toString(),
      powerWatt: (json['power_watt'] ?? '').toString(),
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
      'variant': variant.isEmpty ? null : variant,
      'power_watt': powerWatt.isEmpty ? null : powerWatt,
      'selling_price': sellingPrice,
      'gst_slab': gstSlab,
      'hsn_code': hsnCode.isEmpty ? null : hsnCode,
      'status': status,
    };
  }
}
