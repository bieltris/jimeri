package products

import (
	"github.com/bieltris/jimeri/backend/internal/db"
	"github.com/bieltris/jimeri/backend/internal/pgconv"
	"github.com/bieltris/jimeri/backend/internal/uuidutil"
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
		Category:   pgconv.TextPointer(product.Category),
		PriceCents: product.PriceCents,
		Active:     product.Active,
		CreatedAt:  pgconv.TimeString(product.CreatedAt),
		UpdatedAt:  pgconv.TimeString(product.UpdatedAt),
	}
}
