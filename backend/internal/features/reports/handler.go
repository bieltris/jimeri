package reports

import (
	"net/http"
	"time"

	"github.com/bieltris/jimeri/backend/internal/config"
	"github.com/bieltris/jimeri/backend/internal/db"
	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Handler struct {
	queries  *db.Queries
	location *time.Location
}

func NewHandler(pool *pgxpool.Pool, cfg config.Config) *Handler {
	location, err := time.LoadLocation(cfg.AppTimezone)
	if err != nil {
		location = time.FixedZone("UTC", 0)
	}

	return &Handler{
		queries:  db.New(pool),
		location: location,
	}
}

func (h *Handler) Routes() http.Handler {
	router := chi.NewRouter()

	router.Get("/dashboard", h.dashboard)
	router.Get("/debts", h.debts)

	return router
}
