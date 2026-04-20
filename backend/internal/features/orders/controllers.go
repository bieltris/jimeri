package orders

import (
	"errors"
	"net/http"

	authcore "github.com/bieltris/jimeri/backend/internal/auth"
	"github.com/bieltris/jimeri/backend/internal/db"
	"github.com/bieltris/jimeri/backend/internal/pgconv"
	"github.com/bieltris/jimeri/backend/internal/respond"
	"github.com/jackc/pgx/v5"
)

func (h *Handler) create(w http.ResponseWriter, r *http.Request) {
	input, ok := parseCreateOrderRequest(w, r)
	if !ok {
		return
	}

	currentUser, ok := authcore.UserFromContext(r.Context())
	if !ok {
		respond.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	tx, err := h.pool.Begin(r.Context())
	if err != nil {
		respond.Error(w, http.StatusInternalServerError, "could not create order")
		return
	}
	defer rollback(r, tx)

	qtx := h.queries.WithTx(tx)

	order, err := qtx.CreateOrder(r.Context(), db.CreateOrderParams{
		ClientID:  input.ClientID,
		CreatedBy: currentUser.ID,
		Note:      pgconv.TextFromPointer(input.Note),
	})
	if err != nil {
		respond.Error(w, http.StatusInternalServerError, "could not create order")
		return
	}

	items := make([]db.OrderItem, 0, len(input.Items))
	for _, inputItem := range input.Items {
		product, err := qtx.GetProductByID(r.Context(), inputItem.ProductID)
		if err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				respond.Error(w, http.StatusBadRequest, "product not found")
				return
			}

			respond.Error(w, http.StatusInternalServerError, "could not create order")
			return
		}

		if !product.Active {
			respond.Error(w, http.StatusBadRequest, "product is inactive")
			return
		}

		item, err := qtx.CreateOrderItem(r.Context(), db.CreateOrderItemParams{
			OrderID:        order.ID,
			ProductID:      product.ID,
			ProductName:    product.Name,
			Quantity:       inputItem.Quantity,
			UnitPriceCents: product.PriceCents,
		})
		if err != nil {
			respond.Error(w, http.StatusInternalServerError, "could not create order item")
			return
		}

		items = append(items, item)
	}

	if err := tx.Commit(r.Context()); err != nil {
		respond.Error(w, http.StatusInternalServerError, "could not create order")
		return
	}

	respond.JSON(w, http.StatusCreated, toOrderWithItemsResponse(order, items))
}

func (h *Handler) get(w http.ResponseWriter, r *http.Request) {
	orderID, ok := orderIDParam(w, r)
	if !ok {
		return
	}

	order, err := h.queries.GetOrderByID(r.Context(), orderID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			respond.Error(w, http.StatusNotFound, "order not found")
			return
		}

		respond.Error(w, http.StatusInternalServerError, "could not get order")
		return
	}

	items, err := h.queries.ListOrderItems(r.Context(), order.ID)
	if err != nil {
		respond.Error(w, http.StatusInternalServerError, "could not list order items")
		return
	}

	respond.JSON(w, http.StatusOK, toOrderWithItemsResponse(order, items))
}

func (h *Handler) listByClient(w http.ResponseWriter, r *http.Request) {
	clientID, ok := clientIDParam(w, r)
	if !ok {
		return
	}

	rows, err := h.queries.ListClientOrders(r.Context(), clientID)
	if err != nil {
		respond.Error(w, http.StatusInternalServerError, "could not list client orders")
		return
	}

	respond.JSON(w, http.StatusOK, toOrderSummaryResponses(rows))
}

func (h *Handler) cancel(w http.ResponseWriter, r *http.Request) {
	orderID, ok := orderIDParam(w, r)
	if !ok {
		return
	}

	input, ok := parseCancelOrderRequest(w, r)
	if !ok {
		return
	}

	currentUser, ok := authcore.UserFromContext(r.Context())
	if !ok {
		respond.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	order, err := h.queries.CancelOrder(r.Context(), db.CancelOrderParams{
		ID:           orderID,
		CancelledBy:  currentUser.ID,
		CancelReason: pgconv.TextFromString(input.Reason),
	})
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			respond.Error(w, http.StatusNotFound, "order not found")
			return
		}

		respond.Error(w, http.StatusInternalServerError, "could not cancel order")
		return
	}

	items, err := h.queries.ListOrderItems(r.Context(), order.ID)
	if err != nil {
		respond.Error(w, http.StatusInternalServerError, "could not list order items")
		return
	}

	respond.JSON(w, http.StatusOK, toOrderWithItemsResponse(order, items))
}

func rollback(r *http.Request, tx pgx.Tx) {
	err := tx.Rollback(r.Context())
	if err == nil || errors.Is(err, pgx.ErrTxClosed) {
		return
	}
}
