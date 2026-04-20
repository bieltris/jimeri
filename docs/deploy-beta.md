# Deploy Beta

Guia curto para subir a primeira versao funcional em producao.

Stack da beta:

- Banco: Neon Postgres
- API: Fly.io
- Frontend: Cloudflare Pages, com upload direto do build

## 1. Criar Banco No Neon

No Neon, crie um projeto Postgres e copie a connection string.

Use a connection string com `sslmode=require`, por exemplo:

```text
postgresql://USER:PASSWORD@HOST/jimeri?sslmode=require
```

Se o Neon oferecer duas strings, prefira a pooled connection para a API.

## 2. Rodar Migrations No Banco De Producao

Na raiz do projeto:

```powershell
migrate -path backend/db/migrations -database "postgresql://USER:PASSWORD@HOST/jimeri?sslmode=require" up
```

## 3. Criar Admin Da Beta

Na pasta `backend`:

```powershell
$env:DATABASE_URL="postgresql://USER:PASSWORD@HOST/jimeri?sslmode=require"
$env:ACCESS_TOKEN_SECRET="qualquer-secret-temporario-so-para-o-seed"
$env:ADMIN_NAME="Admin"
$env:ADMIN_EMAIL="admin@"
$env:ADMIN_PASSWORD="123456"
go run ./cmd/seed-admin
```

Depois da beta estar no ar, troque a senha por uma senha real.

## 4. Criar App No Fly.io

Instale e autentique no Fly:

```powershell
fly auth login
```

Entre na pasta `backend` e crie o app sem deploy automatico:

```powershell
cd backend
fly launch --no-deploy
```

Se o nome `jimeri-api` nao estiver disponivel, escolha outro nome e atualize `app` no `backend/fly.toml`.

## 5. Configurar Secrets Da API

Ainda na pasta `backend`:

```powershell
fly secrets set DATABASE_URL="postgresql://USER:PASSWORD@HOST/jimeri?sslmode=require"
fly secrets set ACCESS_TOKEN_SECRET="gere-um-secret-grande-aqui"
fly secrets set CORS_ALLOWED_ORIGINS="https://SEU-PROJETO.pages.dev"
```

No primeiro deploy, se voce ainda nao souber a URL do Cloudflare Pages, use temporariamente:

```powershell
fly secrets set CORS_ALLOWED_ORIGINS="http://localhost:3000"
```

Depois de criar o frontend no Cloudflare, atualize para a URL real.

## 6. Subir API No Fly

Na pasta `backend`:

```powershell
fly deploy
```

Teste:

```powershell
fly status
fly logs
```

Health check:

```text
https://NOME-DO-APP.fly.dev/api/health
```

## 7. Buildar Frontend Para Producao

Na pasta `frontend`, substitua a URL pelo app real do Fly:

```powershell
flutter build web --release --dart-define=API_BASE_URL=https://NOME-DO-APP.fly.dev/api
```

O build fica em:

```text
frontend/build/web
```

## 8. Subir Frontend No Cloudflare Pages

Instale ou rode Wrangler com `npx`:

```powershell
npx wrangler login
```

Na pasta `frontend`:

```powershell
npx wrangler pages deploy build/web --project-name=jimeri
```

O Cloudflare vai retornar uma URL parecida com:

```text
https://jimeri.pages.dev
```

## 9. Atualizar CORS Com A URL Real

Volte para a pasta `backend`:

```powershell
fly secrets set CORS_ALLOWED_ORIGINS="https://jimeri.pages.dev"
fly deploy
```

## 10. Teste Final Da Beta

Teste em producao:

- Login com admin
- Criar cliente
- Criar produto
- Lancar pedido
- Ver divida no cliente
- Registrar pagamento
- Cobrar pelo WhatsApp

Se algum passo falhar, olhe primeiro:

```powershell
fly logs
```

## Observacoes

- Nao commite secrets reais.
- O arquivo `backend/.env.production.example` e apenas modelo.
- O refresh token usa cookie seguro em producao, entao precisa de HTTPS.
- Cloudflare Pages e Fly ja entregam HTTPS por padrao.
