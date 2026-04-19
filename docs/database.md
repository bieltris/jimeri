# Banco de Dados

Este documento define o banco inicial do sistema administrativo da cantina.

## Decisoes

- Banco: PostgreSQL.
- Migrations: golang-migrate.
- IDs: UUID com `gen_random_uuid()`.
- Datas: `timestamptz`.
- Valores monetarios: sempre em centavos, usando `bigint`.
- Compras e pagamentos nao devem ser apagados: devem ser cancelados.
- Divida e calculada, nao armazenada fixa no cliente.
- Produtos salvam snapshot no item do pedido: nome e preco do momento da venda.
- Sistema inicialmente administrativo, sem tela de cliente/aluno.
- Clientes terao dados do responsavel para cobranca via WhatsApp.

## Calculo da Divida

A divida atual de um cliente e:

```sql
total de pedidos nao cancelados - total de pagamentos nao cancelados
```

Pedidos cancelados nao entram no calculo.
Pagamentos cancelados nao entram no calculo.

## WhatsApp

O sistema tera um botao para cobrar o responsavel pelo WhatsApp.

O banco salva o numero limpo, apenas com digitos e codigo do pais:

```text
5511999999999
```

O frontend gera o link:

```text
https://wa.me/NUMERO?text=MENSAGEM
```

Exemplo de mensagem:

```text
Ola, Maria. Tudo bem? Aqui e da cantina da escola.
Consta um valor em aberto de R$ 27,50 referente as compras de Joao.
Pode verificar, por favor?
```

## Tabelas

### users

Usuarios administrativos do sistema.

```text
id
name
email
password_hash
role
created_at
updated_at
```

Regras:

- `email` deve ser unico, comparando em lowercase.
- `role` nasce preparado para mais perfis.
- Perfis iniciais: `admin`, `staff`.

### refresh_tokens

Tokens de renovacao de sessao.

```text
id
user_id
token_hash
expires_at
revoked_at
created_at
```

Regras:

- Salvar apenas hash do refresh token.
- `revoked_at` preenchido quando o token for invalidado.
- A rotacao de refresh token revoga o token antigo e cria um novo.

### clients

Clientes/alunos marcados na cantina.

```text
id
name
responsible_name
responsible_whatsapp
note
active
created_at
updated_at
```

Regras:

- `name` e obrigatorio.
- `responsible_whatsapp` deve ser salvo apenas com numeros.
- `active = false` desativa o cliente sem apagar historico.

### products

Produtos vendidos pela cantina.

```text
id
name
category
price_cents
active
created_at
updated_at
```

Regras:

- `price_cents` deve ser maior ou igual a zero.
- `active = false` desativa o produto sem apagar historico.

### orders

Pedidos/compras marcadas para um cliente.

```text
id
client_id
created_by
note
cancelled_at
cancelled_by
cancel_reason
created_at
```

Regras:

- Pedido cancelado nao entra na divida.
- Cancelamento deve guardar usuario, data e motivo.

### order_items

Itens de cada pedido.

```text
id
order_id
product_id
product_name
quantity
unit_price_cents
created_at
```

Regras:

- `product_name` e `unit_price_cents` sao snapshots do momento da venda.
- Se o produto mudar de nome ou preco depois, o historico continua correto.
- `quantity` deve ser maior que zero.
- `unit_price_cents` deve ser maior ou igual a zero.

### payments

Pagamentos feitos por clientes/responsaveis.

```text
id
client_id
amount_cents
note
created_by
cancelled_at
cancelled_by
cancel_reason
created_at
```

Regras:

- Pagamento cancelado nao entra na divida.
- `amount_cents` deve ser maior que zero.
- No MVP, pagamento maior que a divida nao sera permitido pela regra da API.

## Views

### client_balances

View para consultar saldo atual dos clientes.

Campos:

```text
client_id
orders_total_cents
payments_total_cents
balance_cents
```

`balance_cents` positivo significa divida em aberto.

## Indices Importantes

- `users`: email unico em lowercase.
- `refresh_tokens`: token_hash unico.
- `clients`: busca por nome.
- `products`: busca por nome e categoria.
- `orders`: busca por cliente e data.
- `payments`: busca por cliente e data.

