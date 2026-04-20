package products

import (
	"errors"
	"net/http"

	"github.com/bieltris/jimeri/backend/internal/db"
	"github.com/bieltris/jimeri/backend/internal/respond"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
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

	respond.JSON(w, http.StatusOK, toActiveProductResponses(products))
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

	categoryID, ok := uuidFromPointer(input.CategoryID)
	if !ok {
		respond.Error(w, http.StatusBadRequest, "invalid category id")
		return
	}

	product, err := h.queries.CreateProduct(r.Context(), db.CreateProductParams{
		Name:       input.Name,
		CategoryID: categoryID,
		PriceCents: input.PriceCents,
	})
	if err != nil {
		respond.Error(w, http.StatusInternalServerError, "could not create product")
		return
	}

	respond.JSON(w, http.StatusCreated, toCreatedProductResponse(product))
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

	categoryID, ok := uuidFromPointer(input.CategoryID)
	if !ok {
		respond.Error(w, http.StatusBadRequest, "invalid category id")
		return
	}

	product, err := h.queries.UpdateProduct(r.Context(), db.UpdateProductParams{
		ID:         productID,
		Name:       input.Name,
		CategoryID: categoryID,
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

	respond.JSON(w, http.StatusOK, toUpdatedProductResponse(product))
}

func (h *Handler) listCategories(w http.ResponseWriter, r *http.Request) {
	search := textParam(r.URL.Query().Get("search"))

	categories, err := h.queries.ListProductCategories(r.Context(), search)
	if err != nil {
		respond.Error(w, http.StatusInternalServerError, "could not list product categories")
		return
	}

	respond.JSON(w, http.StatusOK, toProductCategoryResponses(categories))
}

func (h *Handler) listActiveCategories(w http.ResponseWriter, r *http.Request) {
	categories, err := h.queries.ListActiveProductCategories(r.Context())
	if err != nil {
		respond.Error(w, http.StatusInternalServerError, "could not list product categories")
		return
	}

	respond.JSON(w, http.StatusOK, toProductCategoryResponses(categories))
}

func (h *Handler) createCategory(w http.ResponseWriter, r *http.Request) {
	input, ok := parseProductCategoryRequest(w, r)
	if !ok {
		return
	}

	category, err := h.queries.CreateProductCategory(r.Context(), input.Name)
	if err != nil {
		if isUniqueViolation(err) {
			respond.Error(w, http.StatusConflict, "category already exists")
			return
		}

		respond.Error(w, http.StatusInternalServerError, "could not create product category")
		return
	}

	respond.JSON(w, http.StatusCreated, toProductCategoryResponse(category))
}

func (h *Handler) updateCategory(w http.ResponseWriter, r *http.Request) {
	categoryID, ok := productCategoryIDParam(w, r)
	if !ok {
		return
	}

	input, ok := parseProductCategoryRequest(w, r)
	if !ok {
		return
	}

	active := true
	if input.Active != nil {
		active = *input.Active
	}

	category, err := h.queries.UpdateProductCategory(r.Context(), db.UpdateProductCategoryParams{
		ID:     categoryID,
		Name:   input.Name,
		Active: active,
	})
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			respond.Error(w, http.StatusNotFound, "category not found")
			return
		}

		if isUniqueViolation(err) {
			respond.Error(w, http.StatusConflict, "category already exists")
			return
		}

		respond.Error(w, http.StatusInternalServerError, "could not update product category")
		return
	}

	respond.JSON(w, http.StatusOK, toProductCategoryResponse(category))
}

func isUniqueViolation(err error) bool {
	var pgErr *pgconn.PgError
	return errors.As(err, &pgErr) && pgErr.Code == "23505"
}
