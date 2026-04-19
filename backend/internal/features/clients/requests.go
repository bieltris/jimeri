package clients

import (
	"encoding/json"
	"net/http"
	"strings"
	"unicode"

	"github.com/bieltris/jimeri/backend/internal/respond"
	"github.com/bieltris/jimeri/backend/internal/uuidutil"
	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

type clientRequest struct {
	Name                string  `json:"name"`
	ResponsibleName     *string `json:"responsibleName"`
	ResponsibleWhatsapp *string `json:"responsibleWhatsapp"`
	Note                *string `json:"note"`
	Active              *bool   `json:"active"`
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
