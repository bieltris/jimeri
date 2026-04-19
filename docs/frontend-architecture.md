# Arquitetura Do Frontend

Este documento registra a estrutura planejada para o frontend Flutter Web do Jimeri.

## Principios

- O frontend e administrativo.
- A UI nao acessa API diretamente.
- Telas usam providers.
- Providers usam services.
- Services usam o `apiClient`.
- Services retornam dados tipados.
- JSON fica concentrado em models/DTOs e services, nao nas telas.
- Access token fica em memoria.
- Refresh token fica em cookie `HttpOnly`.
- No Flutter Web, o client HTTP precisa enviar cookies com `withCredentials = true`.

## Estrutura

```text
lib/
  main.dart
  app.dart

  core/
    api/
      api_client.dart
      api_exception.dart
      auth_interceptor.dart

    auth/
      auth_controller.dart
      auth_service.dart
      auth_session.dart

    config/
      app_config.dart

    router/
      app_router.dart

    theme/
      app_theme.dart

    utils/
      money_formatter.dart
      whatsapp_link.dart

  models/
    user_model.dart
    client_model.dart
    product_model.dart
    order_model.dart
    order_item_model.dart
    payment_model.dart

  dtos/
    auth/
      login_request_dto.dart
      login_response_dto.dart
      refresh_response_dto.dart

    clients/
      client_with_balance_dto.dart
      create_client_request_dto.dart
      update_client_request_dto.dart

    products/
      create_product_request_dto.dart
      update_product_request_dto.dart

    orders/
      create_order_request_dto.dart
      order_with_items_dto.dart

    payments/
      create_payment_request_dto.dart

    reports/
      dashboard_summary_dto.dart

  services/
    clients_service.dart
    products_service.dart
    orders_service.dart
    payments_service.dart
    reports_service.dart

  shared/
    widgets/
    layout/

  features/
    login/
      login_screen.dart
      login_provider.dart

    dashboard/
      dashboard_screen.dart
      dashboard_provider.dart

    clients/
      clients_screen.dart
      clients_provider.dart
      widgets/

    client_details/
      client_details_screen.dart
      client_details_provider.dart
      widgets/

    products/
      products_screen.dart
      products_provider.dart
      widgets/

    order_form/
      order_form_screen.dart
      order_form_provider.dart
      widgets/

    payment_form/
      payment_form_screen.dart
      payment_form_provider.dart
      widgets/

    reports/
      reports_screen.dart
      reports_provider.dart
```

## Fluxo De Dados

```text
screen
  -> provider
  -> service
  -> apiClient
  -> backend
```

Na volta:

```text
backend JSON
  -> model ou DTO tipado
  -> service
  -> provider
  -> screen
```

## Models

Models representam entidades centrais do app.

Exemplos:

- `UserModel`
- `ClientModel`
- `ProductModel`
- `OrderModel`
- `OrderItemModel`
- `PaymentModel`

Use model quando a resposta da API for uma entidade ou lista simples de entidades.

Exemplo:

```text
GET /api/clients/:id -> ClientModel
GET /api/products -> List<ProductModel>
```

## DTOs

DTOs representam contratos especificos de request/response que nao cabem apenas em um model.

DTO nao substitui model.
DTO pode conter models dentro dele.

Use DTO quando:

- a request tem formato proprio;
- a response mistura uma entidade com dados calculados;
- a response e um resumo;
- a response representa uma operacao especifica.

Exemplos:

```text
LoginRequestDto
LoginResponseDto
ClientWithBalanceDto
DashboardSummaryDto
CreateOrderRequestDto
OrderWithItemsDto
```

Exemplo conceitual:

```dart
class ClientWithBalanceDto {
  final ClientModel client;
  final int balanceCents;

  ClientWithBalanceDto({
    required this.client,
    required this.balanceCents,
  });
}
```

## Services

Services chamam a API e devolvem dados tipados.

Responsabilidades:

- montar URL;
- chamar `apiClient`;
- enviar body quando necessario;
- decodificar JSON;
- devolver model ou DTO;
- transformar erros HTTP em excecoes do app.

Exemplo conceitual:

```dart
Future<List<ClientWithBalanceDto>> listClients();
Future<ClientModel> createClient(CreateClientRequestDto request);
```

## API Client

O `apiClient` e centralizado em `core/api`.

Responsabilidades:

- criar o client HTTP base;
- no Flutter Web, usar `BrowserClient` com `withCredentials = true`;
- permitir envio automatico do cookie `HttpOnly` do refresh token;
- aplicar `auth_interceptor`;
- ser reutilizado por todos os services.

## Auth

Arquivos de auth ficam em `core/auth`.

Responsabilidades:

- manter access token em memoria;
- fazer login;
- fazer refresh;
- fazer logout;
- limpar sessao;
- expor estado de autenticacao para o app.

Fluxo planejado:

```text
POST /api/auth/login
  -> retorna access token no JSON
  -> seta refresh token em cookie HttpOnly

POST /api/auth/refresh
  -> browser envia cookie automaticamente
  -> backend rotaciona refresh token
  -> retorna novo access token

POST /api/auth/logout
  -> revoga refresh token
  -> limpa cookie
```

## Interceptor

O `auth_interceptor` fica em `core/api`.

Responsabilidades:

- adicionar `Authorization: Bearer <accessToken>` em requests protegidas;
- nao adicionar access token nas rotas de login/refresh;
- ao receber `401`, tentar refresh uma vez;
- se o refresh funcionar, repetir a request original;
- se o refresh falhar, limpar a sessao e enviar o usuario para login.

