package auth

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"time"

	"github.com/bieltris/jimeri/backend/internal/db"
	"github.com/bieltris/jimeri/backend/internal/uuidutil"
	"github.com/golang-jwt/jwt/v5"
)

const (
	AccessTokenDuration  = 15 * time.Minute
	RefreshTokenDuration = 30 * 24 * time.Hour
)

type TokenManager struct {
	accessSecret []byte
}

type Claims struct {
	Role string `json:"role"`
	jwt.RegisteredClaims
}

func NewTokenManager(accessSecret string) (*TokenManager, error) {
	if accessSecret == "" {
		return nil, errors.New("ACCESS_TOKEN_SECRET is required")
	}

	return &TokenManager{accessSecret: []byte(accessSecret)}, nil
}

func (m *TokenManager) CreateAccessToken(user db.User) (string, error) {
	now := time.Now()

	claims := Claims{
		Role: user.Role,
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   uuidutil.ToString(user.ID),
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(AccessTokenDuration)),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(m.accessSecret)
}

func (m *TokenManager) ParseAccessToken(rawToken string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(rawToken, &Claims{}, func(token *jwt.Token) (any, error) {
		if token.Method != jwt.SigningMethodHS256 {
			return nil, errors.New("unexpected signing method")
		}

		return m.accessSecret, nil
	})
	if err != nil {
		return nil, err
	}

	claims, ok := token.Claims.(*Claims)
	if !ok || !token.Valid {
		return nil, errors.New("invalid access token")
	}

	return claims, nil
}

func NewRefreshToken() (string, error) {
	bytes := make([]byte, 32)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}

	return base64.RawURLEncoding.EncodeToString(bytes), nil
}

func HashRefreshToken(token string) string {
	sum := sha256.Sum256([]byte(token))
	return hex.EncodeToString(sum[:])
}
