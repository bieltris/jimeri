# Deploy Do Backend

Guia inicial para publicar a API Go.

## Infra Planejada

- API Go: Fly.io
- Banco PostgreSQL: Neon
- Frontend Flutter Web: Cloudflare Pages

## Variaveis Da API

Configurar no provedor da API:

```text
APP_ENV=production
HTTP_ADDR=:8080
DATABASE_URL=postgres://USER:PASSWORD@HOST/jimeri?sslmode=require
ACCESS_TOKEN_SECRET=<segredo-longo>
APP_TIMEZONE=America/Sao_Paulo
CORS_ALLOWED_ORIGINS=https://seu-frontend.pages.dev
REFRESH_COOKIE_NAME=jimeri_refresh_token
REFRESH_COOKIE_SECURE=true
```

`CORS_ALLOWED_ORIGINS` deve ser exatamente a origem do frontend.

## Banco

Antes de subir a API em producao, aplicar migrations no banco Neon:

```powershell
cd backend
migrate -path db/migrations -database "postgres://USER:PASSWORD@HOST/jimeri?sslmode=require" up
```

Depois criar o primeiro admin:

```powershell
$env:DATABASE_URL="postgres://USER:PASSWORD@HOST/jimeri?sslmode=require"
$env:ADMIN_NAME="Admin"
$env:ADMIN_EMAIL="admin@escola.com"
$env:ADMIN_PASSWORD="<senha-forte>"
go run ./cmd/seed-admin
```

## Fly.io

O backend tem Dockerfile em:

```text
backend/Dockerfile
```

Deploy a partir da pasta `backend`:

```powershell
cd backend
fly launch
fly secrets set DATABASE_URL="postgres://USER:PASSWORD@HOST/jimeri?sslmode=require"
fly secrets set ACCESS_TOKEN_SECRET="<segredo-longo>"
fly secrets set CORS_ALLOWED_ORIGINS="https://seu-frontend.pages.dev"
fly secrets set APP_ENV="production"
fly secrets set APP_TIMEZONE="America/Sao_Paulo"
fly secrets set REFRESH_COOKIE_NAME="jimeri_refresh_token"
fly secrets set REFRESH_COOKIE_SECURE="true"
fly deploy
```

## Observacoes

- A API nao roda migrations automaticamente no boot.
- O refresh token depende de cookie HttpOnly.
- Em producao, o cookie precisa de `Secure=true`.
- O frontend deve enviar requests com credentials habilitado.

