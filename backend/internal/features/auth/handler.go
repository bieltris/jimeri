package auth

import (
	"net/http"

	authcore "github.com/bieltris/jimeri/backend/internal/auth"
	"github.com/bieltris/jimeri/backend/internal/config"
	"github.com/bieltris/jimeri/backend/internal/db"
	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Handler struct {
	pool                *pgxpool.Pool
	queries             *db.Queries
	tokens              *authcore.TokenManager
	refreshCookieName   string
	refreshCookieSecure bool
}

func NewHandler(pool *pgxpool.Pool, cfg config.Config) *Handler {
	tokens, err := authcore.NewTokenManager(cfg.AccessTokenSecret)
	if err != nil {
		panic(err)
	}

	return &Handler{
		pool:                pool,
		queries:             db.New(pool),
		tokens:              tokens,
		refreshCookieName:   cfg.RefreshCookieName,
		refreshCookieSecure: cfg.RefreshCookieSecure,
	}
}

func (h *Handler) Routes() http.Handler {
	router := chi.NewRouter()

	router.Post("/login", h.login)
	router.Post("/refresh", h.refresh)
	router.Post("/logout", h.logout)

	router.Group(func(protected chi.Router) {
		protected.Use(authcore.RequireAuth(h.tokens))
		protected.Get("/me", h.me)
	})

	return router
}

func (h *Handler) RequireAuth(next http.Handler) http.Handler {
	return authcore.RequireAuth(h.tokens)(next)
}
