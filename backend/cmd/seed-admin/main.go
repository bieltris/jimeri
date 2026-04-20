package main

import (
	"context"
	"errors"
	"log"
	"os"
	"time"

	"github.com/bieltris/jimeri/backend/internal/config"
	"github.com/bieltris/jimeri/backend/internal/database"
	"github.com/bieltris/jimeri/backend/internal/db"
	"github.com/bieltris/jimeri/backend/internal/envfile"
	"github.com/jackc/pgx/v5"
	"golang.org/x/crypto/bcrypt"
)

func main() {
	if err := envfile.Load(".env"); err != nil {
		log.Fatalf("load .env: %v", err)
	}

	cfg := config.Load()

	name := env("ADMIN_NAME", "Admin")
	email := env("ADMIN_EMAIL", "")
	password := env("ADMIN_PASSWORD", "")

	if email == "" || password == "" {
		log.Fatal("ADMIN_EMAIL and ADMIN_PASSWORD are required")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	pool, err := database.Connect(ctx, cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("connect database: %v", err)
	}
	defer pool.Close()

	passwordHash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		log.Fatalf("hash password: %v", err)
	}

	queries := db.New(pool)

	existing, err := queries.GetUserByEmail(ctx, email)
	if err == nil {
		log.Printf("admin already exists: %s <%s>", existing.Name, existing.Email)
		return
	}
	if !errors.Is(err, pgx.ErrNoRows) {
		log.Fatalf("check existing admin: %v", err)
	}

	user, err := queries.CreateUser(ctx, db.CreateUserParams{
		Name:         name,
		Email:        email,
		PasswordHash: string(passwordHash),
		Role:         "admin",
	})
	if err != nil {
		log.Fatalf("create admin: %v", err)
	}

	log.Printf("admin created: %s <%s>", user.Name, user.Email)
}

func env(key string, fallback string) string {
	value := os.Getenv(key)
	if value == "" {
		return fallback
	}

	return value
}
