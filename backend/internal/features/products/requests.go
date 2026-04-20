package products

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/bieltris/jimeri/backend/internal/httpparam"
	"github.com/bieltris/jimeri/backend/internal/pgconv"
	"github.com/bieltris/jimeri/backend/internal/respond"
	"github.com/bieltris/jimeri/backend/internal/uuidutil"
	"github.com/jackc/pgx/v5/pgtype"
)

type productRequest struct {
	Name       string  `json:"name"`
	CategoryID *string `json:"categoryId"`
	PriceCents int64   `json:"priceCents"`
	Active     *bool   `json:"active"`
}

type productCategoryRequest struct {
	Name   string `json:"name"`
	Active *bool  `json:"active"`
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

func parseProductCategoryRequest(w http.ResponseWriter, r *http.Request) (productCategoryRequest, bool) {
	var input productCategoryRequest
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		respond.Error(w, http.StatusBadRequest, "invalid request body")
		return productCategoryRequest{}, false
	}

	input.Name = strings.TrimSpace(input.Name)
	if input.Name == "" {
		respond.Error(w, http.StatusBadRequest, "name is required")
		return productCategoryRequest{}, false
	}

	return input, true
}

func productIDParam(w http.ResponseWriter, r *http.Request) (pgtype.UUID, bool) {
	return httpparam.UUID(w, r, "productID", "invalid product id")
}

func productCategoryIDParam(w http.ResponseWriter, r *http.Request) (pgtype.UUID, bool) {
	return httpparam.UUID(w, r, "categoryID", "invalid category id")
}

func uuidFromPointer(value *string) (pgtype.UUID, bool) {
	if value == nil || strings.TrimSpace(*value) == "" {
		return pgtype.UUID{}, true
	}

	categoryID, err := uuidutil.FromString(strings.TrimSpace(*value))
	if err != nil {
		return pgtype.UUID{}, false
	}

	return categoryID, true
}

func textParam(value string) pgtype.Text {
	return pgconv.TextFromString(value)
}
