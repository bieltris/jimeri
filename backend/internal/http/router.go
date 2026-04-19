package http

import (
	"net/http"

	"github.com/bieltris/jimeri/backend/internal/features/health"
	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/jackc/pgx/v5/pgxpool"
)

func NewRouter(pool *pgxpool.Pool) http.Handler {
	router := chi.NewRouter()

	router.Use(middleware.RequestID)
	router.Use(middleware.RealIP)
	router.Use(middleware.Logger)
	router.Use(middleware.Recoverer)

	router.Route("/api", func(api chi.Router) {
		api.Get("/health", health.Handle(pool))
	})

	return router
}

