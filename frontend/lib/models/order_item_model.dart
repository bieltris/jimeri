class OrderItemModel {
  const OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPriceCents,
    required this.subtotalCents,
    required this.createdAt,
  });

  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final int quantity;
  final int unitPriceCents;
  final int subtotalCents;
  final String createdAt;

  factory OrderItemModel.fromJson(dynamic json) {
    final data = json as Map<String, dynamic>;

    return OrderItemModel(
      id: data['id'] as String,
      orderId: data['orderId'] as String,
      productId: data['productId'] as String,
      productName: data['productName'] as String,
      quantity: data['quantity'] as int,
      unitPriceCents: data['unitPriceCents'] as int,
      subtotalCents: data['subtotalCents'] as int,
      createdAt: data['createdAt'] as String,
    );
  }
}
