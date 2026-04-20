package orders

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/bieltris/jimeri/backend/internal/httpparam"
	"github.com/bieltris/jimeri/backend/internal/respond"
	"github.com/bieltris/jimeri/backend/internal/uuidutil"
	"github.com/jackc/pgx/v5/pgtype"
)

type createOrderRequest struct {
	ClientID pgtype.UUID
	Note     *string
	Items    []createOrderItemRequest
}

type createOrderItemRequest struct {
	ProductID pgtype.UUID
	Quantity  int32
}

type cancelOrderRequest struct {
	Reason string
}

type createOrderPayload struct {
	ClientID string                   `json:"clientId"`
	Note     *string                  `json:"note"`
	Items    []createOrderItemPayload `json:"items"`
}

type createOrderItemPayload struct {
	ProductID string `json:"productId"`
	Quantity  int32  `json:"quantity"`
}

type cancelOrderPayload struct {
	Reason string `json:"reason"`
}

func parseCreateOrderRequest(w http.ResponseWriter, r *http.Request) (createOrderRequest, bool) {
	var payload createOrderPayload
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		respond.Error(w, http.StatusBadRequest, "invalid request body")
		return createOrderRequest{}, false
	}

	clientID, err := uuidutil.FromString(payload.ClientID)
	if err != nil {
		respond.Error(w, http.StatusBadRequest, "invalid client id")
		return createOrderRequest{}, false
	}

	if len(payload.Items) == 0 {
		respond.Error(w, http.StatusBadRequest, "items are required")
		return createOrderRequest{}, false
	}

	items := make([]createOrderItemRequest, 0, len(payload.Items))
	for _, payloadItem := range payload.Items {
		productID, err := uuidutil.FromString(payloadItem.ProductID)
		if err != nil {
			respond.Error(w, http.StatusBadRequest, "invalid product id")
			return createOrderRequest{}, false
		}

		if payloadItem.Quantity <= 0 {
			respond.Error(w, http.StatusBadRequest, "quantity must be greater than zero")
			return createOrderRequest{}, false
		}

		items = append(items, createOrderItemRequest{
			ProductID: productID,
			Quantity:  payloadItem.Quantity,
		})
	}

	return createOrderRequest{
		ClientID: clientID,
		Note:     payload.Note,
		Items:    items,
	}, true
}

func parseCancelOrderRequest(w http.ResponseWriter, r *http.Request) (cancelOrderRequest, bool) {
	var payload cancelOrderPayload
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		respond.Error(w, http.StatusBadRequest, "invalid request body")
		return cancelOrderRequest{}, false
	}

	reason := strings.TrimSpace(payload.Reason)
	if reason == "" {
		respond.Error(w, http.StatusBadRequest, "reason is required")
		return cancelOrderRequest{}, false
	}

	return cancelOrderRequest{Reason: reason}, true
}

func orderIDParam(w http.ResponseWriter, r *http.Request) (pgtype.UUID, bool) {
	return httpparam.UUID(w, r, "orderID", "invalid order id")
}

func clientIDParam(w http.ResponseWriter, r *http.Request) (pgtype.UUID, bool) {
	return httpparam.UUID(w, r, "clientID", "invalid client id")
}
