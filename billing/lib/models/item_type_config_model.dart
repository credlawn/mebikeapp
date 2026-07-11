class ItemTypeConfig {
  final String id;
  final String collectionId;
  final String collectionName;
  final String itemTypeId;
  final bool appliesColor;
  final bool appliesVariant;
  final DateTime created;
  final DateTime updated;

  ItemTypeConfig({
    required this.id,
    required this.collectionId,
    required this.collectionName,
    required this.itemTypeId,
    required this.appliesColor,
    required this.appliesVariant,
    required this.created,
    required this.updated,
  });

  static String _resolveRelation(dynamic value) {
    if (value is String) return value;
    if (value is List) return value.isNotEmpty ? value.first.toString() : '';
    return '';
  }

  factory ItemTypeConfig.fromJson(Map<String, dynamic> json) {
    return ItemTypeConfig(
      id: json['id'] ?? '',
      collectionId: json['collectionId'] ?? '',
      collectionName: json['collectionName'] ?? '',
      itemTypeId: _resolveRelation(json['item_type']),
      appliesColor: json['applies_color'] ?? false,
      appliesVariant: json['applies_variant'] ?? false,
      created: DateTime.parse(json['created']),
      updated: DateTime.parse(json['updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_type': itemTypeId,
      'applies_color': appliesColor,
      'applies_variant': appliesVariant,
    };
  }
}
