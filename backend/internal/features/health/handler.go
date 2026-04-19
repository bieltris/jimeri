package health

import (
	"context"
	"net/http"
	"time"

	"github.com/bieltris/jimeri/backend/internal/respond"
	"github.com/jackc/pgx/v5/pgxpool"
)

type response struct {
	Status   string `json:"status"`
	Database string `json:"database"`
}

func Handle(pool *pgxpool.Pool) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
		defer cancel()

		if err := pool.Ping(ctx); err != nil {
			respond.JSON(w, http.StatusServiceUnavailable, response{
				Status:   "degraded",
				Database: "unavailable",
			})
			return
		}

		respond.JSON(w, http.StatusOK, response{
			Status:   "ok",
			Database: "ok",
		})
	}
}
