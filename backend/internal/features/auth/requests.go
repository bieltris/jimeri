package auth

import (
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"strings"

	"github.com/bieltris/jimeri/backend/internal/respond"
)

type loginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type refreshRequest struct {
	RefreshToken string `json:"refreshToken"`
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

func parseRefreshRequest(r *http.Request) (refreshRequest, error) {
	var input refreshRequest
	if r.Body == nil {
		return input, nil
	}

	err := json.NewDecoder(r.Body).Decode(&input)
	if err != nil {
		if errors.Is(err, io.EOF) {
			return refreshRequest{}, nil
		}

		return refreshRequest{}, err
	}

	input.RefreshToken = strings.TrimSpace(input.RefreshToken)

	return input, nil
}
