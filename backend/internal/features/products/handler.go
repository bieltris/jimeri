package products

import (
	"net/http"

	"github.com/bieltris/jimeri/backend/internal/db"
	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Handler struct {
	queries *db.Queries
}

func NewHandler(pool *pgxpool.Pool) *Handler {
	return &Handler{queries: db.New(pool)}
}

func (h *Handler) Routes() http.Handler {
	router := chi.NewRouter()

	router.Get("/", h.list)
	router.Post("/", h.create)
	router.Get("/active", h.listActive)
	router.Get("/categories", h.listCategories)
	router.Post("/categories", h.createCategory)
	router.Get("/categories/active", h.listActiveCategories)
	router.Put("/categories/{categoryID}", h.updateCategory)
	router.Get("/{productID}", h.get)
	router.Put("/{productID}", h.update)

	return router
}
