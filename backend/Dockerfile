FROM golang:1.26-alpine AS build

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /bin/jimeri-api ./cmd/api

FROM alpine:3.22

RUN adduser -D -H -u 10001 appuser

WORKDIR /app
COPY --from=build /bin/jimeri-api /app/jimeri-api

USER appuser

EXPOSE 8080

CMD ["/app/jimeri-api"]
