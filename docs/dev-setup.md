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

Subir PostgreSQL local:

```powershell
docker compose up -d postgres
```

String local:

```text
postgres://postgres:postgres@localhost:5432/jimeri?sslmode=disable
```

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

