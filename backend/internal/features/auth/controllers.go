package auth

import (
	"errors"
	"net/http"
	"strings"
	"time"

	authcore "github.com/bieltris/jimeri/backend/internal/auth"
	"github.com/bieltris/jimeri/backend/internal/respond"
	"github.com/jackc/pgx/v5"
	"golang.org/x/crypto/bcrypt"
)

func (h *Handler) login(w http.ResponseWriter, r *http.Request) {
	input, ok := parseLoginRequest(w, r)
	if !ok {
		return
	}

	user, err := h.queries.GetUserByEmail(r.Context(), input.Email)
	if err != nil {
		respond.Error(w, http.StatusUnauthorized, "invalid email or password")
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(input.Password)); err != nil {
		respond.Error(w, http.StatusUnauthorized, "invalid email or password")
		return
	}

	response, rawRefreshToken, err := h.createSession(r.Context(), h.queries, user)
	if err != nil {
		respond.Error(w, http.StatusInternalServerError, "could not create session")
		return
	}

	h.setRefreshCookie(w, rawRefreshToken)
	respond.JSON(w, http.StatusOK, response)
}

func (h *Handler) refresh(w http.ResponseWriter, r *http.Request) {
	rawRefreshToken, ok := h.refreshTokenFromRequest(r)
	if !ok {
		respond.Error(w, http.StatusUnauthorized, "missing refresh token")
		return
	}

	tokenHash := authcore.HashRefreshToken(rawRefreshToken)
	currentToken, err := h.queries.GetRefreshTokenByHash(r.Context(), tokenHash)
	if err != nil {
		h.clearRefreshCookie(w)
		respond.Error(w, http.StatusUnauthorized, "invalid refresh token")
		return
	}

	if currentToken.RevokedAt.Valid || currentToken.ExpiresAt.Time.Before(time.Now()) {
		h.clearRefreshCookie(w)
		respond.Error(w, http.StatusUnauthorized, "expired refresh token")
		return
	}

	tx, err := h.pool.Begin(r.Context())
	if err != nil {
		respond.Error(w, http.StatusInternalServerError, "could not refresh session")
		return
	}
	defer rollback(r, tx)

	qtx := h.queries.WithTx(tx)

	if _, err := qtx.RevokeRefreshToken(r.Context(), currentToken.ID); err != nil {
		respond.Error(w, http.StatusUnauthorized, "invalid refresh token")
		return
	}

	user, err := qtx.GetUserByID(r.Context(), currentToken.UserID)
	if err != nil {
		respond.Error(w, http.StatusUnauthorized, "invalid refresh token")
		return
	}

	response, rawRefreshToken, err := h.createSession(r.Context(), qtx, user)
	if err != nil {
		respond.Error(w, http.StatusInternalServerError, "could not refresh session")
		return
	}

	if err := tx.Commit(r.Context()); err != nil {
		respond.Error(w, http.StatusInternalServerError, "could not refresh session")
		return
	}

	h.setRefreshCookie(w, rawRefreshToken)
	respond.JSON(w, http.StatusOK, response)
}

func (h *Handler) logout(w http.ResponseWriter, r *http.Request) {
	if rawRefreshToken, ok := h.refreshTokenFromRequest(r); ok {
		tokenHash := authcore.HashRefreshToken(rawRefreshToken)
		refreshToken, err := h.queries.GetRefreshTokenByHash(r.Context(), tokenHash)
		if err == nil && !refreshToken.RevokedAt.Valid {
			_, _ = h.queries.RevokeRefreshToken(r.Context(), refreshToken.ID)
		}
	}

	h.clearRefreshCookie(w)
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) refreshTokenFromRequest(r *http.Request) (string, bool) {
	cookie, err := r.Cookie(h.refreshCookieName)
	if err == nil {
		value := strings.TrimSpace(cookie.Value)
		if value != "" {
			return value, true
		}
	}

	input, err := parseRefreshRequest(r)
	if err != nil {
		return "", false
	}

	if input.RefreshToken == "" {
		return "", false
	}

	return input.RefreshToken, true
}

func (h *Handler) me(w http.ResponseWriter, r *http.Request) {
	currentUser, ok := authcore.UserFromContext(r.Context())
	if !ok {
		respond.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	user, err := h.queries.GetUserByID(r.Context(), currentUser.ID)
	if err != nil {
		respond.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	respond.JSON(w, http.StatusOK, toUserResponse(user))
}

func rollback(r *http.Request, tx pgx.Tx) {
	err := tx.Rollback(r.Context())
	if err == nil || errors.Is(err, pgx.ErrTxClosed) {
		return
	}
}
