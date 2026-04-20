package products

import (
	"github.com/bieltris/jimeri/backend/internal/db"
	"github.com/bieltris/jimeri/backend/internal/pgconv"
	"github.com/bieltris/jimeri/backend/internal/uuidutil"
	"github.com/jackc/pgx/v5/pgtype"
)

type productResponse struct {
	ID         string                   `json:"id"`
	Name       string                   `json:"name"`
	Category   *productCategoryResponse `json:"category"`
	PriceCents int64                    `json:"priceCents"`
	Active     bool                     `json:"active"`
	CreatedAt  string                   `json:"createdAt"`
	UpdatedAt  string                   `json:"updatedAt"`
}

type productCategoryResponse struct {
	ID        string `json:"id"`
	Name      string `json:"name"`
	Active    bool   `json:"active"`
	CreatedAt string `json:"createdAt"`
	UpdatedAt string `json:"updatedAt"`
}

func toProductResponses(products []db.ListProductsRow) []productResponse {
	response := make([]productResponse, 0, len(products))
	for _, product := range products {
		response = append(response, productResponseFromFields(
			product.ID,
			product.Name,
			product.CategoryID,
			product.CategoryName,
			product.PriceCents,
			product.Active,
			product.CreatedAt,
			product.UpdatedAt,
		))
	}

	return response
}

func toActiveProductResponses(products []db.ListActiveProductsRow) []productResponse {
	response := make([]productResponse, 0, len(products))
	for _, product := range products {
		response = append(response, productResponseFromFields(
			product.ID,
			product.Name,
			product.CategoryID,
			product.CategoryName,
			product.PriceCents,
			product.Active,
			product.CreatedAt,
			product.UpdatedAt,
		))
	}

	return response
}

func toCreatedProductResponse(product db.CreateProductRow) productResponse {
	return productResponseFromFields(
		product.ID,
		product.Name,
		product.CategoryID,
		product.CategoryName,
		product.PriceCents,
		product.Active,
		product.CreatedAt,
		product.UpdatedAt,
	)
}

func toProductResponse(product db.GetProductByIDRow) productResponse {
	return productResponseFromFields(
		product.ID,
		product.Name,
		product.CategoryID,
		product.CategoryName,
		product.PriceCents,
		product.Active,
		product.CreatedAt,
		product.UpdatedAt,
	)
}

func toUpdatedProductResponse(product db.UpdateProductRow) productResponse {
	return productResponseFromFields(
		product.ID,
		product.Name,
		product.CategoryID,
		product.CategoryName,
		product.PriceCents,
		product.Active,
		product.CreatedAt,
		product.UpdatedAt,
	)
}

func productResponseFromFields(
	id pgtype.UUID,
	name string,
	categoryID pgtype.UUID,
	categoryName pgtype.Text,
	priceCents int64,
	active bool,
	createdAt pgtype.Timestamptz,
	updatedAt pgtype.Timestamptz,
) productResponse {
	return productResponse{
		ID:         uuidutil.ToString(id),
		Name:       name,
		Category:   categoryResponseFromFields(categoryID, categoryName),
		PriceCents: priceCents,
		Active:     active,
		CreatedAt:  pgconv.TimeString(createdAt),
		UpdatedAt:  pgconv.TimeString(updatedAt),
	}
}

func toProductCategoryResponses(categories []db.ProductCategory) []productCategoryResponse {
	response := make([]productCategoryResponse, 0, len(categories))
	for _, category := range categories {
		response = append(response, toProductCategoryResponse(category))
	}

	return response
}

func toProductCategoryResponse(category db.ProductCategory) productCategoryResponse {
	return productCategoryResponse{
		ID:        uuidutil.ToString(category.ID),
		Name:      category.Name,
		Active:    category.Active,
		CreatedAt: pgconv.TimeString(category.CreatedAt),
		UpdatedAt: pgconv.TimeString(category.UpdatedAt),
	}
}

func categoryResponseFromFields(id pgtype.UUID, name pgtype.Text) *productCategoryResponse {
	if !id.Valid || !name.Valid {
		return nil
	}

	return &productCategoryResponse{
		ID:   uuidutil.ToString(id),
		Name: name.String,
	}
}
