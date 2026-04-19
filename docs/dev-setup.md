# Setup de Desenvolvimento

Guia para preparar a maquina local e trabalhar no sistema.

## Ferramentas

Instalar:

- Git
- Go
- Flutter
- Docker Desktop
- sqlc
- golang-migrate

Opcional:

- PostgreSQL local, caso nao queira usar Docker.

## Instalacao Rapida Com Scoop

Se estiver no Windows, o caminho mais simples e usar Scoop.

Instalar ferramentas basicas:

```powershell
scoop install git go
```

O Flutter pode exigir o bucket `extras`:

```powershell
scoop bucket add extras
scoop install flutter
```

Instalar PostgreSQL local pelo Scoop:

```powershell
scoop install postgresql
```

Depois de instalar novas ferramentas, feche e abra o PowerShell se algum comando ainda nao aparecer no PATH.

## Ordem Recomendada

1. Instalar Go.
2. Instalar Flutter.
3. Instalar Docker Desktop.
4. Instalar sqlc e golang-migrate usando Go.
5. Rodar o PostgreSQL local com Docker Compose.
6. Rodar migrations.
7. Gerar codigo do sqlc.
8. Subir a API.

## Go

Depois de instalar o Go, conferir:

```powershell
go version
```

Adicionar o binario do Go user ao PATH se necessario:

```text
%USERPROFILE%\go\bin
```

## Flutter

Depois de instalar o Flutter, conferir:

```powershell
flutter doctor
```

Para web, garantir que o suporte esteja habilitado:

```powershell
flutter config --enable-web
```

## Docker Desktop

Depois de instalar, abrir o Docker Desktop uma vez e esperar ele iniciar.

Conferir:

```powershell
docker --version
docker compose version
```

## sqlc

Instalar depois do Go:

```powershell
go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest
```

Conferir:

```powershell
sqlc version
```

## golang-migrate

Instalar depois do Go:

```powershell
go install -tags "postgres" github.com/golang-migrate/migrate/v4/cmd/migrate@latest
```

Conferir:

```powershell
migrate -version
```

## Banco Local

### Com Docker

Subir PostgreSQL local com Docker:

```powershell
docker compose up -d postgres
```

String local:

```text
postgres://postgres:postgres@localhost:5432/jimeri?sslmode=disable
```

### Com PostgreSQL Do Scoop

Iniciar o PostgreSQL instalado pelo Scoop:

```powershell
pg_ctl start -l "$env:USERPROFILE\scoop\apps\postgresql\current\data\postgres.log"
```

Criar o banco:

```powershell
createdb -U postgres jimeri
```

Opcionalmente, definir a senha local do usuario `postgres` para combinar com o `.env.example`:

```powershell
psql -U postgres -c "ALTER USER postgres PASSWORD 'postgres';"
```

String local:

```text
postgres://postgres:postgres@localhost:5432/jimeri?sslmode=disable
```

Parar o PostgreSQL:

```powershell
pg_ctl stop
```

Se o terminal mostrar logs do PostgreSQL e `Ctrl+C` derrubar o banco, inicie usando o `-l` acima para mandar os logs para arquivo.

## Flutter: Erro De Memoria Na Primeira Execucao

Na primeira execucao, o Flutter compila a propria ferramenta e pode consumir bastante memoria.

Se aparecer `Out of memory` em `flutter --version` ou `flutter doctor`:

1. Feche programas pesados.
2. Feche e abra o PowerShell.
3. Rode novamente:

```powershell
flutter doctor
```

Se continuar, reinicie o Windows e tente de novo. Em maquinas com pouca RAM, confira se a memoria virtual/pagefile do Windows esta habilitada como "gerenciada pelo sistema".

## Backend

Entrar na pasta:

```powershell
cd backend
```

Copiar `.env.example` para `.env` e ajustar se necessario.

Rodar migrations:

```powershell
migrate -path db/migrations -database "postgres://postgres:postgres@localhost:5432/jimeri?sslmode=disable" up
```

Gerar codigo do sqlc:

```powershell
sqlc generate
```

Baixar dependencias:

```powershell
go mod tidy
```

Subir API:

```powershell
go run ./cmd/api
```

Health check:

```text
http://localhost:8080/api/health
```

## Criar Admin Local

Depois das migrations, crie o primeiro usuario administrativo:

```powershell
$env:DATABASE_URL="postgres://postgres:postgres@localhost:5432/jimeri?sslmode=disable"
$env:ADMIN_NAME="Admin"
$env:ADMIN_EMAIL="admin@jimeri.local"
$env:ADMIN_PASSWORD="admin123456"
go run ./cmd/seed-admin
```

Para rodar a API local com auth:

```powershell
$env:DATABASE_URL="postgres://postgres:postgres@localhost:5432/jimeri?sslmode=disable"
$env:ACCESS_TOKEN_SECRET="dev-access-secret"
$env:REFRESH_COOKIE_SECURE="false"
go run ./cmd/api
```

Endpoints iniciais:

```text
POST /api/auth/login
POST /api/auth/refresh
POST /api/auth/logout
GET  /api/auth/me
```
