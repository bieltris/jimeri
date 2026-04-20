package products

import (
	"time"

	"github.com/bieltris/jimeri/backend/internal/db"
	"github.com/bieltris/jimeri/backend/internal/uuidutil"
	"github.com/jackc/pgx/v5/pgtype"
)

type productResponse struct {
	ID         string  `json:"id"`
	Name       string  `json:"name"`
	Category   *string `json:"category"`
	PriceCents int64   `json:"priceCents"`
	Active     bool    `json:"active"`
	CreatedAt  string  `json:"createdAt"`
	UpdatedAt  string  `json:"updatedAt"`
}

func toProductResponses(products []db.Product) []productResponse {
	response := make([]productResponse, 0, len(products))
	for _, product := range products {
		response = append(response, toProductResponse(product))
	}

	return response
}

func toProductResponse(product db.Product) productResponse {
	return productResponse{
		ID:         uuidutil.ToString(product.ID),
		Name:       product.Name,
		Category:   textPointer(product.Category),
		PriceCents: product.PriceCents,
		Active:     product.Active,
		CreatedAt:  timeString(product.CreatedAt),
		UpdatedAt:  timeString(product.UpdatedAt),
	}
}

func textPointer(value pgtype.Text) *string {
	if !value.Valid {
		return nil
	}

	return &value.String
}

func timeString(value pgtype.Timestamptz) string {
	if !value.Valid {
		return ""
	}

	return value.Time.Format(time.RFC3339)
}
