package payments

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

	router.Post("/", h.create)
	router.Get("/client/{clientID}", h.listByClient)
	router.Get("/{paymentID}", h.get)
	router.Post("/{paymentID}/cancel", h.cancel)

	return router
}
