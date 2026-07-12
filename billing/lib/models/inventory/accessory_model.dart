class Accessory {
  final String id;
  final String collectionId;
  final String itemCode;
  final String name;
  final String category;
  final double mrp;
  final double weight;
  final int gstSlab;
  final String hsnCode;
  final String status;
  final DateTime created;
  final DateTime updated;

  Accessory({
    required this.id,
    required this.collectionId,
    required this.itemCode,
    required this.name,
    this.category = '',
    this.mrp = 0,
    this.weight = 0,
    this.gstSlab = 0,
    this.hsnCode = '',
    this.status = 'active',
    required this.created,
    required this.updated,
  });

  factory Accessory.fromJson(Map<String, dynamic> json) {
    return Accessory(
      id: json['id'] ?? '',
      collectionId: json['collectionId'] ?? '',
      itemCode: (json['item_code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      mrp: (json['mrp'] is String ? double.tryParse(json['mrp']) ?? 0 : (json['mrp'] ?? 0)).toDouble(),
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
      'category': category.isEmpty ? null : category,
      'mrp': mrp,
      'weight': weight,
      'gst_slab': gstSlab,
      'hsn_code': hsnCode.isEmpty ? null : hsnCode,
      'status': status,
    };
  }
}
