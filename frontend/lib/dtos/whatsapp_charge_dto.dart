import '../models/client_model.dart';

class WhatsappChargeDto {
  const WhatsappChargeDto({
    required this.client,
    required this.balanceCents,
    required this.responsibleWhatsapp,
    required this.message,
    required this.url,
  });

  final ClientModel client;
  final int balanceCents;
  final String responsibleWhatsapp;
  final String message;
  final String url;

  factory WhatsappChargeDto.fromJson(dynamic json) {
    final data = json as Map<String, dynamic>;

    return WhatsappChargeDto(
      client: ClientModel.fromJson(data['client']),
      balanceCents: data['balanceCents'] as int,
      responsibleWhatsapp: data['responsibleWhatsapp'] as String,
      message: data['message'] as String,
      url: data['url'] as String,
    );
  }
}
