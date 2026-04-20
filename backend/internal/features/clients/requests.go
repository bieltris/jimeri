package clients

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/bieltris/jimeri/backend/internal/httpparam"
	"github.com/bieltris/jimeri/backend/internal/pgconv"
	"github.com/bieltris/jimeri/backend/internal/respond"
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
	return httpparam.UUID(w, r, "clientID", "invalid client id")
}

func textFromPointer(value *string) pgtype.Text {
	return pgconv.TextFromPointer(value)
}

func whatsappFromPointer(value *string) pgtype.Text {
	return pgconv.DigitsTextFromPointer(value)
}

func textParam(value string) pgtype.Text {
	return pgconv.TextFromString(value)
}
