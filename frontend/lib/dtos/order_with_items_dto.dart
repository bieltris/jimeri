import '../models/order_item_model.dart';
import '../models/order_model.dart';

class OrderWithItemsDto {
  const OrderWithItemsDto({
    required this.order,
    required this.items,
    required this.totalCents,
  });

  final OrderModel order;
  final List<OrderItemModel> items;
  final int totalCents;

  factory OrderWithItemsDto.fromJson(dynamic json) {
    final data = json as Map<String, dynamic>;

    return OrderWithItemsDto(
      order: OrderModel.fromJson(data['order']),
      items: (data['items'] as List)
          .map((item) => OrderItemModel.fromJson(item))
          .toList(),
      totalCents: data['totalCents'] as int,
    );
  }
}
