package products

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/bieltris/jimeri/backend/internal/respond"
	"github.com/bieltris/jimeri/backend/internal/uuidutil"
	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

type productRequest struct {
	Name       string  `json:"name"`
	Category   *string `json:"category"`
	PriceCents int64   `json:"priceCents"`
	Active     *bool   `json:"active"`
}

func parseProductRequest(w http.ResponseWriter, r *http.Request) (productRequest, bool) {
	var input productRequest
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		respond.Error(w, http.StatusBadRequest, "invalid request body")
		return productRequest{}, false
	}

	input.Name = strings.TrimSpace(input.Name)
	if input.Name == "" {
		respond.Error(w, http.StatusBadRequest, "name is required")
		return productRequest{}, false
	}

	if input.PriceCents < 0 {
		respond.Error(w, http.StatusBadRequest, "priceCents must be greater than or equal to zero")
		return productRequest{}, false
	}

	return input, true
}

func productIDParam(w http.ResponseWriter, r *http.Request) (pgtype.UUID, bool) {
	productID, err := uuidutil.FromString(chi.URLParam(r, "productID"))
	if err != nil {
		respond.Error(w, http.StatusBadRequest, "invalid product id")
		return pgtype.UUID{}, false
	}

	return productID, true
}

func textFromPointer(value *string) pgtype.Text {
	if value == nil {
		return pgtype.Text{}
	}

	trimmed := strings.TrimSpace(*value)
	if trimmed == "" {
		return pgtype.Text{}
	}

	return pgtype.Text{String: trimmed, Valid: true}
}

func textParam(value string) pgtype.Text {
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		return pgtype.Text{}
	}

	return pgtype.Text{String: trimmed, Valid: true}
}
