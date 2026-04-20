package auth

import (
	"github.com/bieltris/jimeri/backend/internal/db"
	"github.com/bieltris/jimeri/backend/internal/uuidutil"
)

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

func toUserResponse(user db.User) userResponse {
	return userResponse{
		ID:    uuidutil.ToString(user.ID),
		Name:  user.Name,
		Email: user.Email,
		Role:  user.Role,
	}
}
