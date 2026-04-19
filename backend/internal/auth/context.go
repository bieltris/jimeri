package auth

import (
	"context"

	"github.com/jackc/pgx/v5/pgtype"
)

type contextKey string

const userContextKey contextKey = "auth_user"

type UserContext struct {
	ID   pgtype.UUID
	Role string
}

func WithUser(ctx context.Context, user UserContext) context.Context {
	return context.WithValue(ctx, userContextKey, user)
}

func UserFromContext(ctx context.Context) (UserContext, bool) {
	user, ok := ctx.Value(userContextKey).(UserContext)
	return user, ok
}
