package auth

import (
	"net/http"
	"strings"

	"github.com/bieltris/jimeri/backend/internal/respond"
	"github.com/bieltris/jimeri/backend/internal/uuidutil"
)

func RequireAuth(tokens *TokenManager) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			header := r.Header.Get("Authorization")
			if header == "" {
				respond.Error(w, http.StatusUnauthorized, "missing authorization header")
				return
			}

			rawToken, ok := strings.CutPrefix(header, "Bearer ")
			if !ok || strings.TrimSpace(rawToken) == "" {
				respond.Error(w, http.StatusUnauthorized, "invalid authorization header")
				return
			}

			claims, err := tokens.ParseAccessToken(rawToken)
			if err != nil {
				respond.Error(w, http.StatusUnauthorized, "invalid access token")
				return
			}

			userID, err := uuidutil.FromString(claims.Subject)
			if err != nil {
				respond.Error(w, http.StatusUnauthorized, "invalid access token subject")
				return
			}

			ctx := WithUser(r.Context(), UserContext{
				ID:   userID,
				Role: claims.Role,
			})

			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}
