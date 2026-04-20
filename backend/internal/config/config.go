package config

import (
	"os"
	"strings"
)

type Config struct {
	AppEnv              string
	HTTPAddr            string
	DatabaseURL         string
	AccessTokenSecret   string
	AppTimezone         string
	RefreshCookieName   string
	RefreshCookieSecure bool
}

func Load() Config {
	appEnv := env("APP_ENV", "development")

	return Config{
		AppEnv:              appEnv,
		HTTPAddr:            env("HTTP_ADDR", ":8080"),
		DatabaseURL:         env("DATABASE_URL", ""),
		AccessTokenSecret:   env("ACCESS_TOKEN_SECRET", ""),
		AppTimezone:         env("APP_TIMEZONE", "America/Sao_Paulo"),
		RefreshCookieName:   env("REFRESH_COOKIE_NAME", "jimeri_refresh_token"),
		RefreshCookieSecure: envBool("REFRESH_COOKIE_SECURE", appEnv == "production"),
	}
}

func env(key string, fallback string) string {
	value := os.Getenv(key)
	if value == "" {
		return fallback
	}

	return value
}

func envBool(key string, fallback bool) bool {
	value := strings.ToLower(strings.TrimSpace(os.Getenv(key)))
	if value == "" {
		return fallback
	}

	return value == "1" || value == "true" || value == "yes"
}
