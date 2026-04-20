import '../core/api/api_client.dart';
import '../core/api/api_routes.dart';
import '../dtos/client_with_balance_dto.dart';
import '../dtos/whatsapp_charge_dto.dart';

class ClientsService {
  Future<List<ClientWithBalanceDto>> list({
    String? search,
  }) {
    return ApiClient.get<List<ClientWithBalanceDto>>(
      ApiRoutes.clients(search: search),
      fromJson: ApiClient.listFromJson(ClientWithBalanceDto.fromJson),
    );
  }

  Future<ClientWithBalanceDto> create({
    required String name,
    String? responsibleName,
    String? responsibleWhatsapp,
    String? note,
  }) {
    return ApiClient.post<ClientWithBalanceDto>(
      ApiRoutes.clients(),
      body: {
        'name': name,
        'responsibleName': responsibleName,
        'responsibleWhatsapp': responsibleWhatsapp,
        'note': note,
      },
      fromJson: ClientWithBalanceDto.fromJson,
    );
  }

  Future<ClientWithBalanceDto> update({
    required String id,
    required String name,
    required bool active,
    String? responsibleName,
    String? responsibleWhatsapp,
    String? note,
  }) {
    return ApiClient.put<ClientWithBalanceDto>(
      ApiRoutes.client(id),
      body: {
        'name': name,
        'responsibleName': responsibleName,
        'responsibleWhatsapp': responsibleWhatsapp,
        'note': note,
        'active': active,
      },
      fromJson: ClientWithBalanceDto.fromJson,
    );
  }

  Future<WhatsappChargeDto> whatsappCharge(String clientId) {
    return ApiClient.get<WhatsappChargeDto>(
      ApiRoutes.clientWhatsappCharge(clientId),
      fromJson: WhatsappChargeDto.fromJson,
    );
  }
}
