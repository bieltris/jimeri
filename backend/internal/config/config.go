package config

import "os"

type Config struct {
	AppEnv             string
	HTTPAddr          string
	DatabaseURL       string
	AccessTokenSecret string
	RefreshTokenSecret string
}

func Load() Config {
	return Config{
		AppEnv:              env("APP_ENV", "development"),
		HTTPAddr:           env("HTTP_ADDR", ":8080"),
		DatabaseURL:        env("DATABASE_URL", ""),
		AccessTokenSecret:  env("ACCESS_TOKEN_SECRET", ""),
		RefreshTokenSecret: env("REFRESH_TOKEN_SECRET", ""),
	}
}

func env(key string, fallback string) string {
	value := os.Getenv(key)
	if value == "" {
		return fallback
	}

	return value
}

