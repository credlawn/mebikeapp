class ItemVariant {
  final String id;
  final String collectionId;
  final String collectionName;
  final String name;
  final String status;
  final List<String> variantFor;
  final DateTime created;
  final DateTime updated;

  ItemVariant({
    required this.id,
    required this.collectionId,
    required this.collectionName,
    required this.name,
    required this.status,
    this.variantFor = const [],
    required this.created,
    required this.updated,
  });

  static List<String> _resolveRelationList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String && value.isNotEmpty) return [value];
    return [];
  }

  factory ItemVariant.fromJson(Map<String, dynamic> json) {
    return ItemVariant(
      id: json['id'] ?? '',
      collectionId: json['collectionId'] ?? '',
      collectionName: json['collectionName'] ?? '',
      name: json['name'] ?? '',
      status: json['status'] ?? 'active',
      variantFor: _resolveRelationList(json['variant_for']),
      created: DateTime.parse(json['created']),
      updated: DateTime.parse(json['updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'status': status,
      if (variantFor.isNotEmpty) 'variant_for': variantFor,
    };
  }
}
