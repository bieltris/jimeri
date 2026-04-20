package auth

import (
	"net/http"

	authcore "github.com/bieltris/jimeri/backend/internal/auth"
)

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
