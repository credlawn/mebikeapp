class ItemList {
  final String id;
  final String collectionId;
  final String collectionName;
  final String itemFullName;
  final String itemName;
  final String itemCode;
  final String itemTypeId;
  final String itemColorId;
  final String itemVariantId;
  final String hsnCode;
  final double itemWeight;
  final double itemMrp;
  final String gstSlab;
  final String status;
  final DateTime created;
  final DateTime updated;

  ItemList({
    required this.id,
    required this.collectionId,
    required this.collectionName,
    required this.itemFullName,
    required this.itemName,
    required this.itemCode,
    required this.itemTypeId,
    this.itemColorId = '',
    this.itemVariantId = '',
    this.hsnCode = '',
    this.itemWeight = 0,
    this.itemMrp = 0,
    this.gstSlab = '',
    this.status = 'active',
    required this.created,
    required this.updated,
  });

  static String _resolveRelation(dynamic value) {
    if (value is String) return value;
    if (value is List) return value.isNotEmpty ? value.first.toString() : '';
    return '';
  }

  factory ItemList.fromJson(Map<String, dynamic> json) {
    return ItemList(
      id: json['id'] ?? '',
      collectionId: json['collectionId'] ?? '',
      collectionName: json['collectionName'] ?? '',
      itemFullName: json['item_full_name'] ?? '',
      itemName: json['item_name'] ?? '',
      itemCode: json['item_code'] ?? '',
      itemTypeId: _resolveRelation(json['item_type']),
      itemColorId: _resolveRelation(json['item_color']),
      itemVariantId: _resolveRelation(json['item_variant']),
      hsnCode: json['hsn_code'] ?? '',
      itemWeight: (json['item_weight'] ?? 0).toDouble(),
      itemMrp: (json['item_mrp'] ?? 0).toDouble(),
      gstSlab: json['gst_slab'] ?? '',
      status: json['status'] ?? 'active',
      created: DateTime.parse(json['created']),
      updated: DateTime.parse(json['updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_full_name': itemFullName,
      'item_name': itemName,
      'item_code': itemCode,
      'item_type': itemTypeId,
      'item_color': itemColorId.isEmpty ? null : itemColorId,
      'item_variant': itemVariantId.isEmpty ? null : itemVariantId,
      'hsn_code': hsnCode.isEmpty ? null : hsnCode,
      'item_weight': itemWeight,
      'item_mrp': itemMrp,
      'gst_slab': gstSlab.isEmpty ? null : gstSlab,
      'status': status,
    };
  }
}
