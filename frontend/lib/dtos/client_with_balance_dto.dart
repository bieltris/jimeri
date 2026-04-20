import '../models/client_model.dart';

class ClientWithBalanceDto {
  const ClientWithBalanceDto({
    required this.client,
    required this.balanceCents,
  });

  final ClientModel client;
  final int balanceCents;

  factory ClientWithBalanceDto.fromJson(dynamic json) {
    final data = json as Map<String, dynamic>;

    return ClientWithBalanceDto(
      client: ClientModel.fromJson(data['client']),
      balanceCents: data['balanceCents'] as int,
    );
  }
}
