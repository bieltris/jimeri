package products

import (
	"errors"
	"net/http"

	"github.com/bieltris/jimeri/backend/internal/db"
	"github.com/bieltris/jimeri/backend/internal/respond"
	"github.com/jackc/pgx/v5"
)

func (h *Handler) list(w http.ResponseWriter, r *http.Request) {
	search := textParam(r.URL.Query().Get("search"))

	products, err := h.queries.ListProducts(r.Context(), search)
	if err != nil {
		respond.Error(w, http.StatusInternalServerError, "could not list products")
		return
	}

	respond.JSON(w, http.StatusOK, toProductResponses(products))
}

func (h *Handler) listActive(w http.ResponseWriter, r *http.Request) {
	products, err := h.queries.ListActiveProducts(r.Context())
	if err != nil {
		respond.Error(w, http.StatusInternalServerError, "could not list active products")
		return
	}

	respond.JSON(w, http.StatusOK, toProductResponses(products))
}

func (h *Handler) get(w http.ResponseWriter, r *http.Request) {
	productID, ok := productIDParam(w, r)
	if !ok {
		return
	}

	product, err := h.queries.GetProductByID(r.Context(), productID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			respond.Error(w, http.StatusNotFound, "product not found")
			return
		}

		respond.Error(w, http.StatusInternalServerError, "could not get product")
		return
	}

	respond.JSON(w, http.StatusOK, toProductResponse(product))
}

func (h *Handler) create(w http.ResponseWriter, r *http.Request) {
	input, ok := parseProductRequest(w, r)
	if !ok {
		return
	}

	product, err := h.queries.CreateProduct(r.Context(), db.CreateProductParams{
		Name:       input.Name,
		Category:   textFromPointer(input.Category),
		PriceCents: input.PriceCents,
	})
	if err != nil {
		respond.Error(w, http.StatusInternalServerError, "could not create product")
		return
	}

	respond.JSON(w, http.StatusCreated, toProductResponse(product))
}

func (h *Handler) update(w http.ResponseWriter, r *http.Request) {
	productID, ok := productIDParam(w, r)
	if !ok {
		return
	}

	input, ok := parseProductRequest(w, r)
	if !ok {
		return
	}

	active := true
	if input.Active != nil {
		active = *input.Active
	}

	product, err := h.queries.UpdateProduct(r.Context(), db.UpdateProductParams{
		ID:         productID,
		Name:       input.Name,
		Category:   textFromPointer(input.Category),
		PriceCents: input.PriceCents,
		Active:     active,
	})
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			respond.Error(w, http.StatusNotFound, "product not found")
			return
		}

		respond.Error(w, http.StatusInternalServerError, "could not update product")
		return
	}

	respond.JSON(w, http.StatusOK, toProductResponse(product))
}
