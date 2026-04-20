package clients

import (
	"fmt"
	"net/http"
	"net/url"

	"errors"
	"github.com/bieltris/jimeri/backend/internal/respond"
	"github.com/jackc/pgx/v5"
)

type whatsappChargeResponse struct {
	Client              clientResponse `json:"client"`
	BalanceCents        int64          `json:"balanceCents"`
	ResponsibleWhatsapp string         `json:"responsibleWhatsapp"`
	Message             string         `json:"message"`
	URL                 string         `json:"url"`
}

func (h *Handler) whatsappCharge(w http.ResponseWriter, r *http.Request) {
	clientID, ok := clientIDParam(w, r)
	if !ok {
		return
	}

	client, err := h.queries.GetClientByID(r.Context(), clientID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			respond.Error(w, http.StatusNotFound, "client not found")
			return
		}

		respond.Error(w, http.StatusInternalServerError, "could not get client")
		return
	}

	balance, err := h.queries.GetClientBalance(r.Context(), client.ID)
	if err != nil {
		respond.Error(w, http.StatusInternalServerError, "could not get client balance")
		return
	}

	if balance.BalanceCents <= 0 {
		respond.Error(w, http.StatusBadRequest, "client has no debt")
		return
	}

	if !client.ResponsibleWhatsapp.Valid || client.ResponsibleWhatsapp.String == "" {
		respond.Error(w, http.StatusBadRequest, "client has no responsible whatsapp")
		return
	}

	message := chargeMessage(client.Name, balance.BalanceCents)
	phone := client.ResponsibleWhatsapp.String

	respond.JSON(w, http.StatusOK, whatsappChargeResponse{
		Client:              toClientResponse(client),
		BalanceCents:        balance.BalanceCents,
		ResponsibleWhatsapp: phone,
		Message:             message,
		URL:                 "https://wa.me/" + phone + "?text=" + url.QueryEscape(message),
	})
}

func chargeMessage(clientName string, balanceCents int64) string {
	return fmt.Sprintf(
		"Ola, tudo bem? Aqui e da cantina da escola. Consta um valor em aberto de R$ %s referente as compras de %s. Pode verificar, por favor?",
		formatCents(balanceCents),
		clientName,
	)
}

func formatCents(value int64) string {
	reais := value / 100
	centavos := value % 100
	return fmt.Sprintf("%d,%02d", reais, centavos)
}
