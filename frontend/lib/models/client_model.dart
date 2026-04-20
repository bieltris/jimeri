class ClientModel {
  const ClientModel({
    required this.id,
    required this.name,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    this.responsibleName,
    this.responsibleWhatsapp,
    this.note,
  });

  final String id;
  final String name;
  final String? responsibleName;
  final String? responsibleWhatsapp;
  final String? note;
  final bool active;
  final String createdAt;
  final String updatedAt;

  factory ClientModel.fromJson(dynamic json) {
    final data = json as Map<String, dynamic>;

    return ClientModel(
      id: data['id'] as String,
      name: data['name'] as String,
      responsibleName: data['responsibleName'] as String?,
      responsibleWhatsapp: data['responsibleWhatsapp'] as String?,
      note: data['note'] as String?,
      active: data['active'] as bool,
      createdAt: data['createdAt'] as String,
      updatedAt: data['updatedAt'] as String,
    );
  }
}
