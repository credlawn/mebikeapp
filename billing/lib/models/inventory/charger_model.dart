class Charger {
  final String id;
  final String collectionId;
  final String itemCode;
  final String name;
  final String fullName;
  final String variant;
  final String volt;
  final String amp;
  final double sellingPrice;
  final int gstSlab;
  final String hsnCode;
  final String status;
  final DateTime created;
  final DateTime updated;

  Charger({
    required this.id,
    required this.collectionId,
    required this.itemCode,
    required this.name,
    required this.fullName,
    this.variant = '',
    this.volt = '',
    this.amp = '',
    this.sellingPrice = 0,
    this.gstSlab = 0,
    this.hsnCode = '',
    this.status = 'active',
    required this.created,
    required this.updated,
  });

  factory Charger.fromJson(Map<String, dynamic> json) {
    return Charger(
      id: json['id'] ?? '',
      collectionId: json['collectionId'] ?? '',
      itemCode: (json['item_code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      fullName: (json['full_name'] ?? '').toString(),
      variant: (json['variant'] ?? '').toString(),
      volt: (json['volt'] ?? '').toString(),
      amp: (json['amp'] ?? '').toString(),
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
      'variant': variant.isEmpty ? null : variant,
      'volt': volt.isEmpty ? null : volt,
      'amp': amp.isEmpty ? null : amp,
      'selling_price': sellingPrice,
      'gst_slab': gstSlab,
      'hsn_code': hsnCode.isEmpty ? null : hsnCode,
      'status': status,
    };
  }
}
