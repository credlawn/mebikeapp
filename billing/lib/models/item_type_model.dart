class ItemType {
  final String id;
  final String collectionId;
  final String collectionName;
  final String name;
  final String status;
  final DateTime created;
  final DateTime updated;

  ItemType({
    required this.id,
    required this.collectionId,
    required this.collectionName,
    required this.name,
    required this.status,
    required this.created,
    required this.updated,
  });

  factory ItemType.fromJson(Map<String, dynamic> json) {
    return ItemType(
      id: json['id'] ?? '',
      collectionId: json['collectionId'] ?? '',
      collectionName: json['collectionName'] ?? '',
      name: json['name'] ?? '',
      status: json['status'] ?? 'active',
      created: DateTime.parse(json['created']),
      updated: DateTime.parse(json['updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'status': status,
    };
  }
}
