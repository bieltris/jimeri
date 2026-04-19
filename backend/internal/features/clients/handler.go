package clients

import (
	"encoding/json"
	"errors"
	"net/http"
	"strings"
	"time"
	"unicode"

	"github.com/bieltris/jimeri/backend/internal/db"
	"github.com/bieltris/jimeri/backend/internal/respond"
	"github.com/bieltris/jimeri/backend/internal/uuidutil"
	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Handler struct {
	queries *db.Queries
}

type clientRequest struct {
	Name                string  `json:"name"`
	ResponsibleName     *string `json:"responsibleName"`
	ResponsibleWhatsapp *string `json:"responsibleWhatsapp"`
	Note                *string `json:"note"`
	Active              *bool   `json:"active"`
}

type clientResponse struct {
	ID                  string  `json:"id"`
	Name                string  `json:"name"`
	ResponsibleName     *string `json:"responsibleName"`
	ResponsibleWhatsapp *string `json:"responsibleWhatsapp"`
	Note                *string `json:"note"`
	Active              bool    `json:"active"`
	CreatedAt           string  `json:"createdAt"`
	UpdatedAt           string  `json:"updatedAt"`
}

type clientWithBalanceResponse struct {
	Client       clientResponse `json:"client"`
	BalanceCents int64          `json:"balanceCents"`
}

func NewHandler(pool *pgxpool.Pool) *Handler {
	return &Handler{queries: db.New(pool)}
}

func (h *Handler) Routes() http.Handler {
	router := chi.NewRouter()

	router.Get("/", h.list)
	router.Post("/", h.create)
	router.Get("/debt", h.listWithDebt)
	router.Get("/{clientID}", h.get)
	router.Put("/{clientID}", h.update)

	return router
}

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

func parseClientRequest(w http.ResponseWriter, r *http.Request) (clientRequest, bool) {
	var input clientRequest
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		respond.Error(w, http.StatusBadRequest, "invalid request body")
		return clientRequest{}, false
	}

	input.Name = strings.TrimSpace(input.Name)
	if input.Name == "" {
		respond.Error(w, http.StatusBadRequest, "name is required")
		return clientRequest{}, false
	}

	return input, true
}

func clientIDParam(w http.ResponseWriter, r *http.Request) (pgtype.UUID, bool) {
	clientID, err := uuidutil.FromString(chi.URLParam(r, "clientID"))
	if err != nil {
		respond.Error(w, http.StatusBadRequest, "invalid client id")
		return pgtype.UUID{}, false
	}

	return clientID, true
}

func clientWithBalanceFromListRow(row db.ListClientsRow) clientWithBalanceResponse {
	return clientWithBalanceResponse{
		Client: clientResponse{
			ID:                  uuidutil.ToString(row.ID),
			Name:                row.Name,
			ResponsibleName:     textPointer(row.ResponsibleName),
			ResponsibleWhatsapp: textPointer(row.ResponsibleWhatsapp),
			Note:                textPointer(row.Note),
			Active:              row.Active,
			CreatedAt:           timeString(row.CreatedAt),
			UpdatedAt:           timeString(row.UpdatedAt),
		},
		BalanceCents: row.BalanceCents,
	}
}

func clientWithBalanceFromDebtRow(row db.ListClientsWithDebtRow) clientWithBalanceResponse {
	return clientWithBalanceResponse{
		Client: clientResponse{
			ID:                  uuidutil.ToString(row.ID),
			Name:                row.Name,
			ResponsibleName:     textPointer(row.ResponsibleName),
			ResponsibleWhatsapp: textPointer(row.ResponsibleWhatsapp),
			Note:                textPointer(row.Note),
			Active:              row.Active,
			CreatedAt:           timeString(row.CreatedAt),
			UpdatedAt:           timeString(row.UpdatedAt),
		},
		BalanceCents: row.BalanceCents,
	}
}

func toClientResponse(client db.Client) clientResponse {
	return clientResponse{
		ID:                  uuidutil.ToString(client.ID),
		Name:                client.Name,
		ResponsibleName:     textPointer(client.ResponsibleName),
		ResponsibleWhatsapp: textPointer(client.ResponsibleWhatsapp),
		Note:                textPointer(client.Note),
		Active:              client.Active,
		CreatedAt:           timeString(client.CreatedAt),
		UpdatedAt:           timeString(client.UpdatedAt),
	}
}

func textFromPointer(value *string) pgtype.Text {
	if value == nil {
		return pgtype.Text{}
	}

	trimmed := strings.TrimSpace(*value)
	if trimmed == "" {
		return pgtype.Text{}
	}

	return pgtype.Text{String: trimmed, Valid: true}
}

func whatsappFromPointer(value *string) pgtype.Text {
	if value == nil {
		return pgtype.Text{}
	}

	var builder strings.Builder
	for _, char := range *value {
		if unicode.IsDigit(char) {
			builder.WriteRune(char)
		}
	}

	cleaned := builder.String()
	if cleaned == "" {
		return pgtype.Text{}
	}

	return pgtype.Text{String: cleaned, Valid: true}
}

func textParam(value string) pgtype.Text {
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		return pgtype.Text{}
	}

	return pgtype.Text{String: trimmed, Valid: true}
}

func textPointer(value pgtype.Text) *string {
	if !value.Valid {
		return nil
	}

	return &value.String
}

func timeString(value pgtype.Timestamptz) string {
	if !value.Valid {
		return ""
	}

	return value.Time.Format(time.RFC3339)
}
