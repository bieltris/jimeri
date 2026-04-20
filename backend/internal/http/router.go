package http

import (
	"net/http"

	"github.com/bieltris/jimeri/backend/internal/config"
	"github.com/bieltris/jimeri/backend/internal/features/auth"
	"github.com/bieltris/jimeri/backend/internal/features/clients"
	"github.com/bieltris/jimeri/backend/internal/features/health"
	"github.com/bieltris/jimeri/backend/internal/features/orders"
	"github.com/bieltris/jimeri/backend/internal/features/payments"
	"github.com/bieltris/jimeri/backend/internal/features/products"
	"github.com/bieltris/jimeri/backend/internal/features/reports"
	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/jackc/pgx/v5/pgxpool"
)

func NewRouter(pool *pgxpool.Pool, cfg config.Config) http.Handler {
	router := chi.NewRouter()

	router.Use(middleware.RequestID)
	router.Use(middleware.RealIP)
	router.Use(middleware.Logger)
	router.Use(middleware.Recoverer)
	router.Use(CORS(cfg.CORSAllowedOrigins))

	authHandler := auth.NewHandler(pool, cfg)
	clientsHandler := clients.NewHandler(pool)
	ordersHandler := orders.NewHandler(pool)
	paymentsHandler := payments.NewHandler(pool)
	productsHandler := products.NewHandler(pool)
	reportsHandler := reports.NewHandler(pool, cfg)

	router.Route("/api", func(api chi.Router) {
		api.Get("/health", health.Handle(pool))
		api.Mount("/auth", authHandler.Routes())

		api.Group(func(protected chi.Router) {
			protected.Use(authHandler.RequireAuth)
			protected.Mount("/clients", clientsHandler.Routes())
			protected.Mount("/orders", ordersHandler.Routes())
			protected.Mount("/payments", paymentsHandler.Routes())
			protected.Mount("/products", productsHandler.Routes())
			protected.Mount("/reports", reportsHandler.Routes())
		})
	})

	return router
}
