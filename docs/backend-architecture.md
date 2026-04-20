# Arquitetura Do Backend

Este documento descreve a organizacao do backend Go do Jimeri.

## Visao Geral

O backend e uma API HTTP em Go.

Principais responsabilidades:

- autenticar usuarios administrativos;
- proteger rotas administrativas;
- acessar o PostgreSQL;
- aplicar regras de negocio;
- devolver respostas JSON tipadas para o frontend.
- gerar dados de cobranca por WhatsApp.

Stack principal:

- Go
- chi para roteamento HTTP
- pgx para PostgreSQL
- sqlc para gerar codigo Go a partir de SQL
- golang-migrate para migrations
- JWT para access token
- refresh token opaco em cookie HttpOnly
- CORS com credentials para Flutter Web

## Estrutura

```text
backend/
  cmd/
    api/
      main.go
    seed-admin/
      main.go

  db/
    migrations/
    queries/

  internal/
    auth/
    config/
    database/
    db/
    features/
    httpparam/
    http/
    pgconv/
    respond/
    uuidutil/
```

## Configuracao

Variaveis principais:

```text
APP_ENV
HTTP_ADDR
DATABASE_URL
ACCESS_TOKEN_SECRET
APP_TIMEZONE
CORS_ALLOWED_ORIGINS
REFRESH_COOKIE_NAME
REFRESH_COOKIE_SECURE
```

`CORS_ALLOWED_ORIGINS` deve conter as origens do frontend separadas por virgula.

Exemplo:

```text
http://localhost:3000,http://localhost:8081
```

Como o refresh token usa cookie HttpOnly, o CORS precisa permitir credentials.

## Executaveis

Cada pasta dentro de `cmd/` representa um executavel.

```text
cmd/api
```

Sobe o servidor HTTP da API.

```text
cmd/seed-admin
```

Cria o primeiro usuario administrador no banco.

## Rotas HTTP

O roteador principal fica em:

```text
internal/http/router.go
```

Ele registra middlewares globais, rotas publicas e rotas protegidas.

Exemplo conceitual:

```text
/api/health
/api/auth
/api/clients
/api/orders
/api/payments
/api/products
/api/reports
```

Rotas administrativas ficam dentro de um grupo protegido por autenticação.

## Docker

O backend tem `Dockerfile` proprio em:

```text
backend/Dockerfile
```

O `docker-compose.yml` da raiz sobe:

- API Go;
- PostgreSQL local.

## Features

Cada modulo de negocio fica em:

```text
internal/features/<nome>
```

Padrao usado nas features principais:

```text
handler.go
controllers.go
requests.go
responses.go
```

### handler.go

Registra dependencias e rotas da feature.

Responsabilidades:

- criar `Handler`;
- receber dependencias, como `db.Queries`;
- mapear URLs para funcoes do controller.

### controllers.go

Orquestra cada endpoint HTTP.

Responsabilidades:

- ler parametros;
- chamar validacao de request;
- chamar queries ou servicos;
- tratar erros;
- montar resposta.

### requests.go

Define contratos de entrada e validacoes.

Responsabilidades:

- decodificar JSON;
- validar campos obrigatorios;
- converter parametros de URL;
- converter valores de request para tipos usados pelo banco.

### responses.go

Define contratos de saida.

Responsabilidades:

- transformar modelos do banco em JSON;
- esconder campos internos;
- montar DTOs quando a resposta tem dados agregados.

## Acesso Ao Banco

SQL fica em:

```text
db/queries
```

O `sqlc` gera codigo Go em:

```text
internal/db
```

O backend usa as funcoes geradas pelo `sqlc`, por exemplo:

```text
CreateClient
ListClients
UpdateProduct
```

Isso evita SQL espalhado por handlers e mantem as queries tipadas.

## pgtype

O projeto usa `pgtype` porque o PostgreSQL tem valores nulos.

Exemplo:

```text
pgtype.Text{}
```

Representa `NULL`.

```text
pgtype.Text{String: "Maria", Valid: true}
```

Representa o texto `"Maria"`.

Conversoes comuns ficam em:

```text
internal/pgconv
```

## Helpers HTTP

Leitura de parametros comuns fica em:

```text
internal/httpparam
```

Exemplo:

```text
UUID
```

Esse helper le um UUID da URL e responde erro `400` quando o valor e invalido.

## Respostas JSON

Respostas padronizadas ficam em:

```text
internal/respond
```

Responsabilidades:

- escrever JSON;
- escrever erros em formato consistente.

## Autenticacao

Autenticacao usa:

- access token JWT de curta duracao;
- refresh token opaco de longa duracao;
- refresh token salvo no banco apenas como hash;
- refresh token enviado ao browser em cookie HttpOnly.

Rotas:

```text
POST /api/auth/login
POST /api/auth/refresh
POST /api/auth/logout
GET  /api/auth/me
```

Rotas administrativas usam middleware de autenticação.

## Pagamentos

Pagamentos diminuem a divida calculada do cliente.

Regra inicial:

- o valor deve ser maior que zero;
- o cliente precisa ter divida;
- pagamento maior que a divida nao e permitido;
- pagamentos cancelados nao entram no calculo da divida.

## Relatorios

Relatorios usam queries tipadas e dados calculados pelo banco.

Endpoints iniciais:

```text
GET /api/reports/dashboard
GET /api/reports/debts
```

O dashboard usa `APP_TIMEZONE` para calcular o intervalo do dia.

## Cobranca Por WhatsApp

A cobranca por WhatsApp e gerada a partir do cliente e da divida atual.

Endpoint inicial:

```text
GET /api/clients/{clientID}/whatsapp-charge
```

O backend devolve:

- cliente;
- saldo em aberto;
- numero do responsavel;
- mensagem sugerida;
- URL `https://wa.me/...` pronta para abrir no frontend.

## Fluxo De Uma Request

Exemplo: criar produto.

```text
POST /api/products
  -> router.go
  -> products/handler.go
  -> products/controllers.go
  -> products/requests.go
  -> internal/db gerado pelo sqlc
  -> products/responses.go
  -> respond.JSON
```

## Regras De Organizacao

- Handlers nao devem conter SQL manual.
- Controllers devem orquestrar, nao concentrar conversoes repetidas.
- Requests validam entrada.
- Responses montam saida.
- Helpers compartilhados devem ficar em pacotes pequenos dentro de `internal`.
- Campos monetarios sempre usam centavos.
- Registros financeiros devem ser cancelados, nao apagados.
