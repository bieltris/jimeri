package payments

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
	input, ok := parseCreatePaymentRequest(w, r)
	if !ok {
		return
	}

	currentUser, ok := authcore.UserFromContext(r.Context())
	if !ok {
		respond.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	balance, err := h.queries.GetClientBalance(r.Context(), input.ClientID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			respond.Error(w, http.StatusNotFound, "client not found")
			return
		}

		respond.Error(w, http.StatusInternalServerError, "could not get client balance")
		return
	}

	if balance.BalanceCents <= 0 {
		respond.Error(w, http.StatusBadRequest, "client has no debt")
		return
	}

	if input.AmountCents > balance.BalanceCents {
		respond.Error(w, http.StatusBadRequest, "payment cannot be greater than debt")
		return
	}

	payment, err := h.queries.CreatePayment(r.Context(), db.CreatePaymentParams{
		ClientID:    input.ClientID,
		AmountCents: input.AmountCents,
		Note:        pgconv.TextFromPointer(input.Note),
		CreatedBy:   currentUser.ID,
	})
	if err != nil {
		respond.Error(w, http.StatusInternalServerError, "could not create payment")
		return
	}

	respond.JSON(w, http.StatusCreated, toPaymentResponse(payment))
}

func (h *Handler) get(w http.ResponseWriter, r *http.Request) {
	paymentID, ok := paymentIDParam(w, r)
	if !ok {
		return
	}

	payment, err := h.queries.GetPaymentByID(r.Context(), paymentID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			respond.Error(w, http.StatusNotFound, "payment not found")
			return
		}

		respond.Error(w, http.StatusInternalServerError, "could not get payment")
		return
	}

	respond.JSON(w, http.StatusOK, toPaymentResponse(payment))
}

func (h *Handler) listByClient(w http.ResponseWriter, r *http.Request) {
	clientID, ok := clientIDParam(w, r)
	if !ok {
		return
	}

	payments, err := h.queries.ListClientPayments(r.Context(), clientID)
	if err != nil {
		respond.Error(w, http.StatusInternalServerError, "could not list client payments")
		return
	}

	respond.JSON(w, http.StatusOK, toPaymentResponses(payments))
}

func (h *Handler) cancel(w http.ResponseWriter, r *http.Request) {
	paymentID, ok := paymentIDParam(w, r)
	if !ok {
		return
	}

	input, ok := parseCancelPaymentRequest(w, r)
	if !ok {
		return
	}

	currentUser, ok := authcore.UserFromContext(r.Context())
	if !ok {
		respond.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	payment, err := h.queries.CancelPayment(r.Context(), db.CancelPaymentParams{
		ID:           paymentID,
		CancelledBy:  currentUser.ID,
		CancelReason: pgconv.TextFromString(input.Reason),
	})
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			respond.Error(w, http.StatusNotFound, "payment not found")
			return
		}

		respond.Error(w, http.StatusInternalServerError, "could not cancel payment")
		return
	}

	respond.JSON(w, http.StatusOK, toPaymentResponse(payment))
}
