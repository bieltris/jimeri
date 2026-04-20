package auth

import (
	"context"
	"time"

	authcore "github.com/bieltris/jimeri/backend/internal/auth"
	"github.com/bieltris/jimeri/backend/internal/db"
	"github.com/jackc/pgx/v5/pgtype"
)

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
