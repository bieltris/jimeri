import '../core/api/api_client.dart';
import '../core/api/api_routes.dart';
import '../models/payment_model.dart';

class PaymentsService {
  Future<List<PaymentModel>> listByClient(String clientId) {
    return ApiClient.get<List<PaymentModel>>(
      ApiRoutes.clientPayments(clientId),
      fromJson: ApiClient.listFromJson(PaymentModel.fromJson),
    );
  }

  Future<PaymentModel> create({
    required String clientId,
    required int amountCents,
    required PaymentMethod paymentMethod,
    String? note,
  }) {
    return ApiClient.post<PaymentModel>(
      ApiRoutes.payments(),
      body: {
        'clientId': clientId,
        'amountCents': amountCents,
        'paymentMethod': paymentMethod.value,
        'note': note,
      },
      fromJson: PaymentModel.fromJson,
    );
  }

  Future<PaymentModel> cancel({
    required String id,
    required String reason,
  }) {
    return ApiClient.post<PaymentModel>(
      ApiRoutes.cancelPayment(id),
      body: {
        'reason': reason,
      },
      fromJson: PaymentModel.fromJson,
    );
  }
}
