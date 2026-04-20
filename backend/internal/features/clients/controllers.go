package clients

import (
	"errors"
	"net/http"

	"github.com/bieltris/jimeri/backend/internal/db"
	"github.com/bieltris/jimeri/backend/internal/respond"
	"github.com/jackc/pgx/v5"
)

func (h *Handler) list(w http.ResponseWriter, r *http.Request) {
	search := textParam(r.URL.Query().Get("search"))

	rows, err := h.queries.ListClients(r.Context(), search)
	if err != nil {
		respond.Error(w, http.StatusInternalServerError, "could not list clients")
		return
	}

	response := make([]clientWithBalanceResponse, 0, len(rows))
	for _, row := range rows {
		response = append(response, clientWithBalanceFromListRow(row))
	}

	respond.JSON(w, http.StatusOK, response)
}

func (h *Handler) listWithDebt(w http.ResponseWriter, r *http.Request) {
	rows, err := h.queries.ListClientsWithDebt(r.Context())
	if err != nil {
		respond.Error(w, http.StatusInternalServerError, "could not list clients with debt")
		return
	}

	response := make([]clientWithBalanceResponse, 0, len(rows))
	for _, row := range rows {
		response = append(response, clientWithBalanceFromDebtRow(row))
	}

	respond.JSON(w, http.StatusOK, response)
}

func (h *Handler) get(w http.ResponseWriter, r *http.Request) {
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

	respond.JSON(w, http.StatusOK, clientWithBalanceResponse{
		Client:       toClientResponse(client),
		BalanceCents: balance.BalanceCents,
	})
}

func (h *Handler) create(w http.ResponseWriter, r *http.Request) {
	input, ok := parseClientRequest(w, r)
	if !ok {
		return
	}

	client, err := h.queries.CreateClient(r.Context(), db.CreateClientParams{
		Name:                input.Name,
		ResponsibleName:     textFromPointer(input.ResponsibleName),
		ResponsibleWhatsapp: whatsappFromPointer(input.ResponsibleWhatsapp),
		Note:                textFromPointer(input.Note),
	})
	if err != nil {
		respond.Error(w, http.StatusInternalServerError, "could not create client")
		return
	}

	respond.JSON(w, http.StatusCreated, clientWithBalanceResponse{
		Client:       toClientResponse(client),
		BalanceCents: 0,
	})
}

func (h *Handler) update(w http.ResponseWriter, r *http.Request) {
	clientID, ok := clientIDParam(w, r)
	if !ok {
		return
	}

	input, ok := parseClientRequest(w, r)
	if !ok {
		return
	}

	active := true
	if input.Active != nil {
		active = *input.Active
	}

	client, err := h.queries.UpdateClient(r.Context(), db.UpdateClientParams{
		ID:                  clientID,
		Name:                input.Name,
		ResponsibleName:     textFromPointer(input.ResponsibleName),
		ResponsibleWhatsapp: whatsappFromPointer(input.ResponsibleWhatsapp),
		Note:                textFromPointer(input.Note),
		Active:              active,
	})
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			respond.Error(w, http.StatusNotFound, "client not found")
			return
		}

		respond.Error(w, http.StatusInternalServerError, "could not update client")
		return
	}

	balance, err := h.queries.GetClientBalance(r.Context(), client.ID)
	if err != nil {
		respond.Error(w, http.StatusInternalServerError, "could not get client balance")
		return
	}

	respond.JSON(w, http.StatusOK, clientWithBalanceResponse{
		Client:       toClientResponse(client),
		BalanceCents: balance.BalanceCents,
	})
}
