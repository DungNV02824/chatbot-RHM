class ThreadModel {
  final String id;
  final String name;
  final DateTime? updatedAt;

  ThreadModel({
    required this.id,
    required this.name,
    required this.updatedAt,
  });

  factory ThreadModel.fromJson(Map<String, dynamic> json) {
    return ThreadModel(
      id: json["id"].toString(),
      name: json["name"] ?? "Không tên",
      updatedAt: json["updated_at"] != null
          ? DateTime.parse(json["updated_at"])
          : null,
    );
  }
}