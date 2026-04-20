package payments

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/bieltris/jimeri/backend/internal/httpparam"
	"github.com/bieltris/jimeri/backend/internal/respond"
	"github.com/bieltris/jimeri/backend/internal/uuidutil"
	"github.com/jackc/pgx/v5/pgtype"
)

type createPaymentRequest struct {
	ClientID    pgtype.UUID
	AmountCents int64
	Note        *string
}

type cancelPaymentRequest struct {
	Reason string
}

type createPaymentPayload struct {
	ClientID    string  `json:"clientId"`
	AmountCents int64   `json:"amountCents"`
	Note        *string `json:"note"`
}

type cancelPaymentPayload struct {
	Reason string `json:"reason"`
}

func parseCreatePaymentRequest(w http.ResponseWriter, r *http.Request) (createPaymentRequest, bool) {
	var payload createPaymentPayload
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		respond.Error(w, http.StatusBadRequest, "invalid request body")
		return createPaymentRequest{}, false
	}

	clientID, err := uuidutil.FromString(payload.ClientID)
	if err != nil {
		respond.Error(w, http.StatusBadRequest, "invalid client id")
		return createPaymentRequest{}, false
	}

	if payload.AmountCents <= 0 {
		respond.Error(w, http.StatusBadRequest, "amountCents must be greater than zero")
		return createPaymentRequest{}, false
	}

	return createPaymentRequest{
		ClientID:    clientID,
		AmountCents: payload.AmountCents,
		Note:        payload.Note,
	}, true
}

func parseCancelPaymentRequest(w http.ResponseWriter, r *http.Request) (cancelPaymentRequest, bool) {
	var payload cancelPaymentPayload
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		respond.Error(w, http.StatusBadRequest, "invalid request body")
		return cancelPaymentRequest{}, false
	}

	reason := strings.TrimSpace(payload.Reason)
	if reason == "" {
		respond.Error(w, http.StatusBadRequest, "reason is required")
		return cancelPaymentRequest{}, false
	}

	return cancelPaymentRequest{Reason: reason}, true
}

func paymentIDParam(w http.ResponseWriter, r *http.Request) (pgtype.UUID, bool) {
	return httpparam.UUID(w, r, "paymentID", "invalid payment id")
}

func clientIDParam(w http.ResponseWriter, r *http.Request) (pgtype.UUID, bool) {
	return httpparam.UUID(w, r, "clientID", "invalid client id")
}
