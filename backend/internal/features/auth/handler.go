package auth

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"time"

	authcore "github.com/bieltris/jimeri/backend/internal/auth"
	"github.com/bieltris/jimeri/backend/internal/config"
	"github.com/bieltris/jimeri/backend/internal/db"
	"github.com/bieltris/jimeri/backend/internal/respond"
	"github.com/bieltris/jimeri/backend/internal/uuidutil"
	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
	"golang.org/x/crypto/bcrypt"
)

type Handler struct {
	pool                *pgxpool.Pool
	queries             *db.Queries
	tokens              *authcore.TokenManager
	refreshCookieName   string
	refreshCookieSecure bool
}

type loginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type authResponse struct {
	AccessToken string       `json:"accessToken"`
	User        userResponse `json:"user"`
}

type userResponse struct {
	ID    string `json:"id"`
	Name  string `json:"name"`
	Email string `json:"email"`
	Role  string `json:"role"`
}

func NewHandler(pool *pgxpool.Pool, cfg config.Config) *Handler {
	tokens, err := authcore.NewTokenManager(cfg.AccessTokenSecret)
	if err != nil {
		panic(err)
	}

	return &Handler{
		pool:                pool,
		queries:             db.New(pool),
		tokens:              tokens,
		refreshCookieName:   cfg.RefreshCookieName,
		refreshCookieSecure: cfg.RefreshCookieSecure,
	}
}

func (h *Handler) Routes() http.Handler {
	router := chi.NewRouter()

	router.Post("/login", h.login)
	router.Post("/refresh", h.refresh)
	router.Post("/logout", h.logout)

	router.Group(func(protected chi.Router) {
		protected.Use(authcore.RequireAuth(h.tokens))
		protected.Get("/me", h.me)
	})

	return router
}

func (h *Handler) login(w http.ResponseWriter, r *http.Request) {
	var input loginRequest
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		respond.Error(w, http.StatusBadRequest, "invalid request body")
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
	cookie, err := r.Cookie(h.refreshCookieName)
	if err != nil || cookie.Value == "" {
		respond.Error(w, http.StatusUnauthorized, "missing refresh token")
		return
	}

	tokenHash := authcore.HashRefreshToken(cookie.Value)
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
	cookie, err := r.Cookie(h.refreshCookieName)
	if err == nil && cookie.Value != "" {
		tokenHash := authcore.HashRefreshToken(cookie.Value)
		refreshToken, err := h.queries.GetRefreshTokenByHash(r.Context(), tokenHash)
		if err == nil && !refreshToken.RevokedAt.Valid {
			_, _ = h.queries.RevokeRefreshToken(r.Context(), refreshToken.ID)
		}
	}

	h.clearRefreshCookie(w)
	w.WriteHeader(http.StatusNoContent)
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

type sessionCreator interface {
	CreateRefreshToken(ctx context.Context, arg db.CreateRefreshTokenParams) (db.RefreshToken, error)
}

func (h *Handler) createSession(ctx context.Context, q sessionCreator, user db.User) (authResponse, string, error) {
	accessToken, err := h.tokens.CreateAccessToken(user)
	if err != nil {
		return authResponse{}, "", err
	}

	rawRefreshToken, err := authcore.NewRefreshToken()
	if err != nil {
		return authResponse{}, "", err
	}

	expiresAt := time.Now().Add(authcore.RefreshTokenDuration)
	_, err = q.CreateRefreshToken(ctx, db.CreateRefreshTokenParams{
		UserID:    user.ID,
		TokenHash: authcore.HashRefreshToken(rawRefreshToken),
		ExpiresAt: pgtype.Timestamptz{Time: expiresAt, Valid: true},
	})
	if err != nil {
		return authResponse{}, "", err
	}

	return authResponse{
		AccessToken: accessToken,
		User:        toUserResponse(user),
	}, rawRefreshToken, nil
}

func (h *Handler) setRefreshCookie(w http.ResponseWriter, token string) {
	http.SetCookie(w, &http.Cookie{
		Name:     h.refreshCookieName,
		Value:    token,
		Path:     "/api/auth",
		MaxAge:   int(authcore.RefreshTokenDuration.Seconds()),
		HttpOnly: true,
		Secure:   h.refreshCookieSecure,
		SameSite: sameSite(h.refreshCookieSecure),
	})
}

func (h *Handler) clearRefreshCookie(w http.ResponseWriter) {
	http.SetCookie(w, &http.Cookie{
		Name:     h.refreshCookieName,
		Value:    "",
		Path:     "/api/auth",
		MaxAge:   -1,
		HttpOnly: true,
		Secure:   h.refreshCookieSecure,
		SameSite: sameSite(h.refreshCookieSecure),
	})
}

func sameSite(secure bool) http.SameSite {
	if secure {
		return http.SameSiteNoneMode
	}

	return http.SameSiteLaxMode
}

func toUserResponse(user db.User) userResponse {
	return userResponse{
		ID:    uuidutil.ToString(user.ID),
		Name:  user.Name,
		Email: user.Email,
		Role:  user.Role,
	}
}

func rollback(r *http.Request, tx pgx.Tx) {
	err := tx.Rollback(r.Context())
	if err == nil || errors.Is(err, pgx.ErrTxClosed) {
		return
	}
}
