package health

import (
	"context"
	"net/http"
	"time"

	apphttp "github.com/bieltris/jimeri/backend/internal/http"
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
			apphttp.JSON(w, http.StatusServiceUnavailable, response{
				Status:   "degraded",
				Database: "unavailable",
			})
			return
		}

		apphttp.JSON(w, http.StatusOK, response{
			Status:   "ok",
			Database: "ok",
		})
	}
}

