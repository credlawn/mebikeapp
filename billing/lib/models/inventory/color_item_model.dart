class ColorItem {
  final String id;
  final String name;
  final String status;

  ColorItem({required this.id, required this.name, this.status = 'active'});

  factory ColorItem.fromJson(Map<String, dynamic> json) {
    return ColorItem(
      id: json['id'] ?? '',
      name: (json['name'] ?? '').toString(),
      status: (json['status'] ?? 'active').toString(),
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'status': status};
}
