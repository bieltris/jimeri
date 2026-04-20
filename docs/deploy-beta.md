# Deploy Beta

Guia curto para subir a primeira versao funcional em producao.

Stack da beta:

- Banco: Neon Postgres
- API: Koyeb com Dockerfile
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

## 4. Criar API No Koyeb

No painel do Koyeb:

1. Crie um App chamado `jimeri-api`.
2. Escolha deploy por GitHub.
3. Selecione o repositorio `bieltris/jimeri`.
4. Escolha a branch `main`.
5. Em Builder, escolha `Dockerfile`.
6. Em Work directory, coloque:

```text
backend
```

7. Em Dockerfile location, deixe:

```text
Dockerfile
```

8. Em Port, use:

```text
8080
```

## 5. Configurar Variaveis Da API No Koyeb

No service da API, configure as variaveis:

```text
APP_ENV=production
HTTP_ADDR=:8080
DATABASE_URL=postgresql://USER:PASSWORD@HOST/jimeri?sslmode=require
ACCESS_TOKEN_SECRET=gere-um-secret-grande-aqui
APP_TIMEZONE=America/Sao_Paulo
CORS_ALLOWED_ORIGINS=http://localhost:3000
REFRESH_COOKIE_NAME=jimeri_refresh_token
REFRESH_COOKIE_SECURE=true
```

No primeiro deploy, se voce ainda nao souber a URL do Cloudflare Pages, use temporariamente `http://localhost:3000` no CORS.

Depois de criar o frontend no Cloudflare, atualize `CORS_ALLOWED_ORIGINS` para a URL real do Cloudflare Pages.

Para gerar um secret localmente:

```powershell
[Convert]::ToBase64String((1..48 | ForEach-Object { Get-Random -Maximum 256 }))
```

## 6. Subir API No Koyeb

Clique para criar/deployar o service.

Quando terminar, o Koyeb vai fornecer uma URL parecida com:

```text
https://jimeri-api-SEU-USUARIO.koyeb.app
```

Teste:

```text
https://jimeri-api-SEU-USUARIO.koyeb.app/api/health
```

## 7. Buildar Frontend Para Producao

Na pasta `frontend`, substitua a URL pela URL real do Koyeb:

```powershell
flutter build web --release --dart-define=API_BASE_URL=https://jimeri-api-SEU-USUARIO.koyeb.app/api
```

O build fica em:

```text
frontend/build/web
```

## 8. Subir Frontend No Cloudflare Pages

Rode login se ainda nao fez:

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

Volte no Koyeb e altere:

```text
CORS_ALLOWED_ORIGINS=https://jimeri.pages.dev
```

Depois redeploye a API.

## 10. Teste Final Da Beta

Teste em producao:

- Login com admin
- Criar cliente
- Criar produto
- Lancar pedido
- Ver divida no cliente
- Registrar pagamento
- Cobrar pelo WhatsApp

Se algum passo falhar, olhe primeiro os logs do service no Koyeb.

## Observacoes

- Nao commite secrets reais.
- O arquivo `backend/.env.production.example` e apenas modelo.
- O refresh token usa cookie seguro em producao, entao precisa de HTTPS.
- Cloudflare Pages e Koyeb entregam HTTPS por padrao.
