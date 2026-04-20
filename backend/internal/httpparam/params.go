package httpparam

import (
	"net/http"

	"github.com/bieltris/jimeri/backend/internal/respond"
	"github.com/bieltris/jimeri/backend/internal/uuidutil"
	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

func UUID(w http.ResponseWriter, r *http.Request, name string, message string) (pgtype.UUID, bool) {
	value, err := uuidutil.FromString(chi.URLParam(r, name))
	if err != nil {
		respond.Error(w, http.StatusBadRequest, message)
		return pgtype.UUID{}, false
	}

	return value, true
}
