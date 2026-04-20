class OrderModel {
  const OrderModel({
    required this.id,
    required this.clientId,
    required this.createdBy,
    required this.createdAt,
    this.note,
    this.cancelledAt,
    this.cancelledBy,
    this.cancelReason,
  });

  final String id;
  final String clientId;
  final String createdBy;
  final String? note;
  final String? cancelledAt;
  final String? cancelledBy;
  final String? cancelReason;
  final String createdAt;

  bool get cancelled => cancelledAt != null && cancelledAt!.isNotEmpty;

  factory OrderModel.fromJson(dynamic json) {
    final data = json as Map<String, dynamic>;

    return OrderModel(
      id: data['id'] as String,
      clientId: data['clientId'] as String,
      createdBy: data['createdBy'] as String,
      note: data['note'] as String?,
      cancelledAt: data['cancelledAt'] as String?,
      cancelledBy: data['cancelledBy'] as String?,
      cancelReason: data['cancelReason'] as String?,
      createdAt: data['createdAt'] as String,
    );
  }
}
