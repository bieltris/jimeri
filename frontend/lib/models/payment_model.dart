enum PaymentMethod {
  cash('cash', 'Dinheiro'),
  pix('pix', 'Pix'),
  debitCard('debit_card', 'Cartao de debito'),
  creditCard('credit_card', 'Cartao de credito'),
  mealVoucher('meal_voucher', 'Vale/refeicao'),
  bankTransfer('bank_transfer', 'Transferencia'),
  other('other', 'Outro');

  const PaymentMethod(this.value, this.label);

  final String value;
  final String label;

  static PaymentMethod fromValue(String value) {
    return PaymentMethod.values.firstWhere(
      (method) => method.value == value,
      orElse: () => PaymentMethod.other,
    );
  }
}

class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.clientId,
    required this.amountCents,
    required this.paymentMethod,
    required this.createdBy,
    required this.createdAt,
    this.note,
    this.cancelledAt,
    this.cancelledBy,
    this.cancelReason,
  });

  final String id;
  final String clientId;
  final int amountCents;
  final PaymentMethod paymentMethod;
  final String? note;
  final String createdBy;
  final String? cancelledAt;
  final String? cancelledBy;
  final String? cancelReason;
  final String createdAt;

  bool get cancelled => cancelledAt != null && cancelledAt!.isNotEmpty;

  factory PaymentModel.fromJson(dynamic json) {
    final data = json as Map<String, dynamic>;

    return PaymentModel(
      id: data['id'] as String,
      clientId: data['clientId'] as String,
      amountCents: data['amountCents'] as int,
      paymentMethod: PaymentMethod.fromValue(data['paymentMethod'] as String),
      note: data['note'] as String?,
      createdBy: data['createdBy'] as String,
      cancelledAt: data['cancelledAt'] as String?,
      cancelledBy: data['cancelledBy'] as String?,
      cancelReason: data['cancelReason'] as String?,
      createdAt: data['createdAt'] as String,
    );
  }
}
