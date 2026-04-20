package payments

import (
	"github.com/bieltris/jimeri/backend/internal/db"
	"github.com/bieltris/jimeri/backend/internal/pgconv"
	"github.com/bieltris/jimeri/backend/internal/uuidutil"
	"github.com/jackc/pgx/v5/pgtype"
)

type paymentResponse struct {
	ID           string  `json:"id"`
	ClientID     string  `json:"clientId"`
	AmountCents  int64   `json:"amountCents"`
	Note         *string `json:"note"`
	CreatedBy    string  `json:"createdBy"`
	CancelledAt  string  `json:"cancelledAt,omitempty"`
	CancelledBy  *string `json:"cancelledBy,omitempty"`
	CancelReason *string `json:"cancelReason,omitempty"`
	CreatedAt    string  `json:"createdAt"`
}

func toPaymentResponses(payments []db.Payment) []paymentResponse {
	response := make([]paymentResponse, 0, len(payments))
	for _, payment := range payments {
		response = append(response, toPaymentResponse(payment))
	}

	return response
}

func toPaymentResponse(payment db.Payment) paymentResponse {
	return paymentResponse{
		ID:           uuidutil.ToString(payment.ID),
		ClientID:     uuidutil.ToString(payment.ClientID),
		AmountCents:  payment.AmountCents,
		Note:         pgconv.TextPointer(payment.Note),
		CreatedBy:    uuidutil.ToString(payment.CreatedBy),
		CancelledAt:  pgconv.TimeString(payment.CancelledAt),
		CancelledBy:  uuidPointer(payment.CancelledBy),
		CancelReason: pgconv.TextPointer(payment.CancelReason),
		CreatedAt:    pgconv.TimeString(payment.CreatedAt),
	}
}

func uuidPointer(value pgtype.UUID) *string {
	if !value.Valid {
		return nil
	}

	id := uuidutil.ToString(value)
	return &id
}
