package auth

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/bieltris/jimeri/backend/internal/respond"
)

type loginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

func parseLoginRequest(w http.ResponseWriter, r *http.Request) (loginRequest, bool) {
	var input loginRequest
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		respond.Error(w, http.StatusBadRequest, "invalid request body")
		return loginRequest{}, false
	}

	input.Email = strings.TrimSpace(input.Email)
	if input.Email == "" || input.Password == "" {
		respond.Error(w, http.StatusBadRequest, "email and password are required")
		return loginRequest{}, false
	}

	return input, true
}
