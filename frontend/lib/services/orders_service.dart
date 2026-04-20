import '../core/api/api_client.dart';
import '../core/api/api_routes.dart';
import '../dtos/order_with_items_dto.dart';

class OrdersService {
  Future<OrderWithItemsDto> create({
    required String clientId,
    required List<CreateOrderItemInput> items,
    String? note,
  }) {
    return ApiClient.post<OrderWithItemsDto>(
      ApiRoutes.orders(),
      body: {
        'clientId': clientId,
        'note': note,
        'items': items.map((item) => item.toJson()).toList(),
      },
      fromJson: OrderWithItemsDto.fromJson,
    );
  }
}

class CreateOrderItemInput {
  const CreateOrderItemInput({
    required this.productId,
    required this.quantity,
  });

  final String productId;
  final int quantity;

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
    };
  }
}
