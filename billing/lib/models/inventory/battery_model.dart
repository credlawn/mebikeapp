class Battery {
  final String id;
  final String collectionId;
  final String itemCode;
  final String name;
  final String fullName;
  final String volt;
  final String amp;
  final String cellType;
  final String variant;
  final double sellingPrice;
  final double weight;
  final int gstSlab;
  final String hsnCode;
  final String status;
  final DateTime created;
  final DateTime updated;

  Battery({
    required this.id,
    required this.collectionId,
    required this.itemCode,
    required this.name,
    required this.fullName,
    this.volt = '',
    this.amp = '',
    this.cellType = '',
    this.variant = '',
    this.sellingPrice = 0,
    this.weight = 0,
    this.gstSlab = 0,
    this.hsnCode = '',
    this.status = 'active',
    required this.created,
    required this.updated,
  });

  factory Battery.fromJson(Map<String, dynamic> json) {
    return Battery(
      id: json['id'] ?? '',
      collectionId: json['collectionId'] ?? '',
      itemCode: (json['item_code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      fullName: (json['full_name'] ?? '').toString(),
      volt: (json['volt'] ?? '').toString(),
      amp: (json['amp'] ?? '').toString(),
      cellType: (json['cell_type'] ?? '').toString(),
      variant: (json['variant'] ?? '').toString(),
      sellingPrice: (json['selling_price'] is String ? double.tryParse(json['selling_price']) ?? 0 : (json['selling_price'] ?? 0)).toDouble(),
      weight: (json['weight'] is String ? double.tryParse(json['weight']) ?? 0 : (json['weight'] ?? 0)).toDouble(),
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
      'volt': volt.isEmpty ? null : volt,
      'amp': amp.isEmpty ? null : amp,
      'cell_type': cellType.isEmpty ? null : cellType,
      'variant': variant.isEmpty ? null : variant,
      'selling_price': sellingPrice,
      'weight': weight,
      'gst_slab': gstSlab,
      'hsn_code': hsnCode.isEmpty ? null : hsnCode,
      'status': status,
    };
  }
}
